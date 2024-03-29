function intersel = pf_pmg_seltremorUI_kelsey(plots,titles,channels,powspcts,powers,freqs,allchan,peakopt,mancheck)
%
% pf_pmg_seltremor let's you interactively select datapoints of all the
% subplots (plots) plotted in your current figure using the brush tool. 
% It will return the selected channel with corresponding frequency, power, 
% standard deviation of power and coefficient of variation of power. This
% is all stored in a MxN structure corresponding to the row/column index of
% the corresponding subplot.

% �Michiel Dirkx, 2014
% $ParkFunC

%--------------------------------------------------------------------------

%% Initiate parameters
%--------------------------------------------------------------------------

fprintf('\nInteractive data selection activated')

figure(gcf);
intersel    =   [];
[row,col]   =   size(plots);
cnt         =   1;
multiflag   =   0; % Flag for multiple condition, standard 0

%--------------------------------------------------------------------------

%% Select datapoints
%--------------------------------------------------------------------------

% brush on; brush off
if strcmp(peakopt,'mansingle')
    fprintf('\nClick on the datapoints that you want to include in the figure.\nEnter "return" when you are done.\n')
    brush on    % always turn on brush, either to manually select now or perhaps after automatic peakfinder (mancheck='yes')
    brush green
    keyboard
    brush off
elseif strcmp(peakopt,'peakfinder') && strcmp(mancheck,'yes') % if you want to manually select, then you first need to plot all the peaks.
    
    % --- Perform peakselection in plot --- %
    
    fprintf('%s\n','Performing automatic peakselection')
    
    for a = 1:prod([row col])
        
        % --- Select Current subplot --- %
        
        CurChans  =   channels{a};
        nChans   =   length(CurChans);
        
        CurFreqs  =   freqs{a};
        CurPow    =   powspcts{a};        
        
        % --- autoselect peaks --- %
        
        subplot(plots(a))
        hold on
        idx     =   cell(nChans,1);
        val     =   cell(nChans,1);
        for b = 1:nChans
            thrsh                 =   2*std(CurPow(b,:));             % Threshold for peak selection;
            
            [idx{b},val{b}]   =   peakfinder(CurPow(b,:),thrsh);    %         Peakfinder (noise robust)
            
            if ~isempty(idx{b})
                plot(CurFreqs(idx{b}),val{b}+0.5,'*','MarkerSize',10);
            end
        end
    end
    fprintf('\nClick on the datapoints that you want to include in the figure.\nEnter "return" when you are done.\n')
    brush on
    brush green
    keyboard
    brush off
end

%--------------------------------------------------------------------------

%% Retrieve corresponding data values
%--------------------------------------------------------------------------

fprintf('\nSelected:\n')

for a = 1:prod([row col])
    
    % --- Select Current subplot --- %
    
    CurTit    =   titles{a};
    CurChans  =   channels{a};
    CurChans  =   CurChans(:); % ut everything into single column
    CurFreqs  =   freqs{a};
    CurPow    =   powspcts{a};
    CurPowers =   powers{a};
    
    nChans   =   length(CurChans);
    
    fprintf('%s\n',['Subplot ' num2str(a) ': "' CurTit '"']);
    
    % --- Detect Session --- %

    sesscode    =   pf_pmg_seltremorUI_sesscode_kelsey(CurTit);
    
    % --- Retrieve brushdata or autoselect peaks --- %
    subplot(plots(a))
    hold on
    if strcmp(peakopt,'mansingle') || strcmp(mancheck,'yes')
        bh      =   findobj(plots(a),'-property','BrushData');
        bval    =   get(bh,'BrushData');
        if iscell(bval)
            sel     =   cellfun(@(x) length(x)==size(CurPow,2),bval);   % Select only the power data (not plotted peaks)
            bval    =   bval(sel);
            bval    =   flipud(bval); % Because everything is loaded in inverse order
        else
            bval    =   {bval};
        end           
    elseif strcmp(peakopt,'peakfinder')
        idx     =   cell(nChans,1);
        val     =   cell(nChans,1);
        for b = 1:nChans
            thrsh                 =   2*std(CurPow(b,:));             % Threshold for peak selection; 
            [idx{b},val{b}]   =   peakfinder(CurPow(b,:),thrsh);    %         Peakfinder (noise robust)
            if ~isempty(idx{b})
                plot(CurFreqs(idx{b}),val{b},'*','MarkerSize',10);
            end
        end
    end

    % --- Find the selected data --- %
    
    for b = 1:nChans
       
       if ~isempty(strfind(CurTit,'vs'))    % If multiple conditions per plot
           chansel    =  strfind(CurChans{b},' ');
           CurChan    =  CurChans{b}(1:chansel-1);
           
           CurCond    =  CurChans{b}(chansel+1:end);
           condstring =  CurCond;
       else                                 % If only one condition per plot
           CurChan    =  CurChans{b};    
           condstring =  CurTit;
       end
       
       ChanCode     =   pf_pmg_seltremorUI_chancode_kelsey(CurChan);
       
       if isempty(ChanCode) && ~isempty(strfind(CurChans{b},' ')) && isempty(strfind(CurChans{b},'&'))   % If some of the conditions were not loaded into the subplot there will be no 'vs' in the name
           chansel    =  strfind(CurChans{b},' ');
           CurChan    =  CurChans{b}(1:chansel-1);
           
           CurCond    =  CurChans{b}(chansel+1:end);
           condstring =  CurCond;
           ChanCode   =  find(strcmp(allchan,CurChan));
       end
       
       % --- Detect Condition --- %
       
       [cond,condcode] =   pf_pmg_seltremorUI_condcode_kelsey(condstring);
       
       % --- Get idx of selected data --- %
       
       if strcmp(peakopt,'mansingle') || strcmp(mancheck,'yes')
           CurBrush  = bval{b};
           iBrush    = find(CurBrush~=0);
       else
           iBrush    = idx{b};      % Still called iBrush for compatibility
       end
       
       cntt      = 1;
       cntm      = 1;
       
       % --- If something was selected --- %
       
       fprintf('%s\n',[' - Condition "' cond '" (condcode=' num2str(condcode) ')'])
       
       if ~isempty(iBrush)
           
           for c = 1:length(iBrush)
               
               fprintf('%s\n',[' -- Channel "' CurChan '" with frequency "' num2str(CurFreqs(iBrush(c))) '" Hz '])
               
               % --- Store everything --- %

               %==========================================================%
               %[1           2        3      4      5       6        7      8         9       10   ]
               %[Session Condition Channel Frequency Power PowerSTD PowerCOV PowerMIN PowerMAX nDAT]
               if  isempty(CurPowers)
                   intersel(cnt,:)     =   [sesscode condcode ChanCode CurFreqs(iBrush(c)) CurPow(b,iBrush(c)) nan nan nan nan nan];
                   fprintf('%s\n',' ---- Power over time was not found')
               else
                   disp('debug me');keyboard
                   % Implement PowerMIN, PowerMAX, nDat
                   intersel(cnt,:)     =   [sesscode condcode ChanCode type CurFreqs(iBrush(c)) CurPow(b,iBrush(c)) nanstd(CurPowers(b,iBrush(c),:)) (nanstd(CurPowers(b,iBrush(c),:))/CurPow(b,iBrush(c)))];
               end
               cnt = cnt+1;
               subplot(plots(a)); hold on;
               text(CurFreqs(iBrush(c)),CurPow(b,iBrush(c)), strcat('\leftarrow',num2str(CurFreqs(iBrush(c))),' Hz'),'FontSize',10)
               %==========================================================%
           end 
       end 
    end
end

%--------------------------------------------------------------------------

%% Decoding functions
%--------------------------------------------------------------------------

function sesscode    =   pf_pmg_seltremorUI_sesscode_kelsey(str)
% returns the sesscode (as defined in decoding_PMG.xls) based on input str

if ~isempty(strfind(str,'day1'))
    sesscode = 1;
elseif ~isempty(strfind(str,'day2'))
    sesscode = 2;
else
    sesscode = nan;
end

%--------------------------------------------------------------------------

function [cond,condcode]  =   pf_pmg_seltremorUI_condcode_kelsey(condstring)
% returns cond (a string indicating the general condition) and its unique
% condcode (as decoded in decoding_PMG.xls)

if ~isempty(strfind(condstring,'rest1'))
    cond = 'rest';
    condcode = 1;
elseif ~isempty(strfind(condstring,'rest2'))
    cond = 'rest';
    condcode = 2;
elseif ~isempty(strfind(condstring,'rest3'))
    cond = 'rest';
    condcode = 3;
elseif ~isempty(strfind(condstring,'rest'))
    cond = 'rest';
    condcode = 4;
elseif ~isempty(strfind(condstring,'posture'))
    cond = 'posture';
    condcode = 5;
elseif ~isempty(strfind(condstring,'posture1'))
    cond = 'posture';
    condcode = 6;
elseif ~isempty(strfind(condstring,'posture2'))
    cond = 'posture';
    condcode = 7;
else
    cond     = 'NOTFOUND';
    condcode = nan;
    fprintf('%s\n',['Could not detect condition "' condstring '"'])
end

%--------------------------------------------------------------------------

function chancode = pf_pmg_seltremorUI_chancode_kelsey(chanstring)
% Function to retrieve the code corresponding to the current channel. All
% these codes are arbitrarily chosen and registered in an excel file filed
% under Evernote DRDR-PMG-POSTPD sess-cond-chan-type decoding
 
if strcmp(chanstring,'ECR_ma')
    chancode = 1;
elseif strcmp(chanstring,'FCR_ma')
    chancode = 2;
elseif strcmp(chanstring,'ECR_la')
    chancode = 3;
elseif strcmp(chanstring,'FCR_la')
    chancode = 4;
elseif strcmp(chanstring,'Acc_x')
    chancode = 5;
elseif strcmp(chanstring,'Acc_y')
    chancode = 6;
elseif strcmp(chanstring,'Acc_z')
    chancode = 7;
else
    chancode = nan;
end


%==========================================================================