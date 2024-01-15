%TablePrint.m Prints a table to the console with a summary of the
%participant characteristics

clear all

%==========================================================================
% --- Settings --- %
%==========================================================================

% --- Files and directories ---

pfProject = '/project/3024005.02/';
conf.dir.main    = fullfile(pfProject, 'Analysis', 'Participant Characteristics');
conf.dir.output  = fullfile(conf.dir.main, 'output');
conf.dir.files   = fullfile(conf.dir.main, 'input');

conf.file.table          = 'TableFull.mat';

% --- Variables to include ---
% You can remove/add rows to this to remove/add rows to the table
% following this format:

% 1st column: variable name in matlab table
% 2nd column: variable name for output table
% 3rd column: 
%  - string variables should have 3rd column, containing the ordered options 
%    that should be shown in the table. Can remove/add options to the list.
%  - if you put "MA-LA" there, it will calculate a t-test for that
%    variable_MA vs. variable_LA (only add if variables exist in matlab table)

conf.table.rows = {
    {"Gender";                  "Gender [M/F]";                         {'Male', 'Female'}              };
    {"Age";                     "Age [Mean (SD)]"                                                       }; 
    {"Age_at_onset";            "Age at onset [Mean (SD)]"                                              }; 
    {"Disease_duration";        "Disease duration (years) [Mean (SD)]"                                  }; 
    {"Handedness";              "Dominant hand [R/L]";                  {'Right', 'Left'}               }; 
    {"Most_affected_arm";       "Most affected arm [R/L]";              {'Right', 'Left'}               }; 
    {"Most_affected_leg";       "Most affected leg [R/L]";              {'Right', 'Left'}               };
    {"Using_PD_medication";     "Using PD medication? [Y/N]";           {'Yes', 'No'}                   }; 
    {"LEDD";                    "LLED (mg/day) [Mean (SD)]"                                             };
    {"MMSE_score";              "MMSE [Mean (SD)]"                                                      };
    {"Hoehn_and_Yahr";          "Hoehn and Yahr [Mean (SD)]"                                                                                  }; 
    {"UPDRS_total";             "MSD-UPDRS III Total [Mean (SD)]"                                       };
         
    {"UPDRS_total_tremor";      "  Tremor total"                                }; 
    {"Rest_tremor";             "    Rest tremor";                  "MA-LA"     };
    {"Rest_tremor_MA";          "      MA"                                      };
    {"Rest_tremor_LA";          "      LA"                                      };    
    {"Rest_tremor_constancy";   "      Constancy"                               };
    {"Postural_tremor";         "    Postural tremor";              "MA-LA"     };
    {"Postural_tremor_MA";      "      MA"                                      };
    {"Postural_tremor_LA";      "      LA"                                      };    
    {"Kinetic_tremor";          "    Kinetic tremor";               "MA-LA"     };
    {"Kinetic_tremor_MA";       "      MA"                                      };
    {"Kinetic_tremor_LA";       "      LA"                                      };
    {"UPDRS_total_non_tremor";  "  Non-tremor total"                            }; 
    {"B_and_R";                 "    Limb bradykinesia + rigidity"; "MA-LA"     };
    {"B_and_R_MA";              "      MA"                                      };
    {"B_and_R_LA";              "      LA"                                      };
    {"Axial";                   "    Axial"                                     };
}; %#ok<*CLARRSTR>


% 2 options: neuromelanin analysis or propranolol analysis
user = 'propranolol';

switch(user)
    case 'neuromelanin+rest'
        conf.sub = {   
                  '002'; '003'; '004'; '005'; '006';...   % TD Participants
                  '007'; '008'; '009'; '011'; '012'; ...  % excl: 001, 010, 017, 019
                  '013'; '014'; '015'; '016'; '018'; ...
                  '020'; '021'; '022'; '023'; '024';... 
                  '025'; '026'; '027'; '028'; '029';...
                  '030'; '061'; '063'; '064'; '065'; ...
                   
                  '031'; '032'; '033'; '034'; '035'; ...   % NT Participants
                  '036'; '037'; '038'; '039'; '040'; ...   % excl: 053
                  '041'; '042'; '043'; '044'; '045'; ...
                  '046'; '047'; '048'; '049'; '050'; ...
                  '051'; '052'; '054'; '055'; '056'; ...
                  '057'; '058'; '059'; '060'};   
        
        conf.table.nrofgroups = 2; 
        conf.table.groupnames = {'Tremor dominant', 'Non-tremor'};
        
        conf.table.include.TDvsNT = true;   % add column with t-tests comparing TD and NT
        conf.table.include.MAvsLA = true;  % add column comparing MA and LA for UPDRS parts
    
    case 'propranolol' % this now includes also the participants for tremor registration (total 27 patients) 
        conf.sub = {                  
                  '002'; '003'; '004'; '005'; '006'; ...  % excl: 001, 007,
                  '008'; '009'; '011'; '012'; '014';...  % 010, 013, 019, 021,
                  '015'; '016'; '018'; '020'; ...        % 024, 026, 027, 061
                  '022'; '023'; '025'; '028'; '029'; ...
                  '030'; '063'; '064'; '065'; ...
                  '010'; '017'; '019'; '027';}; % these are the 4 that are not included in the fMRI analysis
    
        conf.table.nrofgroups = 1; 
        conf.table.groupnames = {'""'};
        conf.table.include.TDvsNT = false;  % add column with t-tests comparing TD and NT
        conf.table.include.MAvsLA = true;   % add column comparing MA and LA for UPDRS parts
       
end

%==========================================================================
% --- Create Table --- %
%==========================================================================

% --- Load file and remove subjects ---
load(fullfile(conf.dir.output, conf.file.table));
idxToKeep = contains(Table.Properties.RowNames, conf.sub);
Table = Table(idxToKeep,:);

varsInTable = Table.Properties.VariableNames;

% Get the indices of the group(s)
if conf.table.nrofgroups == 2
    indices{1} = strcmp(Table.Tremor_dominant, "Yes");
    indices{2} = strcmp(Table.Tremor_dominant, "No");
else
    indices{1} = repelem(true, height(Table), 1);
    indices{2} = repelem(false, height(Table), 1);
end

% --- Go over the variables to include and add them to the table ---

TableSummary = table();

for var = 1:length(conf.table.rows)
    
    CurVar      = conf.table.rows{var}{1};
    fancyName   = conf.table.rows{var}{2};
    
    % if it doesn't exist in the table, go to next variable
    if ~any(strcmp(varsInTable, CurVar))
        fprintf('can''t find this variable (%s) in the table', CurVar);
        continue;
    end
    
    data = Table.(CurVar);
    datatype = class(data);
    
    switch(datatype)
        
        % if the current variable is a string => get counts
        case 'string'
            
            clear groupdata
            
            % for each group 
            for group = 1:conf.table.nrofgroups
                groupdata{group} = data(indices{group});
                if any(strcmp(groupdata{group}, ""))
                    warning('screeeaaaam') % to check if data is missing 
                end
                
                % get the counts for each option
                countString{group} = '';
                options = conf.table.rows{var}{3};
                for opt = 1:length(options)
                    count = sum(strcmp(groupdata{group}, options{opt}));
                    countString{group} = [countString{group}, num2str(count), '/'];
                end            
                countString{group} = countString{group}(1:end-1); % remove the extra '/' at the end
            
            end
            
            % add it to the table
            totalString = {fancyName};
            for g = 1:conf.table.nrofgroups
                totalString{end+1} = convertCharsToStrings(countString{g});
            end
            if conf.table.include.TDvsNT
                totalString{end+1} = ""; % or if there's some way to compare the groups for this data type, can add test and string here
            end
            TableSummary = [TableSummary; totalString];
            
            
            
        % if it's numbers => calculate mean/sd
        case 'double' 
            
            % for each group 
            for group = 1:conf.table.nrofgroups
                groupdata{group} = data(indices{group});
            
                % calculate mean and SD
                dataMean = round(nanmean(groupdata{group}), 1);
                dataStd  = round(nanstd(groupdata{group}), 1);
                meansdString{group} = [num2str(dataMean) ' (' num2str(dataStd) ')'];
            end
            
            % compare TD and NT
            if conf.table.include.TDvsNT
                [H,P,CI,STATS] = ttest2(groupdata{1}, groupdata{2});
                TDvsNTstring = strcat("t(", num2str(round(STATS.df,2)), ") = ", num2str(round(STATS.tstat,1)),...
                    ", p = ", num2str(round(P,2,'significant')) );
            end
            
            % add it to the table
            totalString = {fancyName};
            for g = 1:conf.table.nrofgroups
                totalString{end+1} = convertCharsToStrings(meansdString{g});
            end
            if conf.table.include.TDvsNT
                totalString{end+1} = TDvsNTstring;
            end
            TableSummary = [TableSummary; totalString];

            
            
        otherwise
            fprintf('don''t know what to do with this datatype: %s\n', datatype)     
    end    
end


% --- Add better column names ---
varNames = [{'Characteristic'} conf.table.groupnames(:)'];
if conf.table.include.TDvsNT
    varNames{end + 1} = 'Difference (TD-NT)';
end
TableSummary.Properties.VariableNames = varNames;


% --- Compare MA and LA ---
if conf.table.include.MAvsLA
    
    TableSummary = [TableSummary table(repelem("", height(TableSummary), 1))];
    TableSummary.Properties.VariableNames(end) = {'Difference (MA-LA)'};
    
    for var = 1:length(conf.table.rows)
        CurVar = conf.table.rows{var};
    
        if length(CurVar) > 2 & strcmp(CurVar{3}, 'MA-LA')
    
            % calc t-scores and add strings
            MAvar = strcat(CurVar{1}, "_MA");
            LAvar = strcat(CurVar{1}, "_LA");
            
            [H,P,CI,STATS] = ttest(Table.(MAvar), Table.(LAvar));
            MAvsLAstring = strcat("t(", num2str(round(STATS.df,2)), ") = ", num2str(round(STATS.tstat,1))  , ", p = ", num2str(round(P,2,'significant')) );
            
            % add it to the table
            TableSummary{var, end} = MAvsLAstring;
            
        end
        
        
    end

end