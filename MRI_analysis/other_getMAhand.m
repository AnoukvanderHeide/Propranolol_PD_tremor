function MAhand = other_getMAhand(conf)
%MAhand.m gets most-affected hand (aka the hand that was measured with ACC
%from castor file
% Inputs: 
%   conf    : structure with settings

    Table   = readtable('/project/3024005.02/Analysis/Participant Characteristics/input/ACCdata.csv');
    idxrow  = ismember(Table.RecordId,conf.sub.name);
    idxcol  = ismember(Table.Properties.VariableNames, {'RecordId', 'tremorreg_ACC_side_1', 'tremorreg_ACC_side_2', 'MA'});
    Table   = Table(idxrow, idxcol);

    MAhand = cell(length(conf.sub.name), 1);
    for i = 1:length(conf.sub.name)
        idx = strcmp(Table.RecordId, conf.sub.name{i});
        MAhand{i} = Table.tremorreg_ACC_side_1{idx}(1); 
    end
    
    
    
%     % sanity check
%     TableMA = load('/project/3024005.02/Analysis/Participant Characteristics/output/TableFull.mat');
%     Table.MA = TableMA.Table.Most_affected_arm;
%     for i = 1:height(Table)
%         if ~strcmp(Table.tremorreg_ACC_side_1{i}, Table.tremorreg_ACC_side_2{i})
%             fprintf('%s: ACC placement is not the same in both sessions\n', Table.RecordId{i})
%         end        
%         if ~strcmp(Table.tremorreg_ACC_side_1{i}, Table.MA{i})
%             fprintf('%s: MA and ACC placement are not the same in ses1\n', Table.RecordId{i});
%         end
%         if ~strcmp(Table.tremorreg_ACC_side_2{i}, Table.MA{i})
%             fprintf('%s: MA and ACC placement are not the same in ses2\n', Table.RecordId{i});
%         end
%     end
%     
    
end




