function coco_secondlevel_2x2(conf)
%coco_secondlevel.m creates and runs a second-level batch for each contrast
%(and skips the contrasts that already have an output SPM.mat file)

allconditions{1} = {'coco_general', 'rest_general'};
allmedication{1} = {'plac', 'prop'};
alloutfolder{1}  = fullfile(conf.dir.spm.group, 'taskxdrug(general)');

allconditions{2} = {'coco_tremoramp', 'rest_tremoramp'};
allmedication{2} = {'plac', 'prop'};
alloutfolder{2}  = fullfile(conf.dir.spm.group, 'taskxdrug(tremoramp)');

allconditions{3} = {'coco_tremorchange', 'rest_tremorchange'};
allmedication{3} = {'plac', 'prop'};
alloutfolder{3}  = fullfile(conf.dir.spm.group, 'taskxdrug(tremorchange)');


for model = 1:length(allconditions)
    
    conditions = allconditions{model};
    medication = allmedication{model};
    outfolder  = alloutfolder{model};
    
    % Get output folder
    if ~exist(outfolder,'dir'); mkdir(outfolder); end
    fprintf('\n  folder: %s\n', outfolder);
    
    % --- Skip if there's already an SPM.mat file for this contrast ---
    if exist(fullfile(outfolder, 'SPM.mat'), 'file')
        fprintf('  there is already an SPM.mat file for this contrast\n');
        continue
    end
    
    contrasts     = conf.fla.con.contrasts;
    contrastNames = {contrasts(:).name};
    nrFcon = length(conf.fla.con.fcontrasts); % the number of F-contrasts that are included (are in the list of contrasts before t-contrasts)
    
    % --- Gather scans ---
    for cond = 1:length(conditions)      % 1: coco; 2:rest  (general, tremamp, or tremchange)
        for med = 1:length(medication)   % 1: plac; 2:prop  (also in that order in output images)
            fprintf('  gathering scans for: %s - %s\n', conditions{cond}, medication{med});

            scans = {};

            % Get the right contrast
            idxCon = find(strcmp(contrastNames, conditions{cond}));
            %idx    = (idxCon-1) * 3 + med; % contrasts are ordered in groups of 3 (general, tremoramp and tremorchange contrast)
            idx    = (idxCon-1) * 3 + nrFcon*3 + med; % contrasts are ordered in groups of 3 (general, tremoramp and tremorchange contrast)
            contrastcode    = ['con_' num2str(idx,'%04.f')];
            infilename = [contrastcode '.nii'];
            fprintf('    contrast code: %s\n', contrastcode);

            % Loop over subjects and retrieve contrast output image
            for sub = 1:length(conf.sub.name)
                subfolder = replace(conf.dir.spm.output, {'Sub'}, conf.sub.name(sub));

                % get flipped file if necessary
                tremside        = conf.sub.hand{sub}; % most affected hand
                if ~strcmp(tremside, 'R') && contains(conditions{cond}, 'tremor')
                    subfile     = fullfile(subfolder, ['rflipped_' infilename]); 
                else
                    subfile     = fullfile(subfolder, infilename);
                end
                                
                if ~exist(subfile, 'file')
                    fprintf('      "%s" does not exist\n', subfile);
                    continue
                end

                scans{end+1} = subfile;
                fprintf('      adding "%s"\n', subfile);
            end

            allScans{cond,med} = scans';
        end
    end
    
    % Order of the weights: [1,1]       [1,2]       [2,1]       [2,2]
    %                       coco-plac   coco-prop   rest-plac   rest-prop

    % --- Fill in SPM batch ---

    matlabbatch{1}.spm.stats.factorial_design.dir = {outfolder};

    % Create factors
    matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(1).name = 'Condition';    
    matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(1).levels = 2;        %1: coco; 2: rest
    matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(1).dept = 1;
    matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(1).variance = 1;
    matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(1).gmsca = 0;
    matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(1).ancova = 0;
    matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(2).name = 'Medication';
    matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(2).levels = 2;        %1: plac; 2: prop
    matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(2).dept = 1;
    matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(2).variance = 1;
    matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(2).gmsca = 0;
    matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(2).ancova = 0;

    % Add the scans to the right factors
    matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(1).levels = [1; 1];
    matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(1).scans = allScans{1,1}; % plac - coco

    matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(2).levels = [2; 1];
    matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(2).scans = allScans{2,1}; % plac - rest

    matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(3).levels = [1; 2];
    matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(3).scans = allScans{1,2}; % prop - coco

    matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(4).levels = [2; 2];
    matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(4).scans = allScans{2,2}; % prop - rest
    
    matlabbatch{1}.spm.stats.factorial_design.des.fd.contrasts = 1;

    % Add covariates
    conf = other_getcovariates(conf);
    fprintf('  adding covariates...\n')
    
    matlabbatch{1}.spm.stats.factorial_design.cov(1).c      = [conf.sub.FDplac conf.sub.FDprop conf.sub.FDplac conf.sub.FDprop]';
    matlabbatch{1}.spm.stats.factorial_design.cov(1).cname  = 'mean(FD)';
    matlabbatch{1}.spm.stats.factorial_design.cov(1).iCFI   = 1;
    matlabbatch{1}.spm.stats.factorial_design.cov(1).iCC    = 1;
    fprintf('    added mean(FD)\n')    
    
    matlabbatch{1}.spm.stats.factorial_design.cov(2).c      = [conf.sub.tremor conf.sub.tremor conf.sub.tremor conf.sub.tremor]';
    matlabbatch{1}.spm.stats.factorial_design.cov(2).cname  = 'Tremor';
    matlabbatch{1}.spm.stats.factorial_design.cov(2).iCFI   = 1;
    matlabbatch{1}.spm.stats.factorial_design.cov(2).iCC    = 1;
    fprintf('    added Tremorlog\n');

%     matlabbatch{1}.spm.stats.factorial_design.cov(2).c      = [conf.sub.age conf.sub.age conf.sub.age conf.sub.age]';
%     matlabbatch{1}.spm.stats.factorial_design.cov(2).cname  = 'Age';
%     matlabbatch{1}.spm.stats.factorial_design.cov(2).iCFI   = 1;
%     matlabbatch{1}.spm.stats.factorial_design.cov(2).iCC    = 1;
%     fprintf('    added Age\n');
%     
%     matlabbatch{1}.spm.stats.factorial_design.cov(3).c      = [conf.sub.gender conf.sub.gender conf.sub.gender conf.sub.gender]';
%     matlabbatch{1}.spm.stats.factorial_design.cov(3).cname  = 'Gender';
%     matlabbatch{1}.spm.stats.factorial_design.cov(3).iCFI   = 1;
%     matlabbatch{1}.spm.stats.factorial_design.cov(3).iCC    = 1;
%     fprintf('    added Gender\n');
    
    matlabbatch{1}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {});
    matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
    matlabbatch{1}.spm.stats.factorial_design.masking.im = 1;
    matlabbatch{1}.spm.stats.factorial_design.masking.em = {''};
    matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
    matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
    matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;
    
     % --- Model estimation ---
    matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep('Factorial design specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
    matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
    matlabbatch{3}.spm.stats.con.spmmat(1) = cfg_dep('Model estimation: SPM.mat File', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    

    % Main effects
    matlabbatch{3}.spm.stats.con.consess{1}.fcon.name       = 'Effects of interest';
    matlabbatch{3}.spm.stats.con.consess{1}.fcon.weights    = [1 0 0 0 
                                                               0 1 0 0 
                                                               0 0 1 0 
                                                               0 0 0 1 ];
    matlabbatch{3}.spm.stats.con.consess{1}.fcon.sessrep    = 'none';


    % Interactions
    matlabbatch{3}.spm.stats.con.consess{end+1}.tcon.name   = 'Prop>Plac, Coco>Rest';
    matlabbatch{3}.spm.stats.con.consess{end}.tcon.weights  = [-1 1 1 -1];
    matlabbatch{3}.spm.stats.con.consess{end}.tcon.sessrep  = 'none';

    matlabbatch{3}.spm.stats.con.consess{end+1}.tcon.name   = 'Plac>Prop, Coco>Rest';
    matlabbatch{3}.spm.stats.con.consess{end}.tcon.weights  = [1 -1 -1 1];
    matlabbatch{3}.spm.stats.con.consess{end}.tcon.sessrep  = 'none';

    % Other
    matlabbatch{3}.spm.stats.con.consess{end+1}.tcon.name   = 'Plac>Prop, Group';
    matlabbatch{3}.spm.stats.con.consess{end}.tcon.weights  = [1 -1 1 -1];
    matlabbatch{3}.spm.stats.con.consess{end}.tcon.sessrep  = 'none';

    matlabbatch{3}.spm.stats.con.consess{end+1}.tcon.name   = 'Plac>Prop, Coco';
    matlabbatch{3}.spm.stats.con.consess{end}.tcon.weights  = [1 -1 0 0];
    matlabbatch{3}.spm.stats.con.consess{end}.tcon.sessrep  = 'none';

    matlabbatch{3}.spm.stats.con.consess{end+1}.tcon.name   = 'Plac>Prop, Rest';
    matlabbatch{3}.spm.stats.con.consess{end}.tcon.weights  = [0 0 1 -1];
    matlabbatch{3}.spm.stats.con.consess{end}.tcon.sessrep  = 'none';

    matlabbatch{3}.spm.stats.con.consess{end+1}.tcon.name   = 'Prop>Plac, Group';
    matlabbatch{3}.spm.stats.con.consess{end}.tcon.weights  = [-1 1 -1 1];
    matlabbatch{3}.spm.stats.con.consess{end}.tcon.sessrep  = 'none';

    matlabbatch{3}.spm.stats.con.consess{end+1}.tcon.name   = 'Prop>Plac, Coco';
    matlabbatch{3}.spm.stats.con.consess{end}.tcon.weights  = [-1 1 0 0];
    matlabbatch{3}.spm.stats.con.consess{end}.tcon.sessrep  = 'none';

    matlabbatch{3}.spm.stats.con.consess{end+1}.tcon.name   = 'Prop>Plac, Rest';
    matlabbatch{3}.spm.stats.con.consess{end}.tcon.weights  = [0 0 -1 1];
    matlabbatch{3}.spm.stats.con.consess{end}.tcon.sessrep  = 'none';

    matlabbatch{3}.spm.stats.con.delete = 0;


    % --- Save batch ---
    savename = [outfolder '.mat'];
    save(savename,'matlabbatch');
    fprintf('\nsaved batch to "%s"\n', savename);

    % --- Run batch ---
    fprintf('\nrunning second-level batch now...\n');
    spm_jobman('run',matlabbatch);
    fprintf('\ndone with second-level!\n\n');
    
    clear matlabbatch

end

end