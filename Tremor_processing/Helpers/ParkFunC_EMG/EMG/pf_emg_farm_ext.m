function pf_emg_farm_ext(conf)
% pf_emg_farm_ext(conf) is a batch like function scripted around the FARM
% toolbox by van der Meer for MR-correction of EMG signals. Specify all
% options under "configuration" and then run the batch. 
%
% See also van der Meer et al, 2010, clin. neurophyisology.

% Made suitable for ParkFunC toolbox by Michiel Dirkx, 2014
% $ParkFunC, version 20140811
% Updated: 20181208

%--------------------------------------------------------------------------

%% Configuration
%--------------------------------------------------------------------------

if nargin<1

tic; clear all; clc;    
    
%==========================================================================    
% --- Directories --- %
%==========================================================================

conf.dir.root    =   '/home/action/micdir/data/DRDR_MRI/EMG/RAW';               % Where raw file are stored
conf.dir.save    =   '/home/action/micdir/data/DRDR_MRI/EMG/FARM1';             % Where FARM corrected files will be saved

conf.dir.preworkdel  = 'yes';                                                   % Delete work directory beforehand (if present)
conf.dir.postworkdel = 'yes';                                                   % Delete work directory afterwards

%==========================================================================
% --- Subjects --- %
%==========================================================================

conf.sub.name   =   {
                     'p30';'p08';'p11';'p28';'p14'; %5
                     'p18';'p27';'p02';'p60';'p59'; %10
                     'p62';'p38';'p49';'p40';'p19'; %15
                     'p29';'p36';'p42';'p33';'p71'; %20
                     'p21';'p70';'p64';'p50';'p72'; %25
                     'p47';'p56';'p24';'p48';'p43'; %30
                     'p63';'p75';'p74';'p76';'p77'; %35
                     'p78';'p73';'p80';'p81';'p82'; %40
                     'p83';                         %41
                     };   
conf.sub.sess   = {
                   'SESS1';
                   'SESS2';
                   };

conf.sub.run    = {
%                    'RestingState';
                   'COCO';
%                    'POSH';
                  };

sel   = 2;
sel = pf_subidx(sel,conf.sub.name);
conf.sub.name   = conf.sub.name(sel);  

%==========================================================================
% --- File Info and options --- %
%==========================================================================

conf.file.name          =   '/CurSub/&/CurSess/&/CurRun/&/.vhdr/';      % .vhdr file of the BVA EMG file(uses pf_findfile)
conf.file.nchan         =   13;                                         % total amount of channels in original file
conf.file.chan          =   1:8;                                        % Channels you want to analyze (usually only EMG)
conf.file.scanpar       =   [0.859;11;nan];                             % Scan parameters: TR / nSlices / nScans (enter nan for nScans if you want to automatically detect this)
conf.file.etype         =   'R  1';                                     % Scan marker (EEG.event.type)

% --- Preprocessing --- %

conf.preproc.mkbipol    =   'no';       % If yes, then it will make bipolar out of monopolar channels

% --- Slice Triggers --- %

conf.slt.plot           = 'yes';        % Plot the slicetrigger check

% --- Additional methods --- %

conf.meth.volcor  =   'yes';            % volume correction
conf.meth.cluster =   'yes';            % Cluster correction
conf.meth.pca     =   'yes';            % do PCA
conf.meth.lp      =   'yes';            % Lowpass filtering
conf.meth.hp      =   'yes';            % Highpass filtering
conf.meth.anc     =   'yes';            % Adaptive noise cancellation

end

%--------------------------------------------------------------------------

%% Initialize
%--------------------------------------------------------------------------

fprintf('\n%s\n\n','% -------------- Initializing -------------- %')

nSub     =   length(conf.sub.name);
nSess    =   length(conf.sub.sess);
nRun     =   length(conf.sub.run);
Files    =   cell(nSub*nSess*nRun,1);
nFiles   =   length(Files);
cnt      =   1;

workmain =   fullfile(conf.dir.root,'work');
if ~exist(workmain,'dir');      mkdir(workmain);      end
if ~exist(conf.dir.save,'dir'); mkdir(conf.dir.save); end

if isempty(findobj('Tag','EEGLAB'))
    eeglab
end

%--------------------------------------------------------------------------

%% Retrieve all fullfiles, initializing workdir
%--------------------------------------------------------------------------

fprintf('\n%s\n\n','% -------------- Retrieving all fullfiles -------------- %')

for a = 1:nSub
    CurSub  =   conf.sub.name{a};
    for b = 1:nSess
        CurSess    =   conf.sub.sess{b};
        for c = 1:nRun
        CurRun     =   conf.sub.run{c};
        CurFile    =   pf_findfile(conf.dir.root,conf.file.name,'conf',conf,'CurSub',a,'CurSess',b,'CurRun',c);
        workdir    =   fullfile(workmain,[CurSub '_' CurSess '_' CurRun]);
        if ~exist(workdir,'dir'); 
            mkdir(workdir); 
        elseif exist(workdir,'dir') && strcmp(conf.dir.preworkdel,'yes')
            rmdir([workdir '/'],'s')
            mkdir(workdir); 
        end
        %=============================FILES===============================%
        Files{cnt,1}.raw  =  fullfile(conf.dir.root,CurFile);
        Files{cnt,1}.work =  workdir;
        Files{cnt,1}.sub  =  CurSub;
        Files{cnt,1}.sess =  CurSess;
        Files{cnt,1}.run  =  CurRun;
        %=================================================================%
        fprintf('%s\n',['- Added "' CurFile '"'])
        cnt =   cnt+1;
        end
    end 
end

%--------------------------------------------------------------------------

%%  FARM correction
%--------------------------------------------------------------------------

fprintf('\n%s\n','% -------------- Performing FARM correction -------------- %')
homer    =   pwd;
detscan  =   0;

for a = 1:nFiles
    
    clear EEG o d sl m mrk ve prebound postbound exevents
    
    CurFile   =  Files{a};
    
    if ~exist(CurFile.work,'dir');
        mkdir(CurFile.work);
    elseif exist(CurFile.work,'dir') && strcmp(conf.dir.preworkdel,'yes')
        rmdir([CurFile.work '/'],'s')
        mkdir(CurFile.work);
    end
    
    CurSub    =  CurFile.sub;
    CurSess   =  CurFile.sess;
    CurRun    =  CurFile.run;
    [rawpath,rawfile,rawext]  =  fileparts(CurFile.raw);   
    
    fprintf('\n%s\n',['Working on Sujbect | ' CurSub ' | Session | ' CurSess ' | Run | ' CurRun ' | ']);
    
    [EEG,~]         = pop_loadbv(rawpath,[rawfile rawext],[],conf.file.chan);
    
    % --- Load channels which need not be processed with FARM --- %
    
    chans           = 1:1:conf.file.nchan;
    iAlt            = find(~pf_numcmp(chans,conf.file.chan));
    [EEGalt,~]      = pop_loadbv(rawpath,[rawfile rawext],[],iAlt);
    
    % --- USE THIS WHEN MISSING SCANMARKER --- %

%     q         = EEG.event(60);               % replace this with random event (to get started)
%     q.latency = EEG.event(55).latency+4295;  % replace the indices with prescan event
%     q.urevent = 999;                         % leave this
%     EEG.event = [EEG.event(1:55) q EEG.event(56:end)]; %replace with prescan event and postscan event
%     EEGalt.event = EEG.event;
    
    % --- Detect amount of scans --- %
    
    if isnan(conf.file.scanpar(3)) || detscan==1
        mrk     =   EEG.event(strcmp({EEG.event.type},conf.file.etype));
        nScans  =   length(mrk);
        conf.file.scanpar(3) = nScans;
        fprintf('%s\n',['- Detected ' num2str(nScans) ' scan markers'])
        detscan =   1;
    end
    
    cd(CurFile.work);
    nChans    =  length(conf.file.chan);
        
    if ~exist('emg_added_slicetriggers.mat','file')
        
        if strcmp(conf.preproc.mkbipol,'yes')
            EEG=emg_make_bipolar(EEG);
        end
        
        %     EEG=emg_add_names(EEG);
        maxvals=max(abs(EEG.data(1:nChans,:)),[],2);
        trigchannel = find(maxvals==max(maxvals));       % add slice-triggers.
        if length(trigchannel)>1                         % If the maximum is in both channels (like with the EMG of C2b)
            trigchannel = 1;
        end
        EEG=emg_add_slicetriggers(EEG,trigchannel,conf);
        
        save('emg_added_slicetriggers.mat','EEG');
        
    else
        load('emg_added_slicetriggers.mat');
    end
    
    % --- Rest of Analysis --- %
    
    ve=EEG.event(strcmp({EEG.event.type},'V'));
    Tr=mean(([ve(2:end).latency]-[ve(1:end-1).latency])/EEG.srate);
    if ~sum(abs(([ve(2:end).latency]-[ve(1:end-1).latency])/EEG.srate-conf.file.scanpar(1))>0.1)
        
        % reject (possibly!) extragenous data.
        % re-do muscle names from files.txt file.
        % samples that is 1 [s] before 1st V
        % smaples that is 1+Tr [s] after last V
        % estimate Tr.
        
        if ~exist('emg_added_slicetriggers_revised.mat','file')
            
            % --- Cut out part of the end and part of the beginning --- %
            
            omit_begin=ve(1).latency-3*EEG.srate;
            if omit_begin<2
                omit_begin=2;
            end
            
            omit_end=ve(end).latency+round((3+Tr)*EEG.srate);
            if omit_end>(size(EEG.data,2)-1)
                omit_end=size(EEG.data,2)-1;
            end
            
            % --- Remove events outside the boundary to prevent crash in eeg_eegrej --- %
            
            lats        =   [EEG.event.latency]';
            
            prebound    =   lats<=omit_begin;
            postbound   =   lats>=omit_end;
            exevents    =   logical(prebound+postbound);
            
            EEG.event   =   EEG.event(~exevents);
            
            % --- Reject Data --- %
            
            EEG = eeg_eegrej( EEG, [1 omit_begin;omit_end size(EEG.data,2)]);
            
            % re-do the names!
            %         try
            %             ruwDir=regexprep(regexprep(pwd,'(.*\d{4}).*','$1'),'pp','ruw','once');
            %             muscles=read_channels_file(regexprep(regexprep([ruwDir '\channels.txt'],'\\','/'),'//','/'));
            %             for i=1:8
            %                 EEG.chanlocs(i).labels=muscles{i};
            %             end
            %         catch
            %             error(['check your channels.txt file!!!! ' lasterr]);
            %         end
            
            save('emg_added_slicetriggers_revised.mat','EEG');
            
        else
            
            load emg_added_slicetriggers_revised.mat
            
        end
        
        % --- Additional Slice timing --- %
        
      
        if exist('state_after_slicetiming.mat','file')
            disp('skipping the slice-timing (already done) !!');
            disp('to re-do, delete state_after_slicetiming.mat');
            
            load state_after_slicetiming.mat
        else
            
            % == Convert to double == %
            EEG.data    =   double(EEG.data);
            % ======================= %
            
            [o d sl m]=init(EEG,conf);
            
            % --- High-pass filter --- %
            
            if strcmp(conf.meth.hp,'yes')                
                d=filter_lowfrequency(d,o);
            end
            
            sl=pick_other_templates(sl,o);
            
            % calculate the needed adjustments.
            tmp=mean(abs(EEG.data(nChans,:)),2);
            trigchannel=find(tmp==max(tmp));
            disp('starting slicetiming, using third workflow (incl. phaseshifting)');
            [sl o]=do_new_slicetiming3(d,sl,o,m,trigchannel);
            save state_after_slicetiming.mat d sl m o
        end
        
        if strcmp(conf.meth.volcor,'yes')
            if exist('state_after_volume_correction.mat','file')
                disp('skipping volume-correction (already done)');
                disp('to re-do, delete state_after_volume_correction.mat');
                
                load state_after_volume_correction.mat
                
            else
                disp('starting volume correction..');
                d=do_volume_correction(d,sl,o,m);
                save state_after_volume_correction.mat d sl m o
            end
        end
        
        % --- Cluster the artifacts into most-resembling sub-groups --- %
        
        if strcmp(conf.meth.cluster,'yes')
            if ~exist('state_after_clustering.mat','file')
                disp('starting clustering...');
                sl=do_clustering(d,sl,o,m);
                save state_after_clustering.mat d sl m o
            else
                disp('skipping volume-correction (already done)');
                disp('to re-do, delete state_after_volume_correction.mat');
                load('state_after_clustering.mat')
            end
        end
        
        % --- Upsample (cluster&align), do pca, and downsample. --- %
        
        if strcmp(conf.meth.pca,'yes')
            if ~exist('state_after_pca.mat','file')
                disp(['starting pca, using ' num2str(o.pca.usr_max_components) ' PCA components...']);
                [d sl m]=do_pca(d,sl,o,m);
                save(['state_after_pca.mat'],'d','sl','m','o');
            else
                disp('skipping PCA (already done)');
                disp('to re-do, delete state_after_pca.mat');
                load('state_after_pca.mat')
            end    
        end
        
        if strcmp(conf.meth.lp,'yes')
            d=filter_high(d,o);
        end
        
        % 2010-05-12: seems that anc field was added later, but is not defined under all circumstances
        
        if strcmp(conf.meth.anc,'yes')
            if ~isfield(o,'anc')
                o.anc = 1;
            end
            if o.anc==1
                disp('starting ANC analysis...');
                d=do_anc(d,o,m,sl);
            end
            d=filter_low(d,o);
        end
        
        load emg_added_slicetriggers_revised.mat
        EEG.data=d.clean';
        EEG.emgcorroptions=o;
        
        if strcmp(conf.meth.pca,'yes')
            % do_pca also returns, if you ask for it, the samples at where segments
            % start and end! -- see if there's bursts there too.
            for sc=1:numel(m.beginsegmarker)
                EEG.event(end+1).type='b_seg';
                EEG.event(end).latency=m.beginsegmarker(sc);
                EEG.event(end).duration=1;
                EEG.event(end+1).type='e_seg';
                EEG.event(end).latency=m.endsegmarker(sc);
                EEG.event(end).duration=1;
            end
        end
        
        % --- Remove outside measurments and slice triggers --- %

        EEG    =emg_remove_outsidemeasurementdata(EEG,'V');
        EEGalt =emg_remove_outsidemeasurementdata(EEGalt,conf.file.etype);
        
        EEG=emg_remove_slicetriggers(EEG);
        try
            EEG=emg_add_modeltriggers(EEG);
        catch;end
        try
            add_events;
        end
        
        % --- DONE, save --- %
        
        save emg_corrected.mat
        fprintf('\n%s\n','Correction procedure completed!');
        
        % --- Add non-processed channels to processed channels --- %
        
        EEG.nbchan   = EEG.nbchan+EEGalt.nbchan;
        EEG.data     = vertcat(EEG.data,EEGalt.data);
        EEG.chanlocs = [EEG.chanlocs EEGalt.chanlocs];
        
        % --- Export --- %
        
        fname   =   fullfile(conf.dir.save,[CurSub '_' CurSess '_' CurRun '_FARM']);
        pop_writebva(EEG,fname);
        fprintf('%s\n',['Saved to ' fname]);
        
        % --- delete workdir --- %
        
        try
            cd(homer)
        end
        
        if strcmp(conf.dir.preworkdel,'yes')
            rmdir(CurFile.work,'s');
        end
        
    else
        latenc = [ve.latency];
        trs    = latenc(2:end)-latenc(1:end-1);
        uTr    = unique(trs);
        incTr  = uTr<4290 | uTr>4300;
        iIncor = find(trs==uTr(incTr));
        disp(['Unique TRs: ' num2str(uTr)])
        warning(['(Some of the) scanmarkers do not match your specified TR (probably scan number: '  num2str(iIncor+2) '-' num2str(iIncor+1) ' )']);
        
    end
    
end

%--------------------------------------------------------------------------

%% Benchmark
%--------------------------------------------------------------------------

t=toc;
fprintf('\n%s\n',['Mission accomplished after ' num2str(t/60) ' minutes!!'])
