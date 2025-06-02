function [poi2labels gaussSets numPOI bgMask_new bgLabels0 unLabels0]=patchInitialization(photo,labels,roiMask,bgMask,areaThres,nDim)

numClusters=max(labels(:));
[height width]=size(roiMask);

bgLabels0=zeros(numClusters,1);
unLabels0=zeros(numClusters,1);
poi2labels=zeros(numClusters,1);
num_bgLabels0=0;
num_unLabels0=0;
numPOI=0;                           %POI: Patch Of Interest

se = strel('disk',1);

featureColor=double(RGB2Lab(photo));
featureColor1=featureColor(:,:,1);
featureColor2=featureColor(:,:,2);
featureColor3=featureColor(:,:,3);


bgMask_new=true(height,width);
gaussSets = struct('labelregion',{},'size',{},'mean', {}, 'cov', {});

for k=1:numClusters       
    regionMap=(labels==k);
    intersectMap=regionMap & roiMask;
    if nnz(intersectMap)==0                 %This is not an interesting patch. Just set as bg patch, no need to do patch statistics.
        continue;
    end
    
    numPOI=numPOI+1;
    poi2labels(numPOI)=k;
    intersectMap=regionMap & bgMask;
    if nnz(intersectMap)==0                 %This is fully within interesting patch. need to set bgMask.
        bgMask_new(regionMap)=0;
        num_unLabels0=num_unLabels0+1;
        unLabels0(num_unLabels0)=numPOI;  
    else                                    %Overlap with roiMask rectangle, but not fully within fg rectangle. ie, the boundary region.
        num_bgLabels0=num_bgLabels0+1;
        bgLabels0(num_bgLabels0)=numPOI;  
    end
    
    regionIndices=find(regionMap==1);
    gaussSets(numPOI).labelregion=regionIndices;        
    regionMap = imerode(regionMap,se);                  
    [rows cols]=find(regionMap==1);                     
    gaussSets(numPOI).size=length(rows);
        
    if length(rows)<areaThres       
        continue;
    end 
    
    if nDim==5
        samples=[featureColor1((cols-1)*height+rows) featureColor2((cols-1)*height+rows) featureColor3((cols-1)*height+rows) rows cols];
    else
        samples=[featureColor1((cols-1)*height+rows) featureColor2((cols-1)*height+rows) featureColor3((cols-1)*height+rows)];
    end
    
    mu=mean(samples);sigma=cov(samples);
    
    %regularization to prevent 0 diagnal terms caused by single feature value for some dimension.
    for j=1:nDim
        if sigma(j,j)<=eps
            sigma(j,j)=1;
        end            
    end
    if det(sigma)<realmin   %prevent det(sigma)==0 caused by degenerate samples.                             
        sigma=eye(nDim);
    end
    gaussSets(numPOI).mean=mu;
    gaussSets(numPOI).cov=sigma;             
end 

gaussSets=gaussSets(1:numPOI);
poi2labels=poi2labels(1:numPOI);
bgLabels0=bgLabels0(1:num_bgLabels0);
unLabels0=unLabels0(1:num_unLabels0); 
