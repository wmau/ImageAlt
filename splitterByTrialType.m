function [cellRespsByTrialType,splittersByTrialType,active] = splitterByTrialType(x,y,FT)
%[cellRespsByTrialType,splittersByTrialType,active] = splitterByTrialType(x,y,FT)
%
%   Searches for transients on the stem for left and right trials. 
%
%   INPUTS
%       X & Y: Tracking data. I used the coordinates from aligned tracking
%       data from batch_align_pos. 
%
%       FT: Trace data, like in ProcOut. 
%
%   OUTPUTS
%       cellRespsByTrialType: Nx2 (N=number of neurons) cell array
%       containing TxB (T=number of left or right trials, B=number of stem
%       bins) matrices. Each element is the number of spikes that occurred
%       on that bin on that trial divided by the occupancy. The first
%       column is left trials; the second is right trials.
%
%       splittersByTrialType: Bad choice of variable naming. Not actually
%       statistically significant splitters yet. Same format as cellResps,
%       but contains fewer cells (in both the MATLAB and the neuron sense),
%       corresponding to the neurons that had responses on the stem. 
%
%       active: Mx1 vector (M=number of neurons active on the stem)
%       containing indices that reference the neurons active on the stem in
%       cellResps and FT. 
%

%% Linearize the trajectory and find bins in the center stem.   
    numNeurons = size(FT,1); 
    nbins = 80; 
    FT = logical(FT); 
    
    %Linearize trajectory. 
    mazetype = 'tmaze';
    X = LinearizeTrajectory(x,y,mazetype);   

    %Find indices for when the mouse is on the stem and for left/right
    %trials. 
    load(fullfile(pwd,'Alternation.mat')); 
    onstem = Alt.section == 2; 
    correct =  Alt.alt == 1;    
    correctTrials = unique(Alt.trial(correct));
    numTrials = length(correctTrials); 
    leftTrials = sum(Alt.summary(:,2)==1);      %Number of left or right trials. 
    rightTrials = sum(Alt.summary(:,2)==2); 
    
    %Occupancy histogram.
    [~,edges] = histcounts(X,nbins); 
    stemOcc = histcounts(X(onstem),edges); 
    %Bin numbers for the center stem.
    stemBins = find(stemOcc,1,'first'):find(stemOcc,1,'last'); 
   
    %Preallocate. 
    cellRespsByTrialType = cell(numNeurons,2);    
    cellRespsByTrialType(:,1) = {zeros(leftTrials,max(stemBins))}; 
    cellRespsByTrialType(:,2) = {zeros(rightTrials,max(stemBins))}; 
        
    %For each neuron and trial, count spikes in each spatial bin on the
    %stem.
    p = ProgressBar(numNeurons);
    for thisNeuron = 1:numNeurons
        leftTrialCounter = 1; 
        rightTrialCounter = 1; 

        for thisTrial = 1:numTrials
            trialNum = correctTrials(thisTrial); 
            %Bin the positions when thisNeuron fired on thisTrial on the
            %stem. 
            spkhist = histcounts(X(FT(thisNeuron,:) & onstem & Alt.trial==trialNum),edges); 
            
            %Separate left vs right trials. 
            if unique(Alt.choice(Alt.trial == trialNum)) == 1
                cellRespsByTrialType{thisNeuron,1}(leftTrialCounter,:) = spkhist(stemBins);
                leftTrialCounter = leftTrialCounter + 1; 
            elseif unique(Alt.choice(Alt.trial == trialNum)) == 2
                cellRespsByTrialType{thisNeuron,2}(rightTrialCounter,:) = spkhist(stemBins); 
                rightTrialCounter = rightTrialCounter + 1; 
            end
            
        end
        
        p.progress;
    end
    p.stop;
    
    %Get active neurons. 
    active = cellfun(@find,cellRespsByTrialType,'unif',0); 
    active = ~cellfun(@isempty,active); 
    active = find(any(active,2));
    
    %Take only the neurons that were active for at least one trial.     
    splittersByTrialType = cellRespsByTrialType(active,:); 
    
    save('splittersByTrialType.mat','splittersByTrialType','cellRespsByTrialType','active'); 
    
end