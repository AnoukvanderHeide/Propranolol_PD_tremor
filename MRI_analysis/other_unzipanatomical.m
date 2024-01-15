%other_unzipanatomical.m gunzips anatomical images (the fmriprep output
%images)

addpath(fullfile(pf, 'Analysis', 'SupportingScripts', 'helpers'));


mainfolder  = '/project/3024005.02/Analysis/MRI/fmriprep-coco/output/fmriprep';
scanname    = '_acq-T1mprage10iso_run-1_space-MNI152NLin6Asym_desc-preproc_T1w.nii.gz';

startdir = pwd;
cd(mainfolder)

folders = dir;
folders = folders(contains({folders.name}, 'sub') & ~contains({folders.name}, '.html'));

for sub = 1:length(folders)
    
    subfol = fullfile(mainfolder, folders(sub).name);
    cd(subfol)
    subfolders = dir;
    subfolders = subfolders(contains({subfolders.name}, 'ses-mri'));
    
    for ses = 1:length(subfolders)
        
        sesfolder = fullfile(subfol, subfolders(ses).name, 'anat'); 
        if ~exist(sesfolder, 'dir'); continue; end
        cd(sesfolder)

        filename = [folders(sub).name '_' subfolders(ses).name scanname];
        if exist(filename, 'file') && ~exist(erase(filename, '.gz'), 'file')
            fprintf('unzipping %s\n', filename);
            gunzip(filename);
        end
        
        
    end
    
    
end

cd(startdir)

