%TableCreate.m Creates a table with participant characteristics

%==========================================================================
% --- Settings --- %
%==========================================================================

clear all

% --- Directory names ---
conf.dir.project = '/project/3024005.02/';
conf.dir.main    = fullfile(conf.dir.project, 'Analysis', 'Participant Characteristics');
conf.dir.output  = fullfile(conf.dir.main, 'output');
conf.dir.files   = fullfile(conf.dir.main, 'input');

% --- File names ---
conf.file.full           = 'FullData.csv';
conf.file.LEDD           = 'LEDD Calculations.xlsx';
conf.file.changesHY      = 'Changes Hoehn and Yahr scores.csv';
conf.file.changesMA      = 'Changes MA arm and leg.csv';
conf.file.changesUPDRS   = 'Changes UPDRS scores Anouk.csv';
conf.file.output.mat     = 'TableFull.mat';
conf.file.output.xls     = 'TableFull.xls';

%==========================================================================
% --- Create table  --- %
%==========================================================================

% --- Load full file ---
opts = detectImportOptions(fullfile(conf.dir.files, conf.file.full));
opts.RowNamesColumn = 1;
opts.CommentStyle = '#';
FullTable = readtable(fullfile(conf.dir.files, conf.file.full),opts);

% --- Get characteristics variables ---
variables = FullTable.Properties.VariableNames;
variablesTable = {'participant_tremor_dominant_Yes'; 'participant_year_of_birth'; 'participant_age'; 'participant_gender'; ...
    'participant_handedness'; 'participant_PD_onset_age'; 'participant_arm_most_affected'; 'participant_leg_most_affected'; ...
    'general_screening_presence_resting_tremor_1'; 'general_screening_absence_resting_tremor_1'; 'medical_PD_medication_1'; ...
    'MMSE_total_score_1'; 'MMSE_total_score_2'; };
indicesTable = ismember(variables, variablesTable);
Table = FullTable(:,indicesTable);

% --- Make column names nice but still useable --- 
Table.Properties.VariableNames = {
    'Tremor_dominant';
    'Year_of_birth';
    'Age';
    'Gender';
    'Handedness';
    'Age_at_onset';
    'Most_affected_arm';
    'Most_affected_leg';
    'Presence_resting_tremor';
    'Absence_resting_tremor';
    'Using_PD_medication';
    'MMSE_score_ses01';
    'MMSE_score_ses02';
    };

% --- Fix a few small things ---

% Fix '41' and move the row 
Table.Properties.RowNames{strcmp(Table.Properties.RowNames, '41')} = '041';
Table = sortrows(Table,'RowNames');

% Put the MMSE scores in one column and remove the other
Table.MMSE_score = mean([Table.MMSE_score_ses01 Table.MMSE_score_ses02], 2,'omitnan');
Table = removevars(Table,{'MMSE_score_ses01', 'MMSE_score_ses02'});

% Add disease duration column
Table.Disease_duration = Table.Age - Table.Age_at_onset;

% Import and add LEDDs
[~,~,leddDataFull]  = xlsread(fullfile(conf.dir.main, conf.file.LEDD));
leddfile.subnrs     = leddDataFull(2:end,strcmp(leddDataFull(1,:), 'Subj. nr.'));
leddfile.LEDDs      = leddDataFull(2:end,strcmp(leddDataFull(1,:), 'LEDD'));
leddfile.LEDDsnew   = leddDataFull(2:end,strcmp(leddDataFull(1,:), 'New LEDD'));

Table.LEDD = repelem(NaN,height(Table))';
for sub = 1:height(Table)
    curSub = Table.Properties.RowNames{sub};
    idx = strcmp(leddfile.subnrs, curSub);
    if ~any(idx)
        ledd = NaN;
    else
        ledd = nanmean( [leddfile.LEDDs{idx} leddfile.LEDDsnew{idx}]);
    end
    Table.LEDD(sub) = ledd;
end

% Invert Absence resting tremor and add it to presence resting tremor row
idxs = Table.Tremor_dominant == 0;
Table.Presence_resting_tremor(idxs) = abs(Table.Absence_resting_tremor(idxs)-1);
Table = removevars(Table,{'Absence_resting_tremor'});

% Reorder the columns a little bit
Table = movevars(Table, 'Gender', 'Before', 'Age');
Table = movevars(Table, 'Age_at_onset', 'Before', 'Handedness');
Table = movevars(Table, 'Disease_duration', 'Before', 'Handedness');

% --- Change the values that need to be changed ---

% MA arm/leg
fileMA = fullfile(conf.dir.files, conf.file.changesMA);
MAfile = fopen(fileMA);
newMA = textscan(MAfile, '%s%s%s', 'Delimiter', '\t', 'CommentStyle', '%');
fclose(MAfile);
 
for i = 1:numel(newMA{1})
    indx = strcmp(Table.Properties.RowNames,newMA{1}{i});
    if strcmp(newMA{3}(i), "Left")
        newValue = 1;
    else
        newValue = 2;
    end
    
    if strcmp(newMA{2}{i},"Arm")
        Table.Most_affected_arm(indx) = newValue;
    else
        Table.Most_affected_leg(indx) = newValue;
    end
end

% (saving them for later)
MA_arm = Table.Most_affected_arm;
MA_leg = Table.Most_affected_leg;


% --- Make the ints chars/strings ---
Table.Tremor_dominant           = ReplaceInts(Table.Tremor_dominant, {0, 1}, {'No', 'Yes'});
Table.Gender                    = ReplaceInts(Table.Gender, {1, 2}, {'Male', 'Female'});
Table.Handedness                = ReplaceInts(Table.Handedness, {1, 2, 3}, {'Left', 'Right', 'Equal'});
Table.Most_affected_arm         = ReplaceInts(Table.Most_affected_arm, {1, 2, 3}, {'Left', 'Right', 'Equal'});
Table.Most_affected_leg         = ReplaceInts(Table.Most_affected_leg, {1, 2, 3}, {'Left', 'Right', 'Equal'});
Table.Presence_resting_tremor   = ReplaceInts(Table.Presence_resting_tremor, {0, 1}, {'No', 'Yes'});
Table.Using_PD_medication       = ReplaceInts(Table.Using_PD_medication, {0, 1}, {'No', 'Yes'});

%==========================================================================
% --- UPDRS --- %
%==========================================================================

% --- Make separate table of the scores ---
UPDRS = FullTable(:,(contains(variables, 'UPDRS') | contains(variables, 'UDPRS')));

% --- Fix a few small things ---

% Fix '41' and move the row 
UPDRS.Properties.RowNames{strcmp(UPDRS.Properties.RowNames, '41')} = '041';
UPDRS = sortrows(UPDRS,'RowNames');

% Rename UPDRS_hoehn_3 to UPDRS_hoehn_2
names = Table.Properties.VariableNames;
indx = find(strcmp(UPDRS.Properties.VariableNames, 'UPDRS_hoehn_3'),1);
UPDRS.Properties.VariableNames{indx} = 'UPDRS_hoehn_2';

% --- Remove all codes for missing values ---
nVars = numel(UPDRS.Properties.VariableNames);
for col = 1:nVars
    UPDRS{:,col}(UPDRS{:,col} < 0) = NaN;
end

% --- Change the values that need to be changed in the UPDRS table ---

% - Hoehn and Yahr TD - 
fileHY = fullfile(conf.dir.files, conf.file.changesHY);
HYfile = fopen(fileHY);
newHY = textscan(HYfile, '%s%n', 'Delimiter', '\t', 'CommentStyle', '%');
fclose(HYfile);

for i = 1:numel(newHY{1})
    indx = strcmp(Table.Properties.RowNames,newHY{1}{i});
    UPDRS.UPDRS_hoehn_1(indx) = newHY{2}(i);
    UPDRS.UPDRS_hoehn_2(indx) = newHY{2}(i);
end

% - UPDRS NT - 
fileUPDRSNewNT = fullfile(conf.dir.files, conf.file.changesUPDRS);
opts = detectImportOptions(fileUPDRSNewNT);
opts.VariableTypes = [repelem({'char'}, length(opts.VariableTypes)-1) 'double'];
UPDRS2 = readtable(fileUPDRSNewNT,opts);
UPDRS2 = [UPDRS2(:,2:end) UPDRS2(:,1)];     % Put row with sub nr at the end

% Get the indices of columns and rows in the original table
indicesVars = [ 
    find(strcmp(UPDRS.Properties.VariableNames, 'UPDRS_speech_1'));     find(strcmp(UPDRS.Properties.VariableNames, 'UPDRS_face_1'));
    find(strcmp(UPDRS.Properties.VariableNames, 'UPDRS_fing_r_1'));     find(strcmp(UPDRS.Properties.VariableNames, 'UPDRS_fing_l_1'));
    find(strcmp(UPDRS.Properties.VariableNames, 'UPDRS_hand_mov_r_1')); find(strcmp(UPDRS.Properties.VariableNames, 'UPDRS_hand_mov_l_1'));
    find(strcmp(UPDRS.Properties.VariableNames, 'UPDRS_pron_sup_r_1')); find(strcmp(UPDRS.Properties.VariableNames, 'UPDRS_pron_sup_l_1'));
    find(strcmp(UPDRS.Properties.VariableNames, 'UPDRS_toe_r_1'));      find(strcmp(UPDRS.Properties.VariableNames, 'UPDRS_toe_l_1'));
    find(strcmp(UPDRS.Properties.VariableNames, 'UPDRS_leg_ag_r_1'));   find(strcmp(UPDRS.Properties.VariableNames, 'UPDRS_leg_ag_l_1'));
    find(strcmp(UPDRS.Properties.VariableNames, 'UPDRS_chair_1'));      find(strcmp(UPDRS.Properties.VariableNames, 'UPDRS_post_1'));
    find(strcmp(UPDRS.Properties.VariableNames, 'UPDRS_gait_1'));       find(strcmp(UPDRS.Properties.VariableNames, 'UPDRS_freeze_1'));
    find(strcmp(UPDRS.Properties.VariableNames, 'UPDRS_post_stab_1'));  find(strcmp(UPDRS.Properties.VariableNames, 'UPDRS_spont_1'));
    find(strcmp(UPDRS.Properties.VariableNames, 'UPDRS_dys_1'));];
indicesSubs = [find(strcmp(UPDRS.Properties.RowNames, '031')):find(strcmp(UPDRS.Properties.RowNames, '045'))];

% Remove all the comments from the new scores, and use the old value if we
% didn't give it a new value
[nRow, nCol] = size(UPDRS2);
for c = 1:nCol-2
    for r = 1:nRow
        score = UPDRS2{r,c};
        if length(score{1}) > 1     % if there's a comment, remove it
            score = extractBefore(score,'*');
        end
        if isempty(score{1})    % if the score is empty, use the old one
            newUPDRS(r,c) = UPDRS{indicesSubs(r),indicesVars(c)}; 
            %score = {'NaN'};
        else 
            newUPDRS(r,c) = str2num(score{1});  
        end
        
    end    
end
UPDRS(indicesSubs,indicesVars) = array2table(newUPDRS);

% - Hoehn and Yahr NT - 
UPDRS.UPDRS_hoehn_1(indicesSubs) = UPDRS2.H_Y;

% --- Add scores ---
Table.UPDRS_total       = nanmean([UPDRS.UPDRSIII_total_score_1 UPDRS.UPDRSIII_total_score_2],2);
Table.Hoehn_and_Yahr    = max([UPDRS.UPDRS_hoehn_1 UPDRS.UPDRS_hoehn_2], [],2); % grab the highest one of the two
% Table.Hoehn_and_Yahr    = nanmean([UPDRS.UPDRS_hoehn_1 UPDRS.UPDRS_hoehn_2], 2);       
Table.Dysk_present      = nanmean([UPDRS.UPDRS_dys_1 UPDRS.UPDRS_dys_2], 2);
Table.Dysk_interf       = nanmean([UPDRS.UDPRS_interf_1 UPDRS.UDPRS_interf_2], 2);

% --- Make the ints chars/strings ---
Table.Dysk_present      = ReplaceInts(Table.Dysk_present, {0, 0.5, 1}, {'No', 'Yes', 'Yes'}, 'No');
Table.Dysk_interf       = ReplaceInts(Table.Dysk_interf,  {0, 0.5, 1}, {'No', 'Yes', 'Yes'}, 'No');

% --- Get the UPDRS scores for bradikinesia+rigidity, axial, and tremors ---
Table = CalculateUPDRSscores(Table, UPDRS, MA_arm, MA_leg);

% --- Move the 'total' items to the beginning ---
Table = movevars(Table, 'UPDRS_total_tremor',     'After', 'UPDRS_total');
Table = movevars(Table, 'UPDRS_total_non_tremor', 'After', 'UPDRS_total');

% --- A small check to see if the numbers were entered correctly and if the total was calculated correctly ---
total_filledin1 = UPDRS.UPDRSIII_total_score_1;
total_filledin2 = UPDRS.UPDRSIII_total_score_2;
 
startindx1  = find(strcmp(UPDRS.Properties.VariableNames, 'UPDRS_speech_1'),1);
endindx1    = find(strcmp(UPDRS.Properties.VariableNames, 'UPDRS_const_1'),1);
startindx2  = find(strcmp(UPDRS.Properties.VariableNames, 'UPDRS_speech_2'),1);
endindx2    = find(strcmp(UPDRS.Properties.VariableNames, 'UPDRS_const_2'),1);
 
total_calc1  = nansum(UPDRS{:,startindx1:endindx1},2);
total_calc1(all(isnan(UPDRS{:,startindx1:endindx1}),2)) = "NaN";
total_calc2  = nansum(UPDRS{:,startindx2:endindx2},2);
total_calc2(all(isnan(UPDRS{:,startindx2:endindx2}),2)) = "NaN";
 
checkTable = table();
checkTable.total_filledin1 = total_filledin1;
checkTable.total_calc1 = total_calc1;
checkTable.equal1 = (total_filledin1==total_calc1) | (isnan(total_filledin1) & isnan(total_calc1));
 
checkTable.total_filledin2 = total_filledin2;
checkTable.total_calc2 = total_calc2;
checkTable.equal2 = (total_filledin2==total_calc2) | (isnan(total_filledin2) & isnan(total_calc2));

checkTable.Properties.RowNames = Table.Properties.RowNames;

checkTable;

% Set the total of those that are not the same to the sum of tremor +
% non-tremor (should only be the case for those where we changed the UPDRS
% scores (31-45), the rest should be the same)
Table.UPDRS_total(~checkTable.equal1,:) = Table.UPDRS_total_non_tremor(~checkTable.equal1,:) + Table.UPDRS_total_tremor(~checkTable.equal1,:);

Table_Michiel = Table(:,3:6);
Table_Michiel.MAside = Table.Most_affected_arm;
Table_Michiel.MMSE = Table.MMSE_score;
Table_Michiel.LEDD = Table.LEDD;
Table_Michiel.UPDRS_total1 = UPDRS.UPDRSIII_total_score_1;
Table_Michiel.UPDRS_total2 = UPDRS.UPDRSIII_total_score_2;
Table_Michiel.UPDRS_total_non_tremor1 = sum( [Table.B_and_R1 Table.Axial1], 2);
Table_Michiel.UPDRS_total_non_tremor2 = sum( [Table.B_and_R2 Table.Axial2], 2);
Table_Michiel.UPDRS_total_tremor1 = sum( [Table.Rest_tremor1 Table.Postural_tremor1 Table.Kinetic_tremor1 Table.lip1], 2 );
Table_Michiel.UPDRS_total_tremor2 = sum( [Table.Rest_tremor2 Table.Postural_tremor2 Table.Kinetic_tremor2 Table.lip2], 2 );

writetable(Table_Michiel, '/project/3024005.02/Analysis/Participant Characteristics/output/Table_Michiel.xls', 'WriteRowNames',true);
 
%==========================================================================
% --- Store table --- %
%==========================================================================

Table = FullTable(:,indicesTable);

% --- Make column names nice but still useable --- 
Table.Properties.VariableNames = {
    'Tremor_dominant';
    'Year_of_birth';
    'Age';
    'Gender';
    'Handedness';
    'Age_at_onset';
    'Most_affected_arm';
    'Most_affected_leg';
    'Presence_resting_tremor';
    'Absence_resting_tremor';
    'Using_PD_medication';
    'MMSE_score_ses01';
    'MMSE_score_ses02';
    };


% As an excel file
TableForExcel = Table;
TableForExcel.SubNr = Table.Properties.RowNames;
TableForExcel = movevars(TableForExcel, 'SubNr', 'Before', 'Tremor_dominant');
writetable(TableForExcel, fullfile(conf.dir.output,conf.file.output.xls));

% As a matlab file
save(fullfile(conf.dir.output, conf.file.output.mat), 'Table');

fprintf('stored table to:\n  %s\n  %s\n', fullfile(conf.dir.output,conf.file.output.xls), fullfile(conf.dir.output,conf.file.output.mat));
