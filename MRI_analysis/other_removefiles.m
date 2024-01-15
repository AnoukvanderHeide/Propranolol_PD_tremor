%other_removefiles.m removes all .nii files from the fmriprep output (was
%useful when working on first-level analysis when some steps had to be
%reran a few times to test if everything works)

conf.dir.project = fullfile('/project', '3024005.02');
addpath(fullfile(conf.dir.project, 'Analysis', 'SupportingScripts'))
addpath(fullfile(conf.dir.project, 'Analysis', 'MRI', 'scripts'))
helperscripts = fullfile(conf.dir.project, 'Analysis', 'SupportingScripts', 'helpers');
addpath(helperscripts);

conf = coco_conf();

for sub = 1:length(conf.sub.name)  
    CurSub = conf.sub.name{sub};
    for ses = 1:length(conf.sub.ses)  
        CurSes = conf.sub.ses{ses};
        
        subfolder = replace(conf.fla.spec.scan.dir, {'Sub', 'Ses'}, {CurSub, CurSes});
        files = pf_findfile(subfolder, '/*.nii|/');
        
        for f = 1:length(files)
            if iscell(files)
                file = files{f};
            else
                file = files;
            end
            
            fprintf('\ncurfile: %s\n', file);
            userinput = input('remove file? (y/n)\n', 's');
%             userinput = 'y';
            if strcmp(userinput, 'y')
                delete(fullfile(subfolder, file));
            end
            fprintf('removed file\n');
            
            if ~iscell(files)
                break
            end
            
        end
        
    end
    
    
end
