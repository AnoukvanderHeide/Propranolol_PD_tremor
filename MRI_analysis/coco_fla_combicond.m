function coco_fla_combicond(conf, CurSub)
%coco_fla_combicond.m creates a file with the conditions for CurSub. The
%file contains two conditions (coco and rest) and for each condition two
%parameteric modulations (tremor and tremor_deriv1). The output will be
%stored as a matlab file.


    for i = 1:length(conf.sub.ses)
        
        clearvars -except conf CurSub i
        CurSes = conf.sub.ses{i};
        fprintf('\nSession %s: \n\n', CurSes);

        outfilename = replace(conf.file.spm.model.conditions, {'Sub', 'Ses'}, {CurSub, CurSes});
        outdirname  = replace(conf.dir.spm.sub, {'Sub', 'Ses'}, {CurSub, CurSes});

        
        % --- Skip if a condition file already exists ---    
        if ~conf.force.combicond & exist(fullfile(outdirname, outfilename))
            fprintf('conditions file already exists\n')
            continue
        end
        
                
        % --- Load EMG data ---
        fprintf('getting EMG/ACC data\n');
        
        % Get the right channel
        idx = strcmp(conf.fla.cond.channels{1}, [CurSub '-' CurSes]);
        if ~any(idx)
            fprintf('  channel not defined in file; using the default channel: ''%s''\n', conf.fla.cond.default);
            channel = conf.fla.cond.default;            
        else
            channel = conf.fla.cond.channels{2}{idx};
        end
        fprintf('  looking for regressor of channel ''%s''\n', channel);
        
        
        % Find the correct regressor file
        emgfilename = replace(conf.file.regr.emg, {'Sub', 'Ses', 'Channel'}, {CurSub, CurSes, channel});
        emgfiledir  = conf.dir.regr.emg;
        emgfile     = pf_findfile(emgfiledir,emgfilename);
        if isempty(emgfile)
            fprintf('  no emg file found with the name "%s" to create tremor regressors from\n', emgfilename);
            continue;
        % If there's more than one file (should never happen though), use the last one
        elseif iscell(emgfile) 
            warning('  found more than one emg file\n')
            emgfile = emgfile{end};
            fprintf('  found more than one emg file with the name "%s"\n', emgfilename);
            fprintf('  using "%s"\n', emgfile);
        end
        
        % Load the regressor file
        fileused 	  = emgfile;
        emg         = load(fullfile(emgfiledir, emgfile));

        fprintf('  creating parametric modulation (EMG/ACC) from "%s"\n', emgfile);

        fprintf('  using %s version\n', conf.fla.cond.emg);
        idxLog      = find(contains(emg.names,['_' conf.fla.cond.emg]) & contains(emg.names, 'lin_'));
        idxDeriv    = find(contains(emg.names,['_' conf.fla.cond.emg]) & contains(emg.names, 'deriv1_'));
        
        
        % --- Create conditions ---

        fprintf('\ngather trial onsets and offsets\n');
        
        expectedLength  = conf.trial.startDelay + conf.trial.duration * conf.trial.nr;
        actualLength    = length(emg.R(:,idxLog));
        
        % Get the on and offsets for the conditions
        
        % if there's less data than there should be (should only be the
        % case for 018-1)
        if actualLength < expectedLength
            fprintf('  EMG regressor contains less scan values (%s) than expected (%s)\n', num2str(actualLength), num2str(expectedLength));
            
            nameInStruct = ['s' CurSub 's' CurSes];
            
            coco_on  = conf.exc.(nameInStruct).coco_on;
            coco_off = conf.exc.(nameInStruct).coco_off;
            rest_on  = conf.exc.(nameInStruct).rest_on;
            rest_off = conf.exc.(nameInStruct).rest_off;

        % normal situation
        else
            % Get the onsets and offsets of conditions (taking into account that dummy scans have already
            % been removed and a nr of scans (startInclude) is included in the front
            coco_on  = [conf.trial.startInclude : conf.trial.duration*2 : conf.trial.duration*(conf.trial.nr-1)];
            coco_off = coco_on + conf.trial.duration - 1;
            rest_on  = coco_on + conf.trial.duration;
            rest_off = rest_on + conf.trial.duration - 1;
            
        end
        
        fprintf('  coco onsets are: %s\n', num2str(coco_on+1));
        fprintf('  rest onsets are: %s\n', num2str(rest_on+1));
                
        nONS = length(coco_on);

        rest_onset = [];
        coco_onset = [];

        for c = 1:nONS 
            coco_onse = coco_on(c):1:coco_off(c);
            rest_onse = rest_on(c):1:rest_off(c);
            coco_onset = [coco_onset coco_onse];
            rest_onset = [rest_onset rest_onse];
        end

        coco_durations = 1; % Durations, every onset takes until the next scan, so duration =1 for all values
        rest_durations = 1;

        % Build an official structure for conditions
        onsets    = {coco_onset; rest_onset};
        durations = {coco_durations; rest_durations};
        names     = {'coco'; 'rest'};       

        scanStart   = min([coco_onset, rest_onset]);
        scanEnd     = max([coco_onset, rest_onset]);
        scansRemoved = conf.trial.startDelay - conf.trial.startInclude;
        fprintf('  first condition starts at scan %s (index %s) in the model, last condition ends at scan %s (index %s) in the model\n\n', ...
            num2str(scanStart + 1), num2str(scanStart), num2str(scanEnd + 1), num2str(scanEnd));


        % --- Create parametric modulations --- %

        fprintf('adding parametric modulation\n');
        % Build the parametric modulation 
        % (dummy scans have already been removed from the regressors when it was created)
        % Add start delay because those extra scans in the beginning shouldn't be included in parametric modulation
        % Add + 1 because Matlab doesn't start counting from 0 but from 1, unlike SPM
        iCoco   = coco_onset + scansRemoved + 1;
        iRest   = rest_onset + scansRemoved + 1;
        fprintf('  first condition starts at datapoint %s of the regressor, last condition ends at datapoint %s of the regressor\n', ...
            num2str(min([iCoco iRest])), num2str(max([iCoco iRest])));        
        
        
        pmod(1).name {1}  = 'coco_tremorlog';
        pmod(1).param{1}  = emg.R(iCoco,idxLog);
        pmod(1).poly {1}  = 1;
        pmod(1).name {2}  = 'coco_tremorlog_deriv1';
        pmod(1).param{2}  = emg.R(iCoco,idxDeriv);
        pmod(1).poly {2}  = 1;
        

        pmod(2).name {1}    = 'rest_tremorlog';
        pmod(2).param{1}    = emg.R(iRest,idxLog);      
        pmod(2).poly {1}    = 1;
        pmod(2).name {2}    = 'rest_tremorlog_deriv1';
        pmod(2).param{2}    = emg.R(iRest,idxDeriv);
        pmod(2).poly {2}    = 1;

	
        % --- Plot the tremor regressors (as sanity check) ---
        % (doesn't work for exceptions)
        aa = length(emg.R(iRest,idxLog));
        bb = length(emg.R(iCoco,idxLog));

        % Full tremor data
        h = figure;
        subplot(3,2,1);
        plot(emg.R(:,idxLog));hold on;title('Full tremorlog')
        for i = 1:length(coco_on)
            xline(coco_on(i)+1, 'color', 'r');
            xline(coco_off(i)+1);
        end
        subplot(3,2,2);
        plot(emg.R(:,idxDeriv));hold on;title('Full tremorlog deriv1')
        for i = 1:length(coco_on)
            xline(coco_on(i)+1, 'color', 'r');
            xline(coco_off(i)+1);
        end

        % Tremor during coco blocks
        seponsets = 0:bb/5:bb;
        subplot(3,2,3);
        
        plot(emg.R(iCoco,idxLog));title('Coco tremorlog')  
        for i = 1:length(seponsets)
            xline(seponsets(i));
        end
        subplot(3,2,4);
        plot(emg.R(iCoco,idxDeriv));title('Coco tremorlog deriv1') 
        for i = 1:length(seponsets)
            xline(seponsets(i));
        end

        % Tremor during rest
        seponsets = 0:aa/5:aa;
        subplot(3,2,5);
        plot(emg.R(iRest,idxLog));hold on;title('Rest tremorlog') 
        for i = 1:length(seponsets)
            xline(seponsets(i));
        end
        subplot(3,2,6);
        plot(emg.R(iRest,idxDeriv));hold on;title('Rest tremorlog deriv1') 
        for i = 1:length(seponsets)
            xline(seponsets(i));
        end

        % Save plot
        plotfilename  = replace(conf.file.spm.model.tremorplot, {'Sub', 'Ses'}, {CurSub, CurSes});
        savename  = fullfile(outdirname, plotfilename);
        saveas(h,savename);
        close(h);
	  
        % --- Save conditions file ---
        savename    = fullfile(outdirname, outfilename);    
        save(savename,'names','onsets','durations','pmod', 'fileused');

        fprintf('\nconditions file saved to "%s"\n',savename)

    end

end