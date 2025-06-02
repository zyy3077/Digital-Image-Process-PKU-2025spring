function binary=mask2binary2(maskphoto)

[height,width,depth]=size(maskphoto);

maskR=(maskphoto(:,:,1)==255);
maskG=(maskphoto(:,:,2)==0);
maskB=(maskphoto(:,:,3)==0);
binaryRed=(maskR & maskG & maskB);

maskR=(maskphoto(:,:,1)==0);
maskG=(maskphoto(:,:,2)==0);
maskB=(maskphoto(:,:,3)==255);
binaryBlue=(maskR & maskG & maskB);

binary=(binaryRed | binaryBlue);            %return a logic type binary groundtruth image.