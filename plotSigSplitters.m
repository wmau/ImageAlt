function plotSigSplitters(splittersByTrialType,tuningcurves,deltacurve,sigcurve,neuronID)
%
%
%

%%  Get statistically significant splitters
    sigSplitters = find(cellfun(@any,sigcurve)); 
    savepdf = 0;
    
    plotSplitters(splittersByTrialType,tuningcurves,deltacurve,sigcurve,sigSplitters,neuronID,savepdf); 
end