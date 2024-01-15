function heartrate_average(conf)
%heartrate_average.m creates an average heart rate regressor over all 
% datasets (the ones from conf.average.exclude are not included)
% Inputs:
%   conf    : structure with settings
% Will store the output regressor as a matlab file and plot as .jpg

    warning('off', 'Findfile:empty');

    if length(conf.sub.name) == 1
        warning('only one subject, average will be weird :)\n')
    end
    
    firstScanIdx    = conf.trial.nrScansPre + 1;
    lastScanIdx     = firstScanIdx + conf.trial.nr * conf.trial.duration - 1;
    nrOfScans       = lastScanIdx - firstScanIdx + 1;
    allregressors = NaN(length(conf.sub.ses), length(conf.sub.name), nrOfScans);

    % ------------------------------------------ %
    % --- Store all regressors in one matrix --- %
    % ------------------------------------------ %
    fprintf('looking for individual regressors...\n');
    
    nExcluded = 0;
    nIncluded = 0;
    nNotFound = 0;
    
    % --- Get and store all the individual regressors ---
    for sub = 1:length(conf.sub.name)
        CurSub  = conf.sub.name{sub};

        for ses = 1:length(conf.sub.ses)
            CurSes = conf.sub.ses{ses};

            if any(contains(conf.average.exclude, [CurSub '-' CurSes]))
                fprintf('  %s-%s: not including because of bad data quality\n', CurSub, CurSes);
                nExcluded = nExcluded + 1;
                continue
            end
            
            % --- Load file ---
            RegrFName = replace(conf.file.regressor, {'Sub', 'Ses'}, {CurSub, CurSes});
            RegrFile  = pf_findfile(conf.dir.regressor, RegrFName);
            
            if isempty(RegrFile)
                fprintf('  %s-%s: no regressor found\n', CurSub, CurSes);
                nNotFound = nNotFound + 1;
                continue
            end

            dat = load(fullfile(conf.dir.regressor, RegrFile));
            nIncluded = nIncluded + 1;
            
            
            % --- Check for weird situation ---
            if length(dat.R) < nrOfScans
                warning('%s-%s has too few scans...', CurSub, CurSes);
                continue
            end

            
            % --- Extract and store data ---
            CurDat = dat.R(firstScanIdx:lastScanIdx,conf.average.index);
            allregressors(ses, sub, :) = CurDat;

        end

    end

    fprintf('collected all regressors\n');
    nDataSets = nExcluded + nNotFound + nIncluded; 
    fprintf('  %i/%i (%.2f%%) not included because of bad data quality\n', nExcluded, nDataSets, nExcluded/nDataSets*100);
    fprintf('  %i/%i (%.2f%%) not included because no regressor found\n', nNotFound, nDataSets, nNotFound/nDataSets*100);
    fprintf('  %i/%i (%.2f%%) included\n', nIncluded, nDataSets, nIncluded/nDataSets*100);
    
    
    % ---------------------- %
    % --- Create average --- %
    % ---------------------- %
    
    % --- Create averages ---
    for zsco = 1:length(conf.average.todo.zscores)
        CurZ = conf.average.todo.zscores{zsco};

        fprintf('%s: creating average\n', CurZ);
        
        
        % --- Average over sessions ---
        regressors  = NaN(length(conf.sub.name), nrOfScans);
        for sub = 1:length(conf.sub.name)
            SubDat  = NaN(length(conf.sub.ses), nrOfScans);
            
            for ses = 1:length(conf.sub.ses)
                % Get data
                CurDat = squeeze(allregressors(ses,sub,:));

                % Transform data if necessary)
                if strcmp(CurZ, 'zscored')
                    CurDat(~isnan(CurDat)) = zscore(CurDat(~isnan(CurDat)));
                end
                
                % Store data
                SubDat(ses, :) = CurDat;
            end

            % Average over sessions and store data
            regressors(sub,:) = nanmean(SubDat);
        end

        
        % --- Average over subjects ---
        AvgDat      = nanmean(regressors);
        StdDat      =  nanstd(regressors);
        nDataSets   = sum(~all(isnan(regressors(:,:)),2)); % nr of subs that have at least 1 good dataset
        SemDat      = StdDat/sqrt(nDataSets);

        
        % --- Store average ---
        savenm      = strrep(conf.file.average, 'Transform', CurZ);
        savenm      = [savenm '.mat'];
        save(fullfile(conf.dir.average, savenm), 'AvgDat');
        fprintf('  average regressor saved to %s\n', savenm);

        
        % --- Plot data ---
        h = figure; hold on
        set(h, 'position', [10,10,conf.average.plot.width,conf.average.plot.height]);
        xlim([1 nrOfScans])
        ylim([(min(AvgDat-SemDat) - 0.5*std(AvgDat)) (max(AvgDat+SemDat) + 0.5*std(AvgDat))])

        % Plot conditions
        if strcmp(conf.average.plot.cond,'yes')

            onsets  = [1:conf.trial.duration*2:nrOfScans];
%             onsets  = onsets(conf.trial.indicesTrial);
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

        % Create error patch
        time        =   1:1:length(AvgDat);
        x           =   [time fliplr(time)];
        y           =   [AvgDat+SemDat fliplr(AvgDat-SemDat)];

        % Plot actual data
        hpatch = patch(x,y,'b');
        plot(AvgDat,'color','b','linewidth',2);
        set(hpatch,'EdgeColor','b','FaceColor',[0.85    0.85    0.85]);

        % Make pretty
        zscorestring = '';
        if strcmp(CurZ, 'zscored')
            zscorestring = ' (zscored)';
        end

        title(['Heart rate'])
        xlabel('Time (scans)')
        ylabel(['Heart rate (BPM)' zscorestring]);

        % Store plot
        savenm  = strrep(conf.file.average, 'Transform', CurZ);
        savenm  = [savenm '.jpg'];
        saveas(h,fullfile(conf.dir.averageplot, savenm));
        close(h)
        fprintf('  plot saved as %s\n', savenm);

        
        

    
        
        fprintf('%s: average created\n', CurZ);

    end

    if length(conf.sub.name) == 1
        warning('only one subject, average will be weird :)\n')
    end
    
end