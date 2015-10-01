function plotSigSplitters(cellRespsByTrialType,tuningcurves,deltacurve,sigcurve,neuronID)
%
%
%

%%  Get statistically significant splitters
    sigSplitters = find(cellfun(@any,sigcurve)); 
    savepdf = 0;
    
    plotSplitters(cellRespsByTrialType,tuningcurves,deltacurve,sigcurve,sigSplitters,neuronID,savepdf); 
end