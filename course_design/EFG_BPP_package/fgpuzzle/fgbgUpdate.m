function [bgLabels0 unLabels0]=fgbgUpdate( gaussSets, bgMask)

numPOI=length(gaussSets);
bgMaskIndices=find(bgMask==1);

bgLabels0=zeros(numPOI,1);
unLabels0=zeros(numPOI,1);
num_bgLabels0=0;
num_unLabels0=0;

for k=1:numPOI       
    regionIndices=gaussSets(k).labelregion;
    intersectIndices=intersect(regionIndices,bgMaskIndices);
    if numel(intersectIndices)==0           %the patch fully drops into the fg region. so this is an interesting unlabeled patch. 
        num_unLabels0=num_unLabels0+1;
        unLabels0(num_unLabels0)=k;        
    else     %nnz(intersectMap)>0           %overlap with roiMask rectangle, but not fully within fg rectangle. ie, the boundary region.
        num_bgLabels0=num_bgLabels0+1;
        bgLabels0(num_bgLabels0)=k;        
    end
end 

bgLabels0=bgLabels0(1:num_bgLabels0);
unLabels0=unLabels0(1:num_unLabels0);       
