function [labelProbabilityMaps_list]=figuregroundLabeling(bgLabels0,unLabels0,numPOI,Dists_sym,nDim,tag_softlabel)

if nDim==5
    Dlower=5;Dupper=50;
else                        %nDim==3
    Dlower=3;Dupper=50;
end
bgmahalDists=zeros(length(unLabels0),length(bgLabels0));
for i=1:length(unLabels0)
    for j=1:length(bgLabels0)
        bgmahalDists(i,j)=Dists_sym(unLabels0(i),bgLabels0(j));
    end
end
[dMin,iMin]=min(bgmahalDists,[],2); 
minTable=[-dMin chi2cdf(dMin,nDim) double(bgLabels0(iMin)) double(unLabels0)];
bgsimilarTable=sortrows(minTable);          %negative, ascendant
ubDists_vec=-bgsimilarTable(:,1);           %positive, descendant

keyIndex= (ubDists_vec>Dlower & ubDists_vec<Dupper) ;       
keyPoints=sort(ubDists_vec(keyIndex));                  %positive, ascendant
keyPoints=[Dlower; keyPoints; Dupper];                  %add head and tail guard.  

thresList=( keyPoints(1:end-1)+keyPoints(2:end) )/2;  
iterNum=length(thresList);
labelProbabilityMaps=zeros(iterNum,numPOI);

fgLabels=zeros(length(unLabels0),1);

for iter=1:iterNum
    thresDist=thresList(iter);
    bgLabels=bgLabels0;

    num_fgLabels=0;

    fgIndices=find(ubDists_vec(:,1)>thresDist);         %fgIndices should be continuous integers 1..n, or empty in special case        
    if isempty(fgIndices)
        fgIndices=1;                                    %force to have at least one fg patch.
    end
    thresIndex=max(fgIndices);    
    poiIndices=uint16(bgsimilarTable(1:thresIndex,4));    
    num_poiIndices=length(poiIndices);
    fgLabels( (num_fgLabels+1):(num_fgLabels+num_poiIndices))=poiIndices;
    num_fgLabels=num_fgLabels+num_poiIndices;    
    labelProbabilityMaps(iter,poiIndices)=1;            %definite foreground patches
    
    for i=thresIndex+1:size(bgsimilarTable,1)
        poiIndex=uint16(bgsimilarTable(i,4));
        
        [dist_bg ind_bg]=min( Dists_sym(poiIndex,bgLabels) );        
        [dist_fg ind_fg]=min( Dists_sym(poiIndex,fgLabels(1:num_fgLabels)) );           
        
        if isnan(dist_bg) || isnan(dist_fg)
            likelihood=1;  %set all ill patches as definite foreground 
            fgLabels(num_fgLabels+1)=poiIndex;
            num_fgLabels=num_fgLabels+1;
        else            
            if tag_softlabel>=1     %scheme 1: soft label. default option.
                dists_fg=Dists_sym(poiIndex,fgLabels(1:num_fgLabels));
                if tag_softlabel==2
                    fgProbabilities=(dist_bg)./(dist_bg+dists_fg);   
                else
                    fgProbabilities=exp(-dists_fg)./(exp(-dist_bg)+exp(-dists_fg)); 
                end
                likelihoods=fgProbabilities.*labelProbabilityMaps(iter,fgLabels(1:num_fgLabels));  
                [likelihood ind_fg]=max(likelihoods);
                fgLabels(num_fgLabels+1)=poiIndex;
                num_fgLabels=num_fgLabels+1;                
            else    %scheme 2: hard label.
                if dist_bg>dist_fg
                    likelihood=1.0;
                    fgLabels(num_fgLabels+1)=poiIndex;
                    num_fgLabels=num_fgLabels+1;
                else
                    likelihood=0.0;
                end
            end 
        end 
        
        labelProbabilityMaps(iter,poiIndex)=likelihood;   
    end     %i loop end

end     %iter loop end

[labelProbabilityMaps_list idx]=unique(labelProbabilityMaps,'rows');

    
