~~~ Data quality ~~~ 

• We only selected participants who have less than 25% drop in eyetracking (pupil diamter < 880 arbitrary unit)
• Epochs in which >40% of the samples showed either a drop in eyetracking (diameter < 880 arbitrary unit) or high variability (+/- 3SD outside the epoch mean) were discarded
• Interpolated over the discarded epochs

~~~ Pipeline ~~~

eyelink_batch.m is the main script that calls the other ones. 
• Steps for each data set: 1. Convert .ascfile to .matfile. 2. Create a regressor (plot it and save as .matfile)
• Then there's also the option to create average regressor and compile data quality information

~~~ Analysis ~~~

eyelink_batch.m: main script that calls different functions. 
• Converts .ascfile to .matif it hasn't been done already
• Creates regressor(s) and looks at data quality
	○ Collect data quality of separate datasets into one structure
	○ Calculate average regressor

Raw data (.asc) was reformatted already to a matlab file (.mat)!

eyelink_regressor.m: creates regressor
• dq.data: % of drops and % of spikes (calls eyelink_spikecheck.m to get these values)
• dq.epoch: for each epoch (whether or not it was discarded while creating the regressors; aka whether it was interpolated over)
	    the % of artifacts in this epoch (if this % is higher than a certain threshold, it will be discarded and interpolated over)
• Notes:
	The eyelink file doesn't have scantriggers, so the brainvision files have to be used to calculate where the scantriggers should be in this data.
	eyelink_getstartcondition.m returns some values that are needed to calculate the scan triggers

eyelink_dataquality.m: collects all the information about the data quality of the individual data sets and stores them in one structure

eyelink_average.m: creates average. First averages over sessions to create an average per subject. Then averages over subjects. 
