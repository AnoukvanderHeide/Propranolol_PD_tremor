function coco_batch_firstlevel(conf)
%coco_batch_firstlevel.m is the main script for the first-level analysis.
%It's called by coco_batch_main.m and calls different sub-steps of the first-level analysis.

% Steps (steps can be skipped by changing it in coco_conf.m):
%   Unzip files (coco_fla_unzip.m)
%   Smooth files (coco_fla_smooth.m)
%   Create a condition file (coco_fla_combicond.m)
%   Create a regressor file (coco_fla_combiregr.m)
%   Create and run first-level batch (coco_fla_run.m)

    CurSub = conf.cur.sub;    
    
    % --- Create SPM output folders if it doesn't exist yet ---
    subfolder       = replace(conf.dir.spm.sub, {'Sub'}, {CurSub});
    resultsfolder   = replace(conf.dir.spm.output, {'Sub'}, {CurSub});
    if ~exist(subfolder, 'dir');        mkdir(subfolder);       end
    if ~exist(resultsfolder, 'dir');    mkdir(resultsfolder);   end

    fprintf('\nWorking on | %s \n\n', CurSub);

    
    % --- Perform different analysis steps ---
    for step = 1:length(conf.todo.fla_steps)
        CurStep = conf.todo.fla_steps{step};

        switch(CurStep)

            % make files ready for first-level
            case 'unzip'
                fprintf('\n -----------------------\n +++ Unzipping files +++ \n -----------------------\n');
                coco_fla_unzip(conf, CurSub);
                fprintf('\n -----------------------\n --- Unzipping files --- \n -----------------------\n\n');
            case 'smooth'
                fprintf('\n -----------------------\n +++ Smoothing image +++ \n -----------------------\n');
                coco_fla_smooth(conf, CurSub);
                fprintf('\n -----------------------\n --- Smoothing image --- \n -----------------------\n\n');

            % create input for SPM    
            case 'combicond'
                fprintf('\n -------------------------------\n +++ Creating condition file +++ \n -------------------------------\n');
                coco_fla_combicond(conf, CurSub);
                fprintf('\n -------------------------------\n --- Creating condition file --- \n -------------------------------\n\n');
            case 'combiregr'
                fprintf('\n -------------------------------\n +++ Creating regressor file +++ \n -------------------------------\n');
                coco_fla_combiregr(conf, CurSub);
                fprintf('\n -------------------------------\n --- Creating regressor file --- \n -------------------------------\n');                    

            % create and run first-level
            case 'firstlevel'
                fprintf('\n ----------------------------------\n +++ Creating first-level batch +++ \n ----------------------------------\n');
                coco_fla_run(conf, CurSub);
                fprintf('\n ----------------------------------\n --- Creating first-level batch --- \n ----------------------------------\n');

            otherwise
                fprintf('what\n')

        end

    end  

    fprintf('\nDone with  | %s \n\n', CurSub);


end

