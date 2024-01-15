function pf_emg_raw2regr(conf, cfg)
% pf_emg_raw2regr(conf,cfg,varargin) is a batch like function with the 
% main goal to transform a raw EMG or Accelerometry signal into a regressor 
% describing tremor fluctuations to be used in a general linear model for 
% fMRI analyses. The input is usually EMG signal after fMRI artifact 
% reduction (e.g. FARM, for example via pf_emg_farm_ext). 

% For fMRI artifact reduction of EMG signal see pf_emg_farm_ext

tic; 

%--------------------------------------------------------------------------
% Add packages
%--------------------------------------------------------------------------
% if isempty(which('ft_defaults')) %check if fieldtrip is installed
%     addpath(path.Fieldtrip); %Add fieldtrip
%     ft_defaults
% end
% addpath(path.SPM); %Add SPM12
% addpath(fullfile(path.Fieldtrip, 'qsub'));
% addpath(genpath(path.ParkFunc));  %Add ParkFunc
% addpath(conf.dir.eeglab); eeglab; %Add eeglab
% addpath(genpath(conf.dir.Farm)); %Add FARM

%Check number of scans
dImg = fullfile(conf.dir.bids, ['sub-' conf.sub.name{1}], ['ses-mri' conf.sub.sess{1}], 'func');
fpImg = spm_select('FPList', dImg, conf.test.pScan);
nScan = size(spm_vol(fpImg(size(fpImg,1),:)),1);    % Takes the last run only
conf.mkregr.nscan = nScan - conf.prepemg.dumscan;

%--------------------------------------------------------------------------
% Frequency analysis ('prepemg')
%--------------------------------------------------------------------------
if conf.todo.prepemg 
    pf_emg_raw2regr_prepemg(conf,cfg);
end

%--------------------------------------------------------------------------
% Create regressor of frequency analyzed data ('mkregressor')
%--------------------------------------------------------------------------
if conf.todo.mkregressor
    pf_emg_raw2regr_mkregr(conf);
end

%--------------------------------------------------------------------------
% Cooling Down
%--------------------------------------------------------------------------
T   =   toc;
fprintf('\n%s\n',['Mission accomplished after ' num2str(T/60) ' minutes!!'])