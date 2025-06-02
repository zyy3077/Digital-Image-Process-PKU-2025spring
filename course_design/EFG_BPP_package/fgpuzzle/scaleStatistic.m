function [hsEstimate hrEstimate]=scaleStatistic(gaussSets,size_roiMask,occupyRatio)

numPOI=length(gaussSets);

hr=zeros(numPOI,3);
hs=zeros(numPOI,2);
for i=1:numPOI
    sigma=gaussSets(i).cov;         
    if numel(sigma)==0              
        hr(i,:)=NaN;
        hs(i,:)=NaN;
        continue;
    end
    hr(i,1:3)=[sigma(1,1) sigma(2,2) sigma(3,3) ];      %Lab covariance matrix, range
    hs(i,1:2)=[sigma(4,4) sigma(5,5) ];                 %xy covariance matrix, spatial
end

validIndex=find(isnan(hr(:,1))==0);
hrValid=hr(validIndex,:);               %n*3 matrix
hsValid=hs(validIndex,:);               %n*2 matrix

hsEstimate=sqrt( mean( hsValid(:) ) );
hrEstimate=sqrt( mean( max(hrValid,[],2) ) );

hsEstimate  =min(15,floor(hsEstimate));
hrEstimate  =min(10.8,hrEstimate);

numPatchThres_high=size_roiMask*occupyRatio/200;
if numPOI>=min(numPatchThres_high,300)      
    hsEstimate =14;                         %treat cluttered textures by bigger kernel bandwidths.
    hrEstimate =12;    
end
