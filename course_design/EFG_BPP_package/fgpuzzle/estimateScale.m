function [hsEstimate hrEstimate ] = estimateScale(photo, topbandSize,bottombandSize,leftbandSize,rightbandSize,insideoutTag, spatialBandwidth,rangeBandwidth,minimumRegionArea,reverseFG,occupyRatio,areaThres,outputDetail)

height=size(photo,1);width=size(photo,2);
yStart=topbandSize+1;yEnd=height-bottombandSize;
xStart=leftbandSize+1;xEnd=width-rightbandSize;

bgMask=ones(height,width);
bgMask(yStart:yEnd,xStart:xEnd)=0;
if insideoutTag==1
    bgMask=1-bgMask;
end
roiMask=(bgMask==0);
roiMaskIndex=find(roiMask==1);    %roiMaskIndex is a column vector recording the position index for the roi rectangle
size_roiMask=length(roiMaskIndex);

[fimage labels modes regSize]=edison_wrapper(photo,@RGB2Lab,'SpatialBandWidth',spatialBandwidth,'RangeBandWidth',rangeBandwidth, 'MinimumRegionArea',minimumRegionArea,'synergistic',false);

modes=modes.';
labels=uint16(labels)+1;

% if outputDetail==1
%     outputfilename='initialmeanshiftpatches.png';
%     outputMeanshiftImage(modes,labels,topbandSize,bottombandSize,leftbandSize,rightbandSize,insideoutTag,reverseFG,outputfilename);
% end

numClusters=max(labels(:));
featureColor=double(RGB2Lab(photo));
featureColor1=featureColor(:,:,1);
featureColor2=featureColor(:,:,2);
featureColor3=featureColor(:,:,3);

nDim=5;                     %always use nDim=5 for estimateScle to be consistent with meanshift.
se = strel('disk',1);
numROI=0;                           %ROI: Region Of Interest
numROB=0;                           %ROB: Region Of Boundary

areaThresMax=length(roiMaskIndex)/4; 
gaussSets = struct('labelIndex',{},'size',{},'mean', {}, 'cov', {});
for k=1:numClusters    
    regionMap=(labels==k);          
    intersectMap=regionMap & roiMask;
    if nnz(intersectMap)==0    
        continue;
    end    
    numROI=numROI+1;    
    intersectMap=regionMap & bgMask;
    if nnz(intersectMap(:))>0    
        numROB=numROB+1;                  
    end     
    regionMap = imerode(regionMap,se); 
    [rows cols]=find(regionMap==1);
    numSamples=length(rows);
    gaussSets(numROI).labelIndex=k;
    gaussSets(numROI).size=numSamples; 
    if numSamples<areaThres     %ignore too-small patches after erosion.
        continue;
    end
    if numSamples>areaThresMax  %ignore too-large patches
        continue;
    end
    samples=[featureColor1((cols-1)*height+rows) featureColor2((cols-1)*height+rows) featureColor3((cols-1)*height+rows) rows cols];
    mu=mean(samples);sigma=cov(samples);
    
    for j=1:nDim
        if sigma(j,j)<=eps
            sigma(j,j)=1;
        end            
    end
    gaussSets(numROI).mean=mu;
    gaussSets(numROI).cov=sigma;  
end

if numROB<2     
    hsEstimate=5;           %use small bandwidth to retain more details (maybe very light or transparent) in very flat or simple background. like weizmann2 20 and 42.
    hrEstimate=3;        
else
    [hsEstimate hrEstimate]=scaleStatistic(gaussSets,size_roiMask,occupyRatio);
end


