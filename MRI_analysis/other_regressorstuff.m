function other_regressorstuff(conf, data, CurSub, CurSes)    
%other_regressorstuff.m some extra stuff related to regressors. Gets called
%by coco_fla_combiregr.m
%   plotmotion  : plots 6 basic motion parameters
%   plotall     : plots all (non-AROMA) nuisance regressors
%   corr        : calculate correlation between each motion parameter and
%   tremor regressor
% Inputs: 
%   conf        : structure with settings
%   data        : structure with data
%   CurSub, CurSes  : current sub-ses
% Saves output to matlab files and .jpg figures

    warning('off', 'MATLAB:structOnObject');
    
    outdirname      = replace(conf.dir.spm.sub, {'Sub', 'Ses'}, {CurSub, CurSes});

    % --- plot motion parameters ---
    if conf.fla.regr.plotmotion.todo
        
        confoundData    = data.confoundData;
        regressorNames  = data.regressorNames;
        
        fprintf('plotting motion parameters\n')
        
        % gather data
        idxTrans    = find(contains(regressorNames, 'trans_') & ~contains(regressorNames, 'power2') & ~contains(regressorNames, 'derivative'));
        idxRot      = find(contains(regressorNames, 'rot_') & ~contains(regressorNames, 'power2') & ~contains(regressorNames, 'derivative'));
        idx = [idxTrans; idxRot];
        motion = array2table(confoundData(:, idx));

        % create plot
        f = figure;
        f.Position = [100 100 1000 500];
        vars = {{motion.Properties.VariableNames{1:3}},{motion.Properties.VariableNames{4:6}}};
        h = stackedplot(motion, vars);
        
        % make plot pretty
        xlabel('Time (volumes)');
        legs = getfield(struct(h),'LegendHandle');
        set(h.AxesProperties(1), 'LegendVisible', 'on');legs(1).Orientation = 'Horizontal';set(h.AxesProperties(1), 'LegendLocation', 'SouthEast'); 
        set(h.AxesProperties(2), 'LegendVisible', 'on');legs(2).Orientation = 'Horizontal';set(h.AxesProperties(2), 'LegendLocation', 'SouthEast'); 
        legs(1).String = {'x' 'y' 'z'};
        legs(2).String = {'x' 'y' 'z'};
        h.DisplayLabels = {'Translation', 'Rotation'};
        ax = findobj(h.NodeChildren, 'Type','Axes');
        set([ax.YLabel],'Rotation',90,'HorizontalAlignment', 'Center', 'VerticalAlignment', 'Bottom')
        title([CurSub '-' CurSes ': motion parameters'])

        % Save plot
        plotfilename    = replace(conf.fla.regr.plotmotion.filename, {'Sub', 'Ses'}, {CurSub, CurSes});
        savename        = fullfile(outdirname, plotfilename);
        saveas(f, savename);
        close(f);
        fprintf('  plot saved to "%s"\n', savename);
        
    end

    % --- plot all (non-aroma) nuisance regressors ---
    if conf.fla.regr.plotall.todo
        
        names   = data.names;
        R       = data.R;
        
        fprintf('plotting all nuisance regressors\n')

        % make plot
        varstoplot = find(~contains(names,'aroma'));
        f = figure;
        f.Position = [100 100 1000 1000];
        title([CurSub '-' CurSes ': nuisance regressors'])

        for p = 1:length(varstoplot)
            
            % plot data
            subplot(round(length(varstoplot))/2, 2, p);
            plot(R(:,varstoplot(p)));
            
            % make plot pretty 
            title(strrep(names{varstoplot(p)}, '_', '-'));
            set(gca,'xtick',[]);set(gca,'xticklabel',[]);
            set(gca,'ytick',[]);set(gca,'yticklabel',[]);
            ax = gca;
            ax.FontSize = 6;
        end

        % Save plot
        plotfilename    = replace(conf.fla.regr.plotall.filename, {'Sub', 'Ses'}, {CurSub, CurSes});
        savename        = fullfile(outdirname, plotfilename);
        saveas(f, savename);
        close(f);
        fprintf('  plot saved to "%s"\n', savename);

    end

    % --- calculate correlation between motion parameters and tremor ---
    if conf.fla.regr.corr.todo
        
        fprintf('calculating correlations\n')
        
        % doesn't work for 018 
        if strcmp(CurSub, '018') && strcmp(CurSes, '01')
            fprintf('  cannot calculate correlations for this sub\n');
        else
            confoundData= data.confoundData;
            motionIdx   = data.idx.motion;

            startIdx    = conf.trial.dummies + conf.trial.startDelay + 1;
            endIdx      = startIdx + conf.trial.duration * conf.trial.nr - 1;

            % collect tremor data
            emgfilename = replace(conf.file.spm.model.conditions, {'Sub', 'Ses'}, {CurSub, CurSes});
            emg = load(fullfile(outdirname, emgfilename));
            tremdata(emg.onsets{1} + 1 - conf.trial.startInclude) = emg.pmod(1).param{1};
            tremdata(emg.onsets{2} + 1 - conf.trial.startInclude) = emg.pmod(2).param{1};

            % calculate correlations
            correls = corr([tremdata' confoundData(startIdx:endIdx, motionIdx)]);
            correl = correls(1,2:end);

            % save correlations        
            filename    = replace(conf.fla.regr.corr.filename, {'Sub', 'Ses'}, {CurSub, CurSes});
            savename    = fullfile(outdirname, filename);
            save(savename, 'correl');
            fprintf('  correlations saved to "%s"\n', savename);

                                  
        end
        
        
    end
       
    
end