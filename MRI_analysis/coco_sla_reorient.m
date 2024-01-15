function coco_sla_reorient(conf)
%coco_sla_reorient.m flips output images from one side so all output images
%have tremor activation on the same side. Only for people with tremor on
%left side, and only relevant for tremor contrasts

% Get subjects with tremor on "wrong" side
subjects    = conf.sub.name(~contains(conf.sub.hand, 'R')); % side on which tremor will be (subjects with tremor on other side will have output images flipped)

% Get all contrasts about tremor (so the ones that need to be flipped)
contrastNames   = {conf.fla.con.contrasts(:).name};
contrastsToFlip = find(contains(contrastNames, 'tremor'));
nrFcon = length(conf.fla.con.fcontrasts); % the number of F-contrasts that are included (are in the list of contrasts before t-contrasts)

fprintf('reorienting images\n');

% --- Collect all contrast images that need to be flipped ---
allfilesOriginal = {};
allfilesToFlip = {};

for con = 1:length(contrastsToFlip)
    idxCon = contrastsToFlip(con); % get index of contrast in list of all tremor contrasts
    CurCon = contrastNames{idxCon}; % get contrast name
    Con_touse = idxCon + nrFcon; % add to nr. of F contrasts in the first level folder
    contrastCodes = cellstr(num2str(( Con_touse*3-2:Con_touse*3)', '%04.f'));
    %contrastCodes = cellstr(num2str(( idxCon*3-2:idxCon*3)', '%04.f'));
   
    fprintf('  looking for images from the contrast "%s" (con_%s  con_%s  con_%s)\n', CurCon, contrastCodes{:});
    
    fileNames   = strcat(conf.fla.spec.output.dir, '/', 'con_', contrastCodes, '.nii'); % input directory (the directory where subject contrast images are stored)
    
    for sub = 1:length(subjects)
        subfiles = replace(fileNames, 'Sub', subjects{sub});
        newfiles = insertAfter(subfiles, 'results/', 'flipped_');
        % Only add the ones that don't exist yet
        filesToAdd = subfiles(~isfile(newfiles));
        
        allfilesOriginal    = [allfilesOriginal; subfiles];      % necessary for reslice batch
        allfilesToFlip      = [allfilesToFlip;   filesToAdd];
        pat = repmat('    added %s\n', 1, length(filesToAdd));
        fprintf(pat, filesToAdd{:});
    end 
end

if isempty(allfilesToFlip)
    fprintf('    all images have been flipped already');
end

% --- Create reorient batch ---
matlabbatch{1}.spm.util.reorient.srcfiles           = allfilesToFlip;
matlabbatch{1}.spm.util.reorient.transform.transM   = [
           -1 0 0 0
            0 1 0 0
            0 0 1 0
            0 0 0 1];
matlabbatch{1}.spm.util.reorient.prefix = 'r';

fprintf('reslicing images\n');
        
% --- Create reslice batch ---
allfilesReoriented         = insertAfter(allfilesOriginal, 'results/', 'flipped_');
allfilesReorientedResliced = insertAfter(allfilesOriginal, 'results/', ['r' 'flipped_']);
scans   = allfilesReoriented(~isfile(allfilesReorientedResliced));
pat = repmat('    added %s\n', 1, length(scans));
fprintf(pat, scans{:});

% Add first scan as reference (a non-flipped one)
if ~isempty(scans)
    scans = [erase(scans{1}, 'flipped_'); scans];
end

% Create batch
matlabbatch{2}.spm.spatial.realign.write.data               = scans;
matlabbatch{2}.spm.spatial.realign.write.roptions.which     = [1 0];   % default = [2 1]
matlabbatch{2}.spm.spatial.realign.write.roptions.interp    = 4;
matlabbatch{2}.spm.spatial.realign.write.roptions.wrap      = [0 0 0]; % default = [0 0 0] 
matlabbatch{2}.spm.spatial.realign.write.roptions.mask      = 1;
matlabbatch{2}.spm.spatial.realign.write.roptions.prefix    = 'r';

% If all images have been both reoriented and resliced => skip
if isempty(matlabbatch{1}.spm.util.reorient.srcfiles) & isempty(matlabbatch{2}.spm.spatial.realign.write.data)
    fprintf('\nall images have been flipped already\n');
    return
end
   
% --- Store batch ---
filename = insertBefore(conf.file.spm.batch.reorient, '.mat', ['-' replace(char(datetime('now')), {':', ' '}, {'.', '-'})]);
savename = fullfile(conf.dir.spm.group, filename);
save(savename,'matlabbatch');
fprintf('\nreorient batch saved to "%s"\n', savename);

% --- Run the batch ---
fprintf('\nrunning reorienting batch now...\n');
spm_jobman('run',matlabbatch);
fprintf('\ndone with reorienting!\n\n');

end
