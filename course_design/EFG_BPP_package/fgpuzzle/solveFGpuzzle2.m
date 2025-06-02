function [finalfgMaps fmeasureScore_max num_iter iter_winner] = solveFGpuzzle2(photo,gtBinary,parameters,outputDetail)

topbandSize         =parameters( 1);
bottombandSize      =parameters( 2);
leftbandSize        =parameters( 3);
rightbandSize       =parameters( 4);
insideoutTag        =parameters( 5);   
spatialBandwidth    =parameters( 6); 
rangeBandwidth      =parameters( 7);
minimumRegionArea   =parameters( 8);
initialIterNum      =parameters( 9);
reverseFG           =parameters(10);
nDim                =parameters(11);
tag_softlabel       =parameters(12);     

height=size(photo,1);width=size(photo,2);

if outputDetail==1
    imwithbox=drawboundingbox(photo,topbandSize,bottombandSize,leftbandSize,rightbandSize,insideoutTag,reverseFG);
    figure,imshow(imwithbox);title('Original image with bounding box'); 
    imwrite(imwithbox,'originalwithBoundingbox.png');
    if ~isempty(gtBinary)
        figure,imshow(gtBinary);title('Ground truth');
        imwrite(gtBinary,'groundtruth.png');
    end        
end

if (topbandSize==0 && bottombandSize==0 && leftbandSize==0 && rightbandSize==0 && insideoutTag==0)  %no background priors means full foreground, direct set to full-foreground and return
    finalfgMaps= true(height,width,3);                                                   
    fmeasureScore_max=fmeasure(gtBinary,finalfgMaps(:,:,1));
    num_iter=0;
    iter_winner=0;
    if outputDetail==1
        figure,imshow(finalfgMaps(:,:,1)); title('No background; Full foreground');
    end
    return;
end

occupyRatio=1.0;
areaThres=18;
for i=1:initialIterNum
    [hsEstimate hrEstimate ] = estimateScale(photo, topbandSize,bottombandSize,leftbandSize,rightbandSize,insideoutTag, spatialBandwidth,rangeBandwidth,minimumRegionArea,reverseFG,occupyRatio,areaThres,outputDetail);
    spatialBandwidth=hsEstimate;
    rangeBandwidth  =hrEstimate;    
end

yStart=topbandSize+1;yEnd=height-bottombandSize;
xStart=leftbandSize+1;xEnd=width-rightbandSize;
bgMask= true(height,width);
bgMask(yStart:yEnd,xStart:xEnd)=0;

if insideoutTag==1
    bgMask=~bgMask;
end
bgMask0=bgMask;
area_fgMask=height*width-sum(bgMask(:));
if insideoutTag==1                  %for insideoutTag==1, use the full image as the roi region.
    roiMask= true(height,width);
else                                %for insideoutTag==0, using a expanding fgMask as the roi region.
    roiMask= false(height,width);     
    bandSize=20;
    yStartROI=max(yStart-bandSize,1);yEndROI=min(yEnd+bandSize,height);
    xStartROI=max(xStart-bandSize,1);xEndROI=min(xEnd+bandSize,width);
    roiMask(yStartROI:yEndROI,xStartROI:xEndROI)=1; %roiMask is a expanding rectangle of the fgMask by dilating the fgMask outwards several pixels in all 4 directions.           
end

[fimage labels modes regSize]=edison_wrapper(photo,@RGB2Lab,'SpatialBandWidth',spatialBandwidth,'RangeBandWidth',rangeBandwidth, 'MinimumRegionArea',minimumRegionArea,'synergistic',false);

modes=modes.';
labels=uint16(labels)+1;
numLabels=max(labels(:));
labelPixels = struct('area',{},'pixels',{});
for i=1:numLabels
    patchPixels=find(labels==i); 
    labelPixels(i).area=length(patchPixels);
    labelPixels(i).pixels=patchPixels;
end

if outputDetail==1
    outputfilename='adaptivemeanshiftpatches.png';
    outputMeanshiftImage(modes,labels,topbandSize,bottombandSize,leftbandSize,rightbandSize,insideoutTag,reverseFG,outputfilename);
end


[poi2labels gaussSets numPOI bgMask bgLabels0 unLabels0]=patchInitialization(photo,labels,roiMask,bgMask,areaThres,nDim); %Defaultly, roiMask is 20-pixel extension of ~bgMask
if (outputDetail==1)
    figure,imshow(~bgMask);title('initial fgMap0');    
end
KLDists_sym5 = computeDistancematrix(gaussSets,areaThres);  

iterNum=10;
similarity_list=zeros(iterNum,1);
fmeasureScore_max=-1.0;     
fgMap_fuse= false(height,width,iterNum);
for i=1:iterNum
    if isempty(unLabels0)
        fprintf('no unLabels0!!!!!!\n');
        fgMap_fuse(:,:,i)= false(height,width);
        similarity_list(i)=1;
        fgMap_max= false(height,width);
        break;        
    end
    
    [labelProbabilityMaps_list]=figuregroundLabeling(bgLabels0,unLabels0,numPOI,KLDists_sym5,nDim,tag_softlabel);    
    [fgMap_hypotheses fmeasureScore_best fgMap_best]=autoSelectbest_soft(i,labelPixels,bgLabels0, unLabels0, poi2labels, KLDists_sym5,labelProbabilityMaps_list,gtBinary,reverseFG,bgMask0,area_fgMask,outputDetail);    
    %note that fgMap_best is always actual fgmap, while fgMap_hypotheses is negative map for reverseFG==1.
    if outputDetail==1 
        figure;
        subplot(2,2,1);imshow(fgMap_hypotheses(:,:,1) ); title(sprintf('MSER result (iter %d)',i));
        subplot(2,2,2);imshow(fgMap_hypotheses(:,:,2) ); title(sprintf('a-cut result (iter %d)',i));
        subplot(2,2,3);imshow(fgMap_hypotheses(:,:,3) ); title(sprintf('m-cut1 result (iter %d)',i));   
        subplot(2,2,4);imshow(fgMap_hypotheses(:,:,4) ); title(sprintf('m-cut2 result (iter %d)',i)); 
    end 
    similarity_list(i)=similarityMeasure(fgMap_hypotheses);       %4 inputs
    if fmeasureScore_best>fmeasureScore_max
        fmeasureScore_max=fmeasureScore_best;
        fgMap_max=fgMap_best;
    end
    fgMap_i=fgMap_hypotheses(:,:,1)+fgMap_hypotheses(:,:,2)+fgMap_hypotheses(:,:,3)+fgMap_hypotheses(:,:,4);    %note that fgMap_i is negative map for reverseFG==1 !!!   
    
    if reverseFG==1     %reverseFG==1 implies insideoutTag==1 !!!
       fgMap_fuse(:,:,i) =(fgMap_i<2);  
    else
       fgMap_fuse(:,:,i)=(fgMap_i>=2);     %use average of the 4 hypotheses as the candidate result for this iteratio    
    end    
        
    fgMask=fgMap_hypotheses(:,:,1);     %scheme 1: use MSER hypothesis for background propagation.
    
    if bgMask==~fgMask
        fprintf('iteration stop updating,break out at i=%d.\n',i);
        similarity_list=similarity_list(1:i);
        break;
    end
    bgMask=~fgMask;    
    [bgLabels0 unLabels0]=fgbgUpdate(gaussSets, bgMask);    %update bgLabels and unLabels under new bgMask.
end 
num_iter=i;
[sim_winner iter_winner]=max(similarity_list);
finalfgMaps= false(height,width,4);
finalfgMaps(:,:,1)=fgMap_fuse(:,:,iter_winner);  
finalfgMaps(:,:,2)=fgMap_fuse(:,:,1);
finalfgMaps(:,:,3)=fgMap_fuse(:,:,i);
finalfgMaps(:,:,4)=fgMap_max;

if reverseFG==1     
    for i=1:4
        fgMap_tmp =extractMatchedregion(finalfgMaps(:,:,i), bgMask0);  
        finalfgMaps(:,:,i)=fgMap_tmp;
    end
end

if outputDetail==1
    figure;    
    subplot(2,2,1);imshow(finalfgMaps(:,:,1)); title(sprintf('AutoChoice result (iter %d)',iter_winner));    
    subplot(2,2,2);imshow(finalfgMaps(:,:,4)); title('Best hypothesis');
    subplot(2,2,3);imshow(finalfgMaps(:,:,2)); title('First iter result');
    subplot(2,2,4);imshow(finalfgMaps(:,:,3)); title(sprintf('Last iter result (iter %d)',num_iter));
    
    imwrite(finalfgMaps(:,:,1),'autoChoice_softlabel.png');
    imwrite(finalfgMaps(:,:,2),'firstIter.png');
    imwrite(finalfgMaps(:,:,3),'lastIter.png');
    imwrite(finalfgMaps(:,:,4),'bestHypothesis.png');
end 
