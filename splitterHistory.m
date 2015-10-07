function splitterHistory(regStruct,sessionStruct) 
%
%
%

%% 
    filepath = sessionStruct.Location; 
    regFilepath = regStruct.Location; 
    altPath = fileparts(regStruct.Location); 
    date = sessionStruct.Date; 
    
    cd(filepath); 
    load(fullfile(filepath,'sigSplitters.mat')); 
    
    %Get significant splitters. 
    splitterInd = find(cellfun(@any,sigcurve)); 
    
    %Get neuron map. 
    cd(regFilepath); 
    load(fullfile(regFilepath,'batch_session_map.mat')); 
        
    map = batch_session_map.map;
    map(:,1) = []; 
   
    %Find column index that corresponds to session. 
    mapSessionInd = find(strcmp(date,{batch_session_map.session.date})); 
    
    %Find row index of splitters within map. 
    [~,mapSplitterInd] = ismember(splitterInd,map(:,mapSessionInd));
    mapSplitterInd(mapSplitterInd==0) = nan;    %Get rid of neurons that don't appear on neuronmap.
    
    %Get the indices for each splitter on each day. 
    splitterInds = map(mapSplitterInd(~isnan(mapSplitterInd)),:);
    splitterInds(splitterInds==0) = nan; 
    
    [numSplitters,numSessions] = size(splitterInds); 
    numSessions = numSessions - 1; 
    
    %Extract all the FTs. 
    AllFT = cell(numSessions,1); 
    disp('Processing FTs.'); 
    for thisSession = 1:numSessions
        thisPath = fullfile(altPath,batch_session_map.session(thisSession).date);
        cd(thisPath);
        load(fullfile(thisPath,'ProcOut.mat'),'FT'); 
        
        AllFT{thisSession} = FT; 
    end
    
    %Get average firing rate history. 
    avgRates = nan(numSplitters,numSessions); 
    for thisNeuron = 1:numSplitters
        for thisSession = 1:numSessions
            if ~isnan(splitterInds(thisNeuron,thisSession))
                spks = sum(AllFT{thisSession}(splitterInds(thisNeuron,thisSession),:));
                avgRates(thisNeuron,thisSession) = spks / size(AllFT{thisSession},2); 
            end
        end
    end
    
    keyboard;
    
end