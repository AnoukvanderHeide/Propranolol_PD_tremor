%eyelink_batch.m is the main script to run eyelink analysis
% Steps
%  single-level: 
%    reformat
%    create regressor
%  group level: 
%    look at data quality
%    average (+ plot average)


clear all
warning('off', 'Findfile:empty');

%==========================================================================
% --- Settings --- %
%==========================================================================

% Task = 'coco'; 
Task = 'rest';

conf.Task = Task;

% --- Directories ---
conf.dir.project        = fullfile('/project', '3024005.02');
conf.dir.raw            = fullfile(conf.dir.project, 'raw');
conf.dir.root           = fullfile(conf.dir.project, 'Analysis', 'Eyelink');
conf.dir.input          = fullfile(conf.dir.root, 'input');
conf.dir.reform         = fullfile(conf.dir.root, ['data_', Task]);             % directory containing .mat files
conf.dir.plots          = fullfile(conf.dir.root, 'plots');                     % directory to save plots
conf.dir.regrplots      = fullfile(conf.dir.plots, 'regressors', Task);         % directory to save plots of regressors
conf.dir.avgplots       = fullfile(conf.dir.plots, 'average', Task);            % directory to save plots of averages
conf.dir.analysis       = fullfile(conf.dir.root, 'analysis');                  % directory where analysis will be stored
conf.dir.spikecheck     = fullfile(conf.dir.analysis, 'dataquality', Task);      % dir where spikecheck analysis results will be stored
conf.dir.regressor      = fullfile(conf.dir.analysis, 'regressors', Task);        % dir where regressors will be stored
conf.dir.average        = fullfile(conf.dir.analysis, 'groupresults', Task);     % dir where plot with average will be stored
conf.dir.averagedq      = conf.dir.average;     % dir where data quality info will be stored

conf.dir.bv             = fullfile(conf.dir.raw, 'sub-Sub', 'Brainvision'); % location of brain vision files
conf.dir.mri            = fullfile(conf.dir.raw, 'sub-Sub', 'ses-mriSes'); % location of brain vision files

% --- File names resting state ---
conf.file.raw           = ['/Sub_Ses_', Task(1),'.asc/'];                        % name of the raw .asc file
conf.file.reformmated   = ['/Sub_Ses_', Task(1),'.mat/'];                        % name of the reformatted .mat file
conf.file.spikecheck    = ['/Sub_Ses_', Task(1),'_dataquality.mat/'];            % name of the .mat file with the results of the spike analysis and regressors
conf.file.regressor     = ['/Sub_Ses_', Task(1),'_regressor_Transform.mat/'];    % name of the .mat file with the regressor
conf.file.mri           = ['MB6_2.0iso_TR1000TE34_', Task];             % name of the MRI scan (used when creating regressors)
conf.file.average       = ['average_Transform_' Task '.mat'];                  % name of the file the average will be saved to (Transform => raw/log-zscored/notzscored)
conf.file.averagedq     = ['data_quality_', Task,'.mat'];                  % name of the file the data quality results will be saved to
conf.file.avgplot       = ['average_Transform_' Task '.png'];
conf.file.bv            = ['/Sub_Ses_/&/_', Task,'.vmrk/'];                % name of brainvision files


% --- Get some useful scripts ---
addpath(fullfile(conf.dir.project, 'Analysis', 'SupportingScripts', 'helpers'));
addpath(fullfile(conf.dir.project, 'Analysis', 'SupportingScripts'));
addpath('/home/common/matlab/spm12')

% --- Subjects ---
conf.sub.name = { 
%                   '001'; '002'; '003'; '004'; '005'; ...        %TD participants
%                   '006'; '007'; '008'; '009'; '010'; ...
%                   '011'; '012'; '013'; '014'; '015'; ...
%                   '016'; '017'; '018'; '019'; '020'; ...
%                   '021'; '022'; '023'; '024'; '025'; ...
%                   '026'; '027'; '028'; '029'; '030'; ...
%                     
                  '031'; '032'; '033'; '034'; '035'; ...        %NT participants
                  '036'; '037'; '038'; '039'; '040'; ...
                  '041'; '042'; '043'; '044'; '045'; ...
                  '046'; '047'; '048'; '049'; '050'; ...
                  '051'; '052'; '053'; '054'; '055'; ...
                  '056'; '057'; '058'; '059'; '060'; ...
                  
                  '061'; '062'; '063'; '064'; '065'
                };  
% conf.sub.name = {'010', '011', '012'};
              
              
                
% --- Session settings ---
conf.sub.ses = {'01'; '02'}; % Names of the sessions (in filenames)

% --- To do ---
% subject level
conf.todo.singlelevel   = true;     % if false, none of the single level things (reformat, spikecheck, regressor) will be done (regardless of what those todo settings are set to below)
conf.todo.reformat      = true;     % reformat the raw data (only done if not done yet)
conf.todo.regressor     = true;     % create a regressor from the data (only done if not done yet, unless conf.force.regressor = true)
% group level
conf.todo.dataquality   = false;     % compile data quality of all datasets into one structure
conf.todo.average       = false;     % create an average of all available regressors from the subs in conf.sub.name
conf.todo.plotaverage   = false;     % create a plot of the average


% --- Force: Which analysis to do even if done already ---
conf.force.regressor    = false;


% --- Trial settings ---
conf.trial.nTrials              = 10;       % nr of trials
conf.trial.trialDurDP           = 60001;    % nr of datapoints in one trial
conf.trial.trialDurSec          = 60;       % nr of seconds in one trial    

% --- Settings regressor ---
conf.regressor.var              = 'Pupil';       % variable in .mat file you want to include (options: 'Raw X', 'Raw Y', 'Pupil'
conf.regressor.scan             = 'detect';      % detect nScans (so it will select conf.regressor.dummyscan+1:conf.regressor.scan)
conf.regressor.tr               = 1;             % the scan TR used to calculate hrf for convolution and to calculate average value per scan

conf.regressor.threshold.spikecheck.drop  = 880; % upper limit (in arbitrary units) to determine data drop-out
conf.regressor.threshold.spikecheck.spike = 175; % threshold (delta a.u. for subsequent datapoint) for spikes
conf.regressor.threshold.drop   =  880;          % threshold for pupil diameter (au) included for average value for scan
conf.regressor.threshold.varsd  =  3;            % threshold: data outside this standard deviation are not included for calcualtion of average value / scan
conf.regressor.threshold.pepoch =  40;           % threshold for how many of the samples within an epoch can have bad quality

conf.regressor.bv.samplingrate  = 5000;          % sampling rate of brainvision files (necessary to get scan markers)
conf.regressor.bv.stnddiff      = 40;            % difference (in ms) between start scan and start condition (only used when no marker files are found)
conf.regressor.bv.stndscanpre.coco   = 11;           % number of complete scans before the start of the first condition (only used when no marker files are found) = 10+1 because scan usually starts just before trial
conf.regressor.bv.stndscanpre.rest   = 6;            % number of complete scans before the start of the first condition (only used when no marker files are found) = 5+1  because scan usually starts just before trial
conf.regressor.bv.maxdiff       = 200;           % if the trial starts more than this nr of ms after previous scan trigger, throw error (because it's sus), otherwise it will ignore the difference
conf.regressor.plot.on          = true;          % plot final regressors
conf.regressor.plot.cond        = strcmp(Task, 'coco');         % plot conditions (strcmp(Task, 'coco') => only plots for coco task).
% which regressors to create: (will create a regressor for each combination of zscore x transform)
conf.regressor.zscore           = {
                                    'zscored';
                                    'notzscored';
                                    };
conf.regressor.transform        = {
                                     'raw'; % raw data
                                     'log'; % log transformed
                                      };

% --- Settings for creating averages ---
conf.average.plot.width          = 750;     
conf.average.plot.height         = 400;
conf.average.plot.plotconditions = false;
conf.average.plot.onsets         = [1:120:600];
conf.average.plot.offsets        = conf.average.plot.onsets + 59;
conf.average.threshold.incl      = 25;       % threshold for how much of the data can be drop (if more % of the data than this threshold is bad, data won't be included)
% which averages to create: (will create an average for each combination
% of zscore x transform)
conf.average.todo.zscores        = {
                                    'zscored';
                                    'notzscored';
                                    };
conf.average.todo.transforms     = {
                                     'raw'; % raw data
                                     'log'; % log transformed
                                      };


%==========================================================================
% --- Individual preprocessing and analysis (per subject) --- %
%==========================================================================

if conf.todo.singlelevel

for i = 1:length(conf.sub.name)
    CurSub = conf.sub.name{i};
    
    for j = 1:length(conf.sub.ses)
        CurSes = conf.sub.ses{j};
        SubSes = [CurSub '-' CurSes];
        
        conf.cur.sub         = CurSub;
        conf.cur.sess        = CurSes;
        
        fprintf('\n%s-%s:\n', CurSub, CurSes);

        %==========================================================================
        % --- reformat: Convert .asc to .mat --- %
        %==========================================================================

        if conf.todo.reformat

        ReformFname = replace(conf.file.reformmated, {'Sub', 'Ses'}, {CurSub, CurSes});
        ReformFile  = pf_findfile(conf.dir.reform, ReformFname);
            
        RawFname    = replace(conf.file.raw, {'Sub', 'Ses'}, {CurSub, CurSes});
        RawFile     = pf_findfile(fullfile(conf.dir.raw, ['sub-' CurSub], 'Eyelink'), RawFname);
        RawFname2   = replace(RawFname, ['_' Task(1) '.'], upper(['_' Task(1) '.']));
        RawFile2    = pf_findfile(fullfile(conf.dir.raw, ['sub-' CurSub], 'Eyelink'), RawFname2);
        
        if isempty(RawFile) & ~isempty(RawFile2)
            RawFile = RawFile2;
        end
        
        % --- Check if the file is already reformated --- 
        if ~isempty(ReformFile) 
            fprintf('  already reformatted\n');

            
        % --- Skip if there's no raw file to reformat --- 
        elseif isempty(RawFile)
            fprintf('  no raw files found\n  => skipped \n');
            fprintf('%s-%s done!\n', CurSub, CurSes);
            continue %if there's no raw file => nothing left to do

        % --- Skip 001-01 --- 
        % There's something wrong with the markers that makes reformatting
        % not possible (and skipping is quicker than waiting for the
        % reformatting script to get to the error each time)
        elseif strcmp(SubSes, '001-01') && strcmp(Task, 'rest')
            fprintf('  skipping because there''s something wrong with the raw file\n');
            continue
            
        % --- Else reformat the file --- 
        else
            fprintf('  reformatting %s... \n', RawFile);
            conf.temp.eyelinkfile = RawFile;
            Reformat_interpol_complete({CurSub}, CurSes, conf)
            fprintf('  reformatting complete \n');
        end
               
        end        
        
        %==========================================================================
        % --- regressor: Create a regressor --- %
        %==========================================================================
        
        if conf.todo.regressor
            
        ReformFname = replace(conf.file.reformmated, {'Sub', 'Ses'}, {CurSub, CurSes});
        ReformFile  = pf_findfile(conf.dir.reform, ReformFname);
            
        % --- Skip if there's no reformatted file to analyse --- 
        if isempty(ReformFile)
            fprintf('  no file found to create regressor for\n  => skipped\n');
            fprintf('%s-%s done!\n', CurSub, CurSes);
            continue
        end
        
        
        % --- Else open file --- 
        clear p
        p = load(fullfile(conf.dir.reform,ReformFile));

        
        % --- Check if there's useful data ---
        if isempty(p.pupdat.trialonsets{3})
            fprintf('  no trial on and offsets found\n');
            fprintf('%s-%s done!\n', CurSub, CurSes);
            continue
        end

        
        % --- Add all the different transforms to create to a list ---
        % (only the ones that haven't been created yet)
        conf.regressor.todo = {};
        for i = 1:length(conf.regressor.transform)
            for j = 1:length(conf.regressor.zscore)
                CurTransform    = [conf.regressor.transform{i} '-' conf.regressor.zscore{j}];
                RegrFname       = replace(conf.file.regressor, {'Sub', 'Ses', 'Transform'}, {CurSub, CurSes, CurTransform});
                RegrFile        = pf_findfile(conf.dir.regressor, RegrFname);
                if isempty(RegrFile) || conf.force.regressor
                    conf.regressor.todo{end+1} = [conf.regressor.transform{i} '-' conf.regressor.zscore{j}];
                end
            end
        end

        
        % --- Check if all regressors have already been created ---
        if isempty(conf.regressor.todo)
            fprintf('  already created all regressors\n');
            fprintf('%s-%s done!\n', CurSub, CurSes);
            continue
        end

        
        % --- Create the regressors ---
        fprintf('  creating %i regressors...\n', length(conf.regressor.todo));
        err = eyelink_regressor(conf);  
        if ~err
            fprintf('  regressors created\n'); 
        end
        
        end
        
        
        %==========================================================================
        % --- done --- %
        %==========================================================================
        
        fprintf('%s-%s done!\n', CurSub, CurSes);
        
    end
    
end
end


%==========================================================================
% --- average: Collect data quality --- %
%==========================================================================

if conf.todo.dataquality   
    
fprintf('  collection data quality\n');
eyelink_dataquality(conf);
fprintf('  data quality collected\n');
      
end


%==========================================================================
% --- average: Calculate average --- %
%==========================================================================

if conf.todo.average
   
fprintf('\n\ncreating averages\n');

for i = 1:length(conf.average.todo.zscores)
    CurZ = conf.average.todo.zscores{i};
    for j = 1:length(conf.average.todo.transforms)
        CurTransform = conf.average.todo.transforms{j};
        
        conf.average.zscore     = CurZ;
        conf.average.transform  = CurTransform;
        
        
        % --- For each zscore x transform, create an average ---
        fprintf('  %s-%s: creating average\n', CurTransform, CurZ);
        eyelink_average(conf);
        fprintf('  %s-%s: average created\n', CurTransform, CurZ);      
        
    end
end
   
fprintf('averages created\n');

end

fprintf('\n\n\ndone!\n');

warning('on', 'Findfile:empty');


