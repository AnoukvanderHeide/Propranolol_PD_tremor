%other_checknrofruns.m checks how many runs there are of a certain sequence
clear all

rawfolder = '/project/3024005.02/raw';
scantocheck = 'coco';

startdir = pwd;
cd(rawfolder)

folders = dir;
folders = folders(contains({folders.name}, 'sub'));
for sub = 1:length(folders)
    subfol = fullfile(rawfolder, folders(sub).name);
    cd(subfol)
    subfolders = dir;
    subfolders = subfolders(contains({subfolders.name}, 'ses-mri'));
    
    for scan = 1:length(subfolders)
        
        sesfolder = fullfile(subfol, subfolders(scan).name);   
        cd(sesfolder)
        
        scanfolders = dir;
        cocofolders = scanfolders(contains({scanfolders.name}, scantocheck));
%         pf_findfile(sesfolder, '/task-coco/&/.nii.gz|/');
        if length(cocofolders) > 1
            fprintf('%s - %s: more than one %s file!\n', folders(sub).name, subfolders(scan).name, scantocheck);
            for i = 1:length(cocofolders)
                fprintf('  %s\n', cocofolders(i).name);
            end
            
        end
        
    end
    
    
end


cd(startdir)
