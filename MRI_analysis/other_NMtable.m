% create table fro neuromelanin

% Load Table full 
table_folder= 'P:\3024005.02\Analysis\Participant Characteristics\output';
addpath 'P:\3024005.02\Analysis\MRI\neuromelanine\scripts';
cd(table_folder)

%% Open Table full 
Tablefull =readtable('TableFull.xls');

%% Rows and columns to keep. 
NMTable=Tablefull(:, [1,2,3,4,7,13, 15,17,18]);
% Removing subjects 1, 10,13, 17, 19, 21,24, 26,46
%NMTable2=Tablefull([2,3,4,5,8,9,11,12,14,15,16,17,18,20,22,23,25,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,47,48,50,51,52,54,55,56,57,58,59,60,61,62,63,64], [1,2,3,7,13, 15,17,18]);

%% Different settings 
%NMtable2=spreadsheetDatastore('TableFull.xls');
%NMtable2.SelectedVariableNames={'SubNr', 'Tremor_dominant', 'Disease_duration', 'MMSE_score', 'UPDRS_total', 'UPDRS_total_tremor', 'Hoehn_and_Yahr'};
% preview(NMtable2)

%% 
% Load the stress and anxiety scores 
stress_folder='P:\3024005.02\Analysis\Participant Characteristics\scripts Giselle';
cd(stress_folder);

%% the pass socres
passcores=readtable('Stress_survey_responses_4Giselle.xlsx','Sheet', 'PAS', 'Range', 'A1:O53');
pas_scores=(passcores(:,[1,15]));

%% The PSS scores 
pssscores=readtable('Stress_survey_responses_4Giselle.xlsx','Sheet', 'PSS', 'Range', 'A1:P53');
pss_scores=pssscores(:,[1,16]);

%% Full table
AStable=join(pss_scores, pas_scores);
NMTableFull=outerjoin(AStable, NMTable);
%NMTable3=outerjoin

%% xlswrite 
%filename='NMTablefull.xls'
writetable(NMTableFull, 'NMTablefull2.xls');