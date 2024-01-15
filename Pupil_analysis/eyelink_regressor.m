function err = eyelink_regressor(conf)
%eyelink_regressor.m Creates a regressor for conf.cur.sess-conf.cur.sub 
% Inputs:
%   conf    : structure with all settings
% Stores created regressor as matlab file and (if desired) as plot
%   coco regressor is cut to be 600 data points (start of first trial to 
%   end of last trial)
%   rest regressor is cut to be 595 data points (data of first 5 scans is
%   removed)
% Output :
%   err     : returns err = true if an error was detected while creating
%             the regressor. returns err = false otherwise
% Adapted from pf_fmri_spm12_crearegr_eyetracker.m

    % --- Get some settings ---
    CurSub      = conf.cur.sub;
    CurSes      = conf.cur.sess;
    SubSes      = [CurSub '-' CurSes]; 
    
    % --- Load file ---
    Fname   = replace(conf.file.reformmated, {'Sub', 'Ses'}, {CurSub, CurSes});
    File    = pf_findfile(conf.dir.reform, Fname);
    p       = load(fullfile(conf.dir.reform,File));

    
    % --- Detect nScans ---
    mriFolder   = replace(conf.dir.mri, {'Sub', 'Ses'}, {CurSub, CurSes});
    allScans    = dir(mriFolder);
    folders     = allScans(~cellfun('isempty', regexp({allScans.name}, conf.file.mri, 'match')));
    if length(folders) > 1      % if there was more than 1 coco run, choose the last one
        fprintf('    more than one MRI run found, using the last one: %s\n', folders(end).name);
        folders = folders(end);
    elseif length(folders) < 1  % if there are 0 coco runs, return...
        fprintf('    no MRI data found\n');
        err = true;
        return
    end    
    taskFolder = folders.name; fprintf('    ');
    Scans   = pf_findfile(fullfile(mriFolder, taskFolder),'*.IMA');
    nScans  = length(Scans);
    
    if strcmp(conf.Task, 'rest') && nScans ~= 600
        fprintf('there are %s scans instead of 600\n', num2str(nScans));
%         keyboard
        fprintf('skipping for now\n')
        err = true;
        return
    end
    
    
    % --- Retrieve some indices ---
    didx      = strcmp(p.pupdat.names,conf.regressor.var);
    scandat   = p.pupdat.rawdat{didx};
    Fs        = p.pupdat.samplerate;        % Sampling frequency
	window    = conf.regressor.tr*Fs; 		% nr of data points in one scan

    
    % --- Get scan triggers ---
    firstTrialOnset = p.pupdat.trialonsets{didx}(1);
    try 
        [startCond, nScansPre] = eyelink_getstartcondition(conf);
    catch ME
        fprintf('    error: %s', ME.message)
        err = true;
        return
    end
    
    % if there's more than a certain nr of ms between start of scan and
    % start of trial, throw an error. otherwise, it's gonna ignore this 
    % small difference to make life easier
    if startCond > conf.regressor.bv.maxdiff
        error('the trial starts too many seconds after last scan trigger\n check if this makes sense\n');
        keyboard
    end
    
    % check if the number of scans makes sense and throw a warning if it doesn't
    if strcmp(conf.Task, 'coco') && nScansPre ~= conf.regressor.bv.stndscanpre.coco
        warning('the first trial doesn''t start after 10 scans... check if this makes sense');
        keyboard
    elseif strcmp(conf.Task, 'rest') && nScansPre ~= conf.regressor.bv.stndscanpre.rest
        warning('the first trial doesn''t start after 5 scans...');
        if strcmp(SubSes, '003-01')
            % seems like the screen wasn't on the cross yet at first, so the trial marker is too late
            % it now makes a regressor that technically starts before the trial officially starts 
            warning('has been checked and ignoring');
        elseif strcmp(SubSes, '005-01') || strcmp(SubSes, '010-01') || strcmp(SubSes, '043-01')
            % 005-01: scanner was stopped and started, first 9 scans don't need to be taken into account
            % 010-01 & 043-01: brainvision file seems to have already been running during inverse scan, first 10 scan markers are from that scan and can be ignored
            warning('has been checked and is taken into account');
            nScansPre = conf.regressor.bv.stndscanpre.rest; 
        elseif strcmp(SubSes, '032-01')
            warning('not sure why or how to fix it, so skipping for now');
            err = true;
            return
        else
            warning('check if this makes sense');
            keyboard
        end
    end
    
    % calculate the scan triggers
    firstScanTrig   = (firstTrialOnset - startCond) - window * (nScansPre - 1);
    lastScanTrig    = (firstTrialOnset - startCond) + window * (nScans - nScansPre);
    
    % 018-1-rest is separate case
    if strcmp(CurSub, '018') & strcmp(CurSes, '01') & strcmp(conf.Task, 'coco')
        % this whole if-statement was commented, but not sure if that was 
        % because of the coco vs. rest thing or because it was deprecated, 
        % so if you ever get here, check whether it is necessary to run
        % this part or not
        keyboard 
        
        % the first rest onset is the 34th scan
        scansMissing = 27;
        firstScanTrig = p.pupdat.trialonsets{didx}(1) + scansMissing * window + 1;
        lastScanTrig  = firstScanTrig + window * (nScans - 1);
    end
    
    scantrig = [firstScanTrig : window : lastScanTrig]';
    
    nTrig     = length(scantrig);                                 
    regr      = nan(nTrig,1);                                     % create regressor
    artifs    = nan(nTrig,1);                                     % create vector to store artifact percentages per epoch
    
    
    if strcmp(conf.Task, 'coco')
        % --- Create windows specifying if data is COCO or REST ---
        coco_ons  = p.pupdat.trialonsets{didx}(1:2:10);
        coco_off  = coco_ons + (p.pupdat.trialwindow{didx}(2)*Fs);
        rest_ons  = p.pupdat.trialonsets{didx}(2:2:10);
        rest_off  = rest_ons + (p.pupdat.trialwindow{didx}(2)*Fs);
        condregr  = [scantrig nan(nTrig,1) nan(nTrig,1)];   % scantrigger, condition - id, discarded

        for c = 1:length(coco_ons)
            CurOns               = coco_ons(c) - conf.regressor.bv.maxdiff; %small room for error (makes sure the 6th scan is included, even though it starts a bit before the task starts)
            CurOff               = coco_off(c) - conf.regressor.bv.maxdiff;
            sel_coco             = condregr(:,1) >= CurOns & condregr(:,1) <= CurOff;
            condregr(sel_coco,2) = 1; % coco

            CurOns               = rest_ons(c) - conf.regressor.bv.maxdiff;
            CurOff               = rest_off(c) - conf.regressor.bv.maxdiff;
            sel_rest             = condregr(:,1) >= CurOns & condregr(:,1) <= CurOff;
            condregr(sel_rest,2) = 0; % rest
        end
    elseif strcmp(conf.Task, 'rest') % The commented version removes the first 5 scans (because they're technically before the start of the trial apparently?)
%         condregr    = [scantrig nan(nTrig,1) nan(nTrig,1)];   % scantrigger, condition - id, discarded
%         CurOns      = p.pupdat.trialonsets{3} - conf.regressor.bv.maxdiff;
%         CurOff      = CurOns + p.pupdat.trialwindow{3}(2) * p.pupdat.samplerate;
%         sel         = condregr(:,1) >= CurOns & condregr(:,1) < CurOff;
%         condregr(sel,2) = 1; % rest
        condregr    = [scantrig nan(nTrig,1) nan(nTrig,1)];   % scantrigger, condition - id, discarded
        condregr(:,2) = 1;      % rest (now it just adds all 600 scans)
        condregr(1:5,2) = nan;  % to remove the first 5 dummy scans (remove/comment this line to include the first 5 scans)
        
    end
             
    
    % --- Go over data and average over epoch to get one value per scan ---
    for c = 1:nTrig
                   
        CurTrig = scantrig(c);

        if round(CurTrig+window)>length(scandat) % deal with situation of not enough datapoints
            warning('eyetrack:datapoint',['Last scan does not have enough datapoints (' num2str(round(CurTrig+window)-length(scandat)) ' too less). Scanner aborted too early? Using only available datapoints'])
            CurWin  = scandat(CurTrig:end);
        else
            CurWin  = scandat(CurTrig:round(CurTrig+window));          % select current scan values
        end

        nSamp   = length(CurWin);                           % total number of values
        avg     = mean(CurWin);
        SD      = std(CurWin);

        ampsel  = CurWin>conf.regressor.threshold.drop;      % select only those values greater than specified
        CurWinS = CurWin(ampsel);

        sdsel   = CurWinS < (avg + (conf.regressor.threshold.varsd*SD)) & CurWinS > (avg - (conf.regressor.threshold.varsd*SD)); % select only those values which fall within specified SD
        CurWinS = CurWinS(sdsel);

        per_artif = ((nSamp-length(CurWinS)) / nSamp)*100;  % percentage artifacts given specified threshold in this epoch

        if per_artif > conf.regressor.threshold.pepoch % if more than specified percentage is artifacts, remove data point (= set to inf)
            %disp(['    scan ' num2str(c) ' contains ' num2str(per_artif) '% artifacts given thresholds, epoch will be discarded and interpolated from adjacent epochs.'])
            regr(c)       = inf;
            condregr(c,3) = 1;
        else
            regr(c)       = mean(CurWinS);
            condregr(c,3) = 0;
        end
        artifs(c)   =   per_artif;
    end
    
    
    % --- Look at data quality ---
    idxs = (condregr(:,2) == 0 | condregr(:,2) == 1);
    
    % Get nr of drops and spikes
    dq = eyelink_spikecheck(conf);
    dq.epoch.discarded      = condregr(idxs,3);
    dq.epoch.pArtifacts     = artifs(idxs);
    disp(['    average artifact per epoch: ' num2str(mean(dq.epoch.pArtifacts)) '%'])

    % Save data quality info
    fileName    = replace(conf.file.spikecheck(2:end-1), {'Sub', 'Ses'}, {CurSub, CurSes});
    save( fullfile(conf.dir.spikecheck, fileName) , 'dq');
    fprintf('    saved info about data quality to %s\n', fileName);
    
    
    % --- Interpolate to insert missing values ---
    sel  = find(regr==inf);     % all missing values 

    if all(regr == inf)         % if all are missing => set whole regressor to 0
        regr = repelem(0, length(regr), 1);

    elseif any(sel)
        x    = 1:1:length(regr);    % create vector with x-coordinates
        sel2 = find(regr~=inf);     % indices of values who are not missing

        while ~isempty(sel)

            % --- Retrieve indices ---
            CurSel  = sel(1);                    % Current index of missing value

            if CurSel==1                         % Special case if first value
                preval_idx = 0;     
            else
                preval_idx  = CurSel-1;          % index of previous value (which is present)
            end

            CurSel2     = find(sel2>CurSel);     % locate when values are not missing again

            if isempty(CurSel2)                  % Special case if end of regressor is missing
                postval_idx = x(end)+1;          % Last scan + 1
            else                    
                postval_idx = sel2(CurSel2(1));  % Index of postvalue not missing
            end

            
            % --- Now select gap between values ---
            if CurSel==1                         % First value missing
                postval     = regr(postval_idx); % postvalue (y)
                postval_x   = x(postval_idx);    % postvalue (x)
                preval      = postval;           % Take preval for missing value
                preval_x    = preval_idx;        % which is zero
            elseif isempty(CurSel2)              % Last values missing
                preval      = regr(preval_idx);  % prevalue (y)
                preval_x    = x(preval_idx);     % prevalue (x)
                postval     = preval;            % take postval for missing value
                postval_x   = postval_idx;       % which is nScan+1
            else                                 % Normal situation
                preval      = regr(preval_idx);  % prevalue (y)
                preval_x    = x(preval_idx);     % prevalue (x)
                postval     = regr(postval_idx); % postvalue (y)
                postval_x   = x(postval_idx);    % postvalue (x)
            end

            
            % --- Calculate in between values ---
            xx    = [preval_x postval_x];       % X-values
            vv    = [preval postval];           % Y-values
            xq    = preval_idx+1:postval_idx-1; % X value you want to estimate the y of (i.e. the missing regressor value)
            int   = interp1(xx,vv,xq);          % Calculate interpolation values

            % --- And replace these values ---
            regr(xq)  = int;
            
            
            % --- Remove values from sel ---
            selvec = ismember(sel,xq);
            sel = sel(~selvec);

        end

    end
   
    % --- Pad data of 018 ---
    if strcmp(CurSub, '018') & strcmp(CurSes, '01') & strcmp(conf.Task, 'coco')
        condregr = [repelem([NaN 1  0], scansMissing, 1); condregr];
    end
    
    
    % --- Create regressors ---
    nTrans = length(conf.regressor.todo);
    
    for c = 1:nTrans
                    
        CurTrans = conf.regressor.todo{c};
        CurTransParts = strsplit(CurTrans,'-');

        
        % --- Log transform data ---
        switch CurTransParts{1}
            case 'raw'
                scandata = regr;
            case 'log'
                scandata = log10(regr);
        end

        
        % --- Zscore data ---
        if strcmp(CurTransParts{2},'zscored')
           scandata = zscore(scandata); 
        end

        
        
        % --- Convolve with HRF ---
        spm('Defaults','fmri');
        hrfOrig = spm_hrf(conf.regressor.tr);  % get HRF for TR

        cr    = conv(scandata, hrfOrig);        % convolve data with HRF
        cr    = cr(1:end-length(hrfOrig)+1);    % get rid of last datapoints (equal to length of HRF)
        cr    = detrend(cr,'constant');         % detrend to remove linear trend

%         % --- Check if it matches nScans ---
%         if length(cr)~=nScans || length(scandata)~=nScans
%             disp('!!One of the regressors does not match nScans, please debug me...!!')
%             keyboard
%         end

        % --- Pad data of 018 ---
        if strcmp(CurSub, '018') & strcmp(CurSes, '01') & strcmp(conf.Task, 'coco')
            fprintf('    padding data\n');
            scandata = [nan(scansMissing,1); scandata];
            cr       = [nan(scansMissing,1); cr];
        end

        
        
        % --- Remove data at start and end ---
        scandata = scandata(condregr(:,2) == 0 | condregr(:,2) == 1);
        cr       =       cr(condregr(:,2) == 0 | condregr(:,2) == 1);
        
        

        % --- Plot data ---
        if conf.regressor.plot.on

            h=figure;
            set(h, 'position', [10,10,875,500]);
            plot(scandata)  % plot unconvolved version
            hold on
            plot(cr,'r')    % plot convolved version
            title([CurSub '-' CurSes ': ' conf.Task ' - eyetracker - ' CurTrans])
            xlabel('Time (scans)')
            ylabel([conf.regressor.var ' (' CurTrans ')']);

            if conf.regressor.plot.cond


                onsets      = 1:(conf.trial.trialDurSec*2):conf.trial.trialDurSec*conf.trial.nTrials;
                offsets     = onsets + conf.trial.trialDurSec - 1;
                nOns     = length(onsets);
                
                xlim([onsets(1) offsets(end) + conf.trial.trialDurSec])
                Y   =   get(gca,'ylim');
                Yf  =   1;            % Factor for making bigger/smaller
                for d = 1:nOns
                    CurStart = onsets(d);
                    CurEnd   = offsets(d);
                    P   =   patch([CurStart CurEnd CurEnd CurStart],[min(Y)*Yf min(Y)*Yf max(Y)*Yf max(Y)*Yf],'k');
                    set(P,'EdgeColor','none','FaceAlpha',0.3)
                end
            end
            %savenm = [CurFile.sub '-' CurFile.sess '-' CurMed '-' CurFile.run '_eyetrackregressor_' CurTrans '.jpg'];
            savenm = replace(conf.file.regressor(2:end-1), {'Sub', 'Ses', 'Transform', '.mat'}, {CurSub, CurSes, CurTrans, '.jpg'});
            saveas(h,fullfile(conf.dir.regrplots, savenm));
            close(h)
            fprintf('    plot saved as %s\n', savenm);
        end

        % --- Save regressor ---

        R      = [scandata cr];
        names  = {'eye';'eye_conv'};

        savenm  = replace(conf.file.regressor(2:end-1), {'Sub', 'Ses', 'Transform'}, {CurSub, CurSes, CurTrans});
        save(fullfile(conf.dir.regressor,savenm),'R','names');

        fprintf('    regressor saved to %s\n',savenm);

    end     
    
    err = false;
    

end