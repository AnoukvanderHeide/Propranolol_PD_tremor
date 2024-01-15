function coco_secondLevel_pairedTtest(conf)
% coco_secondlevel_pairedTtest.m creates and runs a second-level batch with a paired
% t-test for the defined contrast of interest. This can be used to run TFCE.  

% Test for main effect
comparison = {'coco_general', 'all_general', 'all_tremoramp',...
              'coco>rest_general', 'coco>rest_tremoramp'}; % use all_ contrasts to have average over trials, for general drug effect
alloutfolder{1} = fullfile(conf.dir.spm.group, 'cocovsrest(general)');    % task-related activity
alloutfolder{2} = fullfile(conf.dir.spm.group, 'placvsprop(general)');    % main effect drug
alloutfolder{3} = fullfile(conf.dir.spm.group, 'placvsprop(tremoramp)');  % tremor-related drug activity
alloutfolder{4} = fullfile(conf.dir.spm.group, 'interaction(general)');   % interaction trialxdrug
alloutfolder{5} = fullfile(conf.dir.spm.group, 'interaction(tremoramp)'); % interaction trialxdrug

contrasts     = conf.fla.con.contrasts;
contrastNames = {contrasts(:).name};
nrFcon = length(conf.fla.con.fcontrasts); % the number of F-contrasts that are included (are in the list of contrasts before t-contrasts)

% loop over contrasts
for con = 1 : length(comparison)
    
    % Get the right contrasts for placebo and propranolol sessions
    idxCon        = find(strcmp(contrastNames, comparison{con}));
    idx_plac      = (idxCon-1)*3 + nrFcon*3 + 1; % every contrast name is repeated 3x, for plac, prop and average (so +1 for plac). Dont forget F-contrasts!
    concode_plac  = ['con_' num2str(idx_plac,'%04.f')]; 
    filename_plac = [concode_plac '.nii'];
    fprintf('    contrast code placebo contrast: %s\n', concode_plac); % all_tremoramp plac: con_0025; coco>rest_tremoramp plac: con_0034
    idx_prop      = (idxCon-1)*3 + nrFcon*3 + 2; % every contrast name is repeated 3x, for plac, prop and average (so +2 for prop). Dont forget F-contrasts!
    concode_prop  = ['con_' num2str(idx_prop,'%04.f')]; 
    filename_prop = [concode_prop '.nii'];
    fprintf('    contrast code propranolol contrast: %s\n', concode_prop); % all_tremoramp prop: con_0026; coco>rest_tremoramp prop: con_0035
    
    % Get the right contrasts for coco and rest comparison, averaged over both sessions
    idx_coco      = (idxCon-1)*3 + nrFcon*3 + 3; % every contrast name is repeated 3x, for plac, prop and average (so +3 for both). Dont forget F-contrasts!
    concode_coco  = ['con_' num2str(idx_coco,'%04.f')]; 
    filename_coco = [concode_coco '.nii'];
    fprintf('    contrast code contrast for coco: %s\n', concode_coco);
    idxCon2      = find(strcmp(contrastNames, 'rest_general'));
    idx_rest      = (idxCon2-1)*3 + nrFcon*3 + 3; % every contrast name is repeated 3x, for plac, prop and average (so +3 for both). Dont forget F-contrasts!
    concode_rest  = ['con_' num2str(idx_rest,'%04.f')]; 
    filename_rest = [concode_rest '.nii'];
    fprintf('    contrast code contrast for rest: %s\n', concode_rest); 
    
    % Get output folder
    outfolder  = alloutfolder{con};
    
    if ~exist(outfolder,'dir'); mkdir(outfolder); end
    fprintf('\n  folder: %s\n', outfolder);

    % Skip if there's already an SPM.mat file for this contrast
    if exist(fullfile(outfolder, 'SPM.mat'), 'file')
        fprintf('  there is already an SPM.mat file for this contrast\n');
    end

    % Add covariate info
    conf = other_getcovariates(conf);
    fprintf('  adding covariates...\n')
    
    % Loop over subjects and retrieve contrast output images
    for sub = 1:length(conf.sub.name)
        subfolder = replace(conf.dir.spm.output, {'Sub'}, conf.sub.name(sub));

        % get flipped file if necessary (if most affected hand is the left side)
        tremside = conf.sub.hand{sub}; % most affected hand
        if ~strcmp(tremside, 'R') && contains(comparison{con}, 'tremor')
            subfile_plac = fullfile(subfolder, ['rflipped_' filename_plac]);
            subfile_prop = fullfile(subfolder, ['rflipped_' filename_prop]);
        else
            subfile_plac = fullfile(subfolder, filename_plac);
            subfile_prop = fullfile(subfolder, filename_prop);
            subfile_coco = fullfile(subfolder, filename_coco);
            subfile_rest = fullfile(subfolder, filename_rest);
        end

        if ~exist(subfile_plac, 'file')
            fprintf('      "%s" doesn''t exist\n', subfile_plac);
            continue
        end

        % Fill in contrast files for matlab batch in pairs per subject
        if strcmp(comparison{con}, 'coco_general')
            matlabbatch{1}.spm.stats.factorial_design.des.pt.pair(sub).scans = {
            [subfile_coco,',1']
            [subfile_rest,',1']}; 
        else
            matlabbatch{1}.spm.stats.factorial_design.des.pt.pair(sub).scans = {
            [subfile_plac,',1']
            [subfile_prop,',1']}; 
        end

        % Covariates have to be added in pairs as well, so make new array for this
        age_paired(sub*2-1) = conf.sub.age(sub);
        age_paired(sub*2)   = conf.sub.age(sub);
        sex_paired(sub*2-1) = conf.sub.gender(sub);
        sex_paired(sub*2)   = conf.sub.gender(sub);
        FD_paired(sub*2-1)  = conf.sub.FDplac(sub);
        FD_paired(sub*2)    = conf.sub.FDprop(sub);
        tremor_paired(sub*2-1) = conf.sub.tremor(sub);
        tremor_paired(sub*2)   = conf.sub.tremor(sub);

    end

        % --- Further fill in SPM batch ---

        matlabbatch{1}.spm.stats.factorial_design.dir           = {outfolder};    
        matlabbatch{1}.spm.stats.factorial_design.des.pt.gmsca  = 0;  % not for fMRI
        matlabbatch{1}.spm.stats.factorial_design.des.pt.ancova = 0; % not for fMRI
        matlabbatch{1}.spm.stats.factorial_design.cov           = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
       
        % Add covariates to matlabbatch

        matlabbatch{1}.spm.stats.factorial_design.cov(1).c      = [FD_paired]'; % correct for mean FD for all participants
        matlabbatch{1}.spm.stats.factorial_design.cov(1).cname  = 'mean(FD)';
        matlabbatch{1}.spm.stats.factorial_design.cov(1).iCFI   = 1;
        matlabbatch{1}.spm.stats.factorial_design.cov(1).iCC    = 1;
        fprintf('    added mean(FD)\n')
        
%         matlabbatch{1}.spm.stats.factorial_design.cov(2).c      = [tremor_paired]'; % correct for mean tremor amplitude during scan
%         matlabbatch{1}.spm.stats.factorial_design.cov(2).cname  = 'Tremor';
%         matlabbatch{1}.spm.stats.factorial_design.cov(2).iCFI   = 1;
%         matlabbatch{1}.spm.stats.factorial_design.cov(2).iCC    = 1;
%         fprintf('    added Tremorlog\n')
        
%         matlabbatch{1}.spm.stats.factorial_design.cov(2).c      = [age_paired]';
%         matlabbatch{1}.spm.stats.factorial_design.cov(2).cname  = 'Age';
%         matlabbatch{1}.spm.stats.factorial_design.cov(2).iCFI   = 1;
%         matlabbatch{1}.spm.stats.factorial_design.cov(2).iCC    = 1;
%         fprintf('    added Age\n');
% 
%         matlabbatch{1}.spm.stats.factorial_design.cov(3).c      = [sex_paired]';
%         matlabbatch{1}.spm.stats.factorial_design.cov(3).cname  = 'Gender';
%         matlabbatch{1}.spm.stats.factorial_design.cov(3).iCFI   = 1;
%         matlabbatch{1}.spm.stats.factorial_design.cov(3).iCC    = 1;
%         fprintf('    added Gender\n');

        matlabbatch{1}.spm.stats.factorial_design.multi_cov             = struct('files', {}, 'iCFI', {}, 'iCC', {});
        matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none    = 1;
        matlabbatch{1}.spm.stats.factorial_design.masking.im            = 1;
        matlabbatch{1}.spm.stats.factorial_design.masking.em            = {''};
        matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit        = 1;    % option for PET, not for fMRI
        matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;   % option for PET, not for fMRI
        matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm       = 1;    % option for PET, not for fMRI

        % --- Model estimation --- 
        matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep('Factorial design specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
        matlabbatch{2}.spm.stats.fdfmri_est.write_residuals     = 0;            % only for classical inference
        matlabbatch{2}.spm.stats.fmri_est.method.Classical      = 1;
        matlabbatch{3}.spm.stats.con.spmmat(1) = cfg_dep('Model estimation: SPM.mat File', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
        % in case of error that cfg_dep is unknown, first run matlabbatch with spm_jobman for the design settings
        
        % --- Contrasts ---
        if strcmp(comparison{con}, 'coco_general')
            matlabbatch{3}.spm.stats.con.consess{1}.tcon.name   = 'rest>coco';
        else
            matlabbatch{3}.spm.stats.con.consess{1}.tcon.name   = 'prop>plac';
        end
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights    = [-1 1]; 
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep    = 'none';

        if strcmp(comparison{con}, 'coco_general')
            matlabbatch{3}.spm.stats.con.consess{2}.tcon.name   = 'coco>rest';
        else
            matlabbatch{3}.spm.stats.con.consess{2}.tcon.name   = 'plac>prop';
        end
        matlabbatch{3}.spm.stats.con.consess{2}.tcon.weights    = [1 -1]; 
        matlabbatch{3}.spm.stats.con.consess{2}.tcon.sessrep    = 'none';
        
        matlabbatch{3}.spm.stats.con.delete                     = 0;
        
        % --- Save batch ---
        savename = [outfolder '.mat'];
        save(savename,'matlabbatch');
        fprintf('\nsaved batch to "%s"\n', savename);

        % --- Run batch ---
        fprintf('\nrunning second-level batch now...\n');
        spm_jobman('run',matlabbatch);
        fprintf('\ndone with second-level!\n\n');
        
        clear matlabbatch
end

end