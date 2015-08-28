function sortedrates = multi_LinearizedPFs(regfilepath,basedate,dates)
%sortedrates = multi_LinearizedPFs(regfilepath,basedate,dates)
%   
%   Plots heatmaps for linearized place fields across multiple sessions.
%   The order of neurons as they tile the environment is determined by the
%   place field activations in the base date and this order is applied to
%   all other sessions.
%
%   INPUTS
%       regfilepath: Location of first recording session that should
%       contain the registration information. 
%
%       basedate: String in the form 'MM_DD_YYYY' specifying the reference
%       date for your place fields and neuron order. 
%
%       dates: Cell array containing the other sessions you want to
%       examine. 
%
%   OUTPUT
%       sortedrates: D-element cell array (D=number of total dates you're
%       examining). Each element is a NxB array (N=total number of active
%       neurons in session 1, B=number of spatial bins) in the same format
%       as the output of LinearizedPFs(). Neurons are all sorted in the
%       same order, defined by how neurons tiled the environment in session
%       1.
%

%% Get the linearized place fields from the base date. 
    %Get path string and parameter information. 
    currentdir = pwd; 
    altdir = fileparts(regfilepath); 
    basepath = fullfile(altdir,basedate);
    numdates = length(dates);
    mazetype = 'tmaze';                         %Hard-coded for alternation. 

    %Linearize trajectory. 
    cd(basepath); 
    load(fullfile(basepath,'Pos_align.mat'),'x_adj_cm','y_adj_cm');
    X = cell(1,numdates+1); 
    X{1} = LinearizeTrajectory(x_adj_cm,y_adj_cm,mazetype);

    %Get linearized place fields. 
    load(fullfile(basepath,'ProcOut.mat'),'FT'); 
    rates = cell(1,numdates+1);                 %Preallocate. 
    [rates{1},order,inactive] = LinearizedPFs(X{1},FT); 
    numneurons = size(rates{1},1);              %Total number of detected neurons.
    numinactive = sum(inactive);                %Number of inactive neurons.
    numactive = numneurons - numinactive;       %Number of active neurons. 
    
    %Delete inactive neurons.
    rates{1}(inactive,:) = []; 
    order(inactive) = [];
    
    %Preallocate.
    sortedrates = rates;

%% Load the registered neuron profiles. 
    load(fullfile(regfilepath,'Reg_NeuronIDs_updatemasks0.mat')); 
    map = Reg_NeuronIDs(1).all_session_map; map(:,1) = [];  %First column redundant..
    map(cellfun('isempty',map)) = {nan};                    %Fill empty elements with NaNs. 
    map = cell2mat(map);                                    %Convert to matrix form. 
    
    %Find the index in Reg_NeuronIDs associated with the date you are
    %referenced to and also dates you are comparing.  
    registereddates = {Reg_NeuronIDs(1).base_date, Reg_NeuronIDs.reg_date}; 
    baseind = find(strcmp(basedate,registereddates));
    
    dateinds = zeros(numdates,1); 
    for thisdate = 1:numdates
        dateinds(thisdate) = find(strcmp(dates{thisdate},registereddates)); 
        
        %Throw an error if date not found. 
        if isempty(dateinds(thisdate)), disp([dates{this_date}, ' not found in Reg_NeuronIDs!']); return; end
    end
    
    %Throw an error if date not found. 
    if isempty(baseind), disp([basedate,' not found in Reg_NeuronIDs!']); return; end
    
%% Plot linearized place fields for the other sessions. 
    %Get the rows containing the neurons in sorted order. 
    [~,idx] = ismember(order,map(:,baseind));
    
    neuronid = nan(numactive,numdates); 
    for thisdate = 1:numdates
        disp(['Processing ',dates{thisdate},'...']);
        
        %File path containing tracking and imaging data. 
        thispath = fullfile(altdir,dates{thisdate});
        
        %Linearize trajectory. 
        cd(thispath);
        load(fullfile(thispath,'Pos_align.mat'),'x_adj_cm','y_adj_cm'); 
        X{thisdate+1} = LinearizeTrajectory(x_adj_cm,y_adj_cm,mazetype);
        
        %Get linearized place fields. 
        load(fullfile(thispath,'ProcOut.mat'),'FT');
        rates{thisdate+1} = LinearizedPFs(X{thisdate+1},FT); 
        
        %Get the neuron IDs corresponding to the same neurons in the base
        %session.
        sessionnumber = dateinds(thisdate);
        neuronid(:,thisdate) = map(idx,sessionnumber); 
        
        %Okay, now neuronid is a NxD matrix (N=number of active neurons in
        %session 1, D=number of dates you're comparing the base session
        %to). Each element is an index for that respective date's FT. NaNs
        %indicate that there's no neuron on that date that matches with the
        %base session. These are also sorted in the same order as the base
        %session.
    end
   
    %Get all the indices where neurons in the base session appear in later
    %sessions.
    good = ~isnan(neuronid);

    %Sort the rest of the sessions using the same order as the base
    %session.
    for thisdate = 1:numdates
        sortedids = neuronid(good(:,thisdate),thisdate);
        
        sortedrates{thisdate+1}(good(:,thisdate),:) = rates{thisdate+1}(sortedids,:);
        sortedrates{thisdate+1}(~good(:,thisdate),:) = nan;
    end
  
%% Plot.
    basedate(basedate=='_') = '-';
    for i=1:numdates
        dates{i}(dates{i}=='_') = '-';
    end
    
    figure;
    subplot(1,numdates+1,1);
        imagesc(sortedrates{1}); colormap(gray);
        title(basedate);
    for thisplot = 2:numdates+1
        subplot(1,numdates+1,thisplot);
            imagesc(sortedrates{thisplot}); colormap(gray);
            title(dates{thisplot-1});
    end
    
    %Return to directory. 
    cd(currentdir); 
end