function [cellResps,splitters,trialtype,active] = splitter(x,y,FT)
%splitter(x,y,FT)
%
%

%%     
    numNeurons = size(FT,1); 
    nbins = 80; 
    FT = logical(FT); 
    
    %Linearize trajectory. 
    mazetype = 'tmaze';
    X = LinearizeTrajectory(x,y,mazetype);   

    %Find indices for when the mouse is on the stem and for left/right
    %trials. 
    load(fullfile(pwd,'Alternation.mat')); 
    onstem = Alt.section == 2;                      %Logical. 
    correct = Alt.alt == 1;                         %Logical. 
    correctTrials = unique(Alt.trial(correct));     %Vector of correct trials. 
    [~,~,trialtype] = unique(Alt.summary(Alt.summary(:,3)==1,2));   %Left/right turns.
    numTrials = length(correctTrials); 
     
    %Occupancy histogram.
    [~,edges] = histcounts(X,nbins); 
    stemOcc = histcounts(X(onstem),edges); 
    %Bin numbers for the center stem.
    stemBins = find(stemOcc,1,'first'):find(stemOcc,1,'last'); 
    
    %Preallocate. 
    cellResps = cell(numNeurons,1);   
    
    %Get rate by lap. 
    p = ProgressBar(numNeurons);
    for thisNeuron = 1:numNeurons
        for thisTrial = 1:numTrials        
            trialNum = correctTrials(thisTrial);  
            occHist = histcounts(X(onstem & Alt.trial == trialNum),edges); 
            spkHist = histcounts(X(FT(thisNeuron,:) & onstem & Alt.trial==trialNum),edges); 
            
            %Get rate histogram and remove nans. 
            rateHist = spkHist(stemBins) ./ occHist(stemBins);
            rateHist(isnan(rateHist)) = 0; 
            
            %Deal. 
            cellResps{thisNeuron}(thisTrial,:) = rateHist; 
        end
        
    p.progress;
    end
    p.stop;
    
    %Get active neurons. 
    active = cellfun(@find,cellResps,'unif',0); 
    active = find(~cellfun(@isempty,active)); 

    splitters = cellResps(active); 
    
    save('splitters.mat','splitters','cellResps','trialtype','active'); 
end