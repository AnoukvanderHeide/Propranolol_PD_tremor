function conf = coco_conf(conf)
%coco_conf.m returns a structure with settings for the fMRI analysis

% Anouk van der Heide, 2020

warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');
addpath('/project/3024005.02/Analysis/MRI/scripts/')
%addpath(genpath('/project/3024005.02/Analysis/MRI/scripts/TFCE/'))

%==========================================================================
% --- Subject + session settings --- %
%==========================================================================

% --- Subjects ---

conf.sub.name = { '002'; '003'; '004'; '005'; '006'; ... % 001 excluded due to covid, 007 based on low HR
                  '008'; '009'; '011'; '012'; '014'; ... % 010 no 2nd MRI (pain), 013 based on ECG
                  '015'; '016'; '018'; '020'; '022'; ... % 017 excluded (outlier and anxiety in scanner), 019 no 2nd MRI (pain/panic), 021 based on ECG
                  '023'; '025'; '028'; '029'; '030'; ... % 024 and 026 excluded based on ECG, 027 bad ACC 
                  '063'; '064'; '065'; ...               % 061 excluded based on ECG, 062 did not take place
                 };  
     
conf.sub.hand = other_getMAhand(conf);

% conf.sub.drug indicates session with propranolol (1 => 1st session was
% prop, 2nd was placebo; 2 => 1st session was placebo)
conf.sub.drug = other_getdrug(conf);
            
% --- Sessions ---
conf.sub.ses = {'01'; '02'}; 

% --- Trial settings ---
conf.trial.nr           = 10; % nr of trials
conf.trial.duration     = 60; % duration of one trial (in scans)
% these are based on scanning/presentation protocol:
conf.trial.dummies      = 5;  % nr of dummy scans
conf.trial.startDelay   = 5;  % nr of scans (after dummy scans) before the start of the first trial
% these you can choose:
conf.trial.startInclude = 5;  % nr of scans (after dummy scans) before the start of the first trial that you want to INCLUDE in the model (should be smaller or equal to startDelay)
conf.trial.endInclude   = 10; % nr of scans to include after end of last trial (if there aren't this many scans at the end, it will include all scans that are left)

% --- Exceptions ---
% 018-01
conf.exc.s018s01.coco_on    = [0    88    208   328   448];
conf.exc.s018s01.coco_off   = [27   147   267   387   507];
conf.exc.s018s01.rest_on    = [28   148   268   388   508];
conf.exc.s018s01.rest_off   = [87   207   327   447   567];

%==========================================================================
% --- Directory and file settings --- %
%==========================================================================

% --- Directories ---

% General 
conf.dir.pf         = fullfile('/project', '3024005.02');
conf.dir.raw        = fullfile(conf.dir.pf, 'raw');
conf.dir.analysis   = fullfile(conf.dir.pf, 'Analysis');

% Main analysis directories
conf.dir.bids       = fullfile(conf.dir.pf, 'bidsoutput');
conf.dir.pupil      = fullfile(conf.dir.analysis, 'Eyelink');
conf.dir.HR         = fullfile(conf.dir.analysis, 'Heart_rate');
conf.dir.emg        = fullfile(conf.dir.analysis, 'EMG');
conf.dir.MRI        = fullfile(conf.dir.analysis, 'MRI');
conf.dir.tremreg    = fullfile(conf.dir.analysis, 'Tremor_registration');
conf.dir.chars      = fullfile(conf.dir.analysis, 'Participant Characteristics', 'output');
% conf.dir.castor     = fullfile(conf.dir.analysis, 'Participant Characteristics' , 'input');

% fMRIprep output
conf.dir.fmriprep.main      = fullfile(conf.dir.MRI, 'fmriprep-coco', 'output', 'fmriprep'); 
conf.dir.fmriprep.func      = fullfile(conf.dir.fmriprep.main, 'sub-Sub', 'ses-mriSes', 'func');

% Regressors
% conf.dir.regr.HR            = fullfile(conf.dir.HR, 'output', 'regressors');
% conf.dir.regr.pupil         = fullfile(conf.dir.pupil, 'analysis', 'regressors');
conf.dir.regr.emg           = fullfile(conf.dir.emg, 'coco', 'processing', 'prepemg', 'Regressors', 'zscored');
% conf.dir.regr.emgchannels   = conf.dir.tremreg;
conf.dir.regr.nuis          = conf.dir.fmriprep.func;       % nuisance regresosrs

% Preprocessed data
conf.dir.prepro.smooth      = conf.dir.fmriprep.func;       % where the smoothed data is/will be stored (same as input directory usually)
conf.dir.prepro.reorient    = conf.dir.fmriprep.func;       % where the reoriented data is/will be stored (same as input directory usually)

% SPM model
conf.dir.spm.main   = fullfile(conf.dir.MRI, 'output_spm');                    % main spm output folder
conf.dir.spm.sub    = fullfile(conf.dir.spm.main, 'first-level', 'sub-Sub');   % subject specific output folder (Sub will be replaced by sub nr)
conf.dir.spm.output = fullfile(conf.dir.spm.sub, 'results');                   % folder where SPM.mat and contrast images will be stored
conf.dir.spm.group  = fullfile(conf.dir.spm.main, 'second-level_paired_FD');   % folder where group outputs will be stored

% --- File names (for pf_findfile ) ---

% MRI/fMRIprep
conf.file.mri.cocozip           = '/|sub-Sub_ses-mriSes_task-coco_acq-epfid2d1104_run-/&/_echo-1_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz|/'; % the zipped input fmri data
%conf.file.mri.cocozip           = '/|sub-Sub_ses-mriSes_task-coco_acq-epfid2d1104_run-/&/_echo-1_space-MNI152NLin6Asym_desc-smoothAROMAnonaggr_bold.nii.gz|/'; % the zipped input fmri data
conf.file.mri.coco              = erase(conf.file.mri.cocozip, '.gz'); % unzipped filename

% Regressors
conf.file.regr.HR               = '/Sub-Ses_/&/_coco_fMRI_run_/&/_hera_RETROICORplus_regr.mat/';
conf.file.regr.pupil            = 'Sub-Ses_c_regressor_raw-notzscored.mat';
conf.file.regr.emg              = '/Sub-Ses-coco_Channel/&/_regressors_log.mat/';
conf.file.regr.nuis.confounds   = '/sub-Sub_ses-mriSes_task-coco_acq-epfid2d1104_run-/&/_desc-confounds_timeseries.tsv/';
conf.file.regr.nuis.indices     = '/sub-Sub_ses-mriSes_task-coco_acq-epfid2d1104_run-/&/_AROMAnoiseICs.csv/';
conf.file.regr.nuis.aroma       = '/sub-Sub_ses-mriSes_task-coco_acq-epfid2d1104_run-/&/_desc-MELODIC_mixing.tsv/';

% SPM Model
conf.file.spm.model.conditions  = 'model_conditions_Sub-Ses.mat';        % filename to which the file with conditions will be stored
conf.file.spm.model.regressors  = 'model_regressors_Sub-Ses.mat';        % filename to which the file with regressors will be stored
conf.file.spm.model.tremorplot  = 'plot_tremor_regressors_Sub-Ses.jpg';  % filename to which the tremor regressor plot will be stored

% SPM Batch files
conf.file.spm.batch.smooth      = 'batch_smooth_Sub-Ses.mat';   % how smoothing batch will be stored
conf.file.spm.batch.firstlevel  = 'batch_firstlevel_Sub.mat';   % how first-level batch will be stored
conf.file.spm.batch.reorient    = 'batch_reorient.mat';         % how reorient batch will be stored
conf.file.spm.batch.secondlevel = 'batch_ContrastCode.mat';     % how the second-level batches will be stored

% Other
conf.file.other.chars           = 'TableFull.mat';
%conf.file.MA            = 'ACCdata.csv';    % file that contains which hand was measured

%==========================================================================
% --- Analysis settings - GENERAL --- %
%==========================================================================

conf.todo.which = 'first';          % whether to perform first or second-level analysis (in batch script, input from user is asked and this one will be overwritten so sort of useless)

conf.todo.fla_steps = {             % first-level analysis steps to perform
                    'unzip';        % unzip images
                    'smooth';       % smooth images
                    'combicond';    % combine conditions
                    'combiregr';    % combine regressors into one file for your GLM
                    'firstlevel';   % build and run first level batch
                    };
conf.todo.sla_steps = {             % second-level analysis steps to perform
                    'reorient';     % flip images with left-sided tremor
                    'secondlevel';  % build and run second level batch
                    };
            
conf.force.combicond    = false;    % if true => create condition file even if it already exists
conf.force.combiregr    = false;    % if true => create regressor file even if it already exists
conf.force.reorient     = false;

%==========================================================================
% --- Analysis settings - PREPROCESSING --- %
%==========================================================================

% --- Smoothing ---
conf.pre.smooth.filedir         = conf.dir.fmriprep.func;   % input dir
conf.pre.smooth.filename        = conf.file.mri.coco;
conf.pre.smooth.fwhm            = [6 6 6];                  % Default [8 8 8]
conf.pre.smooth.dtype           = 0;                        % Default 0
conf.pre.smooth.im              = 0;                        % Default 0
conf.pre.smooth.prefix          = ['smoothed' replace(num2str(conf.pre.smooth.fwhm), ' ', '') '_'];    % => 'smoothed666_'    Default 's'


%==========================================================================
% --- Analysis settings - CREATE FILES --- %
%==========================================================================

% --- Create Conditions ---
conf.fla.cond.emg           = 'unconvolved';    % choose if you want to add convolved or unconvolved version of emg data
conf.fla.cond.default       = 'Acc';            % if the channel is not defined below, use this one as default
conf.fla.cond.channels      = {
    {'003-02',  '011-01',   '022-01',   '022-02',   '025-01',   '025-02',   '028-02'};
    {'ECR',     'FCR',      'ECR',      'ECR',      'Acc_x',    'Acc_x',    'Acc_x'};   };
% conf.fla.cond.channels = {
%     {'002-02', 	'008-02', 	'009-01', 	'009-02', 	'011-01', 	'011-02', 	'015-01', 	'015-02', 	'016-01', 	'018-01', 	'018-02', 	'020-01', 	'020-02', 	'022-01', 	'022-02', 	'029-02'};		
%     {'ECR_ma', 	'ECR_ma',	'ECR_ma',	'FCR_ma',	'FCR_ma',	'FCR_ma',	'FCR_ma',	'ECR_ma',	'FCR_ma',	'FCR_ma',	'ECR_ma',	'ECR_ma',	'ECR_ma',	'ECR_ma',	'ECR_ma',	'FCR_ma'};
% };

% --- Create regressor matrix ---
conf.fla.regr.dummy     = conf.trial.dummies;    % how many dummy scans there are (will be removed from regressor matrix)
conf.fla.regr.which     = {     % which nuisance regressors to add
      'framewise_displacement';
      'std_dvars';
      %'tremorlog';
      %'tremorderiv';
      %'global_signal';
      'csf';
      'white_matter';
      'motion24';     % add 24 motion parameters
      'aroma-manual'  % add the AROMA components based on the AROMAnoiseICs.csv file
    };

% Which extra analysis things related to regressors to perform and which
% filenames the output should be stored to
conf.fla.regr.plotmotion.todo       = true;
conf.fla.regr.plotmotion.filename   = 'plot_motion_regressors_Sub-Ses.jpg';
conf.fla.regr.plotall.todo          = true;
conf.fla.regr.plotall.filename      = 'plot_nuisance_regressors_Sub-Ses.jpg';
conf.fla.regr.corr.todo             = true;
conf.fla.regr.corr.filename         = 'data_correlations_Sub-Ses.mat';

%==========================================================================
% --- Analysis settings - FIRST LEVEL ANALYSIS --- %
%==========================================================================

% --- fMRI model specification ---

% output things
conf.fla.spec.output.main   = conf.dir.spm.sub;         % subject-specific folder
conf.fla.spec.output.dir    = conf.dir.spm.output;      % folder where SPM.mat and contrast images will be stored
conf.fla.spec.output.name   = conf.file.spm.batch.firstlevel;   % batch file output name

% input scans
conf.fla.spec.scan.name  = ['/|' conf.pre.smooth.prefix conf.pre.smooth.filename(3:end)]; % name of input scans
%conf.fla.spec.scan.name  = ['/|' conf.pre.smooth.filename(3:end)]; % name of input scans with no smoothing
conf.fla.spec.scan.dir   = conf.dir.prepro.smooth;      % directory where input scans are located
% conf.fla.spec.scan.start = conf.trial.startDelay + 1;   % index of first scan to include

conf.fla.spec.multiregr.dir     = conf.dir.spm.sub;                 % directory with regressor file
conf.fla.spec.multiregr.name    = conf.file.spm.model.regressors;   % name of regressor file
conf.fla.spec.multicond.dir     = conf.dir.spm.sub;                 % directory with condition file
conf.fla.spec.multicond.name    = conf.file.spm.model.conditions;   % name of condition file
 
% --- Contrasts ---

% order of regressors:
% 1: coco 
% 2: coco-ACC-amp 
% 3: coco-ACC-change
% 4: rest
% 5: rest-ACC-amp 
% 6: rest-ACC-change

% These contrasts are created per session and averaged over sessions. 

% F-contrasts   
conf.fla.con.fcontrasts  = struct('name', {}, 'weights', {}, 'sessrep', {});

% For DCM first-level models, only coco regressors are included, so 3 columns
% conf.fla.con.fcontrasts(end+1).name  = 'effects of interest';
% conf.fla.con.fcontrasts(end).weights = [1 0 0
%                                         0 1 0
%                                         0 0 1];
% conf.fla.con.fcontrasts(end).sessrep = 'both';

conf.fla.con.fcontrasts(end+1).name  = 'effects of interest';
conf.fla.con.fcontrasts(end).weights = [1 0 0 0 0 0
                                        0 1 0 0 0 0
                                        0 0 1 0 0 0
                                        0 0 0 1 0 0
                                        0 0 0 0 1 0 
                                        0 0 0 0 0 1];
conf.fla.con.fcontrasts(end).sessrep = 'both';

% t-contrasts (all are generated 3 times, for placebo, propranolol and both sessions
conf.fla.con.contrasts  = struct('name', {}, 'weights', {}, 'sessrep', {});

conf.fla.con.contrasts(end+1).name  = 'coco_general'; % contrast nr. 0004 (ses1) 0005 (ses2) 0006 (avg)
conf.fla.con.contrasts(end).weights = [1 0 0];
conf.fla.con.contrasts(end).sessrep = 'both';

conf.fla.con.contrasts(end+1).name  = 'coco_tremoramp'; 
conf.fla.con.contrasts(end).weights = [0 1 0];
conf.fla.con.contrasts(end).sessrep = 'both';

conf.fla.con.contrasts(end+1).name  = 'coco_tremorchange';
conf.fla.con.contrasts(end).weights = [0 0 1];
conf.fla.con.contrasts(end).sessrep = 'both';

conf.fla.con.contrasts(end+1).name  = 'rest_general'; % contrast nr. 0013 (ses1) 0014 (ses2) 0015 (avg)
conf.fla.con.contrasts(end).weights = [0 0 0 1];
conf.fla.con.contrasts(end).sessrep  = 'both';

conf.fla.con.contrasts(end+1).name  = 'rest_tremoramp';
conf.fla.con.contrasts(end).weights = [0 0 0 0 1];
conf.fla.con.contrasts(end).sessrep  = 'both';

conf.fla.con.contrasts(end+1).name  = 'rest_tremorchange'; 
conf.fla.con.contrasts(end).weights = [0 0 0 0 0 1];
conf.fla.con.contrasts(end).sessrep  = 'both';

conf.fla.con.contrasts(end+1).name  = 'all_general'; % contrast nr. 0022 0023 0024
conf.fla.con.contrasts(end).weights = [1 0 0 1 0 0];
conf.fla.con.contrasts(end).sessrep  = 'both';

conf.fla.con.contrasts(end+1).name  = 'all_tremoramp'; % contrast nr. 0025 0026 0027
conf.fla.con.contrasts(end).weights = [0 1 0 0 1 0];
conf.fla.con.contrasts(end).sessrep  = 'both';

conf.fla.con.contrasts(end+1).name  = 'all_tremorchange';
conf.fla.con.contrasts(end).weights = [0 0 1 0 0 1];
conf.fla.con.contrasts(end).sessrep  = 'both';

conf.fla.con.contrasts(end+1).name  = 'coco>rest_general';
conf.fla.con.contrasts(end).weights = [1 0 0 -1 0 0];
conf.fla.con.contrasts(end).sessrep  = 'both';

conf.fla.con.contrasts(end+1).name  = 'coco>rest_tremoramp';
conf.fla.con.contrasts(end).weights = [0 1 0 0 -1 0];
conf.fla.con.contrasts(end).sessrep  = 'both';

conf.fla.con.contrasts(end+1).name  = 'coco>rest_tremorchange';
conf.fla.con.contrasts(end).weights = [0 0 1 0 0 -1];
conf.fla.con.contrasts(end).sessrep  = 'both';

conf.fla.con.contrasts(end+1).name  = 'rest>coco_general';
conf.fla.con.contrasts(end).weights = [-1 0 0 1 0 0];
conf.fla.con.contrasts(end).sessrep  = 'both';

conf.fla.con.contrasts(end+1).name  = 'rest>coco_tremoramp';
conf.fla.con.contrasts(end).weights = [0 -1 0 0 1 0];
conf.fla.con.contrasts(end).sessrep  = 'both';

conf.fla.con.contrasts(end+1).name  = 'rest>coco_tremorchange';
conf.fla.con.contrasts(end).weights = [0 0 -1 0 0 1];
conf.fla.con.contrasts(end).sessrep  = 'both';

%==========================================================================
% --- Analysis settings - TFCE --- %
%==========================================================================


conf.tfce.dir.main          = fullfile(conf.dir.MRI, 'scripts', 'TFCE');
conf.tfce.dir.ROIs          = fullfile(conf.dir.MRI, 'masks');
conf.tfce.dir.clusteroutput = fullfile(conf.tfce.dir.main, 'clusteroutput');
conf.tfce.file.batch        = 'Batch_TFCE_conCon_roiRoi.mat';

% second level folders and ROI definition for 2x2 factorial design (not possible for TFCE)
% conf.tfce.secondlevels  = { 'taskxdrug(general)'; % these are set at the top of the coco_sla_2x2.m script
%                             'taskxdrug(tremoramp)';
%                             'taskxdrug(tremorchange)'
%                           };

% conf.tfce.ROIs  = { {'WB'};
%                     {'WB', 'resliced_L_MC_pos_-28_-26_62.nii', 'resliced_R_CBLM_pos_18_-50_-20.nii', 'resliced_L_VLpv.nii'};
%                     {'WB', 'resliced_L_MC_pos_-28_-26_62.nii', 'resliced_R_CBLM_pos_18_-50_-20.nii', 'resliced_L_VLpv.nii'};
%                   }; 

% second level folders and ROI definition in paired t-test design
conf.tfce.secondlevels  = { 'cocovsrest(general)'; % these are set at the top of the coco_sla_paired_ttest.m script
                            'placvsprop(general)';
                            'placvsprop(tremoramp)';
                            'interaction(general)';
                            'interaction(tremoramp)'
                           };

conf.tfce.ROIs  = { {'WB'};
                    {'WB'};
                    {'WB', 'resliced_L_MC_pos_-28_-26_62.nii', 'resliced_R_CBLM_pos_18_-50_-20.nii', 'resliced_L_VLpv.nii'};
                    {'WB'};
                    {'WB', 'resliced_L_MC_pos_-28_-26_62.nii', 'resliced_R_CBLM_pos_18_-50_-20.nii', 'resliced_L_VLpv.nii'};
                  }; 

% second level folders and ROI definition in one-sampled t-test
%conf.tfce.secondlevels  = { 'tremor' }; % this is set at the top of the coco_sla_onesampled.m script

%conf.tfce.ROIs  = {'WB', 'resliced_L_MC_pos_-28_-26_62.nii', 'resliced_R_CBLM_pos_18_-50_-20.nii', 'resliced_L_VLpv.nii'}; 


end
