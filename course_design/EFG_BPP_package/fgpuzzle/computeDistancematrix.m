function KLDists_sym = computeDistancematrix(gaussSets,areaThres)   

numPOI=length(gaussSets);
KLDivergence=zeros(numPOI,numPOI); 

for k=1:numPOI
    if gaussSets(k).size<areaThres
        KLDivergence(1:numPOI,k)=NaN;
        continue;
    end      
    
    mu_k=gaussSets(k).mean;
    sigma_k=gaussSets(k).cov;
    covInv_k=pinv(sigma_k);

    for i=1:numPOI
        if (i==k)
            continue;
        end
        if gaussSets(i).size<areaThres
            KLDivergence(i,k)=NaN;
            continue;
        end
        mu_i=gaussSets(i).mean;                 
        sigma_i=gaussSets(i).cov; 
        
        KLterm1= log( det(sigma_k)/det(sigma_i) ) ;     %KLterm1 is in general very small in value, but may be negative. It is not dominant.
        KLterm1= real( KLterm1 );                       %KLterm1 may have imaginary term (0i) due to numerical instability. Force it to be real.
        KLterm2 = trace(covInv_k*sigma_i);              %KLterm2 is positive and may be large in value and become the dominant term.
        KLterm3 = (mu_i-mu_k)*covInv_k*(mu_i-mu_k).';
        KLDivergence(i,k)=0.5*( KLterm1+KLterm2+KLterm3 );     
    end
end

KLDists_sym=zeros(numPOI,numPOI);

for i=1:numPOI
    for j=1:numPOI
        KLDists_sym(i,j)=min(KLDivergence(i,j),KLDivergence(j,i));   %note that min(3,NaN)=3
    end
end
