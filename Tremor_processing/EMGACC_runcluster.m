function EMGACC_runcluster(Task)
%EMGACC_runcluster.m script to run FARM and frequency analysis on cluster
%  code from:
%  https://github.com/mejoh/Personalized-Parkinson-Project-Physiological-Recordings/blob/master/EMG_ACC/EMGACC_runcluster.m 

% Aanpassen voor rest vs. coco: regel 8 (task), 95 (markerfiles) & 108 (subj.)

% Task = 'rest'; 
Task = 'coco';
warning('off', 'Findfile:empty');

% Dependencies
% Settings
% SETTINGS pf_emg_raw2regr.m & pf_emg_farm.m
% Directories
% Subjects
% Frequency Analysis ('prepemg')
% Frequency Analysis OPTIONAL
% Make Regressor ('mkregressor')
% FieldTrip Configuration
% File info 
% Preprocessing and slice triggers
% Additional methods
% Call functions
% Final step: select peak frequency and channel, create regressor

% --- Dependencies ---
addpath('/home/common/matlab/spm12')
addpath('/home/common/matlab/fieldtrip')
addpath('/home/common/matlab/fieldtrip/qsub')
ft_defaults

addpath(genpath('/project/3024005.02/Analysis/Tremor_regressors_MRI/eeglab14_0_0b'))
addpath(genpath('/project/3024005.02/Analysis/Tremor_regressors_MRI'))

% --- Settings ---
% NOTE: FARM must be run before anything else, even ACC processing, because FARM 
% calls eeglab-functions that puts data into specific format.

conf.todo.Farm               = true; %Do you want to run Farm
conf.todo.Frequency_analysis = true; %Do you want to run frequency analysis
conf.todo.prepemg            = true; %When doing frequency analysis, do you want to prepair emg using: pf_emg_raw2regr_prepemg
conf.todo.mkregressor        = true; %When doing frequency analysis, do you want to make a regressor using: pf_emg_raw2regr_mkregr
conf.todo.ACC                = true; %Do you want analyse the Accelerometer

% --- Task Settings ---
cluster_outputdir   = fullfile('/project/3024005.02/Analysis/EMG', Task, 'clusteroutput');
processing_dir      = fullfile('/project/3024005.02/Analysis/EMG', Task, 'processing');
TR = 1;
MB = 6;
NSlices = 72 / MB;
pScan = ['^sub-.*task-', Task, '_acq-epfid2d1104.*nii.gz$'];

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SETTINGS pf_emg_raw2regr.m & pf_emg_farm.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Specify all options under configuration and run the batch. The following
% functions can be used:
%   - 'prepemg': will perform preprocessing and frequency analysis on your
%   data using FieldTrip. This data is then stored in a .mat file, which
%   can be used formaking a regressor using:
%   - 'mkregressor': will create regressors based on data analyzed with
%   'prepemg'. To do so, you must first interactively select the tremor
%   frequency. This selection and subsequent creation of regressor must be
%   done via the GUI: pf_emg_raw2regr_mkregressor_gui. If you have already
%   done so but you want to reanalyze data (and use previous peak
%   selection) you can also specify options here, the first option being:
%   conf.mkregr.reanalyze='yes'.

%--------------------------------------------------------------------------
%% Directories
%--------------------------------------------------------------------------
%Function directories 
conf.dir.project    =   fullfile('/project', '3024005.02');
conf.dir.scripts    =   fullfile(conf.dir.project, 'Analysis', 'Tremor_regressors_MRI');
conf.dir.emgacc     =   fullfile(conf.dir.scripts, 'EMG_ACC');
conf.dir.ParkFunc   =   fullfile(conf.dir.emgacc, 'Helpers', 'ParkFunC_EMG');     % Directory containing Park_Func
conf.dir.Farm       =   fullfile(conf.dir.emgacc, 'Helpers', 'FARM_toolbox');
conf.dir.eeglab     =   fullfile(conf.dir.scripts, 'eeglab14_0_0b');
conf.dir.SPM        =   fullfile('/home', 'common', 'matlab', 'spm12');       % Directory containing SPM
conf.dir.Fieldtrip  =   fullfile('/home', 'common', 'matlab', 'fieldtrip');   % Directory containing Fieldtrip

%Output directories 
conf.dir.OutputRoot =   fullfile(conf.dir.project, 'Analysis', 'EMG');
conf.dir.output     =   fullfile(conf.dir.OutputRoot, Task);
conf.dir.preproc    =   fullfile(conf.dir.output, 'processing', 'FARM');     % Directory containing files used for "prepemg" (usually after FARM)
conf.dir.prepemg    =   fullfile(conf.dir.output, 'processing', 'prepemg');  % Directory where files from function "prepemg" will be stored
conf.dir.auc        =   fullfile(conf.dir.output, 'auc');                    % Directory for aucs
conf.dir.regr       =   fullfile(conf.dir.prepemg,'Regressors');             % Directory where files from function "mkregr" will be stored
conf.dir.event      =   conf.dir.preproc;                                    % Directory containing conditions, e.g. if you want to plot the conditions in mkregr
conf.dir.reanalyze.orig =  fullfile(conf.dir.regr,'zscored'); % If in function "mkregr" you want to reanalyze data (so conf.mkregr.reanalyze='yes'), then the regressor files in the directory specified here will be used for peakselection

%Input directories 
conf.dir.emgFixed   =   fullfile(conf.dir.OutputRoot, [Task '_markersfixed']); 
conf.dir.bids       =   char(fullfile(conf.dir.project, 'bidsoutput'));

%FARM
conf.dir.save       =   fullfile(conf.dir.output, 'processing', 'FARM');
conf.dir.work       =   fullfile(conf.dir.output, 'processing', 'FARM', 'work');
conf.dir.preworkdel     = 'yes';           % Delete work directory beforehand (if present)
conf.dir.postworkdel    = 'yes';           % Delete work directory afterwards

%--------------------------------------------------------------------------
%% Subjects
%--------------------------------------------------------------------------

Sub = cellstr(spm_select('List', fullfile(conf.dir.bids), 'dir', 'sub-*'));
Sub = Sub(strcmp(Sub, 'sub-012'));

FARMjobs = cell(numel(Sub),1);
FREQjobs = cell(numel(Sub),1);
conf.sub.run = {Task;};  % Specify run in cell structure (even for only one run, e.g. resting state)

for n = 1:numel(Sub)
    
conf.sub.name   = Sub(n);
conf.sub.name{1} = conf.sub.name{1}(5:7);
fprintf('\n\n --- | sub-%s | ---\n', conf.sub.name{1})

Sessions = cellstr(spm_select('FPList', fullfile(conf.dir.bids, ['sub-' conf.sub.name{1}]), 'dir', 'ses-mri0[1-2]'));
if length(Sessions) > 0
    fmt = ['MRI sessions:' repmat(' ses-%s ',1,numel(Sessions)) '\n'];
    sesstrings = extractAfter(Sessions(:), 'ses-mri');
    fprintf(fmt, sesstrings{:});
else
    fprintf('MRI sessions: none\n');
end

%%Check if there is fMRI and EMG data
SelSes = true(numel(Sessions),1);

for i = 1:numel(Sessions)
    [~, sess, ~] = fileparts(Sessions{i});
    vmrk    = cellstr(spm_select('List', conf.dir.emgFixed, [conf.sub.name{1}, '_', sess(end-1:end), '_.*_', Task, '.*.vmrk$']));
    eeg     = cellstr(spm_select('List', conf.dir.emgFixed, [conf.sub.name{1}, '_', sess(end-1:end), '_.*_', Task, '.*.eeg$']));
    vhdr    = cellstr(spm_select('List', conf.dir.emgFixed, [conf.sub.name{1}, '_', sess(end-1:end), '_.*_', Task, '.*.vhdr$']));
    TaskData_fmri = cellstr(spm_select('List', fullfile(Sessions, 'func'), ['.*task-', Task, '_acq-epfid2d1104.*.nii.gz']));
    
    if isempty(vmrk{1}) || isempty(eeg{1}) || isempty(vhdr{1}) || isempty(TaskData_fmri{1})
        SelSes(i) = false;
        fprintf('Skipping ses-%s with no (fixed marker) vmrk/eeg/vhdr files and/or no (bids) MRI data\n', sess(end-1:end))
    end    
end
Sessions = Sessions(SelSes);

for i = 1:numel(Sessions)
        
    [~, conf.sub.sess, ~] = fileparts(Sessions{i});
    conf.sub.sess = cellstr(conf.sub.sess);
    conf.sub.sess = extractAfter(conf.sub.sess(:), 'ses-mri');
    fprintf('\n| sub-%s | %s | ses-%s |\n', conf.sub.name{1}, conf.sub.run{1}, conf.sub.sess{1})
    
    % Get info about channels recorded
    subinfo = EmgChannelsMeasured(conf.sub.name{1}, conf.sub.sess{1});
    nChannels       = subinfo.nChannels;
    accChannels     = subinfo.accChannels;
    emgChannels     = subinfo.emgChannels;
    labels          = subinfo.labels;
    nrOfNotRecorded = subinfo.nrNotRecorded;
    
    % Print info
    fmt = ['nr of channels = %i | EMG channels:' repmat(' %i ',1,numel(emgChannels)) ...
           '| ACC channels:' repmat(' %i ',1,numel(accChannels)) ' | nr not recorded = %i\n'];
    fprintf(fmt, nChannels, [emgChannels, accChannels], nrOfNotRecorded);
    fmt = ['labels:' repmat(' %s  ',1,numel(labels)) '\n'];
    fprintf(fmt, labels{:});

    %conf.todo.ACC = true;
    
    % for 003-2 and 011-1 use EMG for both rest and coco. For 022 use EMG for coco.
    if (strcmp(conf.sub.name{1}, '003') && strcmp(conf.sub.sess{1}, '02')) || ...
       (strcmp(conf.sub.name{1}, '011') && strcmp(conf.sub.sess{1}, '01')) || ...
        (strcmp(conf.sub.name{1}, '022') && strcmp(conf.sub.sess{1}, '01')) || ...
        (strcmp(conf.sub.name{1}, '022') && strcmp(conf.sub.sess{1}, '02')) 
        conf.todo.ACC = false;
    else
        conf.todo.ACC = true;
    end
    
%--------------------------------------------------------------------------
%% Frequency Analysis ('prepemg')
%--------------------------------------------------------------------------
    conf.prepemg.datfile  = '/CurSub/&/CurSess/&/CurRun/&/FARM.dat/';   % Data file name of preprocessed data (uses pf_findfile)
    conf.prepemg.mrkfile  = '/CurSub/&/CurSess/&/CurRun/&/FARM.vmrk/';  % Marker file name of preprocessed data (uses pf_findfile)
    conf.prepemg.hdrfile  = '/CurSub/&/CurSess/&/CurRun/&/FARM.vhdr/';  % Hdr file name of preprocessed data (uses pf_findfile)
    
    conf.prepemg.precut   = 'no';     % If yes, it will cut out the data before the first volume marker. If you leave this as no, it should already be cut away
    conf.prepemg.sval     = 'V';      % Scan value in your marker file (usually 'V' after FARM);
    conf.prepemg.tr       = TR;       % Choose a fixed TR (repetition time) or enter 'detect' if you want the script to detect this
%     if strcmp(conf.sub.name{1}, '018') && strcmp(conf.sub.sess{1}, '01')
%         conf.prepemg.dumscan  = 3;    % Dummyscans (Start of regressor will be at conf.prepemg.dumscan+1)
%         fprintf('pretending there are three dummy scans\n');
%     else
    conf.prepemg.dumscan  = 5;    % Dummyscans (Start of regressor will be at conf.prepemg.dumscan+1)
%     end
    conf.prepemg.prestart = 3;        % Scans before the start of your first scan (conf.prepemg.dumscan+1) you want to select (for example to account for the hanning taper, BOLD response etc). This data will be processed all the way, and only disregarded at the end of all analyses    
    conf.prepemg.timedat  = 0.001;    % The resolution of the time-frequency representation in seconds (can be used for cfg.cfg_freq.toi)
    conf.prepemg.chan = labels;
   
%--------------------------------------------------------------------------
%% Frequency Analysis OPTIONAL
%--------------------------------------------------------------------------
% --- Plotting options --- %
    conf.prepemg.subplot.idx           = [1,2];    % Every analysis yields one figure, choose the subplot here ([r,c])
    conf.prepemg.subplot.chan          = { conf.prepemg.chan(emgChannels);
        [conf.prepemg.chan(accChannels);'acc-pc1'];
        };        % Choose here the channels you want to plot in the subplots (these need to match the amount of subplots in conf.prepemg.subplot.idx). NB1: it will first check for a single string, you can specify these strings; 'coh': will plot the freshly performed coherence analysis

% --- Optional: combine channels if desired --- %
    conf.prepemg.combichan.on   = 'yes';                                % If you want to combine channels, specify 'yes'
    conf.prepemg.combichan.chan = {conf.prepemg.chan(accChannels) 'acc-pc1';};  % Choose the sets of channels you want to combine (for every row another set of channels, in the left column the channel names (as in conf.prepemg.chan) in the right column the new name)
    conf.prepemg.combichan.meth = 'pca';                                % Choose method of combining ('vector': will make a vector out of a triaxial signal (x^2+y^2+z^2)^0.5 | 'pca': performs principal component analysis and will take first principle component)

% --- Optional: perform coherence analysis if desired --- %
    conf.prepemg.cohchan.on         =  'yes';    % Cohere channels (specify 'yes')
    conf.prepemg.cohchan.channelcmb =  {        
        conf.prepemg.chan(1:4) conf.prepemg.combichan.chan(1,2);
        };       % Channels you want to performe a coherence analysis over. 
    %In the left column specify the channels (multiple) which you want to cohere with 
    %the channel on the right column (one). It will detect the presense of these channels 
    %in the freqana data and only select those which are present.
    %%MW: miss willen we ook 5:8 erbij doen hier?   
    
% --- Optional: only save averaged power spectrum (if you don't need regressors, this will save space) --- %
    conf.prepemg.freqana.avg        = 'no';

% --- Optional: calculate area under the curve for the highest peak in the ACC spectrum (FWHM) --- %
    conf.auc.auto                   = 'no';
    conf.auc.chan                   = {accChannels - nrOfNotRecorded}; % Defines acc. channels, HR and resp. removed
    conf.auc.filter                 = [3.4 6.6]; %filter (two numbers required!) for peak selection. Most tremor peaks fall between 3.4 and 6.6 Hz, so recommended to leave as is.
    conf.auc.us_factor              = 20; %upsample factor for power spectrum for AUC. Recommended: 20.
    conf.auc.manual                 = 'no'; %selects peak within manual range and channel only (specify below)
    conf.auc.manual_chan            = accChannels - nrOfNotRecorded;     %make sure selected channel falls in range auc.chan
    conf.auc.manual_range           = 4;     %Can give range (two numbers) or one value.
% Values should be same as stepsize of foi: normally 0.2 Hz
% In case of one value, the algorithm selects the closest peak.

%--------------------------------------------------------------------------
%% Make Regressor ('mkregressor')
%--------------------------------------------------------------------------
    conf.mkregr.reanalyze = 'no';   % Choose if you want to reanalyze previously selected data. If not, then use the GUI: pf_emg_raw2regr_mkregressor_gui
    conf.mkregr.reanalyzemeth = {  'regressor';
    %                              'ps_save';
        }; % Method for re-analyzing the data ('regressor': create regressors; 'ps_save': only save average power spectrum)
    conf.mkregr.automatic = 'yes';
    %conf.mkregr.automaticfreqwin = [1.99,13.1];
    conf.mkregr.automaticfreqwin = [3.3,6.1];
    conf.mkregr.automaticdir = fullfile(conf.dir.prepemg, 'automaticdir');
    conf.mkregr.file      = '/CurSub/&/CurSess/&/freqana/'; % Name of prepemg data (uses pf_findfile)   
    conf.mkregr.scanname  = '|w*';                          % search criterium for images (only if conf.mkregr.nscan = 'detect'; uses pf_findfile)
    conf.mkregr.sample    = 1;                              % Samplenr of every scan which will be used to represent the tremor during scan (if you used slice time correction, use the reference slice timing here)
    
    conf.mkregr.zscore    = 'yes';                          % If yes, than the data will first be z-normalized
    conf.mkregr.meth      = {'power';'amplitude';'log'};    % Choose methods for regressors ('power': simple power; 'amplitude': sqrt(pow); 'log': log10 transformed)
    conf.mkregr.trans     = {'deriv1'};                     % In addition to regressors specified in conf.mkregr.meth, specify here transformation of made regressors ('deriv1': first temporal derivative)
    conf.mkregr.save      = 'yes';                          % Save regressors/figures

%Choose channels based on acc vs emg and most affected side. 

    subses = [conf.sub.name{1} '-' conf.sub.sess{1}];

    % If ACC has to be analyzed
    if conf.todo.ACC && strcmp(Task, 'coco')  
        % Use x for 025-01, 025-02 and 028-02(because of better signal-noise ratio)
        if (strcmp(conf.sub.name{1}, '025') && strcmp(conf.sub.sess{1}, '01')) || ...
           (strcmp(conf.sub.name{1}, '025') && strcmp(conf.sub.sess{1}, '02')) || ...
           (strcmp(conf.sub.name{1}, '028') && strcmp(conf.sub.sess{1}, '02')) 
            conf.mkregr.automaticchans = accChannels(1) - nrOfNotRecorded;
        % In all other cases use all of them (and the highest one is picked automatically)
        else
             conf.mkregr.automaticchans = accChannels - nrOfNotRecorded;
        end
        
    elseif conf.todo.ACC && strcmp(Task, 'rest')
        % Use x for 004-2, 014-1 and 025-1 and 028-1 (because of better signal-noise ratio)
        if (strcmp(conf.sub.name{1}, '004') && strcmp(conf.sub.sess{1}, '02')) || ...
           (strcmp(conf.sub.name{1}, '014') && strcmp(conf.sub.sess{1}, '01')) || ...
           (strcmp(conf.sub.name{1}, '025') && strcmp(conf.sub.sess{1}, '01')) || ...
           (strcmp(conf.sub.name{1}, '028') && strcmp(conf.sub.sess{1}, '01')) 
            conf.mkregr.automaticchans = accChannels(1) - nrOfNotRecorded;
        % Use y for 016-2 (because of better signal-noise ratio)
        elseif (strcmp(conf.sub.name{1}, '016') && strcmp(conf.sub.sess{1}, '02')) 
            conf.mkregr.automaticchans = accChannels(2) - nrOfNotRecorded;
        % In all other cases use all of them (and the highest one is picked automatically)
        else
             conf.mkregr.automaticchans = accChannels - nrOfNotRecorded;
        end
        
    % If EMG has to be analyzed: get the MA channels
    else   
        
        if (strcmp(conf.sub.name{1}, '011') && strcmp(conf.sub.sess{1}, '01'))
            conf.mkregr.automaticchans = 2; % Use FCR instead of ECR for 011-01     
        elseif strcmp(conf.sub.name{1}, '057') || strcmp(conf.sub.name{1}, '058') || ...
               strcmp(conf.sub.name{1}, '059') || strcmp(conf.sub.name{1}, '060') || ... %strcmp(conf.sub.name{1}, '002') || ...
               (strcmp(conf.sub.name{1}, '027') && strcmp(conf.sub.sess{1}, '02')) || ...
               strcmp(conf.sub.name{1}, '028') || strcmp(conf.sub.name{1}, '030') || ...
               strcmp(conf.sub.name{1}, '063') || strcmp(conf.sub.name{1}, '064') || ...
               strcmp(conf.sub.name{1}, '065')
            conf.mkregr.automaticchans = 3:4; % If MA/LA, is switched (so MA is 3:4)        
        elseif strcmp(subses, '002-01')
            conf.mkregr.automaticchans = 3;
        elseif strcmp(subses, '004-02') || strcmp(subses, '011-01') || strcmp(subses, '011-02') || strcmp(subses, '029-02')
            conf.mkregr.automaticchans = 2; 
        elseif strcmp(subses, '015-02')
            conf.mkregr.automaticchans = 1;           
        else conf.mkregr.automaticchans = 1:2; % For the others MA is 1:2
        end

    end
    
    fmt = ['looking at these channels for max: ' repmat(' %s ',1,numel(conf.mkregr.automaticchans)) '\n'];
    fprintf(fmt, labels{conf.mkregr.automaticchans + nrOfNotRecorded * conf.todo.ACC});

%--------------------------------------------------------------------------
%% Make Regressor OPTIONAL
%--------------------------------------------------------------------------
% --- Optional: plot condition as grey bar --- %
    %%MW: ik heb nu in pf_emg_raw2regr_mkregr.m zelf de onsets en offsets
    %%ingevuld (dat de eerste begint bij 7 en eindigt bij 67 en zo door, 
    %%gebasseerd op presentation script en scan markers)
    if strcmp(Task, 'coco')
        conf.mkregr.plotcond  = 'yes';                                    % If you want to plot the condition (will use the same )
    else 
        conf.mkregr.plotcond  = 'no';                                    % If you want to plot the condition (will use the same )
    end
    conf.mkregr.evefile   = '/CurSub/&/CurSess/&/CurRun/&/.vmrk/';   % Event file stored in conf.dir.event (if you want to plot the conditions
    conf.mkregr.mrk.scan  = 'R  1';                                  % Scan marker (if you want to plot events)
    conf.mkregr.mrk.onset = 'S 10';                                  % Onset marker (if you want to plot events)
    conf.mkregr.mrk.offset= 'S 20';                                  % Offset marker (if you want to plot events)

% --- Optional: plot scan lines --- %
    conf.mkregr.plotscanlines = 'no';                       % If yes then it will plot the scanlines in the original resolution.

%--------------------------------------------------------------------------
%%  FieldTrip Configuration
%--------------------------------------------------------------------------
% Options specified here correspond to the options specified for FieldTrip
% fucntions. Therefore, check the info of FieldTrip for options possible:
% ft_preprocessing for cfg_pre, ft_freqanalysis for cfg_freq
% --- Preprocessing (ft_preprocessing) --- %
    cfg.chandef =   {
        emgChannels;   % First round of preprocessing for channel 1:4 (in my case EMG after FARM)
        emgChannels;   % Second round of preprocessing for channel 1:4 (in my case EMG after FARM)
        accChannels; % First round of preprocessing for channel 7:9 (in my case raw accelerometry)
        };       % Define the different preprocessing for the channels here. For every row define the channels defined in conf.prepemg.chan and define the preprocessing in the options below. The different processed channels will be appended later on.

    cfg.cfg_pre{1}             =   [];       % For every set of channels (nRows in cfg.chandef) you must here define the preprocessing methods. E.g. in this case cfg.cfg_pre{1} corresponds to channels 1:8 (first round), cfg.cfg_pre{3} to channels 11:13
    cfg.cfg_pre{1}.continuous  =   'yes';    % Load all data, select later
    cfg.cfg_pre{1}.detrend     =   'yes';    % Detrend data
    cfg.cfg_pre{1}.demean      =   'yes';    % Demean data
    cfg.cfg_pre{1}.rectify	   =   'yes';    % Rectify for tremor bursts
    
    cfg.cfg_pre{2}.hpfilter	   =   'yes';    % Second round: high-pass filter to remove low-frequency drifts
    cfg.cfg_pre{2}.hpfreq	   =       2;    % HP frequency
    cfg.cfg_pre{2}.hpfilttype  = 'firws';    % HP filter type, 'but' often crashes
    
    cfg.cfg_pre{3}.continuous  =   'yes';    % Load all data, select later
    cfg.cfg_pre{3}.detrend	   =   'yes';    % Detrend data
    cfg.cfg_pre{3}.demean	   =   'yes';    % Demean data
    cfg.cfg_pre{3}.bpfilter	   =   'yes';    % Bandpass filter
    cfg.cfg_pre{3}.bpfreq	   =   [1 40];   % Bandpass filter frequency
    cfg.cfg_pre{3}.bpfiltord   =   1;        % Bandpass filter order
    cfg.cfg_pre{3}.bpfilttype  =   'but';    % Bandpass filter type ('but'=butterworth)

% --- Frequency analysis (ft_freqanalysis) --- %
    cfg.cfg_freq.method     = 'mtmconvol';               % Select method (choose 'mtmconvol' for regressor)
    cfg.cfg_freq.output     = 'pow';                     % Select output ('pow'=power)
    cfg.cfg_freq.taper      = 'hanning';                 % Windowing ('hanning'=hanning taper)
    cfg.cfg_freq.foi        = 2:0.5:13;                  % Frequency range you are interested in (usually 2:0.5:8, make sure you at least include 3-8 Hz)
    nFoi                    = length(cfg.cfg_freq.foi);  % Number of frequencies
    cfg.cfg_freq.t_ftimwin  = repmat(2,1,nFoi);          % Wavelet length (seconds; 1 wavelet per frequency). For practical reasons usually take 2 second (which will contain enough time to detect tremor frequency)
    cfg.cfg_freq.toi        = 'timedat';                 % Temporal resolution of you time-frequency representation (resolution in seconds) ('orig': original resolution; 'timedat': one step specified under conf.prepemg.timedat;)
    cfg.cfg_freq.pad        = 'maxperlen';               % Padding (use 'maxperlen' for default)

% --- AUC analysis --- %
    cfg.fft_auc{1}.length   =  5; %segmentation settings. specify length of windows in seconds
    cfg.fft_auc{1}.overlap  =  0; %Overlap between segments, should be zero in case of resting analysis
    resolution_foi          = 1/cfg.fft_auc{1}.length; % Freq resolution depends on the length of the time window (1/T).
    cfg.fft_auc{2}.method   =  'mtmfft'; %FFT settings.
    cfg.fft_auc{2}.foi      =  2:resolution_foi:8; % define frequency window. Step size is dependent on segment lenghts, so only change first and last value.
    cfg.fft_auc{2}.taper    =  'hanning'; %Hanning seems to work better than dpss.
    cfg.fft_auc{2}.keeptrials = 'no';

% --- Coherence Analysis ('ft_connectivityanalsis') --- %
    cfg.cfg_coh.output    = 'fourier';        % Frequency analysis previous to coherence analysis
    cfg.cfg_coh.method    = 'mtmfft';         % Coherence analysis method ('mtmfft' for simple coherence)
    cfg.cfg_coh.foi       = 2:0.5:13;          % Frequency range (usually same as cfg_freq.foi)
    cfg.cfg_coh.tapsmofrq = 0.5;

%--------------------------------------------------------------------------
%%  File info 
%--------------------------------------------------------------------------

    conf.file.name    =   '/CurSub/&/CurSess/&/CurRun/&/.vhdr/';    % .vhdr file of the BVA EMG file(uses pf_findfile)
    conf.file.nchan   =   nChannels;                                % total amount of channels in original file
    conf.file.chan    =   emgChannels;                              % Channels you want to analyze. EMG
    conf.file.scanpar =   [TR;NSlices;nan];                         % Scan parameters: TR / nSlices / nScans (enter nan for nScans if you want to automatically detect this)
    conf.file.etype   =   'R  1';                                   % Scan marker (EEG.event.type)

%--------------------------------------------------------------------------
%%  Preprocessing and slice triggers
%--------------------------------------------------------------------------
    conf.preproc.mkbipol    =   'no';       % If yes, then it will make bipolar out of monopolar channels
    conf.slt.plot           =   'no';       % Plot the slicetrigger check (no for qsub)

%--------------------------------------------------------------------------
%%  Additional methods
%--------------------------------------------------------------------------
    conf.meth.volcor  =   'yes';   % volume correction
    conf.meth.cluster =   'yes';   % cluster correction
    conf.meth.pca     =   'yes';   % do PCA
    conf.meth.lp      =   'yes';   % do lowpass filtering
    conf.meth.hp      =   'yes';   % do highpass filtering
    conf.meth.anc     =   'yes';   % do ANC


%% Call functions
    startdir = conf.dir.emgacc;
    cd(cluster_outputdir)
    
    % check for existing FARM files
    FARMdir = fullfile(processing_dir,'FARM');
    FARMsearchstring = ['/' conf.sub.name{1} '_' conf.sub.sess{1} '/&/' Task '/'];
    FARMfile = pf_findfile(FARMdir, FARMsearchstring);
    
    % check for existing freqana files
    if strcmp(conf.mkregr.zscore, 'yes'); regrDir = fullfile(conf.dir.regr, 'zscored'); else; regrDir = fullfile(conf.dir.regr, 'notzscored'); end
    chans = labels(conf.mkregr.automaticchans + nrOfNotRecorded * conf.todo.ACC);
    freqFiles = cell(length(chans),1);
    for chan = 1:length(chans)
        searchstring = ['/' conf.sub.name{1} '-' conf.sub.sess{1} '/&/' chans{chan} '_/&/Hz_regressors_/'];
        freqFiles{chan} = pf_findfile(regrDir, searchstring);
    end
    
    % run FARM if not done yet
    if isempty(FARMfile) && conf.todo.Farm
        conf.test.pScan     = pScan;
        fprintf('Submitting FARM-job for %s-%s\n', conf.sub.name{1}, conf.sub.sess{1});
       
        % run on cluster
        FARMjobs{n} = qsubfeval('pf_emg_farm', conf.sub.name, conf,'memreq', 8*1024^3,'timreq',1*60*60);
%         pf_emg_farm(conf.sub.name,conf); % uncomment to run outside of cluster!     
        pause(5)

    % run frequency analysis if not done yet
    elseif all(cellfun(@isempty, freqFiles)) && conf.todo.Frequency_analysis
        conf.test.pScan     = pScan;
        fprintf('Submitting frequency analysis-job for %s-%s\n', conf.sub.name{1}, conf.sub.sess{1});
        
        % run on cluster
        FREQjobs{n} = qsubfeval('pf_emg_raw2regr', conf, cfg, 'memreq',16*1024^3,'timreq',1*60*60);
%         pf_emg_raw2regr(conf,cfg); % uncomment to run outside of cluster
        pause(5)

    else
        fprintf('FARM and frequency analysis already done for %s-%s or not selected as task\n', conf.sub.name{1}, conf.sub.sess{1});
    end
end
end

jobs = [FARMjobs FREQjobs];

% Save clusterjobs
if ~isempty(jobs)
    task.jobs = jobs;
    task.submittime = datestr(clock);
    task.mfile = mfilename;
    task.mfiletext = fileread([task.mfile '.m']);
    save([cluster_outputdir '/jobs_' task.mfile  '_' datestr(clock) '.mat'],'task');
end

fprintf(['\n --- | Done | ---\n']);

cd(startdir)


end