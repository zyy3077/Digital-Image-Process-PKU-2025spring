function fmeasureTable2 = batchSolve2(strImpath,strGtpath, filenames,bandtable)

filenames
imNum=size(bandtable,1); %number of images to process
if imNum==1
    outputDetail=1;
else
    outputDetail=0;
end

if isempty(strGtpath)         %no ground truth  
    hasGroundtruth=0;       
elseif strGtpath(1,1)=='w' && strGtpath(1,9)~='2'    %weizmann 1-obj images ground truth
    hasGroundtruth=1;
elseif strGtpath(1,1)=='w' && strGtpath(1,9)=='2'    %weizmann 2-obj images ground truth
    hasGroundtruth=2;
elseif strGtpath(1,1)=='g'      %grabcut images ground truth
    hasGroundtruth=3;
elseif strGtpath(1,1)=='i'      %ivrg images ground truth
    hasGroundtruth=4;
end

fmeasureTable2=zeros(imNum,7);

for i=1:imNum
    strName=deblank(filenames(i,:));
    parameters=bandtable(i,:);
    
    try
        imphoto = imread([strImpath strName]);
        pointPos=strfind(strName,'.');
        strImageID=strName(1:pointPos-1);
        if hasGroundtruth==1        %weizmann 1-obj images            
            gtphoto = imread([strGtpath strImageID '_gt.png']);
            gtBinary=mask2binary2(gtphoto);            
        elseif hasGroundtruth==2    %weizmann 2-obj images            
            gtphoto = imread([strGtpath strImageID '_gt.png']);
            gtBinary=mask2binary2(gtphoto);
        elseif hasGroundtruth==3    %grabcut images
            gtphoto = imread([strGtpath strImageID '.bmp']);
            gtBinary=mask2binary_grabcut(gtphoto);        
        elseif hasGroundtruth==4    %ivrg images
            gtphoto = imread([strGtpath strImageID '_gt.bmp']);
            gtBinary=mask2binary_grabcut(gtphoto);        
        else
            gtBinary=[];
        end
    catch
        fprintf('Image path or filename incorrect, exit\n');
        return;
    end

    
    fprintf('\ni=%d, Processing image %s...\n',i,[strImpath strName]); 
    tic;
    [finalfgMaps fmeasureScore_max num_iter iter_winner] = solveFGpuzzle2(imphoto,gtBinary,parameters,outputDetail);
    
    time=toc;
    fprintf('Finish\n');   

    if ~hasGroundtruth
        continue;
    end
    
    [fScore  precision recall] = fmeasure(gtBinary,finalfgMaps(:,:,1));
    [fScore2 precision recall] = fmeasure(gtBinary,finalfgMaps(:,:,2));
    [fScore3 precision recall] = fmeasure(gtBinary,finalfgMaps(:,:,3));
    
    fmeasureTable2(i,1)=fScore;
    fmeasureTable2(i,2)=fmeasureScore_max;
    fmeasureTable2(i,3)=num_iter;
    fmeasureTable2(i,4)=iter_winner;    
    fmeasureTable2(i,5)=time;
    fmeasureTable2(i,6)=fScore2;
    fmeasureTable2(i,7)=fScore3;       
end

if hasGroundtruth
    fprintf(  'FinalResult     mean=%f, std=%f\n',  mean( fmeasureTable2(1:imNum,1) ),  std( fmeasureTable2(1:imNum,1) )*1.96/sqrt(imNum) );
    fprintf(  'BestHypothesis  mean=%f, std=%f\n',  mean( fmeasureTable2(1:imNum,2) ),  std( fmeasureTable2(1:imNum,2) )*1.96/sqrt(imNum) );
    fprintf(  'First iteration mean=%f, std=%f\n',  mean( fmeasureTable2(1:imNum,6) ),  std( fmeasureTable2(1:imNum,6) )*1.96/sqrt(imNum) );
    fprintf(  'Last iteration  mean=%f, std=%f\n',  mean( fmeasureTable2(1:imNum,7) ),  std( fmeasureTable2(1:imNum,7) )*1.96/sqrt(imNum) );
    fprintf(  'number_iter mean=%f (s), std=%f\n',  mean( fmeasureTable2(1:imNum,3) ),  std( fmeasureTable2(1:imNum,3) )*1.96/sqrt(imNum) );
    fprintf(  'iter_winner mean=%f (s), std=%f\n',  mean( fmeasureTable2(1:imNum,4) ),  std( fmeasureTable2(1:imNum,4) )*1.96/sqrt(imNum) );
    fprintf(  'mean time=%f\n',  mean( fmeasureTable2(1:imNum,5) ) );
end
    