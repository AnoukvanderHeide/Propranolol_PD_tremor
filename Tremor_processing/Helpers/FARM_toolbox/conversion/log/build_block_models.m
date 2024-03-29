function out=build_block_models(taak,tr)


    
    onsets={};
    names={};
    durations={};

    if strcmp(taak,'tremor1')%if strcmp(taak,'motor_tappen') CHANGED 11-07-2012
        
        
        % dit is een ABAC model, 7x, 10/block.
        names={'re_heffen','re_heffen_lezen','rust'};
        
        onsets{1}= [15 75 105 165 255 315 405 435 495 585]+1;
        onsets{2}= [45 135 195 225 285 345 375 465 525 555]+1;
        onsets{3}= (0:10)*30+1;
        durations{1}= [30 30 30 30 30 30 30 30 30 30];
        durations{2}= [30 30 30 30 30 30 30 30 30 30];
        durations{3}= [30 30 30 30 30 30 30 30 30 30 30];
        
        
        
              
    end


    
    if strcmp(taak,'tremor2')
        
        % dit is een AB model, 10x, 10/block.
        names={'re_heffen_verzwaren','rust'};
        
        onsets{1}= (0:9)*30+15+1;
        onsets{2}= (0:10)*30+1;
        durations{1}= [30 30 30 30 30 30 30 30 30 30];
        durations{2}= [30 30 30 30 30 30 30 30 30 30 30];
        
    end
    
    
    
    if strcmp(taak,'tapping')
        
        % dit is een AB model, 7x, 10/block.
        names={'tapping','rust'};
        
        onsets{1}= (0:5)*30+11;
        onsets{2}= [0 25 55 85 115 145 175]+1;
                
        durations{1}= [30 30 30 30 30 30];
        durations{2}= [20 30 30 30 30 30 10];

    end
    
    
    if strcmp(taak,'wijzen')
        
        % dit is een AB model, 7x, 10/block.
        names={'wijzen','rust'};
        
        onsets{1}= (0:5)*30+11;
        onsets{2}= [0 25 55 85 115 145 175]+1;
        
        durations{1}= [30 30 30 30 30 30];
        durations{2}= [20 30 30 30 30 30 10];

    end
   
        
    %durations=cell(size(onsets)); vervangen door per taak durations te
    %definiëren (24-08-2012, AWB)
        
    % en dan x de tr doen... om mooie 'seconden' te krijgen.
    % en de durations gaan fixen.
    for i=1:numel(onsets)
        onsets{i}=(onsets{i}-1)*tr;
        %durations{i}=10*ones(size(onsets{i}))*tr; durations=cell(size(onsets)); vervangen door per taak durations te
    %definiëren (24-08-2012, AWB)
    end       
    
    
    
    % saven inclusief rust (maar niet 'goede' fmri-werkwijze (??)
    % iig niet met 1 conditie...
    
    disp(pwd);
    
    save block.mat names onsets durations
    out='block.mat';
