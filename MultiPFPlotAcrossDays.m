function MultiPFPlotAcrossDays(regfilepath,basedate,dates)
%
%
%

%% 
    %
    [sortedrates,lneuronid,rneuronid] = multi_LinearizedPFs(regfilepath,basedate,dates);
    close all;
    
    currentdir = pwd;
    altdir = fileparts(regfilepath); 
    basepath = fullfile(altdir,basedate); 
    numdates = length(dates); 
    mazetype = 'tmaze'; 
    data = struct; 
    
    X = cell(numdates+1,1); 
    lefttrials = cell(numdates+1,1); 
    righttrials = cell(numdates+1,1); 
    
%% Get neuron masks. 
    cd(basepath); 
    load('ProcOut.mat','FT','NeuronImage'); 
    data(1).left.Neurons = NeuronImage(lneuronid(:,1));
    data(1).left.IDlist = lneuronid(:,1); 
    data(1).right.Neurons = NeuronImage(rneuronid(:,1)); 
    data(1).right.IDlist = rneuronid(:,1); 
    
%% Get place maps.
    load('PlaceMaps.mat','TMap'); 
    data(1).left.PFs = TMap(lneuronid(:,1));
    data(1).right.PFS = TMap(rneuronid(:,1)); 
    
%% Get linearized place maps. 
    try 
        load('Pos_align.mat','x_adj_cm','y_adj_cm');
        x = x_adj_cm; y = y_adj_cm; 
    catch 
        load('Pos.mat','xpos_interp','ypos_interp'); 
        x = xpos_interp; y = ypos_interp; 
    end
    
    X{1} = LinearizeTrajectory(x,y,mazetype); 
    [lefttrials{1},righttrials{1},~] = LinearizedPFs(X{1},FT);
    
    keyboard;
   
    cd(currentdir); 
end