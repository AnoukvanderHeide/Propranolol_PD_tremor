function dq = eyelink_spikecheck(conf)
%eyelink_spikecheck.m Returns the percentage of drops and spikes in the
%dataset. 
% Inputs:
%   conf    : structure with all settings
% Outputs:
%   dq      : structure with percentage of drops and percentage of spikes

    % --- Get some settings ---
    CurSub      = conf.cur.sub;
    CurSes      = conf.cur.sess;
    nTrials     = conf.trial.nTrials;
    stndTrDur   = conf.trial.trialDurDP;


    % --- Load file ---
    Fname       = replace(conf.file.reformmated, {'Sub', 'Ses'}, {CurSub, CurSes});
    File        = pf_findfile(conf.dir.reform, Fname);
    load(fullfile(conf.dir.reform,File));
    
    
    % --- Extract data ---
    FullDat             = pupdat.rawdat{3};
    
    if strcmp(conf.Task, 'coco')
        trialOnsets         = pupdat.trialonsets{1,3};
        trialOnsets(end+1)  = trialOnsets(nTrials) + stndTrDur;
        startIdx            = trialOnsets(1);
        endIdx              = trialOnsets(11)-1;
    elseif strcmp(conf.Task, 'rest')
        trialOnset      = pupdat.trialonsets{1,3};
        startIdx        = trialOnset(1);
        endIdx          = trialOnset + pupdat.trialwindow{3}(2) * pupdat.samplerate;
    end
    
    if endIdx > length(FullDat)
        newNrScans      = floor((length(FullDat) - trialOnset) / pupdat.samplerate);
        endIdx          = trialOnset + newNrScans * pupdat.samplerate;
        fprintf('    using manual nr of scans (%s) to calculate drops/spikes\n', num2str(newNrScans));
    end
    
    CurDat              = FullDat(startIdx:endIdx);

    
    % --- Check data drops ---
    drops       = find(CurDat<=conf.regressor.threshold.spikecheck.drop);
    p_drops     = length(drops)/length(CurDat);
    p_drops     = p_drops * 100;

    
    % --- Check data spikes ---
    cnt = 1;
    spikes = [];
    for b = 1:length(drops)
        if b == length(drops)
            CurSegment  =   CurDat(drops(b)+4:end);
            start       =   drops(b) + 4;

        elseif b>1
            CurSegment  =   CurDat(drops(b)+4:drops(b+1)-4);
            start       =   drops(b)+4;

        else
            CurSegment  =   CurDat(1:drops(b)-4);
            start       =   1;
        end

        for c = 1:length(CurSegment)
            CurDatPoint = CurSegment(c);

            if c>1
                if abs(diff([CurDatPoint prevpoint])) >= (conf.regressor.threshold.spikecheck.spike)
                    spikes(cnt) = start+c-1;
                    cnt = cnt+1;
                end
            end
            prevpoint = CurDatPoint;
        end
    end
    p_spikes    =   length(spikes)/length(CurDat);
    p_spikes    =   p_spikes * 100;

    
    % --- Store results ---
    dq.data.pDrops  = p_drops;
    dq.data.pSpikes = p_spikes;

end