% Extract tse scans from bidsoutput to new tse_scans folder
 clear all

source = '/project/3024005.02/bidsoutput'; % Main folder location of files
scanname = '_acq-T1mprage10iso_run-1_T1w.nii.gz'; % The scans to extract
destination = '/project/3024005.02/Analysis/MRI/neuromelanine/raw_T1_scans'; % Where to relocate the scans

startdir = pwd; % Startdir = Analysis/MRI/scripts
cd(source); % cd changes the current folder


folders = dir; % lists all files and folders in the folder
folders = folders(contains({folders.name}, 'sub')); %& ~contains({folders.name}, '.html')); % we have folders and .html files


for sub = 1:length(folders)
    
    subfol = fullfile(source, folders(sub).name);
    cd(subfol)
    subfolders = dir;
    subfolders = subfolders(contains({subfolders.name}, 'ses-mri'));
    
    for ses =  1:length(subfolders)
        
        sesfolder = fullfile(subfol, subfolders(ses).name, 'anat'); 
        if ~exist(sesfolder, 'dir'); continue; end
        cd(sesfolder)

        filename = [folders(sub).name '_' subfolders(ses).name scanname];
        if exist(filename, 'file')
            destination = '/project/3024005.02/Analysis/MRI/neuromelanine/raw_T1_scans';
            copyfile(filename, destination)
        else
            print('warning: file does not exist!')
        end
               
    end    
    
end

cd(startdir)