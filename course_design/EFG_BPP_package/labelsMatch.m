clear all;close all;

load labels;
load labels32;

for i=1:max(labels(:));
    a1=find(labels==i);
    iMatch(i)=labels32(a1(1));
    a2=find(labels32==iMatch(i));
    lengthDiff(i)=length(a1)-length(a2);
end
    