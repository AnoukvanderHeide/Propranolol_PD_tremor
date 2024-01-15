function [startCond, nScansPre] = eyelink_getstartcondition(conf)
%eyelink_getstartcondition.m Returns values needed to calculate scan
%triggers. 
% Inputs:
%   conf        : structure with settings
% Outputs:
%   startCond   : start of the first condition (in ms) relative to the last
%   precreding scan
%   nScansPre   : number of scans before the start of the first scan

    % --- Get some settings ---
    CurSub      = conf.cur.sub;
    CurSes      = conf.cur.sess;
    SubSes      = [CurSub '-' CurSes];
    
    % --- Find marker file ---
    Fname   = replace(conf.file.bv, {'Sub', 'Ses'}, {CurSub, CurSes});
    Dir     = replace(conf.dir.bv, {'Sub', 'Ses'}, {CurSub, CurSes});
    File    = pf_findfile(Dir, Fname);
    
    % If no file with scan markers is found, return standard value
    if isempty(File)
        startCond = conf.regressor.bv.stnddiff;
        nScansPre = conf.regressor.bv.stndscanpre.(conf.Task);
        fprintf(['    no marker file found, ', ...
                'using standard difference (%d ms) and standard nr of scans (%d scans) \n'], startCond, nScansPre);
        return
    end
    
    % --- Load marker file
    cData = readtable(fullfile(Dir,File), ...
        'FileType', 'text', ...
        'ReadVariableNames', false, ...
        'Delimiter', {'=', ','}, ...
        'HeaderLines', 11);
    
    
    % --- Find start of condition ---
    if strcmp(conf.Task, 'coco')
        trialMarker = 'S 10';
    elseif strcmp(conf.Task, 'rest')
        trialMarker = 'S 88';
    end
    stimIndices = find(strcmp(cData.Var3, trialMarker));
    scanIndices = find(strcmp(cData.Var3, 'R  1'));
    
    if isempty(stimIndices)
        warning('no trial marker (%s) found\n\n', trialMarker)
        
        if strcmp(SubSes, '004-01') && strcmp(conf.Task, 'rest')
            % something went wrong with the brainvision recordings, so use
            % the standard values instead
            startCond = conf.regressor.bv.stnddiff;
            nScansPre = conf.regressor.bv.stndscanpre.rest;
            
            fprintf(['    something''s wrong with the marker file, ', ...
                     'using standard difference (%d ms) and standard nr of scans (%d scans) instead\n'], startCond, nScansPre);
            return
        else
            keyboard % go figure out what to do :)
        end
    end
    
    % if something went wrong with the scan markers and they're indicated 
    % with a different number than R  1 (at the start or over the whole 
    % period), loop over all uneven numbers till one is found that works
    Rnr = 1;
    if (isempty(scanIndices) || (scanIndices(1) > 20)) && Rnr < 100
        fprintf('    cannot find any normal scan markers (R  1), looking for others...\n');
        
        % I checked it for rest for three cases (010-1, 011-1, and 012-2)
        % and it seemed to work, but not a 100% guarantee
%         if strcmp(conf.Task, 'rest')
%             keyboard
%             fprintf('still needs to be fixed for rest\nskipping for now\n')
%         end

        Rnr = 3; 
        while (isempty(scanIndices) || (scanIndices(1) > 20))
            if Rnr < 10
                scanMarker = ['R  ' int2str(Rnr)];
            else
                scanMarker = ['R ' int2str(Rnr)];
            end
            scanIndices = find(strcmp(cData.Var3, scanMarker));
            Rnr = Rnr + 2; % it's always the uneven marker for some reason, so only check those
        end
        if (isempty(scanIndices) || (scanIndices(1) > 20))
            fprintf('    no other scan marker found. using standard difference (%d ms) and standard nr of scans (%d scans) \n', conf.regressor.bv.stnddiff, conf.regressor.bv.stndscanpre);
            startCond = conf.regressor.bv.stnddiff;
            nScansPre = conf.regressor.bv.stndscanpre.(conf.Task);
            return;
        else
            fprintf('    found other scan marker: %s\n', scanMarker);
        end
    end
    
    posStim = cData.Var4(stimIndices(1));
    
    
    % --- Find the position of the scan right before the start of the trial ---
    if ~exist('scanMarker') 
        % when the scan markers are normal, take the scan before the trial marker
        idx = find(scanIndices == stimIndices(1) - 1);
    else 
        % when there was something wrong with the scan markers, there's usually a wrong marker in between trial marker and scan marker that has to be picked, thus - 2
        idx = find(scanIndices == stimIndices(1) - 2);
        if isempty(idx) % however, in at least one case (011-01-rest), this isn't the case, so also check for - 1 (but throw warning because sus)
            warning('the markers are a bit sus (check if there is indeed no even scan marker between the correct (and uneven) scan marker and the trial marker)')
            idx = find(scanIndices == stimIndices(1) - 1); % if it's still empty now, then there's something else wrong, which the next if statement will catch
        end
    end % (when the scan marker wasn't 'R  1', there's always 2 scan markers per scan, so step = 2)
    
    % If there's no scan right before the start of the condition, use scan
    % after it (shouldn't be the case though, so check what's going wrong)
    if isempty(idx)     
        warning('weird\n')
        keyboard
        idx = find(scanIndices == stimIndices(1)+step);
    end
    posScan = cData.Var4(scanIndices(idx));
    
    startCond = (posStim - posScan)/conf.regressor.bv.samplingrate*1000;
    startCond = round(startCond,0);
    fprintf('    condition starts %d ms after scan\n', startCond);
    
    
    % --- Throw a warning if start is very different from standard value --- 
    if (startCond > 1.5 * conf.regressor.bv.stnddiff) | (startCond <= 0)
        warning('The start of the condition is very different from the standard value: %ims', startCond)
    end
  
    nScansPre = sum(scanIndices < stimIndices(1));
    
    fprintf('    there are %d scans before the start of the first condition\n', nScansPre);
    
    
    
    
end