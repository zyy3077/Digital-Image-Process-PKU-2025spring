%imOne,imTwo:binary image of logical type. 0 for background and 1 for foreground
function [fScore precision recall] = fmeasure(imTrue,imRef)

sizeTrue = sum(imTrue(:)); 
sizeRef  = sum(imRef(:));

fScore=0;
precision=0;
recall=0;

if sizeTrue==0 || sizeRef==0
    return;
end

imCross=imTrue & imRef;
sizeCross = sum(imCross(:));
precision = sizeCross/sizeRef;
recall = sizeCross/sizeTrue;

if (precision+recall==0)    %treat full-background output
    fScore=0;
else
    fScore = 2*precision*recall/(precision+recall);
end

