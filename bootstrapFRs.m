function randmeans = bootstrapFRs(FT,n,B)
%randmeans = bootstrapFRs(FT,n,B)
%
%   Computes the number of calcium events for random neurons normalized to
%   the recording time. 
%
%   INPUTS
%       FT: Tenaspis output. 
%
%       n: Number of neurons in sample. 
%
%       B: Bootstrap iterations. 
%
%   OUTPUTS
%       randmeans: nxB matrix whereby each column entry is the mean
%       activity of a subpopulation of neurons. 
%

%%
    nNeurons = size(FT,1); 
    randmeans = nan(n,B); 
    parfor i=1:B
        randind = randsample(nNeurons,n);
        randmeans(:,i) = mean(FT(randind,:),2); 
    end
    
end