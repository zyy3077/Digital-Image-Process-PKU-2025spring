function outputMeanshiftImage(modes,labels,topbandSize,bottombandSize,leftbandSize,rightbandSize,insideoutTag,reverseFG,outputfilename)

[height width]=size(labels);
numClusters=max(labels(:));

L=zeros(height,width);
a=zeros(height,width);
b=zeros(height,width);
for i=1:numClusters
    index=find(labels==i);
    L(index)=modes(i,1);
    a(index)=modes(i,2);
    b(index)=modes(i,3);
end
Im_seg=Lab2RGB(L,a,b);
Im_seg_bb=drawboundingbox(Im_seg,topbandSize,bottombandSize,leftbandSize,rightbandSize,insideoutTag,reverseFG); 
figure,imshow(Im_seg_bb,[0 255]);title(outputfilename);
imwrite(Im_seg_bb,outputfilename);
