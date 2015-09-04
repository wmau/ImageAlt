function [lefttrials,righttrials,goalbins] = LinearizedPFs(X,FT,bounds)
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
%       lefttrials & righttrials: structure arrays with the following
%       fields for left and right trials...
%           rate: Normalized firing rate sorted such that rows of neurons
%           tile the environment. 
%           
%           inactive: Logical vector (rank the same as rate) indicating
%           whether a neuron was active for that trial type. 
%
%           order: Vector of indices that tells you how the neurons from FT
%           were sorted into rate. 
%
%       goalbins: Structure array containing the fields 'l' and 'r' for
%       left and right respectively. The elements in these fields are the
%       boundaries surrounding the left and right goal locations in
%       linearized space according to getsections. 
%


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
    atleftgoal = Alt.goal==1;
    atrightgoal = Alt.goal==2; 
    
%% Create heatmap.
    %Spatial bins.
    nbins = 100; 
    
    %Occupancy histogram.
    [occ,edges] = histcounts(X,nbins); 
    
    %Get bins corresponding to the reward location. 
    binnedleftgoal = histcounts(X(atleftgoal),edges);
    binnedrightgoal = histcounts(X(atrightgoal),edges); 
    goalbins.l = [find(binnedleftgoal,1,'first'),find(binnedleftgoal,1,'last')];  
    goalbins.r = [find(binnedrightgoal,1,'first'),find(binnedrightgoal,1,'last')];  
    
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
    