function coco_batch_secondlevel(conf)
%coco_batch_secondlevel.m is the main script for the second-level analysis.
%It's called by coco_batch_main.m and calls different sub-steps of the
%second-level analysis
% Steps:
%   Flip images so tremor is on the same side (coco_sla_reorient.m)
%   Create and run second-level batch (coco_sla_2x2.m, coco_sla_onesampled.m or coco_sla_paired_ttest.m)


for step = 1:length(conf.todo.sla_steps)
    CurStep = conf.todo.sla_steps{step};

    % --- Perform different analysis steps ---
    switch(CurStep)

        case 'reorient'
            fprintf('\n -------------------------------\n +++ Flipping contrast images +++ \n -------------------------------\n');
            coco_sla_reorient(conf);
            fprintf('\n -------------------------------\n --- Flipping contrast images --- \n -------------------------------\n');

        case 'secondlevel'
            fprintf('\n -----------------------------------\n +++ Creating second-level batch +++ \n -----------------------------------\n');
	    %coco_sla_2x2(conf);
            coco_sla_paired_ttest(conf);
            %coco_sla_onesampled(conf);
            fprintf('\n -----------------------------------\n --- Creating second-level batch --- \n -----------------------------------\n');

        otherwise
            fprintf('what\n');
            
    end
        
end


end

