
function coco_secondLevel_onesampled(conf)

% Get output folder
conf.dir.spm.group = fullfile(conf.dir.MRI, 'output_spm', 'second-level_one_sampled');
outfolder  = fullfile(conf.dir.spm.group, 'tremor');
if ~exist(outfolder,'dir'); mkdir(outfolder); end
fprintf('\n  folder: %s\n', outfolder);

contrasts     = conf.fla.con.contrasts;
contrastNames = {contrasts(:).name};
nrFcon = length(conf.fla.con.fcontrasts); % the number of F-contrasts that are included (are in the list of contrasts before t-contrasts)
    
scans = {};

% Get the right contrast
idxCon = find(strcmp(contrastNames, 'all_tremoramp')); % contrasts con_0025 con_0026 con_0027
idx    = (idxCon-1) * 3 + nrFcon*3 + 3;
contrastcode    = ['con_' num2str(idx,'%04.f')];
infilename = [contrastcode '.nii'];
fprintf('    contrast code: %s\n', contrastcode); % use con_0027, which is average of ses1 and ses2

% Loop over subjects and retrieve contrast output image
for sub = 1:length(conf.sub.name)
    subfolder = replace(conf.dir.spm.output, {'Sub'}, conf.sub.name(sub));

    % get flipped file if necessary
    tremside    = conf.sub.hand{sub}; % most affected hand
    if ~strcmp(tremside, 'R')
        subfile = fullfile(subfolder, ['rflipped_' infilename]); 
    else
        subfile = fullfile(subfolder, infilename);
    end

    if ~exist(subfile, 'file')
        fprintf('      "%s" does not exist\n', subfile);
        continue
    end

    scans{end+1} = subfile;
    fprintf('      adding "%s"\n', subfile);
end

scans = scans';

% --- Fill in SPM batch ---

matlabbatch{1}.spm.stats.factorial_design.dir = {outfolder};
matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = [scans];
matlabbatch{1}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});

% Add covariates to matlabbatch

conf = other_getcovariates(conf); % Add covariate info


matlabbatch{1}.spm.stats.factorial_design.cov(1).c      = [conf.sub.FD]'; % correct for mean FD for all participants (averaged over sessions)
matlabbatch{1}.spm.stats.factorial_design.cov(1).cname  = 'mean(FD)';
matlabbatch{1}.spm.stats.factorial_design.cov(1).iCFI   = 1;
matlabbatch{1}.spm.stats.factorial_design.cov(1).iCC    = 1;
fprintf('    added mean(FD)\n')

matlabbatch{1}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.im = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.em = {''};
matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;

% Estimate
matlabbatch{2}.spm.stats.fmri_est.spmmat = cfg_dep('Factorial design specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
matlabbatch{3}.spm.stats.con.spmmat(1) = cfg_dep('Model estimation: SPM.mat File', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
% in case of error that cfg_dep is unknown, first run matlabbatch with spm_jobman for the design settings
        
% --- Contrasts ---
matlabbatch{3}.spm.stats.con.consess{1}.tcon.name   = 'tremor';
matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights    = [1]; 
matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep    = 'none';
matlabbatch{3}.spm.stats.con.delete                     = 0;

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