clear all 

set(0,'DefaultFigureWindowStyle','normal')
conf = Settings();

% Directories and file names
conf.file.input         = 'Coco_AllData.mat';

% Trial settings coco
conf.trial.nr           = 10;       % nr of trials
conf.trial.duration     = 60;       % duration of one trial (in scans)
conf.trial.total        = conf.trial.nr * conf.trial.duration;
conf.trial.onsets.coco  = [1 : conf.trial.duration*2 : conf.trial.total];
conf.trial.offsets.coco = conf.trial.onsets.coco + conf.trial.duration - 1;
conf.trial.onsets.rest  = conf.trial.offsets.coco + 1;
conf.trial.offsets.rest = conf.trial.onsets.rest + conf.trial.duration - 1;
conf.trial.conditions   = {'coco', 'rest'};

conf.regr.datatypes     = {'tremor';'pupil'; 'HR';}; % 

% Load data
load(fullfile(conf.dir.files, conf.file.input));

% --- Average over subjects ---
for dt = 1:length(conf.regr.datatypes)
    datatype = conf.regr.datatypes{dt};
    
    sub_prop    = nan(length(conf.sub.name), conf.trial.total);
    sub_plac    = nan(length(conf.sub.name), conf.trial.total); 
    usable      = nan(length(conf.sub.name), 1);
    usablenr    = nan(length(conf.sub.name), 1);
    
    % Get data per subject
    for sub = 1:length(conf.sub.name)

        if conf.sub.drug{sub,2} == 1
           data(sub).ses(1).sesname = ['plac'];         % eerste sessie placebo
           data(sub).ses(2).sesname = ['prop'];         % tweede sessie propranolol
           sub_prop(sub,:) = data(sub).ses(2).(datatype).data;
           sub_plac(sub,:) = data(sub).ses(1).(datatype).data;
        elseif conf.sub.drug{sub,2} == 2
           data(sub).ses(1).sesname = ['prop'];         % eerste sessie propranolol
           data(sub).ses(2).sesname = ['plac'];         % tweede sessie placebo
           sub_prop(sub,:) = data(sub).ses(1).(datatype).data;
           sub_plac(sub,:) = data(sub).ses(2).(datatype).data;
        else 
            fprintf('drug order undefined');
        end
       
        % Store info on data quality
        usablenr(sub) = sum([data(sub).ses(1).(datatype).usable data(sub).ses(2).(datatype).usable]);        
        
    end
    
    % Store data
    subdata_prop.(datatype)      = sub_prop;          % store matrix propranolol data per subject
    subdata_plac.(datatype)      = sub_plac;          % store matrix with placebo data per subject
    averages_prop.(datatype)     = nanmean(sub_prop);  % store average over all subj. for propranolol
    averages_plac.(datatype)     = nanmean(sub_plac);  % store average over all subj. for placebo
    stds_prop.(datatype)         = nanstd(sub_prop);  % store stds over all subj. for propranolol
    stds_plac.(datatype)         = nanstd(sub_plac);  % store stds over all subj. for placebo
    %nrdatasets = sum(usablenr == 1 | usablenr == 2);
    %sems.(datatype)         = stds.(datatype)/sqrt(nrdatasets); % dit moet nog aangepast!
    
    dataquality.(datatype)  = usablenr; 
    
    fprintf('%s:\t0: %s\t1: %s\t2: %s\tn = %s\n', datatype, num2str(sum(dataquality.(datatype) == 0)), ...
        num2str(sum(dataquality.(datatype) == 1)), num2str(sum(dataquality.(datatype) == 2)), ...
        num2str(sum(dataquality.(datatype) == 1 | dataquality.(datatype) == 2)));

end

% get indices for coco and rest blocks
idxs.coco = [];
idxs.rest = [];
for cond = 1:length(conf.trial.conditions)
    CurCond = conf.trial.conditions{cond};
    for ons = 1:length(conf.trial.onsets.(CurCond))
        startIdx = conf.trial.onsets.(CurCond)(ons) + 3;
        endIdx   = conf.trial.offsets.(CurCond)(ons) - 3;
        idxs.(CurCond) = [idxs.(CurCond) startIdx:endIdx];
    end
end

% --- Create plot for drug * context interaction--- %

% Get colors
colors = conf.plot.color.colors;        %ft_colormap(conf.plot.colormap, 500);
conf.plot.color.conditions  = [500 170 500 170]; %[coco rest] 80 = paars, 180 = blauw, 500 = geel
fprintf('drug interaction with coco vs. rest:\n');

h = figure;
set(h, 'position', [5, 5, 1300, 400]);
set(gca,'fontname','calibri');

savefile = ['Barchart_coco_all_newcolors_transp.svg'];
datatosave = [];

for dt = 1:length(conf.regr.datatypes)
    datatype = conf.regr.datatypes{dt};
    
    
    plot = subplot(1,3,dt); hold on
    
    % Do rm ANOVA for all datatypes input_anova_tremor = readmatrix('anova_input_tremor.xlsx'); %rm_anova2(Y,S,F1,F2,FACTNAMES)
    input.(datatype) = readmatrix(['anova_input_',datatype,'.xlsx']);
    anova.(datatype) = rm_anova2(input.(datatype)(:,4),input.(datatype)(:,1),...
        input.(datatype)(:,2),input.(datatype)(:,3),{'drug', 'trialtype'});
    p_drug = anova.(datatype){2,6};
    p_trialtype = anova.(datatype){3,6};
    p_int = anova.(datatype){4,6};
    
    % Get data 
    datCoco_prop = subdata_prop.(datatype)(:, idxs.coco);
    datRest_prop = subdata_prop.(datatype)(:, idxs.rest);
    datCoco_plac = subdata_plac.(datatype)(:, idxs.coco);
    datRest_plac = subdata_plac.(datatype)(:, idxs.rest);    
    
    avgCoco_prop = nanmean(datCoco_prop,2);
    avgRest_prop = nanmean(datRest_prop,2);
    avgCoco_plac = nanmean(datCoco_plac,2);
    avgRest_plac = nanmean(datRest_plac,2);
    
    method = 2;
    
    if  method == 1 && dt == 1 % for tremor, use max. value instead of mean
        maxCoco_prop = max(datCoco_prop,[],2);
        maxRest_prop = max(datRest_prop,[],2);
        maxCoco_plac = max(datCoco_plac,[],2);
        maxRest_plac = max(datRest_plac,[],2);
        avgs_prop = [maxRest_prop maxCoco_prop];
        avgs_plac = [maxRest_plac maxCoco_plac];
        avgs      = [avgs_prop avgs_plac];
        means     = [nanmean(avgs_prop) nanmean(avgs_plac)];
        stderr    = nanstd(avgs);
        semerr    = stderr ./ sqrt(sum(~isnan(avgs)));
        err       = semerr;
    elseif method == 3 && dt == 1 % for tremor, calculate tremor variability
        varCoco_prop = (nanstd(datCoco_prop,[],2)/ nanmean(datCoco_prop,[],2))*100; % nog mee bezig!!
        varRest_prop = max(datRest_prop,[],2);
        varCoco_plac = max(datCoco_plac,[],2);
        varRest_plac = max(datRest_plac,[],2);
        avgs_prop = [varRest_prop varCoco_prop];
        avgs_plac = [varRest_plac varCoco_plac];
        avgs      = [avgs_prop avgs_plac];
        means     = [nanmean(avgs_prop) nanmean(avgs_plac)];
        stderr    = nanstd(avgs);
        semerr    = stderr ./ sqrt(sum(~isnan(avgs)));
        err       = semerr;
    else
        avgs_prop = [avgRest_prop avgCoco_prop];
        avgs_plac = [avgRest_plac avgCoco_plac];
        avgs      = [avgs_prop avgs_plac];
        means     = nanmean(avgs);   
        stderr    = nanstd(avgs);
        semerr    = stderr ./ sqrt(sum(~isnan(avgs)));
        err       = semerr;
    end

    change = ((avgCoco_plac+avgRest_plac)/2) - ((avgCoco_prop+avgRest_prop)/2); % calculate the change between placebo and propranolol per subject
    datatosave.(datatype) = [avgCoco_plac avgCoco_prop avgRest_plac avgRest_prop change];
    
    % Create bar plot
    nr_bars = [1 2 3 4]; % prop rest; prop coco; plac rest; plac coco
    barplot              = bar(nr_bars, means, 'grouped', 'facecolor', 'flat'); hold on
    %barplot.CData        = brighten(conf.plot.color.colors(conf.plot.color.conditions,:), 0.2);    
    barplot.CData        = [(241/255), (189/255), (66/255);...
                            (241/255), (189/255), (66/255);...
                            (64/255), (176/255), (166/255);...
                            (64/255), (176/255), (166/255)];
    %barplot.CData(1,:)   = brighten([0.85 0.11 0.38], 0.2);
    %barplot.CData(3,:)   = brighten([0.85 0.11 0.38], 0.2);
    barplot.EdgeAlpha    = 0;
    barplot.FaceAlpha    = 0.5;

    % Add eror bars
    er              = errorbar(nr_bars, means, -err, err);
    er.Color        = [0 0 0];
    er.LineWidth    = 1;
    er.LineStyle    = 'none';
    
    % Add scatter data
    scatterdata = repelem(nr_bars, length(avgRest_prop), 1);
    randscatter = 0.1 * rand(size(avgCoco_prop));
    scatterdata = scatterdata + randscatter;

    xdata       = reshape(scatterdata, [], 1);
    ydata       = reshape(avgs, [], 1);

    scatterplot = scatter(xdata, ydata, 15, 'k', 'filled');
    scatterplot.MarkerFaceAlpha = 0.7;
      
    % Add siglines (if applicable)
%     if p_drug < 0.05
%         if p_drug < 0.001
%             sigstring = '***';
%         elseif p_drug < 0.01
%             sigstring = '**';
%         elseif p_drug < 0.05
%             sigstring = '*';
%         end
%         sigline([1.5,3.5], 12, sigstring, 1); 
%         %sigline([1,4], conf.plot.bar.sigline.heights(dt), sigstring, 1); 
%         %conf.plot.bar.sigline.heights       = [11.8, 7500 86];
%     end
%     
%     if p_trialtype < 0.05
%         if p_trialtype < 0.001
%             sigstring = '***';
%         elseif p_trialtype < 0.01
%             sigstring = '**';
%         elseif p_trialtype < 0.05
%             sigstring = '*';
%         end
%         sigline([1,2], 11, sigstring, 0.5);
%         sigline([3,4], 11, sigstring, 0.5);
%         %sigline([1,4], conf.plot.bar.sigline.heights(dt), sigstring, 1); 
%         %conf.plot.bar.sigline.heights       = [11.8, 7500 86];
%     end
 
    % Set labels and axis limits per datatype
    yticks.tremor    = [4:1:12];
    yticks.pupil     = [2000:1000:7000];
    yticks.HR        = [50:5:85];
    ylim.tremor      = [4 13];
    ylim.pupil       = [2000 8000];
    ylim.HR          = [48 90];
    labels.tremor   = 'Tremor power (N=20)';
    labels.pupil    = 'Pupil diameter (N=13)';
    labels.HR       = 'Heart rate (N=14)';
    labels_y.tremor  = 'Tremor power [log_{10}(\muV^2)]';
    labels_y.pupil   = 'Pupil diameter [a.u.]';
    labels_y.HR      = 'Heart rate [bpm]';
    
    set(gca, 'xtick', 1:4);
    set(gca, 'xticklabel', {'Rest', 'Coco', 'Rest', 'Coco'});
    set(gca,'fontname','calibri');
    set(gca, 'FontSize', 12);
    set(gca, 'ytick', yticks.(datatype))
    set(gca, 'ylim', ylim.(datatype))
    t = title(labels.(datatype));
    ylabel(labels_y.(datatype));

end

% Save plot
savename = fullfile(conf.dir.figures, savefile);
saveas(h, savename);
fprintf('Plot saved to "%s"\n', savename);

Table = struct2table(datatosave);
filename = fullfile(conf.dir.files, 'Physiology_coco.xlsx');
writetable(Table,filename,'sheet',1,'Range','A1')

