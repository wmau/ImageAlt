function pMap = flattenPosterior(posterior,XBin,YBin)
%pMap = flattenPosterior(posterior,XBin,YBin)
%
%   We ran data that had been passed through sub2ind so the subscripts were
%   transformed into linear indices. This function transforms it back and
%   outputs an intuitive posterior probability map.
%
%   INPUTS
%       posterior: FxB matrix from BayesianPredict. 
%
%       XBin & YBin: Binned tracking data from bin2DTrajectory or
%       BayesianDecode. 
%
%   OUTPUT
%       pMap: XxYxF matrix (X&Y=number of X and Y bins,F=number of frames).
%       Each value in the matrix is the probability of the mouse residing
%       in that pixel based on imaging data. 
%

%% Transform the posterior probability to a more intuitive structure. 
    %Create a bin vector for transformation into subscripts. 
    [nFrames,nBins] = size(posterior); 
    binVector = 1:nBins; 
    
    %Borders of the bins. 
    borders = [max(XBin),max(YBin)]; 
    
    %Transform into subscripts. 
    [r,c] = ind2sub(borders,binVector); 
    
    %Deal posterior probability values. 
    pMap = zeros([borders(2),borders(1),nFrames]); 
    for thisFrame = 1:nFrames
        for thisBin = 1:nBins
            pMap(c(thisBin),r(thisBin),thisFrame) = posterior(thisFrame,thisBin);
        end 
    end
    
end