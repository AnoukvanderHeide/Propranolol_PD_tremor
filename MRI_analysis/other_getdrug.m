
function drug = other_getdrug(conf)


    % Get propanolol vs. placebo info
    addpath('/project/3024005.02/Analysis/Propranolol/Scripts')
    conf2 = Settings();
    rmpath('/project/3024005.02/Analysis/Propranolol/Scripts')

    % Put it in a struct
    drug = cell(length(conf.sub.name), 1);
    for i = 1:length(conf.sub.name)
        idx = strcmp(conf2.sub.drug(:,1), conf.sub.name{i});
        if conf2.sub.drug{idx,2} == 2
            drug{i} = 1;    % first session is propranolol
        elseif conf2.sub.drug{idx,3} == 2
            drug{i} = 2;    % second sesion is propranolol
        else
            error('?????????\n'); % neither is propranolol ?????
        end

    end


end