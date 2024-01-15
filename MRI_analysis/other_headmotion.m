clear all
warning('off', 'Findfile:empty');

%==========================================================================
% --- Settings --- %
%==========================================================================

pf = fullfile('/project', '3024005.02');
cd(fullfile(pf, 'Analysis','MRI','scripts'))

addpath('/home/common/matlab/spm12')
addpath('/home/common/matlab/fieldtrip')
addpath('/home/common/matlab/fieldtrip/qsub')
addpath(fullfile(pf, 'Analysis', 'SupportingScripts'))
addpath(fullfile(pf, 'Analysis', 'MRI', 'scripts'))
helperscripts = fullfile(pf, 'Analysis', 'SupportingScripts', 'helpers');
addpath(helperscripts);
% ft_defaults


% Get settings
conf = coco_conf();


Table = table();

for sub = 1:length(conf.sub.name)
    CurSub = conf.sub.name{sub};
    
    for ses = 1:length(conf.sub.ses)
        CurSes = conf.sub.ses{ses};
        
        idx = (sub-1)*2 + ses;
   
        dirname  = replace(conf.dir.fmriprep.func, {'Sub', 'Ses'}, {CurSub, CurSes});
        filename = replace(conf.file.regr.nuis.confounds, {'Sub', 'Ses'}, {CurSub, CurSes});
        file = pf_findfile(dirname, filename);
        
        if iscell(file)
            file = file{end};
        end
        
        % Load confound data
        confoundData2   = tdfread(fullfile(dirname, file));
        regressorNames  = fieldnames(confoundData2);
        format          = [repmat('%f',1,length(regressorNames))];
        fid             = fopen(fullfile(dirname, file));
        confoundData    = textscan(fid, format, 'HeaderLines', 1, 'TreatAsEmpty', 'n/a');
        fclose(fid);
        confoundData = [confoundData{:}];   % convert to matrix
        
        % Remove annoying ones
        nrMotionOutliers = sum(contains(regressorNames, 'motion_outlier'));
        
        idcs = ~contains(regressorNames, {'aroma', 'a_comp_cor', 't_comp_cor', 'cosine', 'motion_outlier'});
        newRegressorNames  = regressorNames(idcs);
        newConfoundData    = confoundData(:, idcs);
        
        Table.SubSes(idx)           = {[CurSub '-' CurSes]};
        Table.NrMotionOutliers(idx) = nrMotionOutliers;
        Table.FD_max(idx)           =     max(newConfoundData(:,strcmp(newRegressorNames, 'framewise_displacement')));
        Table.FD_mean(idx)          = nanmean(newConfoundData(:,strcmp(newRegressorNames, 'framewise_displacement')));
        Table.dvars_max(idx)        =     max(newConfoundData(:,strcmp(newRegressorNames, 'dvars')));
        Table.dvars_mean(idx)       = nanmean(newConfoundData(:,strcmp(newRegressorNames, 'dvars')));
        Table.stddvars_max(idx)     =     max(newConfoundData(:,strcmp(newRegressorNames, 'std_dvars')));
        Table.stddvars_mean(idx)    = nanmean(newConfoundData(:,strcmp(newRegressorNames, 'std_dvars')));
        
        
    
    end
        
end



Table


%%


Table.FD_max_z          = zscore(Table.FD_max);
Table.FD_mean_z         = zscore(Table.FD_mean);
Table.dvars_max_z       = zscore(Table.dvars_max);
Table.dvars_mean_z      = zscore(Table.dvars_mean);
Table.stddvars_max_z    = zscore(Table.stddvars_max);
Table.stddvars_mean_z   = zscore(Table.stddvars_mean);

%%

figure; hold on

plot(Table.FD_max_z)
plot(Table.FD_mean_z)
plot(Table.dvars_max_z)
plot(Table.dvars_mean_z)
plot(Table.stddvars_max_z)
plot(Table.stddvars_mean_z)

xticks(1:38)

xticklabels(Table.SubSes)
xtickangle(90)




liness = {'002', '003', '008', '011', '015', '016', '018', '022', '029'};
for i = 1:length(liness)
    x = find(strcmp(conf.sub.name, liness{i}));
    xline(x*2);
    xline(x*2-1);
end


legend({'max(FD)', 'mean(FD)', 'max(dvars)', 'mean(dvars)', 'max(std_dvars)', 'min(std_dvars)'});


figure; 
subplot(3,2,1); 
plot(Table.FD_max); title('max(FD)')

subplot(3,2,2);
plot(Table.FD_mean); title('mean(FD)')

subplot(3,2,3);
plot(Table.dvars_max); title('max(dvars)')

subplot(3,2,4);
plot(Table.dvars_mean); title('mean(dvars)')

subplot(3,2,5);
plot(Table.stddvars_max); title('max(std_dvars)')

subplot(3,2,6);
plot(Table.stddvars_mean); title('mean(std_dvars)')













