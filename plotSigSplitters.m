function plotSigSplitters(session)
%plotSigSplitters(session)
%       
%   Takes structure from MD and directs you to the folder, loads splitter
%   information, and plots rasters and tuning curves for left and right
%   trials. 
%

%% Navigate to folder and load data. 
    path = session.Location; 
    cd(path); 
    
    load('splittersByTrialType.mat','cellRespsByTrialType'); 
    load('sigSplitters.mat'); 

%%  Get statistically significant splitters
    sigSplitters = find(cellfun(@any,sigcurve)); 
    savepdf = 1;            %Toggle whether you want to save all rasters as pdfs. 
    
    plotSplitters(cellRespsByTrialType,tuningcurves,deltacurve,sigcurve,sigSplitters,savepdf); 
end