function heartrate_plotregressor(conf, CurSub, CurSes)
%heartrate_plotregressor.m plots the heart rate regressor for a certain
%subject/session
% Inputs:
%   conf                : structure with settings
%   CurSub and CurSes   : function will create regressor for this sub-ses
% Will store the regressor plot as a .jpg

    % --- Load file ---
    Fname   = replace(conf.file.regressor, {'Sub', 'Ses'}, {CurSub, CurSes});
    File    = pf_findfile(conf.dir.regressor, Fname);
    if isempty(File)
        fprintf('no regressor file found to plot...\n')
        return
    end
    load(fullfile(conf.dir.regressor,File));
    
    
    % --- Extract data (remove first 5 data points + extra data at the end) ---
    firstScanIdx    = conf.trial.nrScansPre + 1;
    lastScanIdx     = firstScanIdx + conf.trial.nr * conf.trial.duration - 1;
    nrOfScans       = lastScanIdx - firstScanIdx + 1;
    
%     if lastScanIdx > length(R)
%         fprintf('    problemsssss\n');
%         keyboard
%         fprintf('    skipping for now!\n');
%         return
%     end
    
    CurData         = R(firstScanIdx:lastScanIdx, conf.regressor.plot.index);
    
    % --- Plot data ---
    h = figure; hold on
    set(h, 'position', [10,10,conf.regressor.plot.width,conf.regressor.plot.height]);
    xlim([1 nrOfScans])
    ylim([(min(CurData) - 0.5*nanstd(CurData)) (max(CurData) + 0.5*nanstd(CurData))])
    
    % Plot conditions coco task
    if strcmp(conf.regressor.plot.cond,'yes')

        onsets  = [1:conf.trial.duration*2:nrOfScans];
        offsets = onsets + conf.trial.duration - 1;
        nOns    = length(onsets);

        Y   =   get(gca,'ylim');
        Yf  =   1;            % Factor for making bigger/smaller
        for d = 1:nOns
            CurStart = onsets(d);
            CurEnd   = offsets(d);
            P   =   patch([CurStart CurEnd CurEnd CurStart],[min(Y)*Yf min(Y)*Yf max(Y)*Yf max(Y)*Yf],'k');
            set(P,'EdgeColor','none','FaceAlpha',0.3)
        end
    end
    
    % Plot actual data
    plot([1:nrOfScans], CurData)
    
    % Make pretty
    title([CurSub '-' CurSes ': heart rate'])
    xlabel('Time (volumes)')
    ylabel('Heart rate (BPM)');
    
    % Store plot
    savenm  = replace(conf.file.regrplot, {'Sub', 'Ses'}, {CurSub, CurSes});
    saveas(h,fullfile(conf.dir.regrplot, savenm));
    close(h)
    fprintf('  plot saved as %s\n', savenm);

end