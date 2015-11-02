function plotSigSplitters(session,plot_type,invert_raster_color)
%plotSigSplitters(session)
%       
%   Takes structure from MD and directs you to the folder, loads splitter
%   information, and plots rasters and tuning curves for left and right
%   trials. 
%
%      plot_type =  1 includes the significance curves at the bottomr, 2
%           stacks all 3 in a single column, 3 produces only rasters. 4 is the same
%           as 1 but tacks on the 3D Tmap at the end, and requires inputting the
%           appropriate TMap cell after 4 (e.g. ...'plot_type,'4,TMap). 1 =
%           default.
%
%   invert_raster_color: plots with background white and transients
%           in gray/black.  Default = 0 uses colormap(gray).
%

if nargin < 3
    invert_raster_color = 0;
    if nargin < 2
        plot_type = 1;
    end
end

%% Navigate to folder and load data. 
    path = session.Location; 
    cd(path); 
    
    load('splittersByTrialType.mat','cellRespsByTrialType'); 
    load('sigSplitters.mat'); 
    
    if plot_type == 4
       load('PlaceMaps.mat','TMap','OccMap')
       for j = 1:length(TMap)
           [OccMap_smooth, TMap_nan{j}] = make_nan_TMap(OccMap, TMap{j});
       end
    end

%%  Get statistically significant splitters
    sigSplitters = find(cellfun(@any,sigcurve)); 
    savepdf = 0;            %Toggle whether you want to save all rasters as pdfs. 
    
    if plot_type ~= 4
        plotSplitters(cellRespsByTrialType,tuningcurves,deltacurve,sigcurve,...
            sigSplitters,savepdf,'plot_type',plot_type,'invert_raster_color',...
            invert_raster_color);
    else
       plotSplitters(cellRespsByTrialType,tuningcurves,deltacurve,sigcurve,...
            sigSplitters,savepdf,'plot_type',plot_type,TMap_nan,'invert_raster_color',...
            invert_raster_color); 
    end
end