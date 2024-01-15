function subinfo = EmgChannelsMeasured(sub, ses)
    
    subses = [sub '-' ses];
    
    subnr = str2num(sub);
    if subnr >= 31 && subnr <= 56
        subses = 'NTs 031-056';
    elseif subnr >= 57 && subnr <= 60
        subses = 'NTs 057-060';
    end

    switch subses
        
        % All non-tremor up to (and including) 056:
        case {'NTs 031-056'}

            subinfo.nChannels       = 10;
            subinfo.emgChannels     = 1:4;
            subinfo.accChannels     = 5:7;
            subinfo.nrNotRecorded   = 0;
            %8:10 are HR, resp, GSR

            subinfo.labels = {
                'ECR_ma'; %1
                'FCR_ma'; %2 
                'ECR_la'; %3
                'FCR_la'; %4
                'Acc_x';  %5
                'Acc_y';  %6
                'Acc_z';  %7
                'HR'   ;  %8
                'Resp' ;  %9
                'GSR'  ;  %10
                };

        % All non-tremor from 057 onwards (MA and LA are switched):
        case {'NTs 057-060'}

            subinfo.nChannels       = 10;
            subinfo.emgChannels     = 1:4;
            subinfo.accChannels     = 5:7;
            subinfo.nrNotRecorded   = 0;
            %8:10 are HR, resp, GSR

            subinfo.labels = {
                'ECR_la'; %1
                'FCR_la'; %2
                'ECR_ma'; %3
                'FCR_ma'; %4 
                'Acc_x';  %5
                'Acc_y';  %6
                'Acc_z';  %7
                'HR'   ;  %8
                'Resp' ;  %9
                'GSR'  ;  %10
                };

        % All TDs with 1:4 (arms; MA first then LA) and 7:8 (MA leg):
        case {'004-01', '004-02', '005-01', '005-02', '008-01', ...
              '008-02', '010-01', '010-02', '014-01', '014-02', ...
              '015-01', '017-02', '020-02', '027-01' }

            subinfo.nChannels       = 14;
            subinfo.emgChannels     = [1:4 7:8];
            subinfo.accChannels     = 9:11;
            subinfo.nrNotRecorded   = 2;
            %12:14 are HR, resp, GSR

            subinfo.labels = {
                'ECR_ma'; %1
                'FCR_ma'; %2 
                'ECR_la'; %3
                'FCR_la'; %4
                'xx';     %5
                'xx';     %6
                'TA_ma';  %7
                'GA_ma';  %8
                'Acc_x';  %9
                'Acc_y';  %10
                'Acc_z';  %11
                'HR'   ;  %12
                'Resp' ;  %13
                'GSR'  ;  %14
                };

        % All TDs with 1:4 (arms; LA first then MA) and 7:8 (MA leg):
        case {'002-02', '027-02', '064-01', '064-02'}

            subinfo.nChannels       = 14;
            subinfo.emgChannels     = [1:4 7:8];
            subinfo.accChannels     = 9:11;
            subinfo.nrNotRecorded   = 2;
            %12:14 are HR, resp, GSR

            subinfo.labels = {
                'ECR_la'; %1
                'FCR_la'; %2 
                'ECR_ma'; %3
                'FCR_ma'; %4
                'Bi_ma';  %5
                'Tri_ma'; %6
                'TA_ma';  %7
                'GA_ma';  %8
                'Acc_x';  %9
                'Acc_y';  %10
                'Acc_z';  %11
                'HR'   ;  %12
                'Resp' ;  %13
                'GSR'  ;  %14
                };          
            
        % All TDs with 1:4 (arms; MA first then LA) and 5:6 (MA leg):    
        case {'001-01', '015-02', '017-01', '020-01' }

            subinfo.nChannels       = 14;
            subinfo.emgChannels     = 1:6;
            subinfo.accChannels     = 9:11;
            subinfo.nrNotRecorded   = 2;
            %12:14 are HR, resp, GSR

            subinfo.labels = {
                'ECR_ma'; %1
                'FCR_ma'; %2 
                'ECR_la'; %3
                'FCR_la'; %4
                'TA_ma';  %5
                'GA_ma';  %6
                'Bi_ma';  %7
                'Tri_ma'; %8
                'Acc_x';  %9
                'Acc_y';  %10
                'Acc_z';  %11
                'HR'   ;  %12
                'Resp' ;  %13
                'GSR'  ;  %14
                };

        % All TDs with 1:4 (arms; MA first then LA)
        case {'003-01', '003-02', '006-01', '007-01', '009-01', ...
              '009-02', '011-01', '011-02', '012-01', '012-02', ...
              '013-01', '016-01', '016-02', '018-01', '018-02', ...
              '021-01', '022-01', '022-02', '023-01', '023-02', ...
              '024-01', '025-01', '025-02', '026-01', '029-01', ...
              '029-02', '061-01'}

            subinfo.nChannels       = 14;
            subinfo.emgChannels     = 1:4;
            subinfo.accChannels     = 9:11;
            subinfo.nrNotRecorded   = 4;
            %12:14 are HR, resp, GSR

            subinfo.labels = {
                'ECR_ma'; %1
                'FCR_ma'; %2 
                'ECR_la'; %3
                'FCR_la'; %4
                'Bi_ma';  %5
                'Tri_ma'; %6
                'TA_ma';  %7
                'GA_ma';  %8
                'Acc_x';  %9
                'Acc_y';  %10
                'Acc_z';  %11
                'HR'   ;  %12
                'Resp' ;  %13
                'GSR'  ;  %14
                };

        % All TDs with 1:4 (arms; LA first then MA)
        case {'002-01', '028-01', '028-02', '030-01', '030-02'...
              '063-01', '063-02', '065-01', '065-02'}

            subinfo.nChannels       = 14;
            subinfo.emgChannels     = 1:4;
            subinfo.accChannels     = 9:11;
            subinfo.nrNotRecorded   = 4;
            %12:14 are HR, resp, GSR

            subinfo.labels = {
                'ECR_la'; %1
                'FCR_la'; %2 
                'ECR_ma'; %3
                'FCR_ma'; %4
                'Bi_ma';  %5
                'Tri_ma'; %6
                'TA_ma';  %7
                'GA_ma';  %8
                'Acc_x';  %9
                'Acc_y';  %10
                'Acc_z';  %11
                'HR'   ;  %12
                'Resp' ;  %13
                'GSR'  ;  %14
                };

        % Exception: This session was recorded in a different workspace
        case {'006-02'}

            subinfo.nChannels       = 9;
            subinfo.emgChannels     = 1:4;
            subinfo.accChannels     = 5:7;
            subinfo.nrNotRecorded   = 0;
            %8 and 9 are HR and resp (I think)

            subinfo.labels = {
                'ECR_ma'; %1
                'FCR_ma'; %2 
                'ECR_la'; %3
                'FCR_la'; %4
                'Acc_x';  %9
                'Acc_y';  %10
                'Acc_z';  %11
                'HR'   ;  %12
                'Resp' ;  %13
                };

        % Exception: This subject had tremor in both legs, so 5:6 were used 
        % for LA leg (instead of bicepts/triceps)    
        case {'019-01', '019-02'}
            
            subinfo.nChannels       = 14;
            subinfo.emgChannels     = 1:8;
            subinfo.accChannels     = 9:11;
            subinfo.nrNotRecorded   = 0;
            %12:14 are HR, resp, GSR

            subinfo.labels = {
                'ECR_ma'; %1
                'FCR_ma'; %2 
                'ECR_la'; %3
                'FCR_la'; %4
                'TA_la';  %5
                'GA_la';  %6
                'TA_ma';  %7
                'GA_ma';  %8
                'Acc_x';  %9
                'Acc_y';  %10
                'Acc_z';  %11
                'HR'   ;  %12
                'Resp' ;  %13
                'GSR'  ;  %14
                };

        otherwise 
            error('EmgChannelsMeasured not defined for %s-%s', sub, ses); 
            
    end



end
