function plotSigSplitters(splittersByTrialType,tuningcurves,deltacurve,sigcurve)
%
%
%

%%  Get statistically significant splitters
    sigSplitters = find(cellfun(@any,sigcurve)); 
    
    plotSplitters(splittersByTrialType,tuningcurves,deltacurve,sigcurve,sigSplitters); 
end