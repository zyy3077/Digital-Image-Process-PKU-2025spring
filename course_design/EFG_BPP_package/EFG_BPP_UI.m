addpath('./fgpuzzle/');
clear all;close all;
iptsetpref('ImshowBorder','loose');

[filename,pathname]=uigetfile('*.*','Select image file');
longfilename = strcat(pathname,filename);
photo = imread(longfilename);
[imageHeight,imageWidth,imageDepth]=size(photo);

figure,imshow(photo,'InitialMagnification',100);
title('Drag a ROI rectangle by mouse to start segmentation');

rect = round(getrect());       %rect is a four-element vector with the form [xmin ymin width height], xmin and ymin may be negative.
x_left=max(rect(1),0);
x_right =min(rect(1)+rect(3),imageWidth-1);
y_top =max(rect(2),0);
y_bottom=min(rect(2)+rect(4),imageHeight-1);
corners=[x_left,y_top,x_right,y_bottom];

hold on;
plot([x_left+1,  x_right+1],[y_top+1,   y_top+1   ],'LineWidth', 1, 'Color', 'b');
plot([x_left+1,  x_right+1],[y_bottom+1,y_bottom+1],'LineWidth', 1, 'Color', 'b');
plot([x_left+1,  x_left+1 ],[y_top+1,   y_bottom+1],'LineWidth', 1, 'Color', 'b');
plot([x_right+1, x_right+1],[y_top+1,   y_bottom+1],'LineWidth', 1, 'Color', 'b');
drawnow;

fprintf('Processing EFG_BPP...');
parameters(1)=y_top;
parameters(2)=imageHeight-1-y_bottom;
parameters(3)=x_left;
parameters(4)=imageWidth-1-x_right;
parameters( 5)=0;   
parameters( 6)=7;     
parameters( 7)=6;
parameters( 8)=80;
parameters(9)=1;
parameters(10)=0;
parameters(11)=5;
parameters(12)=1;

parameters

gtBinary=[];outputDetail=1;
[finalfgMaps fmeasureScore_max num_iter iter_winner] = solveFGpuzzle2(photo,gtBinary,parameters,outputDetail);
fprintf('finish\n');
