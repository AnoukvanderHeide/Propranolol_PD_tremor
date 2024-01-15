Main batch script called coco_batch_main.m, that calls all the other scripts. Here you have to choose between running first or second level and running on cluster or not.

Steps first level (steps can be skipped by changing it in coco_conf.m):
	• Unzip images (coco_fla_unzip.m)
	• Smooth images with 6 FWHM (coco_fla_smooth.m)
	• Create a condition file (coco_fla_combicond.m)
		○ Accelerometer data used for tremor pmod (if not otherwise specified)
		○ Condition file per session per condition (coco and rest separate) in /project/3024005.02/Analysis/MRI/output_spm/first-level/model_conditions_Sub-Ses.mat
		○ Order of regressors:
		1: coco
		2: coco-ACC-amp 
		3: coco-ACC-change
		4: rest
		5: rest-ACC-amp 
		6: rest-ACC-change
	• Create a regressor file, combining regressors into one file for the GLM (coco_fla_combiregr.m)
		○ Regressor file per session in /project/3024005.02/Analysis/MRI/output_spm/first-level/model_regressors_Sub-Ses.mat
		○ Regressors in file:
			§ First: FD, std_dvars, CSF, white matter regressors
			§ 24 motion parameters
			§ ICA-AROMA components (created with fmriprep)
	• Create and run first-level batch (coco_fla_run.m)

Steps second level:
	• Flip images of patients with left-sided tremor (coco_sla_reorient.m)
	• Create and run second-level batch (coco_sla_2x2.m, coco_sla_paired.m or coco_sla_onesampled.m)

General notes:
In first level scripts, session order is updated so that 1st session is always placebo, 2nd is propranolol for everyone.