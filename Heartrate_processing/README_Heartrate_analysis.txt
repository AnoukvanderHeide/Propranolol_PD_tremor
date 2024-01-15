First visually check the data in HERA GUI (clear pulses, range between ~45-80 bpm)

~~~ Pipeline ~~~
heartrate_batch.m is the main script that calls the other ones.

Steps for each data set:
	1. Convert .eeg file to .puls file.
	2. Go over the .puls file in HERA.
	3. Create regressors (and plot them) and create average regressor.

~~~ Analysis ~~~
heartrate_batch.m: main script that calls different functions.
• For each data set:
	Convert  .eegfile to .pulsfile.
	(Go over the .pulsfile in HERA => not done in the batch script.)
	Create regressors.
	Then it gives a list of the data sets that gave errors.
	Calculate and plot average regressor.

Scripts in brainampconverter folder: convert .eeg files to .puls files. 
• Converts the input file 
• Saves output to the output folder (conf.dir.reform if run from batch script)

Scripts in hera folder: run hera.m to open the HERA GUI and go over the files.
• Run hera.m to open GUI. 
• Load the file you want to look at
• What you see: Black line: pulse recordings
		Red line: inter-beat intervals
		Grey vertical lines: peaks detected
		Blue bars: scan trigger pulses
• If needed, change stuff and save file
	Change the automatically detected peaks with the red buttons
	(un)reject parts of the data with the yellow buttons (Rejected data will be interpolated when creating regressor)	

Scripts in RETROICORplus folder:
• RETROICORplus interpolates over rejected data, then creates regressors based on this data and stores it in conf.dir.regressor
• Notes
	RETROICORplus creates many different regressors. 
	 □ 1-10: Cardiac phase regressors (assuming you use 5th order Fourier modeling for cardiac phase, this is set in RETROICORplus_defaults_setup).
	 □ 11-20: Respiratory phase regressors (assuming you use 5th order Fourier modeling for cardiac phase, this is set in RETROICORplus_defaults_setup).
	 □ 21-23: Heart rate frequency (one HR frequency regressor per time lag defined in RETROICORplus_defaults_setup). 
	 □ 24-25 RVT: Respiratory volume per unit time (i.e., frequency times amplitude of respiration, averaged per TR using a 9-s window), with one regressor per time lag defined in RETROICORplus_defaults_setup)
		- Because of the time shift of 0 that is added for the heart rate, it's actually 21-24 for the HRF and 25-26 for the RVT. 

heartrate_plotregressor.m: plots a regressor from a subject/session and saves it as a .jpg in conf.dir.regrplot
heartrate_average.m: creates an average of all data sets
• Gathers all available data sets (that are of good quality)
• Averages over sessions (if there are multiple good-quality data sets for one subject)
• Averages over subjects
• Stores average in conf.dir.average