function [cellResps,splitters,trialtype,active] = splitter(x,y,FT)
%[cellResps,splitters,trialtype,active] = splitter(x,y,FT)
%
%   Creates occupancy normalized matrices for the stem. 
%
%   INPUTS
%       X & Y: Tracking data. I used the coordinates from aligned tracking
%       data from batch_align_pos. 
%
%       FT: Trace data, like in ProcOut. 
%
%   OUTPUTS
%       cellResps: Nx1 (N=number of neurons) cell array containing TxB
%       (T=number of total trials, B=number of stem bins) matrices. Each
%       element is the number of spikes that occurred on that bin on that
%       trial divided by the occupancy. 
%
%       splitters: Bad choice of variable naming. Not actually
%       statistically significant splitters yet. Same format as cellResps,
%       but contains fewer cells (in both the MATLAB and the neuron sense),
%       corresponding to the neurons that had responses on the stem. 
%
%       trialtype: Tx1 vector (1=left, 2=right) for input into sigtuning. 
%
%       active: Mx1 vector (M=number of neurons active on the stem)
%       containing indices that reference the neurons active on the stem in
%       cellResps and FT. 
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

    %Take only the neurons that were active for at least one trial.     
    splitters = cellResps(active); 
    
    save('splitters.mat','splitters','cellResps','trialtype','active'); 
end