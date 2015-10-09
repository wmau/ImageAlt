function plotSplitters(splittersByTrialType,tuningcurves,deltacurve,sigcurve,inds,savepdf,varargin)
%plotSplitters(splitters,active)
%
%   Plots splitters lap by lap. 
%
%   INPUTS:
%       splittersByTrialType: Nx2 cell array (N=number of cells active on
%       the stem) output from splitterByTrialType().
%
%       tuningcurves: Nx1 cell array containing 2xB matrices (B=number of
%       stem bins). Each row is the tuning curve for left (1) and right (2)
%       trials. 
%
%       deltacurve: Nx1 cell array containing 1xB matrices that are the
%       difference between the left and right tuning curves. Negative means
%       left responses higher than right. 
%
%       sigcurve: Nx1 cell array containing 1xB binary matrices that
%       indicate which bin contained statistically significant responses
%       between left and right trials. 
%       
%       inds: Vector indexing splittersByTrialType telling the function
%       what to plot. 
%
%       neuronID: Nx1 vector containing indices that reference FT (ie, the
%       ith element references the ith neuron in splittersByTrialType but
%       its value is the index of the neuron within FT. 
%
%       savepdf: Binary indicating whether or not you want to save every
%       plot as a pdf. 
%
%       varargins
%           plot_type =  1 includes the significance curves at the bottomr, 2 
%           stacks all 3 in a single column, 3 produces only rasters. 4 is the same
%            as 1 but tacks on the 3D Tmap at the end, and requires inputting the
%           appropriate TMap cell after 4 (e.g. ...'plot_type,'4,TMap). 1 =
%           default.
%
%           invert_raster_color: plots with background white and transients
%           in gray/black.  Default = 0 uses colormap(gray).
%
%           

% if nargin < 5
%     for i=1:length(inds)
%         figure(inds(i));
%         subplot(1,2,1);
%             imagesc(splittersByTrialType{inds(i),1});
%             title('Left Trials');
%             xlabel('Stem Bins');
%             ylabel('Lap');
%         subplot(1,2,2); 
%             imagesc(splittersByTrialType{inds(i),2});
%             title('Right Trials');
%             xlabel('Stem Bins');
%             ylabel('Lap'); 
%     end
% else

%% Process varargins
plot_type = 0; % default
invert_raster_color = 0; % default
for j = 1:length(varargin)
   if strcmpi('plot_type',varargin{j})
       plot_type = varargin{j+1};
       if plot_type == 4
           TMap_use = varargin{j+2};
       end
   end
   if strcmpi('invert_raster_color',varargin{j})
       invert_raster_color = varargin{j+1};
   end
end

%% Run everything else
    for i=1:length(inds)
        % Setup subplots ahead of time
        figure(inds(i));
        if plot_type == 1
            subplot(2,2,1); h1 = gca;
            subplot(2,2,2); h2 = gca;
            subplot(2,2,3:4); h3 = gca;
        elseif plot_type == 2
            subplot(3,1,1); h1 = gca;
            subplot(3,1,2); h2 = gca;
            subplot(3,1,3); h3 = gca;
        elseif plot_type == 3
            subplot(1,2,1); h1 = gca;
            subplot(1,2,2); h2 = gca;
        elseif plot_type == 4
            subplot(3,2,1); h1 = gca;
            subplot(3,2,2); h2 = gca;
            subplot(3,2,3:4); h3 = gca;
            subplot(3,2,5:6); h4 = gca;
        end
        
        maxRate = max([max(splittersByTrialType{inds(i),1}),...
            max(splittersByTrialType{inds(i),2})]); 

        subplot(h1);
            imagesc(splittersByTrialType{inds(i),1});
                title('Left Trials'); xlabel('Stem Position'); ylabel('Lap');
                caxis([0 maxRate]);
                
        subplot(h2); 
            imagesc(splittersByTrialType{inds(i),2});
                title('Right Trials'); xlabel('Stem Position'); ylabel('Lap'); 
                caxis([0 maxRate]); cmap = colormap('gray');
                if invert_raster_color == 1
%                     cmap = get(gca,'ColorOrder');
                    cmap2 = flip(cmap,1);
                    colormap(h1,cmap2);
                    colormap(h2,cmap2);
                end
                % Plot significance curves if specified
                if plot_type == 1 || plot_type == 2 || plot_type == 4
                    subplot(h3)
                    plot(tuningcurves{inds(i)}(1,:),'b');   %Left
                    hold on;
                    plot(tuningcurves{inds(i)}(2,:),'r');   %Right
                    
                    %Determine whether this cell is more active on left or right
                    %trials by looking at the difference between the tuning curves.
                    deltasign = sign(deltacurve{inds(i)});
                    deltasign(deltasign > 0) = 2;           %Right
                    deltasign(deltasign < 0) = 1;           %Left
                    
                    for trialType = 1:2  %Left and right
                        
                        %Statistically significant bins.
                        sigBins = find(deltasign==trialType & sigcurve{inds(i)});
                        
                        %For placing asterisks a relative distance from the curve.
                        ylim = get(gca,'ylim');
                        sf = 0.1;
                        
                        %Define color based on left or right trial.
                        if trialType == 1; col = 'b';       %Left
                        else col = 'r'; end                %Right
                        
                        plot(sigBins,tuningcurves{inds(i)}(trialType,sigBins)+ylim(2)*sf,['*',col]);
                    end
                    hold off;
                    
                    %Fix up the plot.
                    xlim([1 length(deltasign)]); set(gca,'ticklength',[0 0]); 
                    xlabel('Stem Bins'); ylabel('Transient Probability'); legend({'Left','Right'},'location','best');
                    
                    if plot_type == 4
                       subplot(h4); imagesc_nan(rot90(TMap_use{inds(i)},-1));
                       colormap(h4,'parula')
                    end
                end
                
                % Attempt to add in text...
                annotation(figure(inds(i)),'textbox',...
                    [0.21584375 0.965760322255791 0.58025 0.026183282980866],...
                    'String',{['GCamp6f\_30 Neuron' num2str(inds(i))]},...
                    'FitBoxToText','off','LineStyle','none');

            
            %Save plot as pdf. 
            if savepdf==1
                print(fullfile(pwd,['Neuron #',num2str(inds(i))]),'-dpdf');
            end
            
    end
 %end
end