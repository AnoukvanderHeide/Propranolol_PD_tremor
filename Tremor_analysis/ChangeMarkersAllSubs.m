
function ChangeMarkersAllSubs(Task, ProjectNr, Subset, Force)

% Task = 'rest';
Task = 'coco';
ProjectNr = '3024005.02';
Subset = {};                % if left empty, it will use all subjects
Force = false;              % true = reanalyze already processed subjects

%% ToDo
%Improve descriptions
%Improve error handling
%Task = rest errors after a few subjects

%% OS CHECK
if ispc
    pfProject="P:\";
elseif isunix
    pfProject="/project/";
else
    warning('Platform not supported - Linux settings are used')
    pfProject="/project/";
end


%% USER SETTINGS

%Settings specific to task
if  strcmp(Task, "coco")
    settings.TR = 1;
    settings.Scan = '^sub-.*task-coco_acq-epfid2d1104.*nii.gz$';
    settings.NewFolder  = fullfile(pfProject, "3024005.02", "Analysis", "EMG", "coco_markersfixed"); %Output folder for the new files
elseif strcmp(Task, "rest")
    settings.TR = 1;
    settings.Scan = '^sub-.*task-rest_acq-epfid2d1104.*nii.gz$'; %Regular expression used to search for relevant image
    settings.NewFolder = fullfile(pfProject, "3024005.02", "Analysis", "EMG", "rest_markersfixed"); %Output folder for the new files
end
settings.Task = Task;

%% Execution
fprintf("Processing physiological data from %s task in project %s\n", Task, ProjectNr)

%Retrieve subjects
addpath('/home/common/matlab/spm12')
pDir = fullfile(pfProject, ProjectNr);
pBIDSDir = char(fullfile(pDir, 'bidsoutput'));
pBVDir = char(fullfile(pDir, 'raw'));
Sub = cellstr(spm_select('List', fullfile(pBIDSDir), 'dir', '^sub-.*'));
Sub = Sub(strcmp(Sub, 'sub-012'));
% Sub = Sub(6);
% Sel = true(numel(Sub),1);
% AvdH: Resting state: maybe find a way to use 004-1 (only 541/600 BV markers) & 056 (BV saved in 2 parts, combining the files possible?)

% Generate an input table for the ChangeMarkersEMG function
inputTable = cell2table(cell(0,2), 'VariableNames', {'Subject', 'oldFile'});
for n = 1:numel(Sub)
    cSessions = cellstr(spm_select('FPList', fullfile(pBIDSDir, Sub{n}), 'dir', 'ses-mri0[1-2]'));    
    SelSes = true(numel(cSessions),1);  
    curSub = Sub{n}(end-2:end);
    
    for i = 1:numel(cSessions)
        [~, sess, ~] = fileparts(cSessions{i});
        curSess = cSessions{i}(end-1:end);
        
        %%skip the ones that have already been corrected
        vmrk    = spm_select('List', settings.NewFolder, [curSub, '_', curSess, '_.*_', Task, '.vmrk$']);
        eeg     = spm_select('List', settings.NewFolder, [curSub, '_', curSess, '_.*_', Task, '.eeg$']);
        vhdr    = spm_select('List', settings.NewFolder, [curSub, '_', curSess, '_.*_', Task, '.vhdr$']);
        
        if ~isempty(eeg) && ~isempty(vmrk) && ~isempty(vhdr)
            SelSes(i) = false;
            fprintf('%s-%s already processed => skipped \n', Sub{n}(end-2:end), sess(end-1:end))
            continue
        end
        
        %%skip the ones that don't have eeg/vmrk/vhdr data
        vmrk    = spm_select('List', fullfile(pBVDir, Sub{n}, 'Brainvision'), [curSub, '_', curSess, '_.*_', Task, '.vmrk$']);
        eeg     = spm_select('List', fullfile(pBVDir, Sub{n}, 'Brainvision'), [curSub, '_', curSess, '_.*_', Task, '.eeg$']);
        vhdr    = spm_select('List', fullfile(pBVDir, Sub{n}, 'Brainvision'), [curSub, '_', curSess, '_.*_', Task, '.vhdr$']);

        if isempty(vmrk) || isempty(eeg) || isempty(vhdr)
            SelSes(i) = false;
            fprintf('%s-%s has no vmrk/eeg/vhdr files => skipped \n', Sub{n}(end-2:end), sess(end-1:end))
            continue
        end
    end
    
    cSessions = cSessions(SelSes);
    
    sVmrk = "";
    for ses = 1:size(cSessions,1)
        sesNr = cSessions{ses}(end-1:end);
        
        %dVmrk = dir(fullfile(cSessions{ses}, [Sub{n}, '*', Task, '*.vmrk']));
        dVmrk = dir(fullfile(pBVDir, Sub{n}, 'Brainvision', [Sub{n}(end-2:end), '_', sesNr, '_*_', Task, '.vmrk'] ));
        
        if isempty(dVmrk)
            sVmrk(ses,1) = "";
        else
            sVmrk(ses,1) = string(join([dVmrk(end).folder, filesep, dVmrk(end).name]));
        end
    end
    SubjectID = string(repmat(Sub{n}, numel(sVmrk), 1));
    inputTable = [inputTable; table(SubjectID, 'VariableNames', {'Subject'}), table(sVmrk, 'VariableNames', {'oldFile'})];
end

%Check whether a .vmrk is present and select the last run
if isempty(Subset)
    Subset = height(inputTable);
    fprintf('Processing all remaining participants \n', Subset)
elseif ~isempty(Subset) && Subset > height(inputTable)
    Subset = height(inputTable);
    fprintf('Subset is greater than total number of participants. Processing all %i participants instead \n', Subset)
end
inputTable = inputTable(~cellfun(@isempty, inputTable.oldFile),:); %remove subjects without folder
%inputTable = inputTable(1:Subset,:);            % Subset for testing
settings.EEGfolder  = table2array(rowfun(@fileparts, inputTable(:,2)));

%Check markers
logFile.LogTable = rowfun(@(Subject, oldFile) ChangeMarkersEMG(Subject, oldFile, settings), inputTable, ...
    'NumOutputs', 3, ...
    'OutputVariableNames', ["Subject", "File", "Error"]);

%Remove duplicated 'response' events in .vmrk files
for n=1:size(inputTable,1)
    cSub = char(table2array(inputTable(n,1)));
    VMRKfiles = cellstr(spm_select('FPList', fullfile(settings.NewFolder), [cSub '.*task-', Task, '*._eeg.vmrk'])); % Locates multiple visits if available
    for i=1:numel(VMRKfiles)
        ChangeDoubleResponse(VMRKfiles{i});
    end
end

%Log
logFile.settings = settings;
logFile.MissingOriginalFile = inputTable.Subject(ismissing(inputTable.oldFile));
Logname = fullfile(settings.NewFolder, strcat("LogFile", datestr(now,'_mm-dd-yyyy_HH-MM-SS'), ".mat"));
save(Logname, 'logFile');
disp(strcat("Saved log to: '", Logname, "'"));

%% Functions
%This functions changes marker files
function [cSub, oldFile, cError] = ChangeMarkersEMG(cSub, oldFile, settings)

%Start Disp & check if not already ran for this sub
disp(strcat("Analysing Sub: ", cSub));
[~, cFileID, ~] = fileparts(oldFile);
newFile = fullfile(settings.NewFolder, strcat(cFileID, ".vmrk"));
if exist(newFile, 'file')
    warning(strcat("There is already a new markerfile in the new folder for: ", oldFile))
    cError = "There is already a new markerfile in the new folder";
    return
end

%Load file
%-----------------------------------
%Data
cError = string;
cData = readtable(oldFile, ...
    'FileType', 'text', ...
    'ReadVariableNames', false, ...
    'Delimiter', {'=', ','}, ...
    'HeaderLines', 11);
if(size(cData,2) == 6)
    cData.Properties.VariableNames = {'MarkerNumber','MarkerType','Description','PositionInDatapoints','SizeInDataPoints', 'ChannelNumber'};
elseif(size(cData,2) == 7)
    cData.Properties.VariableNames = {'MarkerNumber','MarkerType','Description','PositionInDatapoints','SizeInDataPoints', 'ChannelNumber', 'Unknown'};
end

%Header
cFile = fopen(oldFile);
header=strings(12,1);
for cLine = 1:12
    header(cLine)=string(fgetl(cFile));
end
fclose(cFile);

%Checks for whether the marker file is acceptable.
%-----------------------------------
%Check 1) acceptable R1 notations, remove all others.
%All possible markers
acceptableDescriptions = [strcat("R  ", string(3:2:9)), strcat("R ", string(11:2:31))];
if any(ismember(string(cData.Description), acceptableDescriptions))
    warning(strcat("Adjusted R pulses to R1 for: ", oldFile));
    cError = strcat(cError, " & Adjusted R pulses to R1");
    cData = cData(ismember(string(cData.Description), ["R  1", acceptableDescriptions]), :);
else
    cData = cData(ismember(string(cData.Description), "R  1"), :);
end

% AvdH: Check whether there is a large timelag between 2 markers somewhere at start of
% marker file, in that case start reading from there (probably scan started there but BV started earlier).
% This is the case for 005-1, 005-2, 043 & 006-2.
% MW: Changed this for 012-1, where this messes some things up
Diff_markers = diff(cData.PositionInDatapoints);
Diff_max = max(Diff_markers);

if  Diff_max > 5010 & ~(contains(cFileID, '012_01') & strcmp(settings.Task, 'coco')) % random number, as long at it is clearly above 5000 
    Max_index = find(Diff_max == Diff_markers);
    cData = cData(Max_index+1:end,:); % if there is a large timelag, this probably meant the scanner started afterwards, so remove all rows before
end
if contains(cFileID, '012_01') & strcmp(settings.Task, 'coco')
    keyboard
    Max_index = find(Diff_max == Diff_markers);
    cData = cData(1:Max_index,:);
end

%Check 2) acceptable timings, will also show additional pulses
acceptableTimings=[settings.TR*5000, (settings.TR*5000)-1, (settings.TR*5000)+1];
if ~all(ismember(diff(cData.PositionInDatapoints), round(acceptableTimings)))
    warning(strcat("Not all R1 scans have the same interval for: ", oldFile, "trying to fix..."))
    cError = strcat(cError, " & Not all R1 pulses have the same interval FIXED!!!!!");
    cData = fixTimings(cData, acceptableTimings);
    
    %Check if fixed
    if ~all(ismember(diff(cData.PositionInDatapoints), round(acceptableTimings)))
        warning(strcat("Not all R1 scans have the same interval for: ", oldFile))
        cError = strcat(cError, " & Not all R1 pulses have the same interval");
        return
    end
end

%Check 3) Check if there are sufficient pulses
%Find number of pulses

temp = char(cFileID);
cSes = temp(5:6);
cImgDir = ['/project/3024005.02/bidsoutput/', char(cSub), '/ses-mri', cSes, '/func'];
cImgDir = convertCharsToStrings(cImgDir);
cImg = spm_select('FPList', cImgDir, settings.Scan);
if strcmp(cSub, "sub-012") & strcmp(cSes, '01') & strcmp(settings.Task, 'coco')   % for coco task!
    idxFile = 1;
else
    idxFile = size(cImg,1);
end
cImgSize = size(spm_vol(cImg(idxFile,:)),1);

if (size(cData, 1) == cImgSize+1)
    warning(strcat("One pulse too many for: ", oldFile));
    cError = strcat(cError, " & One pulse too many - REMOVED LAST PULSE");
    cData(end,:)=[];
elseif (size(cData, 1) > cImgSize)
    warning(strcat("More then one pulse too many for: ", oldFile));
    cError = strcat(cError, " & More then one pulse too many");
    return
elseif (size(cData, 1) < cImgSize)
    warning(strcat("Not enough pulses for: ", oldFile));
    cError = strcat(cError, " & Not enough pulses");
    if ~(strcmp(cSub, "sub-012") & strcmp(cSes, '01') & strcmp(settings.Task, 'coco'))
        return
    else
        fprintf('Continuing for sub-012 (coco)\n');
    end
end

%Check 4) acceptable header name
cHeaderRow = contains(header, "DataFile");
cHeaderID = extractBetween(header(cHeaderRow),"DataFile=",".eeg");
if cHeaderID ~= cFileID
    warning(strcat("Headerfile does not match with filename for: ", oldFile))
    cError = strcat(cError, " & Headerfile does not match with filename");
end

%If no error
if strcmp(cError, ""); cError = "No error detected"; end

% Fix potential problems
%-----------------------------------
%Update fileChange Header "\1" to make it interpretable
header = replace(header, '"\1".', '\"\\1\".');

%Fix Header ID
if contains(cError, "Headerfile")
    header(cHeaderRow)=replace(header(cHeaderRow), cHeaderID, cFileID);
end

%Rework marker numbers & remove unnecessary columns
cData.MarkerNumber = strcat("Mk", string(2:length(cData.MarkerNumber)+1))';
cData.MarkerNumber = strcat(cData.MarkerNumber, "=", cData.MarkerType);
if(size(cData,2) == 6)
    cData=removevars(cData, {'MarkerType'});
elseif(size(cData,2) == 7)
    cData=removevars(cData, {'MarkerType', 'Unknown'});
end

%Set Description markers to "R  1"
cData.Description = repmat("R  1", size(cData,1), 1);

%Save new file
%-----------------------------------
%Make a file with the updated header
cFile = fopen(newFile, 'w+');
for cLine = 1:12
    fprintf(cFile, strcat(header(cLine), '\r\n'));
end
fclose(cFile);

%Make a temp file with the data
tempDataFile = fullfile(settings.NewFolder, strcat(cFileID, "_tempData.vmrk"));
writetable(cData, tempDataFile, 'WriteVariableNames', false, 'FileType', 'text');

%Merge
cHeaderFile = fopen(newFile, 'a'); %open
cDataFile = fopen(tempDataFile, 'r');
cDataFileContents = fread(cDataFile); %read data as binary
fwrite(cHeaderFile,cDataFileContents); %append to headerfile
fclose(cHeaderFile); %close
fclose(cDataFile);

%Remove tempData file
delete(tempDataFile)

%Copy .eeg and .vhdr files
cBase = fullfile(fileparts(oldFile), cFileID);
cTarget = fullfile(settings.NewFolder, cFileID);
copyfile(strcat(cBase, ".eeg"), strcat(cTarget, ".eeg")); %.eeg
copyfile(strcat(cBase, ".vhdr"), strcat(cTarget, ".vhdr")); %.vhdr

%End disp
disp("Done! Next file...");
end

%This function will fix wrong timings
function newData = fixTimings (cData, allTimings)
cDiff = diff(cData.PositionInDatapoints);
cWrong = ~ismember(cDiff, round(allTimings));

%If the pulses are in the beginning, they can just be removed
while cWrong(1)
    cData(1, :) = [];
    cDiff = diff(cData.PositionInDatapoints);
    cWrong = ~ismember(cDiff, allTimings);
end

%Otherwise, find the first one and remove the one afterwards.
while sum(cWrong)>0
    RemovePulse = find(cWrong,1)+1;
    cData(RemovePulse, :) = [];
    cDiff = diff(cData.PositionInDatapoints);
    cWrong = ~ismember(cDiff, round(allTimings));
end

%Parse cData
newData = cData;
end

function [vmrkfile] = ChangeDoubleResponse(vmrkfile)
    
    if(isempty(vmrkfile))
        return
    end
    
    cData = fopen(vmrkfile);
    header=string(fgetl(cData));
    while 1
        OldLine = fgetl(cData);
        if ~ischar(OldLine), break, end         % Break when there are no more lines to read
        if(contains(OldLine, 'Response,Response,R ') || contains(OldLine, 'R 1'))
            newLine = strrep(OldLine, 'Response,Response,R ', 'Response,R ');
            newLine = strrep(newLine, 'R 1', 'R  1');
        else
            newLine = OldLine;
        end
        header = [header; newLine];
    end
    fclose(cData);    
    header = header';
    
    cHeaderFile = fopen(vmrkfile, 'w+');        % overwrite content
    for line = 1:length(header)
        fprintf(cHeaderFile, strcat(header(line), '\r\n'));
    end
    fclose(cHeaderFile); %close
    
end

end
