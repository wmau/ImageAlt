function [normalizedrate,order,inactive] = LinearizedPFs(X,FT)
%normalizedrate = LinearizedPFs(X,FT)
%   
%   Find place fields in linearized space on the alternation Tmaze. 
%
%   INPUTS
%       X: Linearized position vector from LinearizeTrajectory().
%
%       FT: Binary NxT matrix (N=number of neurons, T=number of frames)
%       specifying when calcium transients occurred. From ProcOut out of
%       TENASPIS. 
%
%   OUTPUTS
%       normalizedrate: NxB matrix (N=number of neurons, B=number of
%       spatial bins) containing occupancy-normalized, speed-thresholded
%       transient rates. Each row (neuron) is normalized to the max firing
%       rate of that row. Rows are sorted according to where the max firing
%       rate occurred on the maze.
%
%       order: Vector specifying the pre-sorted indices of normalizedrate.
%
%       inactive: Vector containing 1s if the neuron did not fire, 0s if it
%       did. 
%

%% Align imaging to tracking. 
    Pix2Cm = 0.15;                  %Scaling factor.
    minspeed = 7;       
    nneurons = size(FT,1); 
    
    %Align. 
    [~,~,speed,FT,~,~] = AlignImagingToTracking(Pix2Cm,FT);
    
    FT = logical(FT);               %Convert to logical array.
    isrunning = speed > minspeed;   %Speed threshold. 

%% Create heatmap.
    %Spatial bins.
    nbins = 100; 
    
    %Occupancy histogram.
    [occ,occ_bins] = hist(X,nbins); 
    
    %Preallocate.
    rate = nan(nneurons,nbins); 
    
    %Bin locations where each neuron spiked then divide by the occupancy
    %map.
    for this_neuron = 1:nneurons
        spks = X(FT(this_neuron,isrunning));
        spkpos = hist(spks,nbins);
        rate(this_neuron,:) = spkpos ./ occ; 
    end

    %Find peak firing rate. 
    [peak,inds] = max(rate,[],2);
    inactive = peak==0;
%     rate(inactive,:) = []; %Delete neurons that don't fire. 
%     inds(inactive) = []; peak(inactive) = []; 
    
    %Normalize responses for all neurons such that 1 is the max rate. 
    normalizedrate = bsxfun(@rdivide,rate,peak);
    
    %Smooth. 
    sm = fspecial('gaussian');
    parfor this_neuron = 1:size(normalizedrate,1)
        normalizedrate(this_neuron,:) = imfilter(normalizedrate(this_neuron,:),sm);
    end
    
    %Sort according to position where peak firing rate occurred. 
    [~,order] = sort(inds);
    inactive = inactive(order);
    normalizedrate = normalizedrate(order,:);
    
end
    