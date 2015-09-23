function MultiPFPlotAcrossDays(regfilepath,dates)
%
%
%

%% Initialize. 
    %Extract dates. 
    basedate = dates{1};
    regdates = dates(2:end);
    numDates = length(dates);
    
    %Define and preallocate. 
    mazetype = 'tmaze'; 
    data = struct; 
    
    %Sortedrates is a 2xD cell array containing the plots we want for
    %column 4 in our subplot. 
    [sortedrates,lneuronid,rneuronid] = multi_LinearizedPFs(regfilepath,basedate,regdates);
    close all;

    %Get file paths. 
    currentdir = pwd;
    altdir = fileparts(regfilepath);            %Directory for alternation.
    paths = cell(numDates,1);                   
    
    for thisDate = 1:numDates
        %All file paths of interest. 
        paths{thisDate} = fullfile(altdir,dates{thisDate});       
    end

    %Preallocate. 
    X = cell(numDates,1);                       %Linearized trajectory for each date. 
    lefttrials = cell(numDates,1);              %Left trial firing rates.   
    righttrials = cell(numDates,1);             %Right trial firing rates. 
    
%% Loop through recording sessions and extract data. 
    for thisDate = 1:numDates
        cd(paths{thisDate}); 
        disp(['Processing ', dates{thisDate}, '...']); 
        
        %% Get neuron masks.
        load('ProcOut.mat','FT','NeuronImage'); 
        
        %Vector to preserve order. 
        existCell{1} = ~isnan(lneuronid(:,thisDate));
        existCell{2} = ~isnan(rneuronid(:,thisDate));
        
        %Preallocate. 
        data(thisDate).left.Neurons = cell(size(existCell{1}));
        data(thisDate).right.Neurons = cell(size(existCell{2})); 
        
        %Extract neuron masks. 
        data(thisDate).left.Neurons(existCell{1}) = ...
            NeuronImage(lneuronid(existCell{1},thisDate))';
        data(thisDate).left.IDlist = lneuronid(:,thisDate); 
        data(thisDate).right.Neurons(existCell{2}) = ...
            NeuronImage(rneuronid(existCell{2},thisDate))';
        data(thisDate).right.IDlist = rneuronid(:,thisDate); 
        
        %% Get place maps. 
        load('PlaceMaps.mat','TMap'); 
        
        %Preallocate.
        data(thisDate).left.PFs = cell(size(existCell{1}));
        data(thisDate).right.PFs = cell(size(existCell{2})); 
        
        %Assign. 
        data(thisDate).left.PFs(existCell{1}) = TMap(lneuronid(existCell{1},thisDate))';
        data(thisDate).right.PFs(existCell{2}) = TMap(rneuronid(existCell{2},thisDate))';
        
        %% Get linearized place fields. 
        try 
            load('Pos_align.mat','x_adj_cm','y_adj_cm');
            x = x_adj_cm; y = y_adj_cm; 
        catch 
            load('Pos.mat','xpos_interp','ypos_interp'); 
            x = xpos_interp; y = ypos_interp; 
        end
        
        %Each of these will be sorted within the context of their own
        %recording session. 
        X{thisDate} = LinearizeTrajectory(x,y,mazetype); 
        [lefttrials{thisDate},righttrials{thisDate},~] = LinearizedPFs(X{thisDate},FT);
    end
    
%% Plot stuff. 
    keepgoing = 1;
    thisNeuron = 1;
    numGoodCells = max([length(existCell{1}) length(existCell{2})]); 
    ind = 1; 
    
    while keepgoing
        figure(50);
        figure(51); 
        
        %Row index. 
        rowInc = 0; 
        
        for thisDate = 1:numDates
            %Left trials. 
            figure(50); 
            
            %Neuron mask. 
            subplot(numDates,4,ind+rowInc);
            imagesc(data(thisDate).left.Neurons{thisNeuron}); 
            
            %Place field. 
            subplot(numDates,4,ind+rowInc+1);
            imagesc(data(thisDate).left.PFs{thisNeuron});
            
            %Linearized PF plot with highlighted neuron. 
            goodneurons = any(~isnan(lefttrials{thisDate}.rate),2); 
            subplot(numDates,4,ind+rowInc+2);
            imagesc(lefttrials{thisDate}.rate(goodneurons,:)); 
            
            %Right trials. 
            figure(51); 
            
            %Neuron mask. 
            subplot(numDates,4,ind+rowInc);
            imagesc(data(thisDate).right.Neurons{thisNeuron}); 
            
            %Place field. 
            subplot(numDates,4,ind+rowInc+1);
            imagesc(data(thisDate).right.PFs{thisNeuron});
            
            %Linearized PF plot with highlighted neuron. 
            goodneurons = any(~isnan(righttrials{thisDate}.rate),2); 
            subplot(numDates,4,ind+rowInc+2);
            imagesc(righttrials{thisDate}.rate(goodneurons,:));  
            
            rowInc = rowInc + 4; 
        end
        
        figure(50); colormap('gray');
        figure(51); colormap('gray');
        
        [~,~,key] = ginput(1); 
        
            if key == 29 && thisNeuron < numGoodCells
                thisNeuron = thisNeuron + 1; 
            elseif key == 28 && thisNeuron ~= 1
                thisNeuron = thisNeuron - 1; 
            elseif key == 27
                keepgoing = 0; 
                close all;  
            end
    end
    
    cd(currentdir); 
end