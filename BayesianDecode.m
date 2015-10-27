function [Mdl,XBin,YBin] = BayesianDecode(x,y,FT)
%Mdl = BayesianDecode(x,y,FT)
%
%   Takes the tracking and neural data and produces a Bayesian model for
%   spike data. 
%
%   INPUTS
%       X & Y: Tracking data. 
%
%       FT: Calcium imaging data from ProcOut.mat.
%

%% Construct a Bayesian model using a random subset of training data. 
    %Set up. 
    nFrames = size(FT,2);       %Number of frames. 
    propTrain = 0.5;            %Proportion of the data we are using as training. 
    
    %Bin the position data in two dimensions. 
    cmperbin = 2; 
    [XBin,YBin] = bin2DTrajectory(x,y,cmperbin); 
    
    %Bin borders of the maze. 
    borders = [max(XBin),max(YBin)];    
    
    %Linearize the binned position data then find priors for each pixel. 
    linInd = sub2ind(borders,XBin,YBin); 
    counts = hist(linInd,prod(borders)); 
    prior = counts./nFrames; 
    
    %Transpose the trace data to fit the form that the function wants. 
    FTt = FT'; 
    
    %Generate random indices that will reference the training data. 
    trainingInds = 1:round(nFrames*propTrain); 
    
    %Get the predictor and response variables. 
    X = FTt(trainingInds,:); 
    Y = linInd(trainingInds); 
    
    %Fit the model using a multivariate multinomial distribution. 
    Mdl = fitcnb(X,Y,'Distribution','mvmn','ClassNames',(1:prod(borders)),'Prior','uniform'); 
    Mdl = compact(Mdl); 
end