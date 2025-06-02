addpath('./fgpuzzle/');
clear all; close all;
iptsetpref('ImshowBorder','loose');

strImpath ='images/';
strGtpath ='';
strFilenames='filenames.mat';
strBandtable='bandtable.mat';

try
    load([strImpath strFilenames]);         %load filenames variable
    load([strImpath strBandtable]);         %load bandtable variable
catch
    fprintf('Configuration path or filename incorrect, exit\n');
    return;
end


imStart=18;                                  %try other values between 1 and 20.
imNum=1;
imEnd=imStart+imNum-1;

totalNum=size(bandtable,1);

if imStart>totalNum || imEnd>totalNum
    fprintf('Image index overflow!\n ');
    return;
end

fmeasureTable2 = batchSolve2(strImpath,strGtpath, filenames(imStart:imEnd,:),bandtable(imStart:imEnd,:));   
