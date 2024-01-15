function coco_fla_smooth(conf, CurSub)
%coco_fla_smooth.m creates and runs smooth batch for CurSub
    
    for i = 1:length(conf.sub.ses)        
        
        clearvars -except conf CurSub i
        
        CurSes = conf.sub.ses{i};
        fprintf('\nSession %s: \n\n', CurSes);

        
        % --- Get some file and dir names ---
        batchfilename   = replace(conf.file.spm.batch.smooth, {'Sub', 'Ses'}, {CurSub, CurSes});
        batchdirname    = replace(conf.dir.spm.sub, {'Sub', 'Ses'}, {CurSub, CurSes});
        
        indirname       = replace(conf.pre.smooth.filedir, {'Sub', 'Ses'}, {CurSub, CurSes});
        infilename      = pf_findfile(indirname,replace(conf.pre.smooth.filename, {'Sub', 'Ses'}, {CurSub, CurSes}));
        outfilename     = [conf.pre.smooth.prefix infilename];
        
        
        % --- Skip if images have already been smoothed ---
        if exist(fullfile(indirname, outfilename), 'file')
            fprintf('smoothing has already been run\n')
            continue
        end

        
        % --- Get func files ---
        fprintf('using "%s"\n', infilename);
        files   = spm_select('expand', fullfile(indirname,infilename));
        matlabbatch{1}.spm.spatial.smooth.data = cellstr(files);
        fprintf('added %s functional scans to batch\n', num2str(length(files)));
        fprintf('smoothed file will be saved as "%s"\n', outfilename);

        
        % --- Get settings ---
        matlabbatch{1}.spm.spatial.smooth.fwhm      = conf.pre.smooth.fwhm;
        matlabbatch{1}.spm.spatial.smooth.dtype     = conf.pre.smooth.dtype;
        matlabbatch{1}.spm.spatial.smooth.im        = conf.pre.smooth.im;
        matlabbatch{1}.spm.spatial.smooth.prefix    = conf.pre.smooth.prefix;

        
        % --- Store batch ---
        savename = fullfile(batchdirname, batchfilename);
        save(savename,'matlabbatch');
        fprintf('smoothing batch saved to "%s"\n', savename);

        
        % --- Run the batch ---
        fprintf('\nrunning smoothing batch now...\n');
        spm_jobman('run',matlabbatch);
        fprintf('\ndone with smoothing!\n\n');
       
    end
    

end