function findIntersessionSplitters(regStruct,baseStruct,sessionStruct)
%
%
%

%% 
    
    regFilepath = regStruct.Location;                                   %Filepath for base image. 
    sessionFilepaths = {baseStruct.Location, sessionStruct.Location};   %Filepaths considered sessions. 
    sessionDates = {baseStruct.Date, sessionStruct.Date};               %Dates in the format MM_DD_YYYY.
    numSessions = length(sessionFilepaths);                             %Total number of sessions. 
    
    %Preallocate. 
    putativeSplitters = struct; 
    putativeSplitters(numSessions).date = 1; 
    
    for thisSession = 1:numSessions
        cd(sessionFilepaths{thisSession}); 
        
        %Get tracking data. 
        try
            load('Pos_align.mat','x_adj_cm','y_adj_cm','FT'); 
            x = x_adj_cm; y = y_adj_cm; 
        catch
            load('Pos.mat','xpos_interp','ypos_interp'); 
            x = xpos_interp; y = ypos_interp; 
            load('ProcOut.mat','FT'); 
        end
        
        %Get stem response data. 
        try
            load('sigSplitters.mat'); 
        catch
            [sigcurve,deltacurve,ci,pvalue,tuningcurves,shufdelta,neuronID] = sigtuningAllCells(x,y,FT);
        end
        putativeSplitters(thisSession).date = sessionDates{thisSession};
        putativeSplitters(thisSession).sigcurve = sigcurve; 
        putativeSplitters(thisSession).deltacurve = deltacurve; 
        putativeSplitters(thisSession).ci = ci; 
        putativeSplitters(thisSession).pvalue = pvalue;         
        putativeSplitters(thisSession).tuningcurves = tuningcurves; 
        putativeSplitters(thisSession).shufdelta = shufdelta; 
        putativeSplitters(thisSession).neuronID = neuronID; 
        
        %Get the stem response sorted by trial type. 
        try 
            load('splittersByTrialType.mat'); 
        catch
            cellRespsByTrialType = splitterByTrialType(x,y,FT);
        end
        putativeSplitters(thisSession).cellRespsByTrialType = cellRespsByTrialType;         
        
    end
    
%% 
    %Get neuron map. 
    cd(regFilepath); 
    load('Reg_NeuronIDs_updatemasks0.mat'); 
    map = Reg_NeuronIDs(1).all_session_map;
    map(:,1) = []; 
    
    %Get the column index of map that corresponds to the dates we are
    %interested in. 
    [~,mapInd] = ismember(sessionDates,{Reg_NeuronIDs.reg_date}); mapInd = mapInd+1; 
    truncMap = map(:,mapInd);       %truncMap lines up with sessionDates. 
    truncMap(cellfun('isempty',truncMap)) = {nan};
    truncMap = cell2mat(truncMap);  %Conversion to matrix for easier workflow. 
    
%% 
    %Find splitters within truncMap. 
    sigSplitters = cell(numSessions,1); 
    truncMapSplitters = zeros(size(truncMap)); 
    for thisSession = 1:numSessions
        %Indexes FT. 
        sigSplitters{thisSession} = find(cellfun(@any,putativeSplitters(thisSession).sigcurve)); 
        
        %Indexes truncMap.
        [~,truncMapInds] = ismember(sigSplitters{thisSession},truncMap(:,thisSession));
        
        %For some reason, one cell in the example that I'm working with
        %doesn't appear in neuronmap. Indexes FT.
        missingNeurons = sigSplitters{thisSession}(truncMapInds==0);
        truncMapInds(truncMapInds==0) = nan;
        
        %Logical array, same size as truncMap. 
        truncMapSplitters(truncMapInds(~isnan(truncMapInds)),thisSession) = 1; 
    end
    
    %Since truncMapSplitters is a logical with the same dimensions as
    %truncMap, if we sum across the columns, we get splitters that occur on
    %multiple days if we look for sums more than 1.
    recurringSplitterInds = find(sum(truncMapSplitters,2)>1);      %Row index for truncMap. 
    numRecurringSplitters = length(recurringSplitterInds); 
    recurringSplitters = cell(numSessions,1); 
    
    if ~isempty(recurringSplitters)
        for thisRow = 1:numRecurringSplitters
            for thisSession = 1:numSessions
                if truncMapSplitters(recurringSplitterInds(thisRow),thisSession)==1
                    %For each cell, each element represents the ith element
                    %in truncMap that is a splitter. If it is empty, the
                    %neuron did not pass the bootstrap test. 
                    recurringSplitters{thisSession} = recurringSplitterInds(thisRow);
                end
            end
        end
 
        plotMultiDaySplitters(putativeSplitters,truncMap,recurringSplitters);
        
        %Ignore the recurring splitters after plotting them once. 
        truncMapSplitters(recurringSplitterInds,:) = 0; 
    end

    transientSplitters = cell(numSessions,1); 

    for thisSession = 1:numSessions
        %Find splitters that don't appear on every day. 
        inds = find(truncMapSplitters(:,thisSession));
        existCell = ~isnan(truncMap(inds,:)); 
        transientSplitters{thisSession} = existCell.*repmat(inds,[1,numSessions]);     %Row index for truncMap.        
    end

    %Plot the responses for each day. 
    plotMultiDaySplitters(putativeSplitters,truncMap,transientSplitters);
    
end

 
%% 
function plotMultiDaySplitters(putativeSplitters,truncMap,inds)
    
    numSessions = length(putativeSplitters);

    for thisSESSION = 1:numSessions
        for thisNeuron = 1:length(inds{thisSESSION})
            figure('position',[-1244 -76 560 988]);
            
            for thisSession = 1:numSessions
                try
                    %Get index for cellResps. 
                    mapID = truncMap(inds{thisSESSION}(thisNeuron,thisSession),thisSession);        %References FT. 

                    %For normalizing within a day, across trial types. 
                    maxRate = max([max(putativeSplitters(thisSession).cellRespsByTrialType{mapID,1}), ...
                        max(putativeSplitters(thisSession).cellRespsByTrialType{mapID,2})]); 

                    subplot(2*numSessions,2,1+4*(thisSession-1));
                        imagesc(putativeSplitters(thisSession).cellRespsByTrialType{mapID,1});
                            title('Left Trials'); xlabel('Stem Bins'); ylabel('Lap');
                            caxis([0 maxRate]);
                    subplot(2*numSessions,2,2+4*(thisSession-1));  
                        imagesc(putativeSplitters(thisSession).cellRespsByTrialType{mapID,2});
                            title('Right Trials'); xlabel('Stem Bins'); ylabel('Lap');
                            caxis([0 maxRate]);
                    subplot(2*numSessions,2,3+4*(thisSession-1):4+4*(thisSession-1));
                        plot(putativeSplitters(thisSession).tuningcurves{mapID}(1,:),'b');  %Left
                            hold on;
                        plot(putativeSplitters(thisSession).tuningcurves{mapID}(2,:),'r');  %Right


                    %Determine whether this cell is more active on left or right
                    %trials by looking at the difference between the tuning curves.
                    deltasign = sign(putativeSplitters(thisSession).deltacurve{mapID});
                    deltasign(deltasign > 0) = 2;           %Right
                    deltasign(deltasign < 0) = 1;           %Left

                    for trialType = 1:2  %Left and right

                        %Statistically significant bins. 
                        sigBins = find(deltasign==trialType & putativeSplitters(thisSession).sigcurve{mapID});

                        %For placing asterisks a relative distance from the curve. 
                        ylim = get(gca,'ylim'); 
                        sf = 0.1;

                        %Define color based on left or right trial. 
                        if trialType == 1; col = 'b';       %Left       
                        else col = 'r'; end                 %Right                                

                        plot(sigBins,putativeSplitters(thisSession).tuningcurves{mapID}(trialType,sigBins)+ylim(2)*sf,['*',col]);
                    end
                        hold off;

                    %Fix up the plot. 
                    xlim([1 length(deltasign)]); 
                    xlabel('Stem Bins'); ylabel('Firing Rate'); legend({'Left','Right'},'location','best');
                catch
                end
            end
        end
    end
end
    

            