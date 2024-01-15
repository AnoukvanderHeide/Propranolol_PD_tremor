% heartrate_batch.m is the main script to run heart rate analysis
% Steps:
% 1) reformat data
% 2) go over data in HERA, check and correct automatic detection (not included in script!)
% 3) create regressor (starting at 5 data points before 1st trial, ends at last scan)
% 4) create average regressor for figure

clear all
warning('off', 'Findfile:empty');

conf.task = 'coco';
%conf.task = 'rest';

%==========================================================================
% --- Settings --- %
%==========================================================================

% --- Subjects ---
% subjects included
% conf.sub.name = { 
%                     '002'; '003'; '004'; '005'; '006'; ...    %TD participants
%                     '008'; '009'; '011'; '012'; '014'; ...
%                     '015'; '016'; '017'; '018'; '020'; ...
%                     '022'; '023'; '025'; '027'; '028'; ...
%                     '029'; '030'; '063'; '064'; '065'; ...
%                     
%                     '031'; '032'; '033'; '034'; '035'; ...    %NT participants
%                     '036'; '037'; '038'; '039'; '040'; ...
%                     '041'; '042'; '043'; '044'; '045'; ...
%                     '046'; '047'; '048'; '049'; '050'; ...
%                     '051'; '052'; '054'; '055'; '056'; ...
%                     '057'; '058'; '059'; '060'
% };   

% all subjects
conf.sub.name = { 
                  '001'; '002'; '003'; '004'; '005'; ...
                  '006'; '007'; '008'; '009'; '010'; ...
                  '011'; '012'; '013'; '014'; '015'; ...
                  '016'; '017'; '018'; '019'; '020'; ...
                  '021'; '022'; '023'; '024'; '025'; ...
                  '026'; '027'; '028'; '029'; '030'; ...
                  '031'; '032'; '033'; '034'; '035'; ...
                  '036'; '037'; '038'; '039'; '040'; ...
                  '041'; '042'; '043'; '044'; '045'; ...
                  '046'; '047'; '048'; '049'; '050'; ...
                  '051'; '052'; '053'; '054'; '055'; ...
                  '056'; '057'; '058'; '059'; '060'; ...
                  '061'; '062'; '063'; '064'; '065'; ...
};


% --- Sessions ---
conf.sub.ses = {'01'; '02'}; 

% --- Exceptions (use last run for 012-1 and save scans missing for 018-1) ---
if strcmp(conf.task, 'coco')  
    conf.exceptions.run.default = 'last';
    conf.exceptions.run.s012s01 = 1;   
    conf.exceptions.s018s01.nScansMissing = 27; % nr of scans in front that are missing
end

% --- Directories ---
pf = fullfile('/project', '3024005.02');
conf.dir.raw        = fullfile(pf, 'raw', 'sub-Sub', 'Brainvision');    % location of the raw brainvision files

conf.dir.HR         = fullfile(pf, 'Analysis', 'Heart_rate');   % general HR folder
conf.dir.output     = fullfile(conf.dir.HR, 'output');          % general output folder
conf.dir.reform     = fullfile(conf.dir.output, ['reformatted_', conf.task]); % output folder for reformatted files
conf.dir.regressor  = fullfile(conf.dir.output, ['regressors_', conf.task]);  % output folder for regressors
conf.dir.plot       = fullfile(conf.dir.HR, 'plots');           % general plots folder
conf.dir.regrplot   = fullfile(conf.dir.plot, ['regressors_', conf.task]);    % output directory for plots of regressors
conf.dir.average    = fullfile(conf.dir.output);                % output directory for average regressor
conf.dir.averageplot= fullfile(conf.dir.plot);                  % output directory for plot of average

% --- Useful scripts ---
addpath(genpath(fullfile(conf.dir.HR, 'scripts')))
addpath('/home/common/matlab/fieldtrip')
addpath('/home/common/matlab/fieldtrip/qsub')
addpath('/home/common/matlab/spm12')
addpath(fullfile(pf, 'Analysis', 'SupportingScripts', 'helpers'));
addpath(fullfile(pf, 'Analysis', 'SupportingScripts'));

% --- File names ---
conf.file.raw       = ['/Sub_Ses_/&/_', conf.task, '/&/.eeg/'];         % raw brainvision file name
conf.file.reform    = ['/Sub_Ses_/&/_', conf.task, '_fMRI_run_/&/_hera.mat/'];  % name of reformatted file (don't change unless you also change it in brainampconverter.m)
conf.file.regressor = ['/Sub_Ses_/&/_', conf.task, '_fMRI_run_/&/_hera_RETROICORplus_regr.mat/']; % name of regressor file (don't change unless you also change it in RETROICORplus.m)
conf.file.regrplot  = 'Sub_Ses_regressor.jpg';          % regressor plot ouput file name
conf.file.average   = ['average_heart_rate_Transform_', conf.task];   % average plot ouput file name

% --- To do ---
conf.todo.singlelevel   = true;     % if false, convert and regressor won't be run
conf.todo.convert       = true;     % only runs if not done yet for a data set
conf.todo.regressor     = true;     % only runs if not done yet for a data set
conf.todo.average       = false;

% --- General settings ---
conf.general.skiperrors = false;    % when true, it throws a warning instead of an error 
%(usually want this set to true, set to false to debug when datasets won't run)

% --- Trials ---
if strcmp(conf.task, 'coco')
    conf.trial.nr           = 10;       % nr of trials
    conf.trial.duration     = 60;       % duration of one trial (in scans)
    conf.trial.nrScansPre   = 5;        % nr of scans before the start of the first trial
    conf.trial.indicesTrial = [1:2:conf.trial.nr]; % indices of the non-rest (so coco) trials
elseif strcmp(conf.task, 'rest')
    conf.trial.nr           = 1;    % nr of trials
    conf.trial.duration     = 595;  % duration of the task (in scans) - 023-2 028-2 & 063-2 different
    conf.trial.nrScansPre   = 0;    % nr of scans before the start of the first trial: zero for resting state
end

% --- Regressor settings ---
conf.regressor.dummy         = 5;        % number of dummy scans
conf.regressor.plot.index    = 21;       % index of regressor to plot (= 21, unless things are changed in default settings file) (see also word document with explanation about which regressor is which) 
conf.regressor.plot.on       = 'yes';    % create plot of regressor
if strcmp(conf.task, 'coco')
    conf.regressor.plot.cond = 'yes';    % plot conditions?
    conf.regressor.endscan   = 1;        % 1 if scanner is stopped by hand, since last scan marker has to be removed
elseif strcmp(conf.task, 'rest')
    conf.regressor.plot.cond = 'no';     % plot conditions?
    conf.regressor.endscan   = 0; 
end
conf.regressor.plot.width    = 750;  
conf.regressor.plot.height   = 300;

% --- Average settings ---
conf.average.todo.zscores   = {'zscored';'notzscored';}; % which averages to create
conf.average.index          = 21;       % index of regressor to plot (= 21, unless things are changed in default settings file) 
conf.average.plot.cond      = 'yes';    % plot conditions?
conf.average.plot.width     = 750;  
conf.average.plot.height    = 400;
conf.average.exclude = {};
% conf.average.exclude = {'004-01', '005-02', '006-02', '008-02', '009-02', ...
%                         '011-01', '012-01', '016-02', '022-01', ...
%                         '022-02', '023-01', '027-01'}; 
                       % subjects to not include in average (bad data quality)
                                                    
% --- Initialize some things ---
warning('off', 'Findfile:empty');
cd(conf.dir.HR)
nErrors = 0;

%==========================================================================
% --- Preprocessing --- %
%==========================================================================

if conf.todo.singlelevel 
    
for i = 1:length(conf.sub.name)
    CurSub = conf.sub.name{i};
   
    
    for j = 1:length(conf.sub.ses)
        CurSes = conf.sub.ses{j};

        
        conf.sub.curSub = CurSub;
        conf.sub.curSes = CurSes;
        
        fprintf('\n\n --- | sub-%s | ses-%s | %s | ---\n', CurSub, CurSes, conf.task)
        
        %==========================================================================
        % --- convert: Convert data from .eeg to .puls --- %
        %==========================================================================
        
        if conf.todo.convert
            
        ReformFName = replace(conf.file.reform, {'Sub', 'Ses'}, {CurSub, CurSes});
        ReformFile  = pf_findfile(conf.dir.reform, ReformFName);
        
        RawDir      = replace(conf.dir.raw, {'Sub'}, {CurSub});
        RawFName    = replace(conf.file.raw, {'Sub', 'Ses'}, {CurSub, CurSes});
        RawFile     = pf_findfile(RawDir, RawFName);
        

        % --- Check if data has already been reformatted ---
        if ~isempty(ReformFile)
            fprintf('already reformatted\n');
        
        % --- Check if there's raw data to reformat ---    
        elseif isempty(RawFile)
            fprintf('no raw files found\n --- skipped ---\n');
            continue
            
        % --- Run Analysis ---    
        else
            
            % If more than one file has been found, and ask which one to use
            if iscell(RawFile)
                fprintf('  more than one file found:\n')
                for f = 1:length(RawFile)
                    fprintf('  %i) %s\n',f,RawFile{f})
                end
                idx = input('  which one do you want to use:    ');
                RawFile = RawFile{idx};
                fprintf('  using file %s\n', RawFile);
            end
            
            
            fprintf('found raw file: %s\n', RawFile);
            fprintf('reformatting data...\n');
            
            if ~conf.general.skiperrors
                brainampconverter(fullfile(RawDir, RawFile), conf.dir.reform)
            else
                try
                    brainampconverter(fullfile(RawDir, RawFile), conf.dir.reform)
                catch ME
                    warning('\nan error was detected:\n%s', ME.message)
                    fprintf('\n--- skipped ---\n\n')
                    nErrors = nErrors + 1;
                    errors(nErrors).subses = [CurSub '-' CurSes];
                    errors(nErrors).error   = ME.message;
                    errors(nErrors).where   = 'reformatting';
                    continue
                end
            end
            fprintf('data reformated!\n\n');
            
        end       
        end        
        
        %==========================================================================
        % --- regressor: Create a regressor --- %
        %==========================================================================       
        
        if conf.todo.regressor

        RegrFName = replace(conf.file.regressor, {'Sub', 'Ses'}, {CurSub, CurSes});
        RegrFile  = pf_findfile(conf.dir.regressor, RegrFName);        
            
        ReformFName = replace(conf.file.reform, {'Sub', 'Ses'}, {CurSub, CurSes});
        ReformFile  = pf_findfile(conf.dir.reform, ReformFName);           
        
        % --- Check if regressor has already been created ---
        if ~isempty(RegrFile)
            fprintf('already created regressor\n');
        
        % --- Check if there's reformatted data to create regressor from ---    
        elseif isempty(ReformFile)
            fprintf('no reformatted files found\n --- skipped ---\n');
            continue
            
        % --- Run Analysis ---    
        else
            
            % --- If more than one file has been found, and ask which one to use ---
            if iscell(ReformFile)
                fprintf('  more than one file found:\n')
                for f = 1:length(ReformFile)
                    fprintf('  %i) %s\n',f,ReformFile{f})
                end
                idx = input('  which one do you want to use (NOTE: run here means file part. look at the nr of volumes to see which one to use):    ');
                ReformFile = ReformFile{idx};
                fprintf('  using file %s\n', ReformFile);
            end
            
            fprintf('found reformatted file: %s\n', ReformFile);
            fprintf('creating regressor...\n');

            nDummy = conf.regressor.dummy;
            if strcmp(conf.task, 'coco') & strcmp(CurSub, '018') & strcmp(CurSes, '01')
                nDummy = 0;
            end
            
            if ~conf.general.skiperrors
                RETROICORplus(fullfile(conf.dir.reform, ReformFile), nDummy, conf.regressor.endscan, conf.dir.regressor, conf);
            else
                try
                    RETROICORplus(fullfile(conf.dir.reform, ReformFile), nDummy, conf.regressor.endscan, conf.dir.regressor, conf);
                catch ME
                    warning('\nan error was detected:\n%s', ME.message)
                    fprintf('\n--- skipped ---\n\n')
                    nErrors = nErrors + 1;
                    errors(nErrors).subses = [CurSub '-' CurSes];
                    errors(nErrors).error   = ME.message;
                    errors(nErrors).where   = 'regressor';
                    continue
                end
            end
            
            fprintf('regressor created!\n');           
            
            % --- Plot regressor ---
            if strcmp(conf.regressor.plot.on, 'yes')
                fprintf('plotting regressor\n');
                heartrate_plotregressor(conf, CurSub, CurSes);
                fprintf('regressor plotted!\n\n');
            end      
        end      
        
        end
        
        fprintf(' --- done ---\n');       
    end     
end

fprintf(['\n --- | Done with single-level processing | ---\n']);

% --- Print found errors in overview ---
fprintf('\n\n --- | Errors | ---\n')
if exist('errors')
    
    fprintf('found %i errors:\n', length(errors))
    fprintf('sub\t step\t\t error\n')

    for i = 1:length(errors)
        fprintf('%s \t %s \t %s\n', errors(i).subses, errors(i).where, errors(i).error);
    end
else
   fprintf('found 0 errors!\n') 
end
end

%==========================================================================
% --- Average regressor --- %
%==========================================================================

if conf.todo.average
    
fprintf(['\n\n\n --- | Creating averages | ---\n\n']);
heartrate_average(conf);
fprintf(['\n\n\n --- | Done creating average | ---\n']);

end

warning('on', 'Findfile:empty');
