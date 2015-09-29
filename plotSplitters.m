function plotSplitters(splittersByTrialType,tuningcurves,deltacurve,sigcurve,inds,neuronID,savepdf)
%plotSplitters(splitters,active)
%
%   Plots splitters lap by lap. 
%
%   INPUTS:
%       splitters: Cell array output from splitterbyLaps.
%
%       neuronID: Vector indexing neurons. 
%
%       tuningcurves (optional): output from sigtuning. 
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
                title('Left Trials'); xlabel('Stem Bins'); ylabel('Lap');
                caxis([0 maxRate]);
        subplot(2,2,2); 
            imagesc(splittersByTrialType{inds(i),2});
                title('Right Trials'); xlabel('Stem Bins'); ylabel('Lap'); 
                caxis([0 maxRate]); colormap('gray'); 
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
            
            xlim([1 length(deltasign)]); 
            xlabel('Stem Bins'); ylabel('Firing Rate'); legend({'Left','Right'}); 
            
            if savepdf==1
                print(fullfile(pwd,['Neuron #',num2str(neuronID(inds(i)))]),'-dpdf');
            end
            
    end
 %end
end