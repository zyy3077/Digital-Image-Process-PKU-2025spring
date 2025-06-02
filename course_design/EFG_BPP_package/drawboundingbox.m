function Im_seg=drawboundingbox(photo,topbandSize,bottombandSize,leftbandSize,rightbandSize,insideoutTag,reverseFG) 

Im_seg=photo;
height=size(photo,1);width=size(photo,2);

yStart=topbandSize+1;yEnd=height-bottombandSize;
xStart=leftbandSize+1;xEnd=width-rightbandSize;

if insideoutTag==0              
    maskborderColor=[0 0 255];
elseif reverseFG==0
    maskborderColor=[255 0 0];
else
    maskborderColor=[0 255 0];
end 

for i=1:3   
    Im_seg(yStart,xStart:xEnd,i)=maskborderColor(i);
    Im_seg(yEnd,xStart:xEnd,i)  =maskborderColor(i);
    Im_seg(yStart:yEnd,xStart,i)=maskborderColor(i);
    Im_seg(yStart:yEnd,xEnd,i)  =maskborderColor(i);
end
