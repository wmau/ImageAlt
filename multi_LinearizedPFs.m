function [sortedrates,lneuronid,rneuronid] = multi_LinearizedPFs(regfilepath,basedate,dates)
%sortedrates = multi_LinearizedPFs(regfilepath,basedate,dates)
%   
%   Plots heatmaps for linearized place fields across multiple sessions.
%   The order of neurons as they tile the environment is determined by the
%   place field activations in the base date and this order is applied to
%   all other sessions. The red line indicates the reward location. 
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
%       sortedrates: 2xD cell array (D=number of sessions). The first row
%       contains the normalized and sorted transients for left trials. The
%       second contains the right trials. The first column is the base date
%       and the following columns are the rest of the sessions in the order
%       specified in the 'dates' argument. 
%

%% Get the linearized place fields from the base date. 
    %Get path string and parameter information. 
    currentdir = pwd; 
    altdir = fileparts(regfilepath); 
    basepath = fullfile(altdir,basedate);
    numdates = length(dates);
    mazetype = 'tmaze';                         %Hard-coded for alternation. 

    %Linearize trajectory. 
    cd(basepath);                               %Necessary because sections() loads from pwd.
    load(fullfile(basepath,'Pos_align.mat'),'x_adj_cm','y_adj_cm');
    X = cell(1,numdates+1); 
    X{1} = LinearizeTrajectory(x_adj_cm,y_adj_cm,mazetype);

    %Get linearized place fields. 
    load(fullfile(basepath,'ProcOut.mat'),'FT'); 

    [ltrials,rtrials,goalbins] = LinearizedPFs(X{1},FT); 
    LNumNeurons = size(ltrials(1).rate,1);              %Total number of detected neurons.
    numinactive.l = sum(ltrials.inactive);              %Number of inactive neurons.
    numinactive.r = sum(rtrials.inactive);          
    numactive.l = LNumNeurons - numinactive.l;       	%Number of active neurons. 
    numactive.r = LNumNeurons - numinactive.r; 
    
    %Delete inactive neurons.
    ltrials(1).rate(ltrials(1).inactive,:) = [];    rtrials(1).rate(rtrials(1).inactive,:) = [];
    ltrials(1).order(ltrials(1).inactive) = [];     rtrials(1).order(rtrials(1).inactive) = []; 
    
    %Preallocate.
    lsortedrates = cell(numdates+1,1);
    rsortedrates = lsortedrates; 
    lsortedrates{1} = ltrials(1).rate;
    rsortedrates{1} = rtrials(1).rate; 

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
    [~,lidx] = ismember(ltrials.order,map(:,baseind));
    [~,ridx] = ismember(rtrials.order,map(:,baseind)); 
    
    %Preallocate. 
    lneuronid = nan(numactive.l,numdates+1); 
    rneuronid = nan(numactive.r,numdates+1);  
    lneuronid(:,1) = ltrials(1).order;
    rneuronid(:,1) = rtrials(1).order; 
    
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
        [ltrials(thisdate+1),rtrials(thisdate+1),goalbins(thisdate+1)] = LinearizedPFs(X{thisdate+1},FT); 
        
        %Get the neuron IDs corresponding to the same neurons in the base
        %session.
        sessionnumber = dateinds(thisdate);
        lneuronid(:,thisdate+1) = map(lidx,sessionnumber); 
        rneuronid(:,thisdate+1) = map(ridx,sessionnumber); 
        
        %Okay, now neuronid is a NxD matrix (N=number of active neurons in
        %session 1, D=number of dates you're comparing the base session
        %to). Each element is an index for that respective date's FT. NaNs
        %indicate that there's no neuron on that date that matches with the
        %base session. These are also sorted in the same order as the base
        %session.
    end
   
    %Get all the indices where neurons in the base session appear in later
    %sessions.
    lgood = ~isnan(lneuronid);
    rgood = ~isnan(rneuronid); 

    %Sort the rest of the sessions using the same order as the base
    %session.
    for thisdate = 1:numdates
        lsortedids = lneuronid(lgood(:,thisdate+1),thisdate+1);
        rsortedids = rneuronid(rgood(:,thisdate+1),thisdate+1); 
        
        lsortedrates{thisdate+1}(lgood(:,thisdate+1),:) = ltrials(thisdate+1).rate(lsortedids,:);
        lsortedrates{thisdate+1}(~lgood(:,thisdate+1),:) = nan;
        
        rsortedrates{thisdate+1}(rgood(:,thisdate+1),:) = rtrials(thisdate+1).rate(rsortedids,:);
        rsortedrates{thisdate+1}(~rgood(:,thisdate+1),:) = nan; 
    end
  
%% Plot.
    %Necessary to not screw up figure titles. 
    basedate(basedate=='_') = '-';
    for i=1:numdates
        dates{i}(dates{i}=='_') = '-';
    end
    
    %Number of active neurons in the base session. 
    LNumNeurons = size(lsortedrates{1},1); 
    RNumNeurons = size(rsortedrates{1},1); 
    
    figure(200);
    subplot(2,numdates+1,1);
        imagesc(lsortedrates{1}); colormap(gray);   %Left trials.
        line([goalbins(1).l(1),goalbins(1).l(1),goalbins(1).l(2),goalbins(1).l(2)],...
            [0,LNumNeurons,LNumNeurons,0],...
            'color','r','linewidth',2);
        title(basedate);
    subplot(2,numdates+1,numdates+2); 
        imagesc(rsortedrates{1}); colormap(gray);   %Right trials. 
        line([goalbins(1).r(1),goalbins(1).r(1),goalbins(1).r(2),goalbins(1).r(2)],...
            [0,RNumNeurons,RNumNeurons,0],...
            'color','r','linewidth',2);

        
    for thisplot = 2:numdates+1
        subplot(2,numdates+1,thisplot);
            imagesc(lsortedrates{thisplot}); colormap(gray);
            title(dates{thisplot-1});
            line([goalbins(thisplot).l(1),goalbins(thisplot).l(1),...
                goalbins(thisplot).l(2),goalbins(thisplot).l(2)],...
                [0,LNumNeurons,LNumNeurons,0],...
            'color','r','linewidth',2);
        subplot(2,numdates+1,thisplot+numdates+1);
            imagesc(rsortedrates{thisplot}); colormap(gray); 
            line([goalbins(thisplot).r(1),goalbins(thisplot).r(1),...
                goalbins(thisplot).r(2),goalbins(thisplot).r(2)],...
                [0,RNumNeurons,RNumNeurons,0],...
                'color','r','linewidth',2);
    end
    
    %Compile. 
    sortedrates = {lsortedrates{:}; rsortedrates{:}}; 
    
    %Return to directory. 
    cd(currentdir); 
end