function [cellResps,active] = splitterByTrialType(x,y,FT)
%[splitters,active] = splitterByTrialType(x,y,FT)
%
%   Searches for transients on the stem for left and right trials. You then
%   have the capability of plotting cells that were active. 
%
%   INPUTS:
%       X & Y: Tracking data from a position .mat. 
%
%       FT: Output in ProcOut.mat.
%
%   OUTPUTS: 
%       splitters: Nx2 cell array (N = number of neurons) each containing
%       a TxB array (T = number of trials for left and right trials, B =
%       number of stem bins). 
%
%       active: Indices of cells that were active in either left or right
%       trials. 
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
    cellResps = cell(numNeurons,2);    
    cellResps(:,1) = {zeros(leftTrials,max(stemBins))}; 
    cellResps(:,2) = {zeros(rightTrials,max(stemBins))}; 
        
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
                cellResps{thisNeuron,1}(leftTrialCounter,:) = spkhist(stemBins);
                leftTrialCounter = leftTrialCounter + 1; 
            elseif unique(Alt.choice(Alt.trial == trialNum)) == 2
                cellResps{thisNeuron,2}(rightTrialCounter,:) = spkhist(stemBins); 
                rightTrialCounter = rightTrialCounter + 1; 
            end
            
        end
        
        p.progress;
    end
    p.stop;
    
    %Get active neurons. 
    active = cellfun(@find,cellResps,'unif',0); 
    active = ~cellfun(@isempty,active); 
    active = find(any(active,2));
    
    %Take only the neurons that were active for at least one trial.     
    splittersByTrialType = cellResps(active,:); 
    
    save('splittersByTrialType.mat','splittersByTrialType','cellResps','active'); 
    
end