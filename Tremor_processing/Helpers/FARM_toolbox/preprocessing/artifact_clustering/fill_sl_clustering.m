% this'll take care of clustering and slice-timing and will tell you the
% best possible artifact.

function sl=fill_sl_clustering(d,sl,o,m)


    ss                  =m.ss;
    sections            =o.sections;
    beginshift          =o.beginshift;
    window              =o.window;
    interpfactor        =o.interpfactor;
    MRtimes             =o.MRtimes;
    fs                  =o.fs;
    speedup             =o.cl.corrspeedup;
    nch                 =o.nch;
    
    hpffac              =o.filter.hpffac;
    lpffac              =o.filter.lpffac;
    trans               =o.filter.trans;
        
    sduration           =ceil(median(ss(2:end)-ss(1:end-1)));
    soffset             =round(-1*beginshift*sduration);
    
    % how many slice-markers in one go?
    seclength           =floor(numel(ss)/sections);
    

    
    %
    % when the 'adjusts' are known, we can continue with clustering our
    % data.
    % do this for every channel.
    % cluster data; if not enough clusters, proceed to next 'level'.
    disp('clustering the "elects" into most-resembling sub-groups, for each channel, and also determine scaling factors alpha...!');

    
    for i=1:nch
        
        for sc=1:sections
            
            disp(['interpolating data channel ' num2str(i) ' section ' num2str(sc)]);

            % first determine what sl we should go through.
            sli=((sc-1)*seclength+1):(sc*seclength);
            if sc==sections
                sli=((sc-1)*seclength+1):numel(sl);
            end


            
            % do the helper again.
            [samples adjust]=marker_helper(sli,sl,interpfactor);
            v=d.original(samples,i);
            
            % filter?? -yep, look > 150 Hz for template clustering.
            filtorder=round(hpffac*fs*interpfactor/((1-trans)*clusthpf));

            if rem(filtorder,2)~=0
                filtorder=filtorder+1;
            end

            f=[0 hpffac*(1-trans)/nyq/interpfactor hpffac/nyq/interpfactor 1];
            a=[0 0 1 1];
            hpfweights=firls(filtorder,f,a);


            iv=interp(v,interpfactor);
            
            % filter it, for clustering at artifact details of > 150 Hz.
            iv=filtfilt(hpfweights,1,iv);


            % v=interp(EEG.data(i,:),interpfactor);
            for j=sli


                
                % - rescale
                % - cluster!
                % row or column vectors !?!?! we support row vectors.
                curdata=iv((sl(j).b-adjust):(sl(j).e-adjust))';

                % clustermat_unscaled=zeros(numel(sl(j).b:sl(j).e),numel(sl(j).others));
                clustermat_unscaled=zeros(numel(sl(j).b:sl(j).e),numel(sl(j).others));

                for k=1:numel(sl(j).others)


                    tmp_b=sl(sl(j).others(k)).b + sl(j).adjusts(k)-adjust;
                    tmp_e=sl(sl(j).others(k)).e + sl(j).adjusts(k)-adjust;

                    % one of the other artifact templates.
                    otherdata=iv(tmp_b:tmp_e)';
                    
                    % determing scaling parameters(!), for each channel.
                    scale_factor=curdata'*otherdata/(otherdata'*otherdata);

                    % storing scaling info
                    sl(j).scalingdata(i,k)=scale_factor;
                    
                    % and scaling the (filtered -- with less emg
                    % 'artifact') artifact template.
                    clustermat_unscaled(:,k)=otherdata;
                    % clustermat_scaled(:,k)=scale_factor*otherdata;
 
                end
                


                % impose another restriction on clustermat... use only the
                % very
                % first few samples; before the gradient pulses!
                % the first 0.014 secs is representative for what comes next!
                % throw out some of the gradient-artifact stuff.
                % focus even more closely on what you'd like to cluster!!
                % the slice-select gradient
                % define the exact timing above.
                MRi=round(MRtimes*interpfactor*EEG.srate);
                keep=[1:MRi(1) MRi(2):MRi(3) MRi(4):size(clustermat_unscaled,1)];
                away=1:size(clustermat_unscaled,1);
                away(keep)=0;
                away(away==0)=[];


                % away=round([0.0228 0.0488]*EEG.srate*interpfactor);

                % round(0.014*EEG.srate*interpfactor);
                clustermat_chopped=clustermat_unscaled(keep,:);


                
                % how many clusters?
                % mojena_stopping_rule(Z,k1_offset,k2_std,window,extra_lag,
                % lag_offset,verbosity);
                
                % and now... our secret weapon, applied!
                Y=pdist(clustermat_chopped','euclidean');
                Z=linkage(Y,'centroid');
                sl(j).Tmat(:,:,i)=Z;

                N=mojena_stopping_rule(Z,1,5,35,0,4,0,fh);
                

                ncount=1;
                iterate=1;
                
                % there should be 1 cluster of at the very least, this
                % size!
                min_elements=min_clustersize;
                
                while iterate

                    T=cluster(Z,'maxclust',N(ncount));

                    % size of the cluster.
                    sizes=zeros(1,max(T));
                    for Ti=1:max(T)
                        sizes(Ti)=sum(T==Ti);
                    end
                
                    if max(sizes)>=min_elements
                        iterate=0;
                        % ncount=ncount;
                    
                    elseif max(sizes)<min_elements&&numel(N)>ncount
                        % keyboard;
                        % disp(['slice ' num2str(j) ': detected too low clustersize (' num2str(max(sizes)) ') ... going to bigger clusters.']);
                        iterate=1;
                        ncount=ncount+1;

                    elseif max(sizes)<min_elements&&numel(N)==ncount
                        disp(['slice ' num2str(j) ': still not enough templates put in clusters, but stopping anyway.\nClustering at maxclust=7.']);
                        iterate=0;
                        
                        % fall back onto something else.
                        T=cluster(Z,'maxclust',7);
                        sizes=zeros(1,max(T));
                        for Ti=1:max(T)
                            sizes(Ti)=sum(T==Ti);
                        end
                        
                        % ncount=ncount;
                    end
                end

                    
                sl(j).clusterdata(i,:)=T;

                
                % which correlations are biggest??
                corrdata=[];
                eligible_clusters=find(sizes>=min_clustersize);
                for tc=1:numel(eligible_clusters)
                    
                    vec=find(T==eligible_clusters(tc));
                    

                    % corrdata number of elements (to be > 10!).
                    corrdata(tc,1)=numel(vec);
                    
                    % a look-up matrix; the cluster
                    % number in T to use.
                    corrdata(tc,2)=eligible_clusters(tc);
                    
                    % the correlation.
                    % scaledmat=ones(size(clustermat_unscaled,1),1)*sl(9000).scalingdata(i,:).*clustermat_unscaled;
                    % corrdata(tc,3)=prcorr2(curdata,sum(scaledmat(:,vec),2));
                    corrdata(tc,3)=prcorr2(curdata,mean(clustermat_unscaled(:,vec),2));

                    
                    
                end
                
                
                try
                [corr tmp]=max(corrdata(:,3));
                catch
                    keyboard
                    lasterr
                end
                % store, for later diagnotical use, the correlation between
                % clustermean and 

                sl(j).chosenTemplate(i)=corrdata(tmp,2);
        


                check=mod(j,round(numel(sl)/100));
                if ~check
                    str=['channel ' num2str(i) ', section ' num2str(sc) ', ' num2str(j/round(numel(sl)/100)) ' percent done \n'];
                    fprintf(str);
                end

            end

        end
    end
    
    
    
% and now an in-between step, to align the slices precisely.

for i=1:EEG.nbchan
    
        
    for sc=1:sections
        
        disp(['refining template adjustments and scalings, channel ' num2str(i) ' section ' num2str(sc)]);

        % first determine what sl we should go through.
        sli=((sc-1)*seclength+1):(sc*seclength);
        if sc==sections
            sli=((sc-1)*seclength+1):numel(sl);
        end



        % do the helper again.
        [samples adjust]=marker_helper(sli,sl,interpfactor);
        v=EEG.data(i,samples);
        iv=interp(v,interpfactor);

        for j=sli

            % make the 'current data'.
            curdata=iv((sl(j).b-adjust):(sl(j).e-adjust))';

            % construct the template.
            % which of the others to take??
            parts=find(sl(j).clusterdata(i,:)==sl(j).chosenTemplate(i));
            adjusts=sl(j).adjusts(parts);
            scalings=sl(j).scalingdata(i,parts);
            
            
            % construct the template.
            mat=zeros(numel(curdata),numel(parts));
            for tc=1:numel(parts)
                tmp_b=sl(sl(j).others(parts(tc))).b+adjusts(tc)-adjust;
                tmp_e=sl(sl(j).others(parts(tc))).e+adjusts(tc)-adjust;
                otherdata=iv(tmp_b:tmp_e)'*scalings(tc);

                mat(:,tc)=otherdata;

            end
            template=mean(mat,2);
            
            
            % now calculate template temporal adjustment and extra scaling
            % factor.
            extra_adjust=find_adjustment(curdata,template,2*interpfactor,8);

            % do some tricks to faithfully calculate the extra needed
            % scaling for the template.
            tmp=zeros(size(template));
            if extra_adjust>0
                tmp=template(1+extra_adjust:end);

                % determine RC at the end of template.
                rc=template(end)/2-template(end-2)/2;

                tmp((numel(tmp)+1):(numel(tmp)+extra_adjust))=template(end)+rc*(1:extra_adjust);

                template=tmp;
            end
        
            if extra_adjust<0

                tmp((1-extra_adjust):numel(template))=template(1:(end+extra_adjust));

                % determine RC at the beginning of template.
                rc=template(1)/2-template(3)/2;
                tmp(1:(-extra_adjust))=template(1)+rc*((-extra_adjust):-1:1);

                template=tmp;

            end
            
            sl(j).template_scalings(i)=(curdata'*template)/(template'*template);
            sl(j).template_adjusts(i)=extra_adjust;
            
            % for later diagnostical use, store the 'cluster correlation'.
            % how well does you matched cluster actually fit the current
            % slice template ???
            sl(j).cluster_correlation(i)=prcorr2(curdata,sl(j).template_scalings(i)*template);
            
            
            check=mod(j,round(numel(sl)/100));
            if ~check
                str=['channel ' num2str(i) ', section ' num2str(sc) ', ' num2str(j/round(numel(sl)/100)) ' percent done \n'];
                fprintf(str);
            end
 
        end
    
    end
end