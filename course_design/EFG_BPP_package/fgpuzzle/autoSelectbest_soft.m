function [fgMap_hypotheses fmeasureScore_best fgMap_best]=autoSelectbest_soft(iteround,labelPixels,bgLabels0, unLabels0, poi2labels,Dists_sym,labelProbabilityMaps_list,gtBinary,reverseFG,bgMask0,area_fgMask,outputDetail)

[height width]=size(bgMask0);

numValid=size(labelProbabilityMaps_list,1);           
num_POI=size(labelProbabilityMaps_list,2);
candidateMap=zeros(height,width,numValid);

for i=1:numValid
    fgMap_tmp=zeros(height,width);                          
    for j=1:num_POI
        labelIndex=uint16( poi2labels(j) );
        regionPixels=labelPixels(labelIndex).pixels;
        fgMap_tmp(regionPixels) = labelProbabilityMaps_list( i,j );
    end
    candidateMap(:,:,i)=fgMap_tmp;         
end

if numValid==1 || numValid==2
    fgMap_best=(candidateMap(:,:,numValid)>0.5);
    fgMap_hypotheses=cat(3,fgMap_best,fgMap_best,fgMap_best,fgMap_best); 
    if reverseFG==0
        fmeasureScore_best=fmeasure(gtBinary,fgMap_best);
    else
        fgMap_best=~fgMap_best;
        fmeasureScore_best=fmeasure(gtBinary,fgMap_best);
    end    
    return;
end

differenceMatrix=zeros(numValid,numValid);
index=0;
diff=zeros(numValid*(numValid-1)/2,1);
for i=1:numValid-1
    map1=candidateMap(:,:,i);
    for j=i+1:numValid
        map2=candidateMap(:,:,j);
        sumdiffMap =sum(sum( abs(map1-map2) ));
        sumunionMap=sum(sum( map1|map2 ));
        differenceMatrix(i,j)=sumdiffMap/sumunionMap;
        
        differenceMatrix(j,i)=differenceMatrix(i,j);
        index=index+1;
        diff(index)=differenceMatrix(i,j);
    end
end

sigma2=var(diff);                       %sigma2 means sigma^2 estimeted by var(samples)
affinityMatrix=eye(numValid,numValid);  %preassign diagonal terms to 1.0
for i=1:numValid
    for j=i+1:numValid
        affinityMatrix(i,j)=exp(-(differenceMatrix(i,j)^2 )/(2*sigma2) );
        affinityMatrix(j,i)=affinityMatrix(i,j);
    end
end

[V,D] = eig(affinityMatrix);    %The top eigenvector should have all-positive entries. Perron-Frobenius theorem.
weight=V(:,numValid).^2;        

sumMap=zeros(height,width);
for i=1:numValid
    sumMap=sumMap+candidateMap(:,:,i)*weight(i);
end

prob_poi=zeros(num_POI,1);
for j=1:num_POI
    labelIndex=uint16( poi2labels(j) );
    regionPixels=labelPixels(labelIndex).pixels;
    prob_poi(j)=sumMap(regionPixels(1));            
end

keyValues=unique(sumMap(:));    %unique and ascendent sortng. repeated value is removed here.find all probability values in the weighted probability map
thresList=( keyValues(1:end-1)+keyValues(2:end) )/2.0;        %enumerate all midpoints as thresholds.

validInd= (thresList<=0.9999);
thresList=thresList(validInd);                            %to avoid repetitive thresList values caused by very small keyValues interval. 

num_thresholds=length(thresList);
fmeasureScore_best=0.00;
fgMap_best= false(height,width);

fgMap_probabilityMaps= false(height,width,num_thresholds);
area_fgMap=zeros(num_thresholds,1);
score_acut_mcut=zeros(num_thresholds,2);
num_valid=num_thresholds; 

for i=1:num_thresholds                       %test all possible thresholds
    fgMap_current=(sumMap>thresList(i));     %logical type. 
    area_fg=sum(fgMap_current(:));
    if ( area_fg<area_fgMask/20 && i>1 )     
        num_valid=i-1;
        break;
    end
    fgMap_tmp=fgMap_current;      
    if reverseFG==1     
        fgMap_tmp =extractMatchedregion(~fgMap_current, bgMask0);  
        fgMap_current=~fgMap_tmp;                                         
    end
    [fScore precision recall]=fmeasure(gtBinary,fgMap_tmp);
    if fScore>fmeasureScore_best
        fgMap_best=fgMap_tmp;                       
        fmeasureScore_best=fScore;
    end
    
    area_fgMap(i)=sum(fgMap_current(:));    
    fgMap_probabilityMaps(:,:,i)=fgMap_current; 

    fgLabels=find(prob_poi>thresList(i));
    mgLabels=setdiff(unLabels0,fgLabels);
    bmLabels=[bgLabels0;mgLabels];

    minMinDist=10000.0;
    sumDist_fg=0.0;
    count_fg=0;
    for k=1:length(fgLabels)
        currMinDist=min(Dists_sym(fgLabels(k),bmLabels));
        if ~isnan(currMinDist)            
            sumDist_fg=sumDist_fg+currMinDist;
            count_fg=count_fg+1;
            if currMinDist<minMinDist
                minMinDist=currMinDist;
            end            
        end
    end
    avgCut=sumDist_fg/count_fg;
    minCut=minMinDist;

    score_acut_mcut(i,:)=[avgCut minCut];      
end

fgMap_probabilityMaps=fgMap_probabilityMaps(:,:,1:num_valid);
area_fgMap=area_fgMap(1:num_valid,:);
score_acut_mcut=score_acut_mcut(1:num_valid,:);

ind_acut_best=find( score_acut_mcut(:,1)==max(score_acut_mcut(:,1)) );      %a-cut or average-cut
fgMap_acut=fgMap_probabilityMaps(:,:,ind_acut_best(1));
inds_mcut_best=find( score_acut_mcut(:,2)==max(score_acut_mcut(:,2)) );     %m-cut or maxmin-cut
fgMap_mcut1=fgMap_probabilityMaps(:,:,inds_mcut_best(1));
fgMap_mcut2=fgMap_probabilityMaps(:,:,inds_mcut_best(end));

halfspan=1;
area_delta=zeros(num_valid,1);
score_MSER=1000*ones(num_valid,1);
for i=1:num_valid            
    if i-halfspan>=1
        areaHead=area_fgMap(i-halfspan);        
    else
        areaHead=area_fgMap(1);
    end
    if i+halfspan<=num_valid
        areaTail=area_fgMap(i+halfspan);
    else
        areaTail=area_fgMap(num_valid);
    end    
    area_delta(i)=(areaHead-areaTail);
    score_MSER(i)=area_delta(i)/area_fgMap(i);      %MSER=|R(g-d)|-|R(g+d)|/R(g). See [Matas02BMVC]
    if i==1 || i==num_valid
        score_MSER(i)=score_MSER(i)*2;  %compensation for head or tail scores by doubling the score, because only single lateral signal is computed.
    end
end

[score_MSER_best, ind_MSER_best]=min(score_MSER);
fgMap_MSER=fgMap_probabilityMaps(:,:,ind_MSER_best);
fgMap_hypotheses=cat(3,fgMap_MSER,fgMap_acut,fgMap_mcut1,fgMap_mcut2); 
