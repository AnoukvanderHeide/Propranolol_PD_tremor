
clear all
warning('off', 'Findfile:empty');

%==========================================================================
% --- Settings --- %
%==========================================================================

% --- Directories ---
conf.dir.project        = fullfile('/project', '3024005.02');
conf.dir.input          = fullfile(conf.dir.project, 'Analysis', 'Participant Characteristics', 'output');

% --- Useful scripts ---
addpath(fullfile(conf.dir.project, 'Analysis', 'SupportingScripts', 'helpers'));

% --- File names ---
conf.file.input            = 'Logfile scores.mat';


% --- Subjects ---
conf.sub.name = { '002'; '003'; '004'; '005'; '006'; ... % 001 excluded due to covid, 007 based on low HR
                  '008'; '009'; '011'; '012'; '014'; ... % 010 no 2nd MRI (pain), 013 based on ECG
                  '015'; '016'; '018'; '020'; '022'; ... % 017 excluded (outlier and anxiety in scanner), 019 no 2nd MRI (pain/panic), 021 based on ECG
                  '023'; '025'; '028'; '029'; '030'; ... % 024 and 026 excluded based on ECG, 027 bad ACC 
                  '063'; '064'; '065';...                % 061 excluded based on ECG, 062 did not take place
                 };  
               
               
%==========================================================================
% --- Analysis --- %
%==========================================================================

% Load button box data
load(fullfile(conf.dir.input, conf.file.input));

% Get propranolol ses info
addpath('/project/3024005.02/Analysis/MRI/scripts')
druginfo      = other_getdrug(conf);
conf.sub.drug = [druginfo{:}]; % reshape data to make it easier with indexing

% Remove subjects 
allScores = allScores(contains(allScores.subnr, conf.sub.name), :);

% Divide data into prop vs. plac
propIdcs = allScores.sesnr == reshape(repelem(conf.sub.drug, 2,1), 1, [])';
allScores_prop = allScores(propIdcs, :);
allScores_plac = allScores(~propIdcs, :);


% Run paired t-tests
vars = {'StressCoco', 'StressRest', 'DifficultyCoco', 'DifficultyRest'};

for var = 1:length(vars)
    curVar = vars{var};
    placScores = allScores_plac.(curVar);
    propScores = allScores_prop.(curVar);
    [H,P,CI,STATS] = ttest(placScores, propScores) ;
    
    % Calculate Cohen's d
    mean_diff = nanmean(placScores - propScores);
    n1 = length(placScores);
    n2 = length(propScores);
    pooled_std = sqrt(((n1 - 1) * std(placScores)^2 + (n2 - 1) * std(propScores)^2) / (n1 + n2 - 2));
    cohen_d = mean_diff / pooled_std;
    
    fprintf('%s:\n', curVar)
    fprintf('    plac: %s \t prop: %s\n', num2str(nanmean(placScores)), num2str(nanmean(propScores)));
    fprintf('    t(%s) = %s, P = %s\n', num2str(STATS.df), num2str(STATS.tstat), num2str(P));
    fprintf('    Cohens d: %s', num2str(cohen_d));
    fprintf('\n');
    
%     figure
%     sct = scatter(repelem([(var*2-1) var*2 ], length(conf.sub.name)), [allScores_plac.(curVar); allScores_prop.(curVar)]);
%     sct.MarkerFaceColor = 'k';
%     sct.MarkerFaceAlpha = 0.1;
%     sct.MarkerEdgeColor = 'none';
%     
%     
%     figure
%     hist(allScores_plac.(curVar)); hold on; hist(allScores_prop.(curVar))
end


% Perform the repeated measures ANOVA


% Run the ANOVA and get the results
ranovaResults = ranova(rm);

% Display the results
disp(ranovaResults);







