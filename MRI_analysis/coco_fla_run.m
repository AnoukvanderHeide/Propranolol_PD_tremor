function coco_fla_run(conf, CurSub)
%coco_fla_run.m creates and runs the first-level batch for the current
%subject (CurSub)

    suboutfolder    = replace(conf.fla.spec.output.main, {'Sub'}, {CurSub});
    outputfolder    = replace(conf.fla.spec.output.dir, {'Sub'}, {CurSub});
    outputname      = replace(conf.fla.spec.output.name, {'Sub'}, {CurSub});
    
    % --- Skip if there's already an SPM.mat file ---
    if exist(fullfile(outputfolder, 'SPM.mat'), 'file')
        fprintf('an SPM.mat file already exists, not running first-level again\n');
        return
    end
    
    % --- fMRI model specification ---
    
    % Some settings
    matlabbatch{1}.spm.stats.fmri_spec.dir              = { outputfolder };
    matlabbatch{1}.spm.stats.fmri_spec.timing.units     = 'scans'; % default = undefined
    matlabbatch{1}.spm.stats.fmri_spec.timing.RT        = 1;       % default = undefined
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t    = 16;      % default = 16
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0   = 1;       % default = 8    
    
    % fill in sessions
    propSes  = conf.sub.drug{strcmp(conf.sub.name, CurSub)};
    sesOrder = {'placebo', 'propranolol'};
    if propSes == 1
        order = [2 1]; % first add second session (placebo), then add first session (propranolol)
    else
        order = [1 2]; % first add first session (placebo), then add second session (propranolol)
    end
    
    % Add placebo session first (as Session 1), then propranolol session (as Session 2)
    for i = 1:length(conf.sub.ses)
        CurSes = conf.sub.ses{order(i)};
        fprintf('\nAdding %s session (ses-%s):\n\n', sesOrder{i}, CurSes);
        
        % Check if there's a smoothed functional file 
        mridirname  = replace(conf.fla.spec.scan.dir, {'Sub', 'Ses'}, {CurSub, CurSes});
        filename    = replace(conf.fla.spec.scan.name, {'Sub', 'Ses'}, {CurSub, CurSes});
        mrifilename = pf_findfile(mridirname, filename);
        
        if isempty(mrifilename)  
            fprintf('no functional scans found with name %s\n', mrifilename);
            fprintf('stopping with creating first-level batch\n');
            return
        end
        
        % Gather scan files
        allfiles    = spm_select('expand', fullfile(mridirname, mrifilename));
        fprintf('using "%s"\n', mrifilename);
        fprintf('  there are %s scans in total\n', num2str(length(allfiles)));
        
        expectedLength  = conf.trial.startDelay + conf.trial.duration * conf.trial.nr;
        actualLength    = length(allfiles);
        
        % Remove scans at start and end
        
        % If there's less data than there should be (should only be the case for 018-1)
        if actualLength < expectedLength
            fprintf('  there are less scans (%s) than expected (%s)\n', num2str(actualLength), num2str(expectedLength));
            
            nameInStruct = ['s' CurSub 's' CurSes];
            startIdx     = conf.trial.dummies + 1;      % have to remove "dummy scans" because of how the trem regressor is created
            endTrial     = conf.exc.(nameInStruct).rest_off(end) + conf.trial.dummies + 1;
            endIdx       = min(length(allfiles), endTrial + conf.trial.endInclude);
            fprintf('  removed first %s scans ("dummy scans" have to be removed because of how tremor regressor is created)\n', num2str(startIdx-1));
        
        % Normal situation
        else
            scansRemoved= conf.trial.startDelay - conf.trial.startInclude;
            startIdx    = conf.trial.dummies + scansRemoved + 1;
            preferredEnd= startIdx + conf.trial.startInclude + conf.trial.duration * conf.trial.nr + conf.trial.endInclude - 1;
            endIdx      = min(length(allfiles), preferredEnd); 
            
            fprintf('  removed first %s scans (%s dummy scans and %s/%s scans before the start of the first trial)\n',...
                num2str(startIdx - 1), num2str(conf.trial.dummies), num2str(scansRemoved), num2str(conf.trial.startDelay));
            
        end
        
        files       = cellstr(allfiles(startIdx:endIdx,:));
        fprintf('  removed last %s scans\n', num2str(length(allfiles)-endIdx));
        fprintf('  added %s functional scans to first-level batch\n', num2str(length(files)));
        
        % Gather regressor and condition files
        multiregr   = replace(fullfile(conf.fla.spec.multiregr.dir, conf.fla.spec.multiregr.name), {'Sub', 'Ses'}, {CurSub, CurSes});
        multicond   = replace(fullfile(conf.fla.spec.multicond.dir, conf.fla.spec.multicond.name), {'Sub', 'Ses'}, {CurSub, CurSes});
        fprintf('added multi regressor file "%s" to batch\n', multiregr);
        fprintf('added multi condition file "%s" to batch\n', multicond);
        
        
        % Get correct HPF
        if any(contains(conf.fla.regr.which, 'cosines')); hpf = 'inf'; else; hpf = 180; end
        fprintf('using hpf of ''%s''\n', num2str(hpf));
        
        % Add everything to model
        matlabbatch{1}.spm.stats.fmri_spec.sess(i).scans     = files;
        matlabbatch{1}.spm.stats.fmri_spec.sess(i).cond      = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}, 'orth', {});
        %matlabbatch{1}.spm.stats.fmri_spec.sess(i).cond      = struct('name', {}, 'onset', {}, 'duration', {});
        matlabbatch{1}.spm.stats.fmri_spec.sess(i).multi     = { multicond };
        matlabbatch{1}.spm.stats.fmri_spec.sess(i).regress   = struct('name', {}, 'val', {});
        matlabbatch{1}.spm.stats.fmri_spec.sess(i).multi_reg = { multiregr };
        matlabbatch{1}.spm.stats.fmri_spec.sess(i).hpf       = hpf;

    end

    % Other settings
    matlabbatch{1}.spm.stats.fmri_spec.fact             = struct('name', {}, 'levels', {});
    matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];    % default = [0 0]
    matlabbatch{1}.spm.stats.fmri_spec.volt             = 1;        % default = 1
    matlabbatch{1}.spm.stats.fmri_spec.global           = 'None';   % default = 'None'
    matlabbatch{1}.spm.stats.fmri_spec.mthresh          = 0.3;      % default = 0.8
    matlabbatch{1}.spm.stats.fmri_spec.mask             = {''};     % default = ''
    matlabbatch{1}.spm.stats.fmri_spec.cvi              = 'AR(1)';  % default = 'AR(1)'
    
    
    % --- Model estimation ---
    matlabbatch{2}.spm.stats.fmri_est.spmmat(1)         = cfg_dep('fMRI model specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    matlabbatch{2}.spm.stats.fmri_est.write_residuals   = 0;        % default = 0
    matlabbatch{2}.spm.stats.fmri_est.method.Classical  = 1;        % default = 1

    
    % --- Contrasts ---
    matlabbatch{3}.spm.stats.con.spmmat(1)              = cfg_dep('Model estimation: SPM.mat File', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    matlabbatch{3}.spm.stats.con.consess{1}.fcon = conf.fla.con.fcontrasts(1);
                                                           
    for con = 1:length(conf.fla.con.contrasts)  % t-contrasts to be made, defined in coco_conf.m
        matlabbatch{3}.spm.stats.con.consess{con+1}.tcon = conf.fla.con.contrasts(con);
    end
    
    matlabbatch{3}.spm.stats.con.delete                 = 0;    % default = 0
    
    
    % --- Save batch ---
    savename = fullfile(suboutfolder, outputname);
    save(savename,'matlabbatch');
    fprintf('\nsaved first-level batch to "%s"\n', savename);

    
    % --- Run batch ---
    fprintf('\nrunning first-level batch now...\n');
    spm_jobman('run',matlabbatch);
    fprintf('\ndone with first-level!\n\n');

    clear matlabbatch
    
end