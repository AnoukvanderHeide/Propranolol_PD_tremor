% This script gives the mean parameter estimates for the selected SPM.mat files in
% the defined ROIs, per subject per condition (so for 2x2 design 4 estimates per subject)
clear

addpath('/project/3024005.02/Analysis/MRI/scripts/');
conf = coco_conf();

% Define all ROIs and SPM output folders
ROI_files = {fullfile(conf.tfce.dir.ROIs,'resliced_L_MC_pos_-28_-26_62.nii');...
             fullfile(conf.tfce.dir.ROIs,'resliced_R_CBLM_pos_18_-50_-20.nii');...
             fullfile(conf.tfce.dir.ROIs,'resliced_L_VLpv.nii');...
             fullfile(conf.tfce.dir.ROIs,'studyspec_L_MC_-33_-29_58.nii');...
             fullfile(conf.tfce.dir.ROIs,'studyspec_R_CRBL_11_-51_-20.nii')};
             
SPM_dir = {[conf.dir.spm.main, '/second-level_2x2_FDtremor/taskxdrug(tremoramp)/'];...
           [conf.dir.spm.main, '/second-level_paired_FDtremor/drug_tremoramp/']};
       
ROI_data = [];
ROI_paired = [];

for model = 1:length(SPM_dir)
    
    for roi = 1:length(ROI_files)
        ROI = ROI_files{roi};
        cd(SPM_dir{model,1});
        load SPM;
        
        % SPM: get ROI coordinates
        Y = spm_read_vols(spm_vol(ROI),1);
        indx = find(Y>0);
        [x,y,z] = ind2sub(size(Y),indx);
        XYZ = [x y z]';

            % SPM: get one estimate per condition per subject (92 values for 2x2 design, 46 for paired design)
            if      strcmp(SPM_dir{model}(58:63), 'paired')== 0
                    ROI_data(:,end+1) = nanmean(spm_get_data(SPM.xY.P, XYZ),2);
            elseif  strcmp(SPM_dir{model}(58:63), 'paired')== 1
                    ROI_paired(:,end+1) = nanmean(spm_get_data(SPM.xY.P, XYZ),2);
            end
    end
    
    if strcmp(SPM_dir{model}(58:63), 'paired')== 0
        
        % Put data in order per condition and medication factor in wide format file
        % Order: 1-23: coco-plac; 24-46: coco-prop; 47-69: rest-plac; 70-92: rest-prop
        data.MC_coco_plac = ROI_data(1:23,1);
        data.MC_coco_prop = ROI_data(24:46,1);
        data.MC_rest_plac = ROI_data(47:69,1);
        data.MC_rest_prop = ROI_data(70:92,1);
        data.CRBL_coco_plac = ROI_data(1:23,2);
        data.CRBL_coco_prop = ROI_data(24:46,2);
        data.CRBL_rest_plac = ROI_data(47:69,2);
        data.CRBL_rest_prop = ROI_data(70:92,2);
        data.VLpv_coco_plac = ROI_data(1:23,3);
        data.VLpv_coco_prop = ROI_data(24:46,3);
        data.VLpv_rest_plac = ROI_data(47:69,3);
        data.VLpv_rest_prop = ROI_data(70:92,3);
        data.MCstu_coco_plac = ROI_data(1:23,4);
        data.MCstu_coco_prop = ROI_data(24:46,4);
        data.MCstu_rest_plac = ROI_data(47:69,4);
        data.MCstu_rest_prop = ROI_data(70:92,4);
        data.CRBLstu_coco_plac = ROI_data(1:23,5);
        data.CRBLstu_coco_prop = ROI_data(24:46,5);
        data.CRBLstu_rest_plac = ROI_data(47:69,5);
        data.CRBLstu_rest_prop = ROI_data(70:92,5);

        eval(['Table_' num2str(model) '=struct2table(data);']);
        clear data
        
        % Make long format file for separate analysis in R
        data2.MC = ROI_data(:,1);
        data2.CRBL = ROI_data(:,2);
        data2.VLpv = ROI_data(:,3);
        data2.MCstu = ROI_data(:,4);
        data2.CRBLstu = ROI_data(:,5);
        
        eval(['Table_long_' num2str(model) '=struct2table(data2);']);
        clear data2
        
    elseif strcmp(SPM_dir{model}(58:63), 'paired')== 1

        % Put in order per medication
        % Order: odd numbers placebo, even numbers propranolol
        data.MC_plac = ROI_paired(1:2:46,1); % MC placebo
        data.MC_prop = ROI_paired(2:2:46,1); % MC propranolol
        data.CRBL_plac = ROI_paired(1:2:46,2); % CRBL placebo
        data.CRBL_prop = ROI_paired(2:2:46,2); % CRBL propranolol
        data.VLpv_plac = ROI_paired(1:2:46,3); % VLpv placebo
        data.VLpv_prop = ROI_paired(2:2:46,3); % VLpv propranolol
        data.MCstu_plac = ROI_paired(1:2:46,4); % MC placebo study specific
        data.MCstu_prop = ROI_paired(2:2:46,4); % MC propranolol study specific
        data.CRBLstu_plac = ROI_paired(1:2:46,5); % CRBL placebo study specific
        data.CRBLstu_prop = ROI_paired(2:2:46,5); % CRBL propranolol study specific

        eval(['Table_' num2str(model) '=struct2table(data);']);
        clear data
        
        % Make long format file for separate analysis in R
        data2.MC = ROI_paired(:,1);
        data2.CRBL = ROI_paired(:,2);
        data2.VLpv = ROI_paired(:,3);
        data2.MCstu = ROI_paired(:,4);
        data2.CRBLstu = ROI_paired(:,5);
        
        eval(['Table_long_' num2str(model) '=struct2table(data2);']);
        clear data2
        
    end
    
end

filename_wide = fullfile(conf.dir.MRI, 'results', 'betas', 'Betas_all_wide.xlsx');
filename_long = fullfile(conf.dir.MRI, 'results', 'betas', 'Betas_all_long.xlsx');

writetable(Table_1,filename_wide,'sheet',1,'Range','A1')
writetable(Table_2,filename_wide,'sheet',2,'Range','A1')
writetable(Table_long_1,filename_long,'sheet',1,'Range','A1')
writetable(Table_long_2,filename_long,'sheet',2,'Range','A1')
 