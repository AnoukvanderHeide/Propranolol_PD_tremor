function eyelink_dataquality(conf)
%eyelink_dataquality.m compiles the data quality of individual datasets
%into one structure
% Inputs:
%   conf             : structure with settings
% Saves output as a matlab file with a structure called dq
%   dq.nEpochs       : number of epochs in data set
%   dq.pEpochsUsable : percentage of epochs in data sets that were usable (aka had less drops/spikes than a certain threshold)
%   dq.nEpochsUsable : nr of epochs in data set that were usable
%   dq.artifacts     : percentage of artifacts per epoch (is list with length nEpochs)
%   dq.pDrops        : percentage of drops in data set
%   dq.pSpikes       : percentage of spikes in data set
%   dq.usable        : whether the data set is usable (aka whether the number of drops is smaller than certain threshold)

    idx = 1;
    
    % --- load all data ---
    for sub = 1:length(conf.sub.name)
        CurSub = conf.sub.name{sub};

        for ses = 1:length(conf.sub.ses)
            CurSes = conf.sub.ses{ses};
            clear subdq
            

            dq.name{idx}    = [CurSub '-' CurSes];

            % --- Check if file exists---
            dqFilename  = replace(conf.file.spikecheck, {'Sub', 'Ses'}, {CurSub, CurSes});
            dqFile      = pf_findfile(conf.dir.spikecheck,dqFilename);
            
            if isempty(dqFile)
                fprintf('      %s-%s: no data quality info found\n', CurSub, CurSes);
                dq.exists(idx)          = false;
                dq.usable(idx)          = false;
                dq.nEpochs(idx)         = NaN;
                dq.pEpochsUsable(idx)   = NaN;
                dq.nEpochsUsable(idx)   = NaN;
                dq.artifacts(idx)       = {NaN};
                dq.pDrops(idx)          = NaN;
                dq.pSpikes(idx)         = NaN;
                
                idx = idx + 1;
                continue
            end
            dq.exists(idx)  = true;
            
            
            % --- Load file --- 
            subdq       = load(fullfile(conf.dir.spikecheck, dqFile));
            
            
            % --- Get data quality results ---
            dq.nEpochs(idx)         = length(subdq.dq.epoch.discarded);
            dq.pEpochsUsable(idx)   = sum(~subdq.dq.epoch.discarded) / length(subdq.dq.epoch.discarded) * 100;
            dq.nEpochsUsable(idx)   = sum(~subdq.dq.epoch.discarded);
            dq.artifacts(idx)       = {subdq.dq.epoch.pArtifacts};
            dq.pDrops(idx)          = subdq.dq.data.pDrops;
            dq.pSpikes(idx)         = subdq.dq.data.pSpikes;
            dq.usable(idx)          = dq.pDrops(idx) <= conf.average.threshold.incl;
 
            fprintf('      %s-%s: percentage drop in eyetracking: %s%%\n', CurSub, CurSes, num2str(dq.pDrops(idx)));
            
            idx = idx + 1;

        end
        
    end
    
    % --- Save info about data quality ---    
    save(fullfile(conf.dir.averagedq,conf.file.averagedq),'dq');
    fprintf('    info about data quality saved to %s\n',conf.file.averagedq);


end