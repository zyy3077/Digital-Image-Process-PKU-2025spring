Enhanced figure-ground classification with background prior propagation (EFG_BPP) matlab source code package ver2.0 README
-------------------------------------------------------------------

License:
============
We allow the freedom to inspect, modify, and reuse the code for academic and non-commercial purpose. 

Following is a list of the third-party code on which this package relies on. They are all open sources that allow free academic usage. 
1. mean-shift matlab wrapper files: edison_wrapper_mex.mexw64, edison_wrapper_mex.mexw32,edison_wrapper.m (http://www.wisdom.weizmann.ac.il/~bagon/matlab.html)
2. rgb2lab and lab2rgb converter matlab functions: rgb2lab.m lab2rgb.m. 

All other codes are fully developed by ourselves.


Availability:
============
The code can be downloaded by anyone, anywhere, free of charge, and without impediments such as registering, creating an account, contacting the authors, or knowing a password.


Functionality:
============
The code presents the idea of the algorithm clearly and permit replication of experimental results reported in the following paper:

Yisong Chen, Antoni. B. Chan, Adaptive figure-ground classification, CVPR2012.

Yisong Chen, Antoni. B. Chan, Enhanced figure-ground classification with background prior propagation, available on request.

We test the code with Matlab 7.x on windowsXP and windows7 platforms.  The code is self-contained and can in general directly run as guided in "installation".

It is our belief that the idea of the algorithm can be easily expanded to many vision tasks. You are encouraged to test it in all kinds of applications.


Installation: 
============
Easy. In general you can start immediately after unzipping the package.   

Try the following commands in matlab to test the f-g puzzle for some example images. We test them under windows7 and windowsXP operating systems.

>>testTrial_weizmann2	%test the 100 weizmann2 2-obj images in the folder imagesWeizmann2/ and give f-measure report.
>>EFG_BPP_UI		%This is a mini interactive fgclassification tool. Open an image, drag a blue mask box and see the segmentation result.
>>testTrial		%Examples of more configurations, including various mask types, non-adaptive initialization, and varied partition generation schemes. 

You can edit the following line in tesTrial.m to change the example image:
imStart=1;		%try other values between 1 and 20 

Following is a description of the bandtable parameters:

bandtable(:, 1): mask box top bandwidth (in pixels)
bandtable(:, 2): mask box bottom bandwidth (in pixels)
bandtable(:, 3): mask box left bandwidth (in pixels)
bandtable(:, 4): mask box right bandwidth (in pixels)
bandtable(:, 5): 0 denotes fg-inside mask (blue); 1 denotes fg-outside mask (red).
bandtable(:, 6): initial hs parameter, fixed to 7
bandtable(:, 7): initial hr parameter, fixed to 6
bandtable(:, 8): meanshift MinimumRegionArea parameter, generally set to 80 is OK, occasionally change for treating small holes or noises  
bandtable(:, 9): 1 denotes adaptive mean-shift (default); 0 denotes nonadaptive mean-shift. 
bandtable(:,10): 0 for default setting; 1 for figure/ground switch (green mask).
bandtable(:,11): 5 for 5D (L a b x y ) feature vector (default); 3 for 3D (L a b) feature vector. You can make a comparison.
bandtable(:,12): 1 for soft-label partitions (default); 0 for hard-label partitions.

You can test other images by organizing your own filenames.mat and bandtable.mat and checking the newly created *.png after running. 
Following are some websites for more images:

[1]	http://www.wisdom.weizmann.ac.il/~vision/Seg_Evaluation_DB/scores.html, Weizmann dataset webpage.
[2]	http://ivrg.epfl.ch/supplementary_material/RK_CVPR09/index.html, ivrg dataset webpage.
[3]	http://research.microsoft.com/en-us/um/cambridge/projects/visionimagevideoediting/segmentation/grabcut.htm.
[4]	http://www.eecs.berkeley.edu/Research/Projects/CS/vision/grouping/segbench/,Berkeley segmentation dataset page.


Memo: 
============
The meanshift dll files edison_wrapper_mex.mexw32/edison_wrapper_mex.mexw64 were built and work for matlab 7.x under windows7 and windowsXP operating systems.
In case the dll does not work due to different platforms, you can build edison_wrapper_mex.mexw32/edison_wrapper_mex.mexw64 yourself by following the steps below.

1. Install an open source matlab edison wrapper package and make it work: http://www.wisdom.weizmann.ac.il/~bagon/matlab.html.
2. Run compile_edison_wrapper.m to build the dll file edison_wrapper_mex.mexw32 or edison_wrapper_mex.mexw64 for your machine.
3. Copy (only) the newly generated edison_wrapper_mex.mexw32 or edison_wrapper_mex.mexw64 from the edison wrapper folder to the f-g classification working folder.
4. Run the tests.