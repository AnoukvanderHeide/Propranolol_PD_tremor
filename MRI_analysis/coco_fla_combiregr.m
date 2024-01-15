function coco_fla_combiregr(conf, CurSub)
%coco_fla_combiregr.m creates a file with the nuisance regressors for CurSub. 

    for ses = 1:length(conf.sub.ses)
        
        clearvars -except conf CurSub ses
        
        CurSes = conf.sub.ses{ses};
        fprintf('\nSession %s: \n\n', CurSes);

        outfilename = replace(conf.file.spm.model.regressors, {'Sub', 'Ses'}, {CurSub, CurSes});
        outdirname  = replace(conf.dir.spm.sub, {'Sub', 'Ses'}, {CurSub, CurSes});
        
        % --- Skip if regressor file already exists ---
        if ~conf.force.combiregr & exist(fullfile(outdirname, outfilename), 'file')
            fprintf('regressor file already exists\n')
            continue
        end

        % --- Load data ---
        fileDir = replace(conf.dir.regr.nuis, {'Sub', 'Ses'}, {CurSub, CurSes});

        confoundsfilename   = replace(conf.file.regr.nuis.confounds, {'Sub', 'Ses'}, {CurSub, CurSes});
        confoundsFile       = pf_findfile(fileDir,confoundsfilename);

        aromafilename       = replace(conf.file.regr.nuis.aroma, {'Sub', 'Ses'}, {CurSub, CurSes});
        aromaFile           = pf_findfile(fileDir,aromafilename);

        indicesfilename     = replace(conf.file.regr.nuis.indices, {'Sub', 'Ses'}, {CurSub, CurSes});
        indicesFile         = pf_findfile(fileDir,indicesfilename);

        % Check if all files exist
        if isempty(confoundsFile) || isempty(aromaFile) || isempty(indicesFile)
            warning('no confounds or indices file(s) found\n');
            continue;
        % Grab last run if there's more than one
        elseif iscell(confoundsFile)
            fprintf('found %s runs\n', num2str(length(confoundsFile)));
            if strcmp([CurSub '-' CurSes], '012-01')
                confoundsFile   = confoundsFile{1};
                aromaFile       = aromaFile{1};
                indicesFile     = indicesFile{1};
            else
                confoundsFile   = confoundsFile{end};
                aromaFile       = aromaFile{end};
                indicesFile     = indicesFile{end};
            end
            
        end

        fprintf('creating regressors from:\n  %s\n  %s\n  %s\n', confoundsFile, aromaFile, indicesFile);

        % Load confound data
        confoundData2 = tdfread(fullfile(fileDir,confoundsFile));
        regressorNames = fieldnames(confoundData2);
        format = [repmat('%f',1,length(regressorNames))];
        fid = fopen(fullfile(fileDir, confoundsFile));
        confoundData = textscan(fid, format, 'HeaderLines', 1, 'TreatAsEmpty', 'n/a');
        fclose(fid);
        confoundData = [confoundData{:}];   % convert to matrix

        % Load AROMA components
        format = [repmat('%f',1,200)];
        fid = fopen(fullfile(fileDir, aromaFile));
        aromaData = textscan(fid, format);
        fclose(fid);
        aromaData = [aromaData{:}];   % convert to matrix

        % Load AROMA indices
        aromaIndices = csvread(fullfile(fileDir,indicesFile));

        % --- Gather all components into one matrix ---
        fprintf('\nthere are %s scans in total\n', num2str(size(aromaData,1)));
        
        % Gather indices
        expectedLength  = conf.trial.startDelay + conf.trial.duration * conf.trial.nr;
        actualLength    = size(confoundData,1);
        
        % if there's less data than there should be (should only be the case for 018-1)
        if actualLength < expectedLength
            fprintf('  there are less datapoints (%s) than expected (%s)\n', num2str(actualLength), num2str(expectedLength));
            nameInStruct = ['s' CurSub 's' CurSes];
            
            startIdx        = conf.trial.dummies + 1;
            startTrial      = startIdx;
            endTrial        = conf.exc.(nameInStruct).rest_off(end) + conf.trial.dummies + 1;
            endIdx          = endTrial + conf.trial.endInclude;
            
            fprintf('  removing first %s datapoints ("dummy scans" have to be removed because of how the tremor regressor is created)\n', num2str(startIdx-1));
            
        % normal situation
        else
            totDur      = conf.trial.duration * conf.trial.nr;
            scansRemoved= conf.trial.startDelay - conf.trial.startInclude;
            startIdx    = conf.trial.dummies + scansRemoved + 1;
            startTrial  = startIdx + (conf.trial.startDelay - scansRemoved);
            endTrial    = startTrial + totDur - 1;
            endIdx      = endTrial + conf.trial.endInclude;
            
            fprintf('  removing first %s datapoints (from %s dummy scans and from %s/%s scans before the start of the first trial)\n', ...
                num2str(startIdx-1), num2str(conf.trial.dummies), num2str(scansRemoved), num2str(conf.trial.startDelay) );
        end
        
        % remove data points at the end if necessary        
        if endIdx > size(aromaData,1)
            endIdx = size(aromaData,1);
            endAdded = endIdx - endTrial;
            fprintf('  including %s extra datapoints after last trial (instead of %s, because there isn''t enough data)\n', ...
                num2str(endAdded), num2str(conf.trial.endInclude));
        else
            fprintf('  including %s extra datapoints after last trial \n', num2str(conf.trial.endInclude));
            fprintf('  removed last %s datapoints\n', num2str(size(aromaData,1) - endIdx));
        end
        
        fprintf('  first datapoint used is %s; first trial starts at %s; last trial ends at %s; last datapoint used is %s\n', ...
            num2str(startIdx), num2str(startTrial), num2str(endTrial), num2str(endIdx));

        
        % Gather the components (based on the indices)
        count = 1;
        fprintf('gathering all components\n');

        for i = 1:length(conf.fla.regr.which)
            curRegr = conf.fla.regr.which{i};

            switch(curRegr)

                % collect data of a few simple ones
                case {'framewise_displacement', 'std_dvars', 'csf', 'white_matter','global_signal'}
                    fprintf('  adding %s\n', curRegr);
                    idx = find(strcmp(regressorNames, curRegr));
                    R(:,count) = confoundData(startIdx:endIdx, idx);        
                    names(count) = regressorNames(idx);
                    count = count + 1;

                case {'acompcor', 'cosines', 'motion6', 'motion12', 'motion24', 'aroma-automatic'}

                    % collect indices of the regressors
                    switch curRegr
                        case 'acompcor'
                            % compcor %%%% if this one is used, might need to change it to
                            % include top 8 from wm/csf/combined instead of top8 from
                            fprintf('  adding aCompCor\n');
                            idx = find(contains(regressorNames, 'a_comp_cor_00')):find(contains(regressorNames, 'a_comp_cor_08'));
                        case 'cosines'
                            fprintf('  adding cosines\n');
                            idx = find(contains(regressorNames, 'cosine'));
                        case 'aroma-automatic'
                            fprintf('  adding AROMA components (automatically classified)\n');
                            idx = find(contains(regressorNames, 'aroma_motion_'));
                        case 'motion6'
                            fprintf('  adding 6 motion parameters\n');
                            idxTrans    = find(contains(regressorNames, 'trans_') & ~contains(regressorNames, 'power2') & ~contains(regressorNames, 'derivative'));
                            idxRot      = find(contains(regressorNames, 'rot_') & ~contains(regressorNames, 'power2') & ~contains(regressorNames, 'derivative'));
                            idx = [idxTrans; idxRot];
                            motionIdx = idx;
                        case 'motion12'
                            fprintf('  adding 12 motion parameters\n');
                            idxTrans    = find(contains(regressorNames, 'trans_') & ~contains(regressorNames, 'power2'));
                            idxRot      = find(contains(regressorNames, 'rot_') & ~contains(regressorNames, 'power2'));
                            idx = [idxTrans; idxRot];
                            motionIdx = idx;
                        case 'motion24'
                            fprintf('  adding 24 motion parameters\n');
                            idxTrans    = find(contains(regressorNames, 'trans_'));
                            idxRot      = find(contains(regressorNames, 'rot_'));
                            idx = [idxTrans; idxRot];
                            motionIdx = idx;
                    end

                    % get the data
                    R(:,count:count+length(idx)-1) = confoundData(startIdx:endIdx, idx);        
                    names(count:count+length(idx)-1) = regressorNames(idx);
                    count = count + length(idx);

                % get AROMA components based on indices file
                case 'aroma-manual'
                    fprintf('  adding AROMA components (manually classified)\n');
                    R(:,count:count+length(aromaIndices)-1) = aromaData(startIdx:endIdx, aromaIndices);
                    names(count:count+length(aromaIndices)-1) = cellstr(num2str((aromaIndices)', 'aroma_motion_%d'));

                otherwise
                    fprintf('unknown regressor: %s\n', curRegr);
                    fprintf('check for typos or add it to the switch statement in coco_combiregr.m\n');
            end

        end

        
        % --- Lil check ---
        if any(any(isnan(R)))
            warning('there are NaNs in the regressor, spm will not like this\n')
        end

        
        % --- Store the matrix ---
        savename    = fullfile(outdirname, outfilename);
        save(savename,'names','R');

        fprintf('\nregressor file saved to "%s"\n\n', savename);
        
        
        % --- Do some optional other things ---
        if any(contains(conf.fla.regr.which, 'motion24')) & any(contains(conf.fla.regr.which, 'csf')) & any(contains(conf.fla.regr.which, 'white_matter'))
            data = struct();
            if conf.fla.regr.plotmotion.todo
                data.confoundData   = confoundData; 
                data.regressorNames = regressorNames;
            end
            if conf.fla.regr.plotall.todo
                data.names          = names;
                data.R              = R;
            end
            if conf.fla.regr.corr.todo
                data.confoundData   = confoundData; 
                data.idx.motion     = motionIdx;
            end
            other_regressorstuff(conf, data, CurSub, CurSes)
        end
	  end


end