function binary=mask2binary_grabcut(maskphoto)

maskR=(maskphoto(:,:,1)==255);
binary=maskR; 
