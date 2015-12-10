function [I,sig,surrogate] = getAllSpatialInfo(sessionStruct)
%[I,sig] = getAllSpatialInfo(sessionStruct) 
%
%   Computes the spatial information of all the neurons in a recording
%   session. Also looks for neurons that have statistically significant
%   information scores compared to shuffled data. 
%
%   INPUT
%       sessionStruct: MD entry
%
%   OUTPUTS
%       I: N-element vector (N=number of neurons) containing spatial
%       information scores. 
%
%       sig: N-element logical vector where 1 is a neuron with a
%       statistically significant information score. 
%
%       surrogate = NxB matrix (B=number of shuffles) with spatial
%       information scores for each neuron and shuffle. 
%

%% Set up.
    path = sessionStruct.Location;
    cmperbin = 2; 
    
    %Load files.
    load(fullfile(path,'Pos_align.mat'),'x_adj_cm','y_adj_cm','FT'); 
    x = x_adj_cm; y = y_adj_cm; %Necessary for parfor apparently. 
    [XBin,YBin] = bin2DTrajectory(x,y,cmperbin);
    
    %Preallocate. 
    [nNeurons,nFrames] = size(FT);
    I = nan(nNeurons,1); 
    B = 100; 
    surrogate = nan(nNeurons,B); 
    
%% Compute information score and significance. 
    p = ProgressBar(nNeurons);
    parfor thisNeuron=1:nNeurons
        %Calculate spatial information.
        I(thisNeuron) = spatialInfo(FT(thisNeuron,:),XBin,YBin); 
        
        %Shuffle spikes and find distribution of spatial information. 
        jitters = randsample(nFrames,B,true); 
        for i=1:B
            FTshift = circshift(FT(thisNeuron,:),[0,jitters(i)]); 
            
            %Generate surrogate distribution.
            surrogate(thisNeuron,i) = spatialInfo(FTshift,XBin,YBin); 
        end
        p.progress;
    end
    p.stop;
    
    %Spatial information p-value. How often does the empirical spatial
    %information exceed that of shuffled data? 
    pval = sum(surrogate>repmat(I,[1,B]),2)/B; 
    
    %Logical indexing significant neurons with a nonzero information score.
    sig = pval<0.05 & I>0;
    
    save('SpatialInfo.mat','I','sig','surrogate','pval');
    
end