%coco_batch_main.m is the main script to run the fMRI analysis. 
% It runs either first or second-level analysis (depending on user input
% and settings in the coco_conf.m settings file). 
%   If first-level is chosen, it will loop over all subjects and run
%   coco_batch_firstlevel.m for each subject who doesn't have an SPM.mat
%   output file yet in the defined results folder.
%   If second-level is chosen, it will run coco_batch_secondlevel.m.
% Script will either run it on cluster or directly, depending on user input  

clear all
warning('off', 'Findfile:empty');

%==========================================================================
% --- Settings --- %
%==========================================================================

pf = fullfile('/project', '3024005.02');
cd(fullfile(pf, 'Analysis','MRI','scripts'))
helperscripts = fullfile(pf, 'Analysis', 'SupportingScripts', 'helpers');


% Get settings
conf = coco_conf();

% Add useful scripts to path
addpath('/home/common/matlab/spm12')
spm('defaults', 'FMRI');
addpath('/home/common/matlab/fieldtrip')
addpath('/home/common/matlab/fieldtrip/qsub')
addpath(fullfile(pf, 'Analysis', 'SupportingScripts'))
addpath(fullfile(pf, 'Analysis', 'MRI', 'scripts'))
addpath(helperscripts);
ft_defaults

% Get some user input
conf.todo.which = input('first or second level? (first/second)\n', 's');
usecluster      = input('run on cluster? (y/n)\n', 's');

if strcmp(conf.todo.which, 'first') || strcmp(conf.todo.which, 'f')
    
    fprintf('\n\n\n\n ------------------------------------\n +++ Running first-level analysis +++ \n ------------------------------------\n\n');

    % Run first-level analysis per subject
    for sub = 1:length(conf.sub.name)
        CurSub = conf.sub.name{sub};

        conf.cur.sub = CurSub;

        subdir      = replace(conf.dir.spm.sub, {'Sub'}, {CurSub});
        outputdir   = replace(conf.dir.spm.output, {'Sub'}, {CurSub});

        if exist(fullfile(outputdir, 'SPM.mat'), 'file')
            fprintf('%s: there is already an SPM.mat file in the output folder, not running again\n', CurSub);
            continue
        end

        fprintf('%s: ', CurSub); 

        if ~exist(subdir, 'dir'); mkdir(subdir); end
        % run with cluster:
        if strcmp(usecluster, 'y')    
            cd(subdir)
            qsubfeval('coco_batch_firstlevel',conf,'timreq',1.5*60*60,'memreq',12*1024*1000*1000);    
            fprintf('  added %s to cluster\n', conf.cur.sub);
        % run without cluster:
        else
            coco_batch_firstlevel(conf);
        end  


    end

    fprintf('\n\n --------------------------------------\n --- Done with first-level analysis --- \n --------------------------------------\n\n');

% second level:
elseif strcmp(conf.todo.which, 'second') || strcmp(conf.todo.which, 's')
    
    fprintf('\n\n\n\n -------------------------------------\n +++ Running second-level analysis +++ \n -------------------------------------\n\n');

    groupdir = conf.dir.spm.group;
    if ~exist(groupdir, 'dir'); mkdir(groupdir); end

    % run with cluster:
    if strcmp(usecluster, 'y')
        cd(groupdir)
        qsubfeval('coco_batch_secondlevel',conf,'timreq',6*60*60,'memreq',24*1024*1000*1000);    
        fprintf('  added second-level batch to cluster\n');
    % run without cluster:
    else
        coco_batch_secondlevel(conf);
    end  

    fprintf('\n\n ---------------------------------------\n --- Done with second-level analysis --- \n ---------------------------------------\n');
      
else
    fprintf('that''s not an option\n');
       
end

cd(fullfile(conf.dir.MRI, 'scripts')) 
        