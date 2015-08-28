function normalizedrate = LinearizedPFs(X,FT)
%normalizedrate = LinearizedPFs(X,FT)
%   
%   Find place fields in linearized space on the alternation Tmaze. 
%
%   INPUTS:
%       X: Linearized position vector from LinearizeTrajectory().
%
%       FT: Binary NxT matrix (N=number of neurons, T=number of frames)
%       specifying when calcium transients occurred. From ProcOut out of
%       TENASPIS. 
%
%   OUTPUT: 
%       normalizedrate: NxB matrix (N=number of neurons that fired,
%       B=number of spatial bins) containing occupancy-normalized transient
%       rates. Each row (neuron) is normalized to the max firing rate of
%       that row so max(normalizedrate) = 1. 
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
    normalizedrate = nan(nneurons,nbins); 
    
    %Bin locations where each neuron spiked then divide by the occupancy
    %map.
    for this_neuron = 1:nneurons
        spks = X(FT(this_neuron,isrunning));
        spkpos = hist(spks,nbins);
        normalizedrate(this_neuron,:) = spkpos ./ occ; 
    end

    %Find peak firing rate. 
    [peak,inds] = max(normalizedrate,[],2);
    normalizedrate(peak==0,:) = []; %Delete neurons that don't fire. 
    inds(peak==0) = []; peak(peak==0) = []; 
    
    %Normalize responses for all neurons such that 1 is the max rate. 
    normalizedrate = bsxfun(@rdivide,normalizedrate,peak);
    
    %Smooth. 
    sm = fspecial('gaussian');
    parfor this_neuron = 1:size(normalizedrate,1)
        normalizedrate(this_neuron,:) = imfilter(normalizedrate(this_neuron,:),sm);
    end
    
    %Sort according to position where peak firing rate occurred. 
    [~,sorted] = sort(inds);
    normalizedrate = normalizedrate(sorted,:);
    
end
    