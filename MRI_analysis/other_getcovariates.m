function conf = other_getcovariates(conf)

 conf = coco_conf();

    % Initialize matrices
    conf.sub.FDprop = nan(1, length(conf.sub.name));
    conf.sub.FDplac = nan(1, length(conf.sub.name));
    conf.sub.FD     = nan(1, length(conf.sub.name));
    conf.sub.age    = nan(1, length(conf.sub.name));
    conf.sub.gender = nan(1, length(conf.sub.name));
    conf.sub.tremor = nan(1, length(conf.sub.name));
    
    
    % Load full table with participant characteristics
    load(fullfile(conf.dir.chars, conf.file.other.chars));

    % Loop over subjects 
    for sub = 1:length(conf.sub.name)
        CurSub = conf.sub.name{sub};

        % --- Get Framewise Displacement ---
        
        % Get data
        subfolder   = replace(conf.dir.spm.sub, {'Sub'}, {CurSub});
        filename    = replace(conf.file.spm.model.regressors, {'Sub'}, {CurSub});
        
        datases1    = load(fullfile(subfolder, replace(filename, 'Ses', '01')));
        datases2    = load(fullfile(subfolder, replace(filename, 'Ses', '02')));
        FDses1      = datases1.R(:, strcmp(datases1.names, 'framewise_displacement'));
        FDses2      = datases2.R(:, strcmp(datases2.names, 'framewise_displacement'));

        % Store data (in plac-prop order)
        propSes  = conf.sub.drug{strcmp(conf.sub.name, CurSub)};
        if propSes == 1
            conf.sub.FDprop(sub) = nanmean(FDses1);
            conf.sub.FDplac(sub) = nanmean(FDses2);
        else 
            conf.sub.FDprop(sub) = nanmean(FDses2);
            conf.sub.FDplac(sub) = nanmean(FDses1);
        end
        
        conf.sub.FD(sub) = (conf.sub.FDprop(sub) + conf.sub.FDplac(sub)) / 2;
        
        % --- Get Age and Gender ---
        subIdx = strcmp(Table.Properties.RowNames, CurSub);
        
        if strcmp(Table.Gender(subIdx), "Male")
            conf.sub.gender(sub) = -1;
        else
            conf.sub.gender(sub) = 1;
        end
        
        conf.sub.age(sub)    = Table.Age(subIdx);
        
        % --- UPDRS tremor severity ---
        conf.sub.tremor(sub)    = Table.Rest_tremor(subIdx);
        
    end


end





