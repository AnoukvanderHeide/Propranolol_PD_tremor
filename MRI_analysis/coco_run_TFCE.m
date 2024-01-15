% This script runs TFCE on a second-level analysis that has already been
% run. The output folders in which the contrasts are found and the ROIs are
% defined in coco_conf.m 

% Anouk van der Heide, 2020

clear all

%==========================================================================
% ---                         Settings                                --- %
%==========================================================================

addpath('/project/3024005.02/Analysis/MRI/scripts/');
conf = coco_conf();

addpath('/home/common/matlab/spm12')
addpath('/home/common/matlab/fieldtrip')
addpath('/home/common/matlab/fieldtrip/qsub')
addpath(fullfile(conf.dir.pf, 'Analysis', 'SupportingScripts'))
addpath(fullfile(conf.dir.pf, 'Analysis', 'MRI', 'scripts'))


%==========================================================================
% ---                          Analysis                               --- %
%==========================================================================

startdir = pwd;

% --- Loop over second level folders ---
for slIdx = 1:length(conf.tfce.secondlevels)
    curSL   = conf.tfce.secondlevels{slIdx};
    mainSlDir = fullfile(conf.dir.spm.group, curSL);
    
    fprintf('\n\nSecond level: %s\n', curSL);
    
    % --- Loop over ROIs ---
    ROIs = conf.tfce.ROIs{slIdx};
    
    for roiIdx = 1:length(ROIs)
        curROI = ROIs{roiIdx};
        
        % Select the correct mask file and folder (either whole-brain or ROI)
        if strcmp(curROI, 'WB')
            ROIname   = 'WholeBrain';
            ROIfolder = fullfile(mainSlDir, ['TFCE_' ROIname]);
            mask      = fullfile(ROIfolder, 'mask.nii,1');
        else
            ROIname   = extractBefore(extractAfter(curROI, 'resliced_'), '.nii');
            ROIfolder = fullfile(mainSlDir, ['TFCE_' ROIname]);
            mask      = fullfile(conf.tfce.dir.ROIs, [curROI, ',1']);
        end
        
        fprintf('  ROI: %s \n', ROIname);
        
        % Create new folder for this ROI
        if ~exist(ROIfolder,'dir'); mkdir(ROIfolder); end
        fprintf('    folder: %s\n', ROIfolder);
        
        % Copy the files to the ROI folder
        fprintf('    copying files\n');
        cd(mainSlDir)
        copyfile('*.nii', ROIfolder)
        
        copyfile('*.mat', ROIfolder)
        cd(ROIfolder)
        
        % Load SPM.mat file to get nr of contrasts
        spmfile         = load(fullfile(ROIfolder, 'SPM.mat'));
        nContrasts      = length(spmfile.SPM.xCon);
        contrastNames   = {spmfile.SPM.xCon(:).name};
        
        fprintf('    running analysis for each contrast\n');

        % --- Loop over the contrasts ---
        for conIdx = 1:nContrasts % for conIdx = [2:8, 10:nContrasts]    % skip con-0009, which is an F-contrast (in case of 2x2 design analysis)
            curCon      = contrastNames{conIdx};
            conString   = num2str(conIdx,'%04.f');
            
            fprintf('      %s | %s | con%s (%s) \n', curSL, ROIname, conString, curCon);
            
            % Check if analysis has already been run for this analysis/ROI/contrast
            if isfile(fullfile(ROIfolder, ['TFCE_' conString '.nii']))
                fprintf('      %s TFCE already run\n', char(8594));
                fprintf('      %s skipping\n', char(8594));
                continue
            end
            
            % Create batch
            matlabbatch = [];
            matlabbatch{1}.spm.tools.tfce_estimate.data              = { fullfile(ROIfolder, 'SPM.mat') };      % select SPM.mat file with contrasts already specified
            matlabbatch{1}.spm.tools.tfce_estimate.nproc             = 0;                                       % use np parallel threads?
            matlabbatch{1}.spm.tools.tfce_estimate.mask              = { mask };                                % specify current mask
            matlabbatch{1}.spm.tools.tfce_estimate.conspec.titlestr  = '';  
            matlabbatch{1}.spm.tools.tfce_estimate.conspec.contrasts = conIdx;                                  % specify current contrast
            matlabbatch{1}.spm.tools.tfce_estimate.conspec.n_perm    = 10000;                                   % number of permutations (default 5000)
            matlabbatch{1}.spm.tools.tfce_estimate.nuisance_method   = 2;                                       % permutation method to deal with nuisance variables; if nuisance variables are found, default=Smith
            matlabbatch{1}.spm.tools.tfce_estimate.tbss              = 0;                                       % use 2D optimization (eg. for DTI data)?
            matlabbatch{1}.spm.tools.tfce_estimate.E_weight          = 0.5;                                     % weighting of cluster size (default=0.5; more weighting of focal effects
            matlabbatch{1}.spm.tools.tfce_estimate.singlethreaded    = 0;                                       % use multi-threading to spead up calculations? Can give trouble on Windows

            % Run batch on cluster
            fprintf('      %s ', char(8594));
            fprintf(' running on cluster\n');
            %qsubfeval('spm_jobman','run',matlabbatch,'memreq',10^10,'timreq',12*3600);
            spm_jobman('run', matlabbatch); % to run without cluster

        end
    end

end

fprintf('\n\nDone!\n\n');


