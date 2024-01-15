~~~ Pipeline ~~~ 

• ChangeMarkersAllSubs.m: Fixes a few marker problems:
	○ Checks and fixes if there's one scan marker too many. 
	○ When there are two markers at the same time, Brainvision sometimes collapses them into one other marker. This is also fixed by the script.
• EMGACC_runcluster.m: runs FARM (if it hasn't been run yet)
• EMGACC_runcluster.m: creates regressor (if it hasn't been run yet)

~~~ Analysis ~~~

ChangeMarkersAllSubs.m: For each subject that has BIDS data, it will check marker file. If necessary fixes some things.
Only runs if there's not already a file with fixed markers for this subject/session.

EMGACC_runcluster.m: Main script for FARM/creating regressor




Channels
• Normally:
	○ 1: ECR MA
	○ 2: FCR MA
	○ 3: ECR LA
	○ 4: FCR LA
	○ 5: empty
	○ 6: empty
	○ 7: TA MA (leg, only if there was a leg tremor)
	○ 8: GA MA (leg, only if there was a leg tremor)
	○ 9: Acc x
	○ 10: Acc y
	○ 11: Acc z
• For a few, 5 and 6 were used instead of 7 and 8 for TA and GA:
	○ 001-01
	○ 016-02
	○ 017-01
	○ 020-01
• For the last ones, we switched MA and LA (because channel 1 is often very noisy/doesn't give good signal in behavior 3 lab)
	○ 002
	○ 027-02
	○ 028
	○ 030
	○ 063
	○ 064
	○ 065
	○ 057-060
• 006-02 was recorded in a different workspace during scanning so is a bit different when creating a regressor (see EmgChannelsMeasured.m for specifics)
• 019 had very clear tremor in both legs, so both legs were recorded (channel 5 and 6 were used for LA leg)
