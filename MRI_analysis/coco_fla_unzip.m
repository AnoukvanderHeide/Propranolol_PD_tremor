function coco_fla_unzip(conf, CurSub)
%coco_fla_unzip.m unzips functional mri images for CurSub (if more than one
%run is found, it will use the last one)

    for i = 1:length(conf.sub.ses)
        
        CurSes = conf.sub.ses{i};
        
        fprintf('\nSession %s:\n\n', CurSes);

        subfolder   = replace(conf.pre.smooth.filedir, {'Sub', 'Ses'}, {CurSub, CurSes});

        % --- Skip if this sub doesn't exist---
        if ~exist(subfolder, 'dir')
            fprintf('this subject-session does not exist...\n');
            continue
        end
        
        
        % --- Skip if the files have already been unzipped ---
        unzippedfilename = replace(conf.file.mri.coco, {'Sub', 'Ses'}, {CurSub, CurSes});
        unzippedfile = pf_findfile(subfolder,unzippedfilename);
        if ~isempty(unzippedfile)
            fprintf('file is already unzipped\n')
            continue
        end

        zippedfilename = replace(conf.file.mri.cocozip, {'Sub', 'Ses'}, {CurSub, CurSes});
        zippedfile = pf_findfile(subfolder,zippedfilename);   
        
        % --- Skip if there's no zipped file to unzip ---
        if isempty(zippedfile)
            fprintf('there is no coco file in this folder...\n');
            continue
        % --- Grab last run if there's more than one ---
        elseif length(zippedfile) > 1     && iscell(zippedfile)
            fprintf('found %s runs\n', num2str(length(zippedfile)))
            if strcmp([CurSub '-' CurSes], '012-01')
                zippedfile = zippedfile{1};
            else
                zippedfile = zippedfile{end};
            end
        else
            fprintf('found 1 run\n')
        end
        
        fprintf('using "%s"\n', zippedfile);

        % --- Unzip the files ---
        fprintf('unzipping files...\n');
        gunzip(fullfile(subfolder,zippedfile));
        fprintf('done unzipping files!\n');   
    
    end
    
    
end
    