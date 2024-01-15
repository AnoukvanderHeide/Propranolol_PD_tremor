%--------------------------------------------------------------------------
%RETROICORplus v1.2 (previously RETROICOR v1.0-v1.1)
%
%RETROICORplus creates physiological noise regressors for fRMI data.
%
%usage:
%RETROICORplus(matFilename,RETROICORbegremscans,RETROICORendremscans, outputdir)
%
%matFilename: name of the matfile created by HeRa
%RETROICORbegremscans: how many EPIs are discarded at the beginning
%RETROICORendremscans:  how many EPIs are discarded at the end
%outputdir: folder where output regressors should be saved.
%
%This RETROICOR implementation is based on Glover et al's 2000 MRM paper.
%Initial versions of the implementation were created by Bas Neggers,
%Matthijs Vink, Thomas Gladwin, and Mariet van Buuren at Utrecht
%University. The current version was updated in collaboration with Mariet
%van Buuren.
%EJH 2010-16
%--------------------------------------------------------------------------

%MW: added code to pad 018-01 with NaNs for coco
%MW: also store list with names of regressors

function RETROICORplus(matFilename,RETROICORbegremscans,RETROICORendremscans, outputdir, conf)

  
if ~nargin
    [matfile, matpath, irr] = uigetfile( ...
       {'*.mat','HeRa MAT files (*.mat)'}, ...
        'Pick a MAT file created by HeRa');
    matFilename = fullfile(matpath,matfile);
    
    outputdir = matpath;
    
    RETROICORbegremscans = inputdlg('Number of scans to remove at beginning','',1);
    RETROICORbegremscans = str2num(RETROICORbegremscans{1});

    RETROICORendremscans = inputdlg('Number of scans to remove at end','',1);
    RETROICORendremscans = str2num(RETROICORendremscans{1});

end

%--------------------------------------------------------------------------
%Get defaults
RETROICORplus_defaults_setup;

%--------------------------------------------------------------------------

%Load hera processed pulse data
heradata = load(matFilename);
%--------------------------------------------------------------------------

%Get sample rate
SR = heradata.matfile.settings.samplerate;

%Run rejection interpolation
heradata.matfile = ...
    RETROICORplus_interpolate_hera_reject(heradata.matfile,SR);

%Get all scan triggers, set to vertical vector
if size(heradata.matfile.markerlocs,2)>1
    scanTriggers = heradata.matfile.markerlocs';
else
    scanTriggers = heradata.matfile.markerlocs;
end

%Check if this is a continuous run
if sum(abs(diff(scanTriggers)-mean(diff(scanTriggers)))>2) >0 %TR is never more than 2 ms off mean
    error('This appears not to be a continuous recording')
end

%Run RETROICOR to create regressors
[CPR,RPR,NR]=RETROICORplus_calc(...
    scanTriggers,...                    %Scan trigger indices
    heradata.matfile.prepeaklocs,...    %Heart beat peak indices
    heradata.matfile.rawpulsedata,...   %Pulse data
    heradata.matfile.rawrespdata,...    %Respiration data
    SR,...                              %sample rate
    RETROICORplus_defaults);                %Defaults

%Save the result
R = [CPR,RPR,NR];
R = R(RETROICORbegremscans+1:end-RETROICORendremscans,:); %Remove omitted scans

% MW: pad data of 018-1 for coco task with NaNs
fname = extractAfter(matFilename, ['reformatted_' conf.task '/']);
if strcmp(conf.task, 'coco') && strcmp(fname(1:6), '018_01')
    fprintf('  fixing the 018-01 stuff\n')
    % the first rest onset is the 34th scan => instead of 60 scans, there's only 33 in the first coco block, so:
    scansMissing = conf.exception.s018s01.nScansMissing; 
    extraScans   = conf.trial.nrScansPre;
    R = [nan(scansMissing + extraScans, size(R,2)); R];
    
% MW: Pad restings state scans with NaNs if data at the end is missing
elseif strcmp(conf.task, 'rest') && length(R) < conf.trial.duration
    scansMissing = conf.trial.duration - length(R);
    if scansMissing < 5 % ignore when a few data points at the end are missing (shouldn't be too many though)
        warning('  the regressor is too short, padding with %s zeroes at the end\n', num2str(scansMissing));
        R = [R; nan(scansMissing, size(R,2))];
    elseif strcmp(fname(1:6), '004_01') || strcmp(fname(1:6), '056_01') 
        % 004-01: I have no idea what went wrong with this brainvision file, but only has 540 markers, so for now don't create regressor
        % 056-01: data is split in two brainvision files, not sure how those could be put back together (alignment-wise), so skipping for now
        error('  there''s something wrong with this brainvision file, skipping for now\n');
    else
        warning('  the regressor is missing %s datapoints, check what''s going wrong\n', num2str(scansMissing));
                
        keyboard
    end
end


%%MW: add names as well
names = [
    strtrim(cellstr(num2str([1:10]', 'cardiac_phase_%d')));                         %1-10:  cardiac phase regressors 
    strtrim(cellstr(num2str([1:10]', 'resp_phase_%d')));                            %11-20: respiratory phase regressors 
    strtrim(cellstr(num2str(RETROICORplus_defaults.TS_HRF', 'HR_bpm_timelag_%d'))); %Heart rate (bpm): one per time lag (defined in RETROICORplus_defaults_setup)
    strtrim(cellstr(num2str(RETROICORplus_defaults.TS_RVT', 'HR_bpm_timelag_%d'))); %Repiratory volume per unit time: one per time lag
];

[path,matname,EXT] = fileparts(matFilename);
outfile = fullfile(outputdir,[matname,'_RETROICORplus_regr.mat']);
save(outfile,'R', 'names');

