function I = spatialInfo(FTcell,XBin,YBin)
%
%
%

%% 
    nXBins = max(XBin); nYBins = max(YBin); 
    flat = sub2ind([nXBins,nYBins],XBin,YBin); 
    bins = unique(flat); 
    nBins = length(bins); 
    nFrames = size(FTcell,2); 
    
    %Preallocate.
    lambda_i = nan(nBins,1); 
    dwell = nan(nBins,1); 
    inBin = logical(zeros(nFrames,nBins)); 
    
    for i=1:nBins
        thisBin = bins(i);
        inBin(:,i) = flat == thisBin;
        
        dwell(i) = sum(inBin(:,i)); 
    end
    
    %Probability of dwelling in a bin. 
    p_i = dwell./nFrames; 
    
    %Eliminate frames where occupancy < 50 ms. 
    dwell(dwell<=1) = nan;
    p_i(isnan(dwell)) = nan; 
       
    %Find good bins. 
    good = find(~isnan(p_i)); 
    nGood = length(good); 
    
    for thisBin=1:nGood
        i = good(thisBin);
        lambda_i(i) = sum(FTcell(inBin(:,i)))/dwell(i);
    end
    
    %Mean calcium event rate. 
    lambda = mean(FTcell); 
    
    %I = sum(p_i * lambda_i * log2(lambda_i/lambda))
    I = nansum(p_i.*lambda_i.*log2(lambda_i./lambda));

end