function [lefttrials,righttrials] = LinearizedPFs(X,FT)
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


%% Align imaging to tracking. 
    Pix2Cm = 0.15;                  %Scaling factor.
    minspeed = 7;       
    nneurons = size(FT,1); 
    
    %Align. 
    [~,~,speed,FT,~,~] = AlignImagingToTracking(Pix2Cm,FT);
    
    FT = logical(FT);               %Convert to logical array.
    isrunning = speed > minspeed;   %Speed threshold. 
    
    %Separate left and right trials. 
    load(fullfile(pwd,'Alternation.mat')); 
    left = Alt.choice == 1;
    right = Alt.choice == 2; 
    
%% Create heatmap.
    %Spatial bins.
    nbins = 100; 
    
    %Occupancy histogram.
    occ = hist(X,nbins); 
    
    %Preallocate.
    lrate = nan(nneurons,nbins); 
    rrate = nan(nneurons,nbins); 
    
    %Bin locations where each neuron spiked then divide by the occupancy
    %map.
    for this_neuron = 1:nneurons
        lspkpos = X(FT(this_neuron,isrunning & left));
        rspkpos = X(FT(this_neuron,isrunning & right)); 
        
        lbinned = hist(lspkpos,nbins);
        rbinned = hist(rspkpos,nbins); 
        
        lrate(this_neuron,:) = lbinned ./ occ; 
        rrate(this_neuron,:) = rbinned ./ occ;
    end

    %Find peak firing rate. 
    [lpeak,linds] = max(lrate,[],2);
    [rpeak,rinds] = max(rrate,[],2); 
    linactive = lpeak==0; rinactive = rpeak == 0; 
%     rate(inactive,:) = []; %Delete neurons that don't fire. 
%     inds(inactive) = []; peak(inactive) = []; 
    
    %Normalize responses for all neurons such that 1 is the max rate. 
    lnormalizedrate = bsxfun(@rdivide,lrate,lpeak);
    rnormalizedrate = bsxfun(@rdivide,rrate,rpeak); 
    
    %Smooth. 
    sm = fspecial('gaussian');
    parfor this_neuron = 1:size(lnormalizedrate,1)
        lnormalizedrate(this_neuron,:) = imfilter(lnormalizedrate(this_neuron,:),sm);
        rnormalizedrate(this_neuron,:) = imfilter(rnormalizedrate(this_neuron,:),sm); 
    end
    
    %Sort according to position where peak firing rate occurred. 
    [~,lorder] = sort(linds);                       [~,rorder] = sort(rinds);
    linactive = linactive(lorder);                  rinactive = rinactive(rorder); 
    lnormalizedrate = lnormalizedrate(lorder,:);    rnormalizedrate = rnormalizedrate(rorder,:); 
    
    %Compile. 
    lefttrials.rate = lnormalizedrate;  righttrials.rate = rnormalizedrate; 
    lefttrials.inactive = linactive;    righttrials.inactive = rinactive; 
    lefttrials.order = lorder;          righttrials.order = rorder;
    
    
end
    