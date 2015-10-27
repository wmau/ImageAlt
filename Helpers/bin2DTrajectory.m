function [Xbin,Ybin] = bin2DTrajectory(x,y,cmperbin)
%[Xbin,Ybin] = bin2DTrajectory(x,y,cmperbin)
%
%   Bins trajectory in two-dimensional space. 
%
%   INPUTS
%       X & Y: Tracking data. 
%
%       cmperbin: Centimeters per pixel. Usually 0.25. 
%

    Xrange = max(x)-min(x);
    Yrange = max(y)-min(y);

    NumXBins = ceil(Xrange/cmperbin);
    NumYBins = ceil(Yrange/cmperbin);

    Xedges = (0:NumXBins)*cmperbin+min(x);
    Yedges = (0:NumYBins)*cmperbin+min(y);

    [~,Xbin] = histc(x,Xedges);
    [~,Ybin] = histc(y,Yedges);

    Xbin(Xbin == (NumXBins+1)) = NumXBins;
    Ybin(Ybin == (NumYBins+1)) = NumYBins;

    Xbin(Xbin == 0) = 1;
    Ybin(Ybin == 0) = 1;
end