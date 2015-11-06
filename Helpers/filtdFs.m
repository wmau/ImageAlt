function [dFF,raw] = filtdFs(Rawtrace,FT)
%[dFF,raw] = filtdFs(Rawtrace,FT)
%
%   Filters the raw fluorescence trace of an neuron mask. Eliminates some
%   ROI crosstalk by filtering Rawtrace through FT. dFF is Rawtrace where
%   FT is equal to 1. Where FT is equal to 0, Rawtrace is 0. 
%
%   INPUTS
%       Rawtrace: Output from ExtractTracesProc.
%
%       FT: Output from TENASPIS. 
%
%   OUTPUT
%       dFF: Thresholded Rawtrace.
%
%       raw: dF/F without thresholding. 
%

%% 
    %Get the mean fluorescence and divide fluorescence by this mean. 
    nFrames = size(Rawtrace,2); 
    F = mean(Rawtrace,2); 
    dFF = Rawtrace./repmat(F,1,nFrames); 
    raw = dFF; 
    
    %Get rid of fluorescence where TENASPIS did not detect a spike. 
    dFF(FT~=1) = 0;
    
end