function [splitters,active] = splitterByLaps(x,y,FT)
%[splitters,active] = splitterByLaps(x,y,FT)
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
    Pix2Cm = 0.15; 
    nbins = 100; 
    [~,~,~,FT] = AlignImagingToTracking_WM2(Pix2Cm,FT);
    FT = logical(FT); 
    
    %Linearize trajectory. 
    mazetype = 'tmaze';
    X = LinearizeTrajectory(x,y,mazetype);   

    %Find indices for when the mouse is on the stem and for left/right
    %trials. 
    load(fullfile(pwd,'Alternation.mat')); 
    onstem = Alt.section == 2; %& Alt.alt == 1;   %Logicals. On stem and correct.   
    numTrials = max(Alt.trial); 
    leftTrials = sum(Alt.summary(:,2)==1);      %Number of left or right trials. 
    rightTrials = sum(Alt.summary(:,2)==2); 
    
    %Occupancy histogram.
    [~,edges] = histcounts(X,nbins); 
    stemOcc = histcounts(X(onstem),edges); 
    stemBins = find(stemOcc,1,'first'):find(stemOcc,1,'last'); 
   
    %Preallocate. 
    splitters = cell(numNeurons,2);    
    splitters(:,1) = {zeros(leftTrials,max(stemBins))}; 
    splitters(:,2) = {zeros(rightTrials,max(stemBins))}; 
        
    %For each neuron and trial, count spikes in each spatial bin on the
    %stem.
    p = ProgressBar(numNeurons);
    for thisNeuron = 1:numNeurons
        leftTrialCounter = 1; 
        rightTrialCounter = 1; 

        for thisTrial = 1:numTrials
            %Bin the positions when thisNeuron fired on thisTrial on the
            %stem. 
            spkhist = histcounts(X(FT(thisNeuron,onstem & Alt.trial == thisTrial)),edges); 
            
            %Separate left vs right trials. 
            if unique(Alt.choice(Alt.trial == thisTrial)) == 1
                splitters{thisNeuron,1}(leftTrialCounter,:) = spkhist(stemBins);
                leftTrialCounter = leftTrialCounter + 1; 
            elseif unique(Alt.choice(Alt.trial == thisTrial)) == 2
                splitters{thisNeuron,2}(rightTrialCounter,:) = spkhist(stemBins); 
                rightTrialCounter = rightTrialCounter + 1; 
            end
            
        end
        
        p.progress;
    end
    p.stop;
    
    %Get active neurons. 
    active = cellfun(@find,splitters,'unif',0); 
    active = ~cellfun(@isempty,active); 
    active = find(any(active,2));
    
end