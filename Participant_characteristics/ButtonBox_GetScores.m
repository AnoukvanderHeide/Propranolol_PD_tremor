%GetLogfileScores.m extracts responses to the final questions that are
%filled in after the coco task in the MRI and stores them in one file.

clear all
warning('off', 'Findfile:empty');

%==========================================================================
% --- Settings --- %
%==========================================================================

% --- Directories ---
conf.dir.project        = fullfile('/project', '3024005.02');
conf.dir.presentation   = fullfile(conf.dir.project, 'raw', 'sub-Sub', 'Presentation');
conf.dir.output         = fullfile(conf.dir.project, 'Analysis', 'Participant Characteristics', 'output');

% --- Useful scripts ---
addpath(fullfile(conf.dir.project, 'Analysis', 'SupportingScripts', 'helpers'));

% --- File names ---
conf.file.presentation      = '/Sub_Ses_/&/-MRI_coco_/&/.log/'; % name of the presentation files
conf.file.output            = 'Logfile scores';     % name the output will be stored as (will add .xls and .mat)


% --- Subjects ---
conf.sub.name = {  
                  '001'; '002'; '003'; '004'; '005'; ...    %TD Participants
                  '006'; '007'; '008'; '009'; '010'; ...   
                  '011'; '012'; '013'; '014'; '015'; ...
                  '016'; '017'; '018'; '019'; '020'; ... 
                  '021'; '022'; '023'; '024'; '025'; ...
                  '026'; '027'; '028'; '029'; '030'; ...
                   
                  '031'; '032'; '033'; '034'; '035'; ...    %NT Participants
                  '036'; '037'; '038'; '039'; '040'; ...
                  '041'; '042'; '043'; '044'; '045'; ...
                  '046'; '047'; '048'; '049'; '050'; ...
                  '051'; '052'; '053'; '054'; '055'; ...
                  '056'; '057'; '058'; '059'; '060'; ...
                  
                  '061'; '062'; '063'; '064'; '065'; ...    % more TD
                   }; 
               
% --- Sessions ---
conf.sub.ses = {'01'; '02'};         

% --- Scores to extract from files ---
conf.scores.names = {'StressCoco', 'StressRest', 'DifficultyCoco', 'DifficultyRest'};



% --- Exceptions ---
conf.exceptions.s063s01 = {4,2,3,1}; % weren't answered during the scan but asked afterwards, so are not in the presentation file



%==========================================================================
% --- Get scores --- %
%==========================================================================

% --- Initialize some things ---
nSub    = length(conf.sub.name);
nSes    = length(conf.sub.ses);
nScores = length(conf.scores.names);

allScores       = table();
allScores.subnr = repelem(conf.sub.name,nSes,1);
% allScores.sesnr = repmat(conf.sub.ses,nSub,1);
allScores.sesnr = repmat(cellfun(@str2num, conf.sub.ses), nSub, 1);

for i = 1:nScores; allScores.(conf.scores.names{i}) = repelem(NaN,nSub*nSes,1); end


% --- Get scores for each sub/sess ---          
for i = 1:nSub
    CurSub = conf.sub.name{i};
    
    for j = 1:nSes
        CurSes = conf.sub.ses{j};
        
        
        % --- Get file ---
        FileName    = replace(conf.file.presentation, {'Sub', 'Ses'}, {CurSub, CurSes});
        DirName     = replace(conf.dir.presentation, {'Sub'}, {CurSub});
        File        = pf_findfile(DirName, FileName);
            
        
        % --- Skip if there's no presentation file --- 
        if isempty(File) 
            fprintf('%s-%s  no presentation file found\n', CurSub, CurSes);
            continue
        end
            
        
        % --- If there's more than one file, ask the user which one is the correct file ---
        if ~ischar(File) & length(File) > 1
            fprintf('%s-%s more than one file found:\n', CurSub, CurSes)
            for f = 1:length(File)
                fprintf('  %i) %s\n',f,File{f})
            end
            idx = input('  which one do you want to use:    ');
            File = File{idx};
            fprintf('  using file %s\n', File);
        end

        
        % --- Read file ---
        text = fileread(fullfile(DirName,File));
        TextAsCells = regexp(text, '\n', 'split');

        
        % --- Extract and store scores ---
        idx = (i-1) * nSes + j;
        
        substring = ['s' CurSub 's' CurSes];
        
        if isfield(conf.exceptions, substring) % if it's an exception, add those numbers instead of those from the file
            allScores(idx,3:end) = conf.exceptions.(substring);
        else % get the scores from the file
            for resp = 1:nScores
                curResp = conf.scores.names{resp};
                scoreLine = TextAsCells(contains(TextAsCells, curResp));
                if ~isempty(scoreLine)
                    scoreLine = scoreLine{1};
                    score = str2double(scoreLine(strfind(scoreLine, ':') + 2));
                    allScores(idx,:).(conf.scores.names{resp}) = score;
                end

            end
        end
        
    end
      
end
               
               
% --- Store scores to excel ---
writetable(allScores, fullfile(conf.dir.output, [conf.file.output '.xls']));
save(fullfile(conf.dir.output, [conf.file.output '.mat']), 'allScores')
fprintf('\nfile saved to %s\n', fullfile(conf.dir.output, [conf.file.output ' (.xls/.mat)']));
               
               


               
               
               
               
               
               
               
               
               