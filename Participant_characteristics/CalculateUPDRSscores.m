function Table = CalculateUPDRSscores(Table, UPDRS, MA_arm, MA_leg)
%CalculateUPDRSscores.m Calculates UPDRS scores (bradykinesia + rigidity,
%axial, rest tremor, postural tremor, kinetic tremor) and stores them in
%Table
% Inputs: 
%   Table   : table where the scores will be stored
%   UPDRS   : table with the UPDRS subscores
%   MA_arm  : list with for each subject which arm is MA
%   MA_leg  : list with for each subject which leg is MA
% Outputs: 
%   Table   : same as input table but now with the new UPDRS scores added


    % --- Limb bradykinesia + limb rigidity: item 3 (excl. neck), 4-8 ---

    % = Total = 

    bradyrig.values.day1 = [ 
        UPDRS.UPDRS_rig_rue_1       UPDRS.UPDRS_rig_lue_1       ... %item 3: rigidity (upper extremities)
        UPDRS.UPDRS_rig_rle_1       UPDRS.UPDRS_rig_lle_1       ... %item 3: rigidity (lower extremities)
        UPDRS.UPDRS_fing_r_1        UPDRS.UPDRS_fing_l_1        ... %item 4: finger tapping
        UPDRS.UPDRS_hand_mov_r_1    UPDRS.UPDRS_hand_mov_l_1    ... %item 5: hand movements
        UPDRS.UPDRS_pron_sup_r_1    UPDRS.UPDRS_pron_sup_l_1    ... %item 6: pronation-supination
        UPDRS.UPDRS_toe_r_1         UPDRS.UPDRS_toe_l_1         ... %item 7: toe tapping
        UPDRS.UPDRS_leg_ag_r_1      UPDRS.UPDRS_leg_ag_l_1 ];       %item 8: leg agility
    bradyrig.total.day1 = nansum( bradyrig.values.day1, 2);
    bradyrig.total.day1(all(isnan(bradyrig.values.day1),2)) = "NaN";
    bradyrig.values.day2 = [ 
        UPDRS.UPDRS_rig_rue_2       UPDRS.UPDRS_rig_lue_2       ... %item 3: rigidity (upper extremities)
        UPDRS.UPDRS_rig_rle_2       UPDRS.UPDRS_rig_lle_2       ... %item 3: rigidity (lower extremities)
        UPDRS.UPDRS_fing_r_2        UPDRS.UPDRS_fing_l_2        ... %item 4: finger tapping
        UPDRS.UPDRS_hand_mov_r_2    UPDRS.UPDRS_hand_mov_l_2    ... %item 5: hand movements
        UPDRS.UPDRS_pron_sup_r_2    UPDRS.UPDRS_pron_sup_l_2    ... %item 6: pronation-supination
        UPDRS.UPDRS_toe_r_2         UPDRS.UPDRS_toe_l_2         ... %item 7: toe tapping
        UPDRS.UPDRS_leg_ag_r_2      UPDRS.UPDRS_leg_ag_l_2 ];       %item 8: leg agility
    bradyrig.total.day2  = nansum(bradyrig.values.day2, 2);
    bradyrig.total.day2(all(isnan(bradyrig.values.day2),2)) = "NaN";
    Table.B_and_R = nanmean([bradyrig.total.day1 bradyrig.total.day2],2);

    % = Most affected and least affected =

    bradyrig.values.arm.r.day1 = [ 
        UPDRS.UPDRS_rig_rue_1    ...  %item 3: rigidity (right upper)
        UPDRS.UPDRS_fing_r_1     ...  %item 4: finger tapping (right)
        UPDRS.UPDRS_hand_mov_r_1 ...  %item 5: hand movements (right)
        UPDRS.UPDRS_pron_sup_r_1];    %item 6: pronation-supination (right)
    bradyrig.arm.r.day1  = nansum([ bradyrig.values.arm.r.day1 ], 2);
    bradyrig.arm.r.day1(all(isnan(bradyrig.values.arm.r.day1),2)) = "NaN";
    bradyrig.values.arm.l.day1 = [ 
        UPDRS.UPDRS_rig_lue_1    ...  %item 3: rigidity (left upper)
        UPDRS.UPDRS_fing_l_1     ...  %item 4: finger tapping (left)
        UPDRS.UPDRS_hand_mov_l_1 ...  %item 5: hand movements (left)
        UPDRS.UPDRS_pron_sup_l_1];    %item 6: pronation-supination (left)
    bradyrig.arm.l.day1  = nansum([ bradyrig.values.arm.l.day1 ], 2);
    bradyrig.arm.l.day1(all(isnan(bradyrig.values.arm.l.day1),2)) = "NaN";
    bradyrig.values.leg.r.day1 = [ 
        UPDRS.UPDRS_rig_rle_1    ...  %item 3: rigidity (right lower)
        UPDRS.UPDRS_toe_r_1      ...  %item 7: toe tapping (right)
        UPDRS.UPDRS_leg_ag_r_1];      %item 8: leg agility (right)
    bradyrig.leg.r.day1  = nansum([ bradyrig.values.leg.r.day1 ], 2);
    bradyrig.leg.r.day1(all(isnan(bradyrig.values.leg.r.day1),2)) = "NaN";
    bradyrig.values.leg.l.day1 = [ 
        UPDRS.UPDRS_rig_lle_1    ...  %item 3: rigidity (left lower)
        UPDRS.UPDRS_toe_l_1      ...  %item 7: toe tapping (left)
        UPDRS.UPDRS_leg_ag_l_1];      %item 8: leg agility (left)
    bradyrig.leg.l.day1  = nansum([ bradyrig.values.leg.l.day1 ], 2);
    bradyrig.leg.l.day1(all(isnan(bradyrig.values.leg.l.day1),2)) = "NaN";
    bradyrig.values.arm.r.day2 = [ 
        UPDRS.UPDRS_rig_rue_2    ...  %item 3: rigidity (right upper)
        UPDRS.UPDRS_fing_r_2     ...  %item 4: finger tapping (right)
        UPDRS.UPDRS_hand_mov_r_2 ...  %item 5: hand movements (right)
        UPDRS.UPDRS_pron_sup_r_2];    %item 6: pronation-supination (right)
    bradyrig.arm.r.day2  = nansum([ bradyrig.values.arm.r.day2 ], 2);
    bradyrig.arm.r.day2(all(isnan(bradyrig.values.arm.r.day2),2)) = "NaN";
    bradyrig.values.arm.l.day2 = [ 
        UPDRS.UPDRS_rig_lue_2    ...  %item 3: rigidity (left upper)
        UPDRS.UPDRS_fing_l_2     ...  %item 4: finger tapping (left)
        UPDRS.UPDRS_hand_mov_l_2 ...  %item 5: hand movements (left)
        UPDRS.UPDRS_pron_sup_l_2];    %item 6: pronation-supination (left)
    bradyrig.arm.l.day2  = nansum([ bradyrig.values.arm.l.day2 ], 2);
    bradyrig.arm.l.day2(all(isnan(bradyrig.values.arm.l.day2),2)) = "NaN";
    bradyrig.values.leg.r.day2 = [ 
        UPDRS.UPDRS_rig_rle_2    ...  %item 3: rigidity (right lower)
        UPDRS.UPDRS_toe_r_2      ...  %item 7: toe tapping (right)
        UPDRS.UPDRS_leg_ag_r_2];      %item 8: leg agility (right)
    bradyrig.leg.r.day2  = nansum([ bradyrig.values.leg.r.day2 ], 2);
    bradyrig.leg.r.day2(all(isnan(bradyrig.values.leg.r.day2),2)) = "NaN";
    bradyrig.values.leg.l.day2 = [ 
        UPDRS.UPDRS_rig_lle_2    ...  %item 3: rigidity (left lower)
        UPDRS.UPDRS_toe_l_2      ...  %item 7: toe tapping (left)
        UPDRS.UPDRS_leg_ag_l_2];      %item 8: leg agility (left)
    bradyrig.leg.l.day2  = nansum([ bradyrig.values.leg.l.day2 ], 2);
    bradyrig.leg.l.day2(all(isnan(bradyrig.values.leg.l.day2),2)) = "NaN";

    % Set most and least affected to correct arm/leg
    bradyrig.arm.MA.day1 = bradyrig.arm.l.day1;     
    bradyrig.arm.MA.day1(MA_arm == 2) = bradyrig.arm.r.day1(MA_arm == 2);
    bradyrig.arm.MA.day1(MA_arm == 3) = NaN;
    bradyrig.leg.MA.day1 = bradyrig.leg.l.day1;     
    bradyrig.leg.MA.day1(MA_leg == 2) = bradyrig.leg.r.day1(MA_leg == 2);
    bradyrig.leg.MA.day1(MA_leg == 3) = NaN;
    bradyrig.arm.MA.day2 = bradyrig.arm.l.day2;     
    bradyrig.arm.MA.day2(MA_arm == 2) = bradyrig.arm.r.day2(MA_arm == 2);
    bradyrig.arm.MA.day2(MA_arm == 3) = NaN;
    bradyrig.leg.MA.day2 = bradyrig.leg.l.day2;     
    bradyrig.leg.MA.day2(MA_leg == 2) = bradyrig.leg.r.day2(MA_leg == 2);
    bradyrig.leg.MA.day2(MA_leg == 3) = NaN;
    bradyrig.arm.LA.day1 = bradyrig.arm.r.day1;     
    bradyrig.arm.LA.day1(MA_arm == 2) = bradyrig.arm.l.day1(MA_arm == 2);
    bradyrig.arm.LA.day1(MA_arm == 3) = NaN;
    bradyrig.leg.LA.day1 = bradyrig.leg.r.day1;     
    bradyrig.leg.LA.day1(MA_leg == 2) = bradyrig.leg.l.day1(MA_leg == 2);
    bradyrig.leg.LA.day1(MA_leg == 3) = NaN;
    bradyrig.arm.LA.day2 = bradyrig.arm.r.day2;     
    bradyrig.arm.LA.day2(MA_arm == 2) = bradyrig.arm.l.day2(MA_arm == 2);
    bradyrig.arm.LA.day2(MA_arm == 3) = NaN;
    bradyrig.leg.LA.day2 = bradyrig.leg.r.day2;
    bradyrig.leg.LA.day2(MA_leg == 2) = bradyrig.leg.l.day2(MA_leg == 2);
    bradyrig.leg.LA.day2(MA_leg == 3) = NaN;

    % Sum upper and lower together
    bradyrig.values.MA.day1 = [bradyrig.arm.MA.day1, bradyrig.leg.MA.day1];
    bradyrig.MA.day1  = nansum( bradyrig.values.MA.day1, 2);
    bradyrig.MA.day1(all(isnan(bradyrig.values.MA.day1),2)) = "NaN";
    bradyrig.values.LA.day1 = [bradyrig.arm.LA.day1, bradyrig.leg.LA.day1];
    bradyrig.LA.day1  = nansum( bradyrig.values.LA.day1, 2);
    bradyrig.LA.day1(all(isnan(bradyrig.values.LA.day1),2)) = "NaN";
    bradyrig.values.MA.day2 = [bradyrig.arm.MA.day2, bradyrig.leg.MA.day2];
    bradyrig.MA.day2  = nansum( bradyrig.values.MA.day2, 2);
    bradyrig.MA.day2(all(isnan(bradyrig.values.MA.day2),2)) = "NaN";
    bradyrig.values.LA.day2 = [bradyrig.arm.LA.day2, bradyrig.leg.LA.day2];
    bradyrig.LA.day2  = nansum( bradyrig.values.LA.day2, 2);
    bradyrig.LA.day2(all(isnan(bradyrig.values.LA.day2),2)) = "NaN";

    % Average over the two sessions
    Table.B_and_R_MA = nanmean([bradyrig.MA.day1 bradyrig.MA.day2],2);
    Table.B_and_R_LA = nanmean([bradyrig.LA.day1 bradyrig.LA.day2],2);


    % --- Axial: items 1, 2, 3 (neck), 9-14 ---

    axial.values.day1 = [ 
        UPDRS.UPDRS_speech_1    UPDRS.UPDRS_face_1      ...     %item 1:  speech              item 2: facial expression
        UPDRS.UPDRS_chair_1     UPDRS.UPDRS_gait_1      ...     %item 9:  arising from chair  item 10: gait
        UPDRS.UPDRS_freeze_1    UPDRS.UPDRS_post_stab_1 ...     %item 11: freezing of gait    item 12: postural stability
        UPDRS.UPDRS_post_1      UPDRS.UPDRS_spont_1     ...     %item 13: posture             item 14: global spontaneity of movements  
        UPDRS.UPDRS_rig_neck_1 ];                               %item 3:  rigidity (neck)
    axial.total.day1  = nansum(axial.values.day1,2);
    axial.total.day1(all(isnan(axial.values.day1),2)) = "NaN";
    axial.values.day2 = [ 
        UPDRS.UPDRS_speech_2    UPDRS.UPDRS_face_2      ...     %item 1:  speech              item 2: facial expression
        UPDRS.UPDRS_chair_2     UPDRS.UPDRS_gait_2      ...     %item 9:  arising from chair  item 10: gait
        UPDRS.UPDRS_freeze_2    UPDRS.UPDRS_post_stab_2 ...     %item 11: freezing of gait    item 12: postural stability
        UPDRS.UPDRS_post_2      UPDRS.UPDRS_spont_2     ...     %item 13: posture             item 14: global spontaneity of movements
        UPDRS.UPDRS_rig_neck_2 ];                               %item 3:  rigidity (neck)
    axial.total.day2  = nansum(axial.values.day2,2);
    axial.total.day2(all(isnan(axial.values.day2),2)) = "NaN";
    Table.Axial = nanmean([axial.total.day1 axial.total.day2],2);


    % --- Rest tremor: sum of item 17 (excl. lip/jaw) and item 18 ---
    % = Total = 

    tremor.values.day1 = [ 
        UPDRS.UPDRS_rue_1   UPDRS.UPDRS_lue_1   ...     %item 17: rest tremor amplitude (upper)
        UPDRS.UPDRS_rle_1   UPDRS.UPDRS_lle_1   ...     %item 17: rest tremor amplitude (lower)
        UPDRS.UPDRS_const_1 ];                          %item 18: constancy of rest tremor
    tremor.total.day1  = nansum(tremor.values.day1,2);
    tremor.total.day1(all(isnan(tremor.values.day1),2)) = "NaN";
    tremor.values.day2 = [ 
        UPDRS.UPDRS_rue_2   UPDRS.UPDRS_lue_2   ...     %item 17: rest tremor amplitude (upper)
        UPDRS.UPDRS_rle_2   UPDRS.UPDRS_lle_2   ...     %item 17: rest tremor amplitude (lower)
        UPDRS.UPDRS_const_2 ];                          %item 18: constancy of rest tremor
    tremor.total.day2  = nansum(tremor.values.day2,2);
    tremor.total.day2(all(isnan(tremor.values.day2),2)) = "NaN";

    Table.Rest_tremor = nanmean([tremor.total.day1 tremor.total.day2],2);


    % --- Rest tremor: sum of item 17 (excl. lip/jaw) and item 18 ---
    % = Most affected, least affected, and constancy =

    tremor.arm.l.day1 = UPDRS.UPDRS_lue_1;      tremor.arm.l.day2 = UPDRS.UPDRS_lue_2;      %item 17: rest tremor amplitude (left upper)
    tremor.arm.r.day1 = UPDRS.UPDRS_rue_1;      tremor.arm.r.day2 = UPDRS.UPDRS_rue_2;     %item 17: rest tremor amplitude (right upper)
    tremor.leg.l.day1 = UPDRS.UPDRS_lle_1;      tremor.leg.l.day2 = UPDRS.UPDRS_lle_2;     %item 17: rest tremor amplitude (left lower)
    tremor.leg.r.day1 = UPDRS.UPDRS_rle_1;      tremor.leg.r.day2 = UPDRS.UPDRS_rle_2;     %item 17: rest tremor amplitude (right lower)
    tremor.const.day1 = UPDRS.UPDRS_const_1;    tremor.const.day2 = UPDRS.UPDRS_const_2;    %item 18: constancy of rest tremor

    % Add constancy
    Table.Rest_tremor_constancy = nanmean([tremor.const.day1 tremor.const.day2], 2);

    % Set most and least affected to correct arm/leg
    tremor.arm.MA.day1 = tremor.arm.l.day1;
    tremor.arm.MA.day1(MA_arm == 2) = tremor.arm.r.day1(MA_arm == 2);
    tremor.arm.MA.day1(MA_arm == 3) = NaN;
    tremor.arm.MA.day2 = tremor.arm.l.day2;
    tremor.arm.MA.day2(MA_arm == 2) = tremor.arm.r.day2(MA_arm == 2);
    tremor.arm.MA.day2(MA_arm == 3) = NaN;
    tremor.leg.MA.day1 = tremor.leg.l.day1;
    tremor.leg.MA.day1(MA_leg == 2) = tremor.leg.r.day1(MA_leg == 2);
    tremor.leg.MA.day1(MA_leg == 3) = NaN;
    tremor.leg.MA.day2 = tremor.leg.l.day2;
    tremor.leg.MA.day2(MA_leg == 2) = tremor.leg.r.day2(MA_leg == 2);
    tremor.leg.MA.day2(MA_leg == 3) = NaN;
    tremor.arm.LA.day1 = tremor.arm.r.day1;     
    tremor.arm.LA.day1(MA_arm == 2) = tremor.arm.l.day1(MA_arm == 2);
    tremor.arm.LA.day1(MA_arm == 3) = NaN;
    tremor.arm.LA.day2 = tremor.arm.r.day2;     
    tremor.arm.LA.day2(MA_arm == 2) = tremor.arm.l.day2(MA_arm == 2);
    tremor.arm.LA.day2(MA_arm == 3) = NaN;
    tremor.leg.LA.day1 = tremor.leg.r.day1;
    tremor.leg.LA.day1(MA_leg == 2) = tremor.leg.l.day1(MA_leg == 2);
    tremor.leg.LA.day1(MA_leg == 3) = NaN;
    tremor.leg.LA.day2 = tremor.leg.r.day2;
    tremor.leg.LA.day2(MA_leg == 2) = tremor.leg.l.day2(MA_leg == 2);
    tremor.leg.LA.day2(MA_leg == 3) = NaN;

    % Sum upper and lower together
    tremor.values.MA.day1 = [tremor.arm.MA.day1, tremor.leg.MA.day1];
    tremor.MA.day1  = nansum(tremor.values.MA.day1, 2);
    tremor.MA.day1(all(isnan(tremor.values.MA.day1),2)) = "NaN";
    tremor.values.LA.day1 = [tremor.arm.LA.day1, tremor.leg.LA.day1];
    tremor.LA.day1  = nansum(tremor.values.LA.day1, 2);
    tremor.LA.day1(all(isnan(tremor.values.LA.day1),2)) = "NaN";
    tremor.values.MA.day2 = [tremor.arm.MA.day2, tremor.leg.MA.day2];
    tremor.MA.day2  = nansum(tremor.values.MA.day2, 2);
    tremor.MA.day2(all(isnan(tremor.values.MA.day2),2)) = "NaN";
    tremor.values.LA.day2 = [tremor.arm.LA.day2, tremor.leg.LA.day2];
    tremor.LA.day2  = nansum(tremor.values.LA.day2, 2);
    tremor.LA.day2(all(isnan(tremor.values.LA.day2),2)) = "NaN";

    % Average over the two sessions
    Table.Rest_tremor_MA = nanmean([tremor.MA.day1 tremor.MA.day2], 2);
    Table.Rest_tremor_LA = nanmean([tremor.LA.day1 tremor.LA.day2], 2);


    % --- Postural tremor: item 15 ---
    % = total = 

    posttremor.values.day1 = [ UPDRS.UPDRS_post_tr_r_1   UPDRS.UPDRS_post_tr_l_1 ];    %item 15: postural tremor hand
    posttremor.total.day1 = nansum( posttremor.values.day1, 2);
    posttremor.total.day1(all(isnan(posttremor.values.day1),2)) = "NaN";
    posttremor.values.day2 = [ UPDRS.UPDRS_post_tr_r_2   UPDRS.UPDRS_post_tr_l_2 ];    %item 15: postural tremor hand
    posttremor.total.day2  = nansum(posttremor.values.day2, 2);
    posttremor.total.day2(all(isnan(posttremor.values.day2),2)) = "NaN";

    Table.Postural_tremor = nanmean([posttremor.total.day1 posttremor.total.day2],2);


    % --- Postural tremor: item 15 ---
    % = Most affected and least affected = 

    posttremor.arm.l.day1 = UPDRS.UPDRS_post_tr_l_1;    %item 15: postural tremor hand (left)
    posttremor.arm.l.day2 = UPDRS.UPDRS_post_tr_l_2;    %item 15: postural tremor hand (left)
    posttremor.arm.r.day1 = UPDRS.UPDRS_post_tr_r_1;    %item 15: postural tremor hand (right)
    posttremor.arm.r.day2 = UPDRS.UPDRS_post_tr_r_2;    %item 15: postural tremor hand (right)

    % Set most and least affected to correct arm/leg
    posttremor.MA.day1 = posttremor.arm.l.day1;
    posttremor.MA.day1(MA_arm == 2) = posttremor.arm.r.day1(MA_arm == 2);
    posttremor.MA.day1(MA_arm == 3) = NaN;
    posttremor.MA.day2 = posttremor.arm.l.day2;
    posttremor.MA.day2(MA_arm == 2) = posttremor.arm.r.day2(MA_arm == 2);
    posttremor.MA.day2(MA_arm == 3) = NaN;
    posttremor.LA.day1 = posttremor.arm.r.day1;
    posttremor.LA.day1(MA_arm == 2) = posttremor.arm.l.day1(MA_arm == 2);
    posttremor.LA.day1(MA_arm == 3) = NaN;
    posttremor.LA.day2 = posttremor.arm.r.day2;
    posttremor.LA.day2(MA_arm == 2) = posttremor.arm.l.day2(MA_arm == 2);
    posttremor.LA.day2(MA_arm == 3) = NaN;

    % Average over the two sessions
    Table.Postural_tremor_MA = nanmean([posttremor.MA.day1 posttremor.MA.day2], 2);
    Table.Postural_tremor_LA = nanmean([posttremor.LA.day1 posttremor.LA.day2], 2);


    % --- Kinetic tremor: item 16 --- 
    % = total = 

    kintremor.values.day1 = [ UPDRS.UPDRS_kin_r_1   UPDRS.UPDRS_kin_l_1 ];    %item 15: kinetic tremor hand
    kintremor.total.day1 = nansum( kintremor.values.day1, 2);
    kintremor.total.day1(all(isnan(kintremor.values.day1),2)) = "NaN";
    kintremor.values.day2 = [ UPDRS.UPDRS_kin_r_2   UPDRS.UPDRS_kin_l_2 ];    %item 15: kinetic tremor hand
    kintremor.total.day2  = nansum(kintremor.values.day2, 2);
    kintremor.total.day2(all(isnan(kintremor.values.day2),2)) = "NaN";

    Table.Kinetic_tremor = nanmean([kintremor.total.day1 kintremor.total.day2],2);


    % --- Kinetic tremor: item 16 --- 
    % = Most affected and least affected = 

    kintremor.arm.l.day1 = UPDRS.UPDRS_kin_l_1;    %item 16: kinetic tremor hand (left)
    kintremor.arm.l.day2 = UPDRS.UPDRS_kin_l_2;    %item 16: kinetic tremor hand (left)
    kintremor.arm.r.day1 = UPDRS.UPDRS_kin_r_1;    %item 16: kinetic tremor hand (right)
    kintremor.arm.r.day2 = UPDRS.UPDRS_kin_r_2;    %item 16: kinetic tremor hand (right)

    % Set most and least affected to correct arm/leg
    kintremor.MA.day1 = kintremor.arm.l.day1;
    kintremor.MA.day1(MA_arm == 2) = kintremor.arm.r.day1(MA_arm == 2);
    kintremor.MA.day1(MA_arm == 3) = NaN;
    kintremor.MA.day2 = kintremor.arm.l.day2;
    kintremor.MA.day2(MA_arm == 2) = kintremor.arm.r.day2(MA_arm == 2);
    kintremor.MA.day2(MA_arm == 3) = NaN;
    kintremor.LA.day1 = kintremor.arm.r.day1;
    kintremor.LA.day1(MA_arm == 2) = kintremor.arm.l.day1(MA_arm == 2);
    kintremor.LA.day1(MA_arm == 3) = NaN;
    kintremor.LA.day2 = kintremor.arm.r.day2;
    kintremor.LA.day2(MA_arm == 2) = kintremor.arm.l.day2(MA_arm == 2);
    kintremor.LA.day2(MA_arm == 3) = NaN;

    % Average over the two sessions
    Table.Kinetic_tremor_MA = nanmean([kintremor.MA.day1 kintremor.MA.day2], 2);
    Table.Kinetic_tremor_LA = nanmean([kintremor.LA.day1 kintremor.LA.day2], 2);


    % --- All tremor items together: items 15-18 ---

    tremor.lip = nanmean([UPDRS.UPDRS_lip_1 UPDRS.UPDRS_lip_2],2);
    Table.UPDRS_total_tremor = sum( [Table.Rest_tremor Table.Postural_tremor Table.Kinetic_tremor tremor.lip], 2 );

    % --- All non-tremor items together: 1-14 ---

    Table.UPDRS_total_non_tremor = sum( [Table.B_and_R Table.Axial], 2);

    % For table with values separate per session:
    Table.Rest_tremor1 = tremor.total.day1;
    Table.Rest_tremor2 = tremor.total.day2;
    Table.Postural_tremor1 = posttremor.total.day1;
    Table.Postural_tremor2 = posttremor.total.day2;
    Table.Kinetic_tremor1 = kintremor.total.day1;
    Table.Kinetic_tremor2 = kintremor.total.day2;
    Table.lip1 = UPDRS.UPDRS_lip_1;
    Table.lip2 = UPDRS.UPDRS_lip_2;
    Table.B_and_R1 = bradyrig.total.day1;
    Table.B_and_R2 = bradyrig.total.day2;
    Table.Axial1 = axial.total.day1;
    Table.Axial2 = axial.total.day2;
end