function similarity=similarityMeasure(fgMap_hypotheses)

k=0;
num=size(fgMap_hypotheses,3);
sim=zeros(1,num*(num-1)/2);

for i=1:num-1
    for j=i+1:num
        map1=fgMap_hypotheses(:,:,i);
        map2=fgMap_hypotheses(:,:,j);
        
        map_inter=map1 & map2;
        map_union=map1 | map2;        
        k=k+1;
        sim(k)=sum(map_inter(:))/sum(map_union(:));
    end
end

similarity=mean(sim);
        
        


