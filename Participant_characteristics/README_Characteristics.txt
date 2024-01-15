ButtonBox_GetScores.m: collects the score and stores them in excel and matlab files
	• When more than one presentation file is found, it will ask which one to use

ButtonBox_Analysis.m: uses the matlab file to analyze the data. 
	• Runs rm-ANOVA t-tests for BLOCK*DRUG
        • Prints results

TableCreate.m: creates a table with all the data
	• Collects all data from castor file and LEDD file and puts it in a table
	• Also calculates UPDRS (sub-)scores
	• Saves table as excel and matlab files

TablePrint.m: uses the table created by TableCreate.mand creates a table with counts and means/SDs
There are two sets of settings, one for when you include the whole dataset with non-tremor and tremor-dominant participants, and one where only tremor-dominant participants are included.