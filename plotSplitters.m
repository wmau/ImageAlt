function plotSplitters(splittersByTrialType,tuningcurves,deltacurve,sigcurve,inds,savepdf)
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
    for i=1:length(inds)
        maxRate = max([max(splittersByTrialType{inds(i),1}),...
            max(splittersByTrialType{inds(i),2})]); 
        figure(inds(i));
        subplot(2,2,1);
            imagesc(splittersByTrialType{inds(i),1});
                title('Left Trials'); ylabel('Lap'); 
                caxis([0 maxRate]); set(gca,'xtick',[]);
        subplot(2,2,2); 
            imagesc(splittersByTrialType{inds(i),2});
                title('Right Trials'); ylabel('Lap'); 
                caxis([0 maxRate]); colormap('gray'); set(gca,'xtick',[]);
        subplot(2,2,3:4)
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
            xlabel('Stem Bins'); ylabel('Firing Rate'); legend({'Left','Right'},'location','best'); 
            
            %Save plot as pdf. 
            if savepdf==1
                print(fullfile(pwd,['Neuron #',num2str(inds(i))]),'-dpdf');
            end
            
    end
 %end
end