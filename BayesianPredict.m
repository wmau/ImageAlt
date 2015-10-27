function posterior = BayesianPredict(Mdl,FT)
%posterior = BayesianPredict(Mdl,FT)
%
%   Get the posterior probabilities for each pixel. 
%
%   INPUTS
%       Mdl: Bayesian classifier object. 
%
%       FT: Imaging data from ProcOut.mat. 
%
%   OUTPUT
%       posterior: FxB matrix (F=number of frames, B=number of pixels)
%       containing posterior probabilities, or predictions, of the mouse's
%       location based off the Bayesian model. 
%

%% Get posterior probabilities.
    FTt = FT'; 
    [~,posterior] = predict(Mdl,FTt); 
   
end