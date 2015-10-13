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
%           plot_type =  
%               1 (default) includes the significance curves at the bottom.
%               2 stacks all 3 in a single column.
%               3 produces only rasters. 
%               4 is the same as 1 but tacks on the 3D Tmap at the end, and
%                   requires inputting the appropriate TMap cell after 4
%                   (e.g. ...'plot_type',4,TMap).
%               5 concatenates the left and right turn rasters then
%                   overlays a smoothed calcium event histogram. Note that
%                   significance markers are not plotted because they're hard
%                   to see. 
%               6 does the same as 5 but the histogram is a separate
%                   subplot.
%               7 same as 6 but with TMap also, need to include TMap
%                   variable as in 4.
%               8 same as 6 but plots a difference of TMaps for left and
%               right trials.  Must include Tmap_left and Tmap_right as 
%                   inputs after 'plot_type'.
%               
%           invert_raster_color: plots with background white and transients
%           in gray/black.  Default = 0 uses colormap(gray). 2 in
%           conjunction with plot_type = 7 results in plotting left trials
%           blue and right trials red
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
       if plot_type == 4 || plot_type == 7
           TMap_use = varargin{j+2};
       elseif plot_type == 8
           Tleft_nan = varargin{j+2};
           Tright_nan = varargin{j+3};
       end
   end
   if strcmpi('invert_raster_color',varargin{j})
       invert_raster_color = varargin{j+1};
   end
end

%% Run everything else
    if ismember(plot_type,[1:4]); 
    for i=1:length(inds)
        % Setup subplots ahead of time
        figure(inds(i));
        if plot_type == 1
            h1 = subplot(2,2,1);
            h2 = subplot(2,2,2); 
            h3 = subplot(2,2,3:4);
        elseif plot_type == 2
            h1 = subplot(3,1,1); 
            h2 = subplot(3,1,2); 
            h3 = subplot(3,1,3); 
        elseif plot_type == 3
            h1 = subplot(1,2,1);  
            h2 = subplot(1,2,2); 
        elseif plot_type == 4
            h1 = subplot(3,2,1); 
            h2 = subplot(3,2,2); 
            h3 = subplot(3,2,3:4); 
            h4 = subplot(3,2,5:6); 
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
                        yLim = get(gca,'ylim');
                        sf = 0.1;
                        
                        %Define color based on left or right trial.
                        if trialType == 1; col = 'b';       %Left
                        else col = 'r'; end                %Right
                        
                        plot(sigBins,tuningcurves{inds(i)}(trialType,sigBins)+yLim(2)*sf,['*',col]);
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
    
%% Stack rasters and overlay histogram. 
    %Number of left trials. We'll need this value when we separate the left
    %and right trials with a red line. 
    [nLTrials,nBins] = size(splittersByTrialType{1,1});
    nTrials = size(splittersByTrialType{1,2},1) + nLTrials;
    binDims = [1,nBins]; trialDims = [1,nTrials];
    bins = [1:0.001:nBins]';

    for i=1:length(inds)
        f = figure(inds(i));
        f.Position = [520 254 481 544];
        
        %Concatenate the rasters. Now we have one matrix with left trials
        %first and right trials start at index numLTrials+1. 
        raster = [  splittersByTrialType{inds(i),1};
                    -splittersByTrialType{inds(i),2}     ];  
        n_left = size(splittersByTrialType{inds(i),1},1);
        n_right = size(splittersByTrialType{inds(i),2},1);
                
        %Smoothing.
        leftFit = fit([1:nBins]',tuningcurves{inds(i)}(1,:)','smoothingspline');
        rightFit = fit([1:nBins]',tuningcurves{inds(i)}(2,:)','smoothingspline');
        leftCurve = feval(leftFit,bins);
        rightCurve = feval(rightFit,bins);
                
        %% Raster with overlaid smoothed histogram. 
        if plot_type == 5
        %Plot everything using plotyy. First y axis will be laps. Second
        %will be rate. 
            hold on;
            [h,~,splitCurves] = plotyy(binDims,trialDims,[bins, bins],[leftCurve, rightCurve]);   
                splitCurves(1).LineWidth = 2; splitCurves(1).Color = 'b';
                splitCurves(2).LineWidth = 2; splitCurves(2).Color = 'r';
                splitCurves = [leftCurve, rightCurve];
                set(h(1),'ydir','reverse'); 
            imagesc(raster);
            line(binDims,[nLTrials+0.5,nLTrials+0.5],'Color','g','LineWidth',2);
                yLim = get(h(2),'ylim');
                axis(h(1),[binDims,trialDims]); 
                set(h(1),'ytick',[1:10:nTrials]);    
                set(h(2),'ylim',[0,yLim(2)]);
                cmap = colormap('gray');
                if invert_raster_color == 1
                    cmap = flip(cmap,1);
                    colormap(h(1),cmap);
                end
                set(get(h(1),'Ylabel'),'String','Laps');
                set(get(h(2),'Ylabel'),'String','Rate'); 
                xlabel('Stem Bins'); xlim([1 nBins]);
                
%             [BIN,SIG] = significance(deltacurve,sigcurve,splitCurves,inds,i,bins,1);
%             plot(BIN{1},SIG{1},'b*',BIN{2},SIG{2},'r*');
                hold off;
                
        %% Concatenated raster with separate smoothed histogram. 
        elseif plot_type == 6
            subplot(2,1,1);           
            imagesc(raster);
            line(binDims,[nLTrials+0.5,nLTrials+0.5],'Color','g','LineWidth',2);  
                set(gca,'ytick',[1:10:nTrials]);    
                cmap = colormap('gray');
                if invert_raster_color == 1
                    cmap = flip(cmap,1);
                    colormap(gca,cmap);
                end
                ylabel('Laps'); set(gca,'ticklength',[0 0]);
            
            subplot(2,1,2);
            plot(bins,leftCurve,'b',bins,rightCurve,'r','LineWidth',2);
                xlabel('Stem Bins'); ylabel('Rate'); 
                hold on;
                
            splitCurves = [leftCurve,rightCurve];
            [BIN,SIG] = significance(deltacurve,sigcurve,splitCurves,inds,i,bins,1);
            plot(BIN{1},SIG{1},'b*',BIN{2},SIG{2},'r*');
                yLims = get(gca,'ylim');
                ylim([0,yLims(2)]); xlim([1,nBins]);
                hold off;
                set(gca,'ticklength',[0 0]); 
                legend({'Left','Right'},'location','best');
        elseif plot_type == 7 || plot_type == 8
            subplot(3,1,1);           
            imagesc(raster);
            line(binDims,[nLTrials+0.5,nLTrials+0.5],'Color','g','LineWidth',2);  
                set(gca,'ytick',[1:10:nTrials]);    
                cmap = colormap('gray');
                if invert_raster_color == 1
                    cmap = flip(cmap,1);
                    colormap(gca,cmap);
                elseif invert_raster_color == 2
                    cmap_use = [1 0 0; 1 1 1; 0 0 1];
%                     cmap_use = [1 0 0; 0.5 0 0; 1 1 1; 1 1 1; 1 1 1; 0 0 0.5; 0 0 1];
                    colormap(gca,cmap_use);
                    caxis([-2 2]);
                end
                ylabel('Laps'); set(gca,'ticklength',[0 0]);
                set(gca,'YTick',[1, n_left, n_left + n_right],...
                    'YTickLabel',{num2str(1), num2str(n_left), num2str(n_left + n_right)})
            
            subplot(3,1,2);
            plot(bins,leftCurve,'b',bins,rightCurve,'r','LineWidth',2);
                xlabel('Stem Bins'); ylabel('RTransient Probability'); 
                hold on;
                
            splitCurves = [leftCurve,rightCurve];
            [BIN,SIG] = significance(deltacurve,sigcurve,splitCurves,inds,i,bins,1);
            plot(BIN{1},SIG{1},'b*',BIN{2},SIG{2},'r*');
                yLims = get(gca,'ylim');
                ylim([0,yLims(2)]); xlim([1,nBins]);
                hold off;
                set(gca,'ticklength',[0 0]); 
                legend({'Left','Right'},'location','best');
                
                if plot_type == 7
                    h7 = subplot(3,1,3);
                    imagesc_nan(rot90(TMap_use{inds(i)},-1));
                    colormap(h7,'parula')
                elseif plot_type == 8 % Plot difference between TMaps with left = blue and right = red
                    h8 = subplot(3,1,3);
                    % Hack to scale plots appropriately
                    Tleft_use = Tleft_nan{inds(i)}*max(leftCurve)/max(Tleft_nan{inds(i)}(:));
                    Tright_use = Tright_nan{inds(i)}*max(rightCurve)/max(Tright_nan{inds(i)}(:));
                    imagesc_nan(rot90(Tleft_use-Tright_use,-1))
                    cmap_use = [1 0 0 ; 0.875 0 0; 0.75 0 0 ; 0.625 0 0; 0.5 0 0 ; 0.375 0 0; 0.25 0 0 ; 0.125 0 0; ...
                        0.9 0.9 0.9; 0.9 0.9 0.9; 0.9 0.9 0.9; 
                        0 0 0.125; 0 0 0.25 ; 0 0 0.375; 0 0 0.5; 0 0 0.625; 0 0 0.75; 0 0 0.875; 0 0 1];
                    colormap(h8,cmap_use)
                end
            
        elseif plot_type == 9 % Hacked together from Jon's code - not tested yet
            
            %% Plot rasters
            cmap = [0 0 1; 1 0 0];
            h8 = subplot(3,1,1);
            xlim_use = [0 size(raster,2)];
            n_left_trials = size(splittersByTrialType{inds(i),1},1);
            n_right_trials = size(splittersByTrialType{inds(i),2},1);
            n_trials = size(raster,1);
%             nn = 1;
            for j = 1:n_trials
                curspktrl = raster(j,:);
                if j <= n_left_trials
                   cmap_use = cmap(1,:);
                elseif j > n_left_trials 
                    cmap_use = cmap(2,:);
                end
%                 nn = nn + 1;
%             curtrials=find(trialtype==c);
                X=find( curspktrl > 0); %curspkpos(ismember(curspktrl,curtrials));
                X=repmat(X(:)',3,1);
                X=X(:);
                Y=curspktrl(curspktrl > 0);
                Y=[j+Y(:)'; Y(:)'+j+1; nan(1,numel(Y))];
                Y=Y(:);
                line(X,Y,'Parent',h8,'Color',cmap_use);
                set(h8,'Xlim',[xlim_use(1) xlim_use(2)],...
                    'Ylim',[1 n_trials+1],'Ydir','Reverse')
                
                h8_1 = subplot(3,1,3);
                imagesc_nan(rot90(TMap_use{inds(i)},-1));
                colormap(h8_1,'parula')
            end
            
            % Plot significance curves
            subplot(3,1,2);
            plot(bins,leftCurve,'b',bins,rightCurve,'r','LineWidth',2);
                xlabel('Stem Bins'); ylabel('Rate'); 
                hold on;
                
        end
            

        if savepdf==1
            print(fullfile(pwd,['Neuron #',num2str(inds(i))]),'-dpdf');
        end

    end
end

function [BIN,SIG] = significance(deltacurve,sigcurve,splitCurves,inds,i,bins,smooth)
    %Determine whether this cell is more active on left or right
    %trials by looking at the difference between the tuning curves.
    deltasign = sign(deltacurve{inds(i)});
    deltasign(deltasign > 0) = 2;           %Right
    deltasign(deltasign < 0) = 1;           %Left

    for trialType = 1:2  %Left and right

        %Statistically significant bins.
        sigBins = find(deltasign==trialType & sigcurve{inds(i)});

        %For placing asterisks a relative distance from the curve.
        YLIM = get(gca,'ylim');
        sf = 0.1;
        
        %For smoothed vectors, which are longer. Hard coded for 1000 bins
        %for every 1 stem bin.         
        sigBinInds = sigBins;
        if smooth
            [~,sigBinInds] = ismember(sigBins,bins);
        end

        %Define color based on left or right trial.
        if trialType == 1; col = 'b';       %Left
        else col = 'r'; end                %Right

        BIN{trialType} = sigBins; 
        SIG{trialType} = splitCurves(sigBinInds,trialType)+YLIM(2)*sf;
    end
    
end