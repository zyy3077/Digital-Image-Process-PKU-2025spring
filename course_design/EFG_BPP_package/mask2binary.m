function binary=mask2binary(maskphoto)

[height,width,depth]=size(maskphoto);

maskR=(maskphoto(:,:,1)==255);
maskG=(maskphoto(:,:,2)==0);
maskB=(maskphoto(:,:,3)==0);

binary=255*uint8(maskR & maskG & maskB); 
