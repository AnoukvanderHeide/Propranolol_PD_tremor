function eyelink_average(conf)
%eyelink_average.m creates an average regressor over all individual
%datasets. 
% First averages over sessions (if there are multiple useable datasets for
% a single subject) and then over subjects. 
% Inputs: 
%   conf    : structure with settings
% Stores output regressor as matlab file and (optionally) plots it to a
% .jpg file

    CurTrans = [conf.average.transform '-' conf.average.zscore];

    average     = nan(length(conf.sub.name), conf.trial.nTrials * conf.trial.trialDurSec);
    
    % --- load all data ---
    for sub = 1:length(conf.sub.name)
        CurSub = conf.sub.name{sub};

        submat = nan(length(conf.sub.ses), conf.trial.nTrials * conf.trial.trialDurSec);

        for ses = 1:length(conf.sub.ses)
            CurSes = conf.sub.ses{ses};

            % --- Load file --- 
            
            Fname = replace(conf.file.regressor, {'Sub', 'Ses', 'Transform'}, {CurSub, CurSes, CurTrans});
            File  = pf_findfile(conf.dir.regressor, Fname);

            if isempty(File)
                continue
            end
            
            
            % --- Check data quality and skip if it's bad ---
            dqFilename  = replace(conf.file.spikecheck, {'Sub', 'Ses'}, {CurSub, CurSes});
            dqFile      = pf_findfile(conf.dir.spikecheck,dqFilename);
            subdq       = load(fullfile(conf.dir.spikecheck, dqFile));
            
            % if more than a certain threshold of data has drops + spikes,
            % don't include the data
            pDrops = subdq.dq.data.pDrops;
            if (pDrops > conf.average.threshold.incl)
                continue;
            end
            
            
            % --- Load data ---
            load(fullfile(conf.dir.regressor, Fname(2:end-1)));
            CurDat = R(:,1);

            
            % --- Store Data ---
            submat(ses,:) =   CurDat;
            
        end

        average(sub,:) = mean(submat, 'omitnan');
        
    end


    % --- Save average ---
    fName = replace(conf.file.average, {'Transform'}, {CurTrans});
    save(fullfile(conf.dir.average,fName),'average');
    fprintf('    average regressor saved to %s\n',fName);
    

    % --- Plot average ---
    if conf.todo.plotaverage
       
        fprintf('    plotting average\n');
        
        AvgDat      =   nanmean(average);
        StdDat      =   nanstd(average);
        %SemDat      =   StdDat/sqrt(nSub);
        SemDat      =   StdDat/sqrt(sum(~isnan(average(:,1))));

        sel         =   isnan(AvgDat);
%         sel(1:10)   =   1;              %remove the first 10 datapoints
%         sel(611:end)=   1;
        AvgDat      =   AvgDat(~sel);
        StdDat      =   StdDat(~sel);
        SemDat      =   SemDat(~sel);

        % -- Create error patch --- %
        time        =   1:1:length(AvgDat);
        x           =   [time fliplr(time)];
        y           =   [AvgDat+SemDat fliplr(AvgDat-SemDat)];

        % --- plot the average figure --- %
        figure;
        set(gcf, 'position', [10,10,conf.average.plot.width,conf.average.plot.height]);
        ylim([min(y)-mean(StdDat)*0.1 max(y)+mean(StdDat)*0.1])
        hold on

        if conf.average.plot.plotconditions
            nOns      = length(conf.average.plot.onsets);
            Y   =   get(gca,'ylim');
            Yf  =   1;            % Factor for making bigger/smaller
            for a = 1:nOns
                CurStart = conf.average.plot.onsets(a);
                CurEnd   = conf.average.plot.offsets(a);
                P   =   patch([CurStart CurEnd CurEnd CurStart],[min(Y)*Yf min(Y)*Yf max(Y)*Yf max(Y)*Yf],'k');
                set(P,'EdgeColor','none','FaceAlpha',0.3)
            end
        end
        hpatch = patch(x,y,'b');
        plot(AvgDat,'color','b','linewidth',2);
        set(hpatch,'EdgeColor','b','FaceColor',[0.85    0.85    0.85]);

        %set(gca, 'XTick', [0:60:600]);
        %set(gca, 'xticklabel', [0:10]);

        zscorestring = '';
        if strcmp(conf.average.zscore, 'zscored')
            zscorestring = ' - zscored';
        end
        ylabel(['Pupil diameter (arbitrary unit' zscorestring ')']);
        xlabel('Time (scans)')
        title('Average pupil diameter')

        
        savename = replace(conf.file.avgplot, {'Transform'}, {CurTrans});
%         savename = ['average_' conf.average.transform '_' conf.average.zscore '.png'];
        filename = fullfile(conf.dir.avgplots, savename);
        saveas(gcf,filename)    
        close(gcf)
        fprintf('    plot saved to %s\n',savename);

   end

end