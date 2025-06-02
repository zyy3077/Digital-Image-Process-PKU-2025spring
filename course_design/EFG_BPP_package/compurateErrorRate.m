function errorRate=compurateErrorRate(imTrue,imRef,parameters)

topbandSize         =parameters( 1);
bottombandSize      =parameters( 2);
leftbandSize        =parameters( 3);
rightbandSize       =parameters( 4);
insideoutTag        =parameters( 5);   

[height,width]=size(imTrue);

iTrue = find(imTrue == 1);
iRef = find(imRef == 1);

errorArea=length(setxor(iTrue,iRef));

yStart=topbandSize+1;yEnd=height-bottombandSize;
xStart=leftbandSize+1;xEnd=width-rightbandSize;
boxArea=(xEnd-xStart+1)*(yEnd-yStart+1);

if insideoutTag==0
    roiArea=boxArea;
else
    roiArea=height*width-boxArea;
end

errorRate=errorArea/roiArea;

    
    
    