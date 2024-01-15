
clear all 

%==========================================================================
% --- Settings --- %
%==========================================================================

ft_defaults; % voor gebruiken van ft_colorbar nodig
conf = Settings();

addpath(conf.dir.other.supporting);
addpath(fullfile(conf.dir.other.supporting, 'helpers'));

% --- Trial settings ---
conf.trial.nr           = 10;       % nr of trials
conf.trial.duration     = 60;       % duration of one trial (in scans)
conf.trial.start.tremor = 6;        % nr of scans before the start of the first trial
conf.trial.start.pupil  = 1;
conf.trial.start.HR     = 6;
conf.trial.indicesTrial = [1:2:conf.trial.nr];     % indices of the non-rest (so coco) trials
conf.trial.total        = conf.trial.nr * conf.trial.duration;

% --- General settings ---
conf.regr.datatypes     = {'tremor'; 'pupil'; 'HR';};
%conf.regr.zscored       = 'zscored';
conf.regr.zscored       = 'notzscored';

conf.regr.which.tremor  = 'lin_unconvolved';
conf.regr.which.pupil   = 'eye';
conf.regr.which.HR      = 'HR_bpm_timelag_0';

conf.regr.HR.toexclude = {    
    '004-01', '005-02', '006-02', '008-02', '009-02', ...
    '011-01', '012-01', '016-02', '022-01', '022-02', ...
    '023-01'};

conf.regr.pupil.dq.dir  = fullfile(conf.dir.eyelink, 'analysis', 'dataquality', 'coco');
conf.regr.pupil.dq.file = 'Sub_Ses_c_dataquality.mat';
conf.regr.pupil.dq.trheshold = 25;

conf.regr.tremor.channel = {
    {'003-02',  '011-01',   '022-01',   '022-02',   '025-01',   '025-02',   '028-02'};
    {'ECR',     'FCR',      'ECR',      'ECR',      'Acc_x',    'Acc_x',    'Acc_x'};
                };
conf.regr.tremor.default = 'Acc';
conf.regr.tremor.toexclude = {'003-02', '011-01', '012-01', '022-01', '022-02'};

% --- Directories ---

% Regressors
conf.dir.tremor     = fullfile(conf.dir.emg,        'coco', 'processing', 'prepemg', 'Regressors', conf.regr.zscored);
conf.dir.pupil      = fullfile(conf.dir.eyelink,    'analysis', 'regressors', 'coco');
conf.dir.HR         = fullfile(conf.dir.heartrate,  'output', 'regressors_coco');

% --- File names (for pf_findfile ) ---

% Regressors
conf.file.HR        = '/Sub_Ses_/&/_coco_fMRI_run_/&/_hera_RETROICORplus_regr.mat/';
conf.file.pupil     = ['Sub_Ses_c_regressor_raw-' conf.regr.zscored '.mat'];
conf.file.tremor    = '/Sub-Ses-coco_Channel/&/_regressors_log.mat/';

% Other
conf.file.save      = 'Coco_AllData.mat';

%==========================================================================
% --- Put all data into one structure --- %
%==========================================================================

% PER SUBJECT
for sub = 1:length(conf.sub.name)
    CurSub = conf.sub.name{sub};
	data(sub).subname = CurSub;
    fprintf('subject %s\n', CurSub);
	
    % PER SESSION
    for ses = 1:length(conf.sub.ses)
        CurSes = conf.sub.ses{ses};
        data(sub).ses(ses).sesname = CurSes;
        fprintf('  session %s\n', CurSes);
    
        
        % Get the channel to use for EMG file 
        idx = strcmp(conf.regr.tremor.channel{1}, [CurSub '-' CurSes]);
        if ~any(idx)
            channel = conf.regr.tremor.default;            
        else
            channel = conf.regr.tremor.channel{2}{idx};
        end
        

        
        % PER DATA TYPE
        for dt = 1:length(conf.regr.datatypes)
            datatype = conf.regr.datatypes{dt};
            fprintf('    %s:\t', datatype(1:2));
            
            % find file
            fileName   = replace(conf.file.(datatype), {'Sub', 'Ses'}, {CurSub, CurSes});
            if strcmp(datatype, 'tremor')
                fileName = replace(fileName, 'Channel', channel);
            end
            file = pf_findfile(conf.dir.(datatype), fileName);
 
            % --- If there's more than one file, ask the user which one is the correct file ---
            if iscell(file)
                fprintf('%s-%s more than one file found:\n', CurSub, CurSes)
                for f = 1:length(file)
                    fprintf('  %i) %s\n',f,file{f})
                end
                idx = input('  which one do you want to use:    ');
                file = file{idx};
                fprintf('  using file %s\n', file{f});
            end                 
            
            % if there is a file => load file and check if it's usable
            if ~isempty(file)
                % load data
                curdata = load(fullfile(conf.dir.(datatype), file));

                % get the indices of the data
                indices = conf.trial.start.(datatype) : conf.trial.total + conf.trial.start.(datatype) - 1;
                
                % 018 tremor one first needs to be padded with zeroes
                if strcmp(datatype, 'tremor') && strcmp([CurSub '-' CurSes], '018-01')
                    nScansMissing   = 32; % 32 scans of first coco block are missing (27 always, 5 because of how regressor is created)
                    extraScans      = 5;  % the 5 scans before first coco block are also missing
                    curdata.R       = [nan(nScansMissing + extraScans, size(curdata.R,2)); curdata.R];
                end
                         
                % check if the data is useable and get indices of the data
                switch(datatype)
                    case 'tremor'   
                        % a few are not useable for averages because of EMG instead of ACC
                       data(sub).ses(ses).(datatype).usable = ~any(contains(conf.regr.tremor.toexclude, [CurSub '-' CurSes]));
                        %data(sub).ses(ses).(datatype).usable = contains(file, 'Acc');

                    case 'pupil'
                        % load file with info about data quality and check whether p(drops) is below a certain threshold 
                        dqfilename = replace(conf.regr.pupil.dq.file, {'Sub', 'Ses'}, {CurSub, CurSes});
                        dqfile      = fullfile(conf.regr.pupil.dq.dir, dqfilename);
                        dq          = load(dqfile);
                        
                        if dq.dq.data.pDrops <= conf.regr.pupil.dq.trheshold
                            data(sub).ses(ses).(datatype).usable = true;
                        else
                           data(sub).ses(ses).(datatype).usable = false;
                        end
                        
                    case 'HR'
                        % 
                        data(sub).ses(ses).(datatype).usable = ~any(contains(conf.regr.HR.toexclude, [CurSub '-' CurSes]));

                end
                
            % if there's no file => not usable
            else
                data(sub).ses(ses).(datatype).usable = false;
            end
            
            
            % store the data
            if data(sub).ses(ses).(datatype).usable
                fprintf(' usable      (%s)\n', file);
                data(sub).ses(ses).(datatype).data = curdata.R(indices, strcmp(curdata.names, conf.regr.which.(datatype)));
            else
                data(sub).ses(ses).(datatype).data = repelem(NaN, conf.trial.total, 1);
                fprintf(' NOT usable  (%s)\n', file);
            end       
        end
    end    
end

% --- Save file ---
savename = fullfile(conf.dir.files, conf.file.save);
save(savename,'data'); 
fprintf('Data saved to "%s"\n', savename);

