function matchedfgMap=extractMatchedregion(finalfgMap,rectangleMask)

[L,num] = bwlabel(finalfgMap,4);
if num<=1       %less than or only one connected component.
    matchedfgMap=finalfgMap;
    return;
end    
for i=1:num
    regionMask=(L==i);          
    if any (regionMask(:) & rectangleMask(:) )  %true means the intersection is nonempty 
        matchedfgMap=regionMask;
        break;
    end
end




        
