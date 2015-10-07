function findIntersessionSplitters(regStruct,baseStruct,sessionStruct)
%findIntersessionSplitters(regStruct,baseStruct,sessionStruct)
%   
%   Tracks splitters across days. First, plots neuronal responses on the
%   stem that had significantly different tuning curves for left versus
%   right trials. Then plots splitters that appeared on one day but not any
%   others. 
%
%   INPUTS
%       regStruct, baseStruct, sessionStruct: MasteryDirectory entries that
%       correspond to the session where the registration information lives,
%       the base session, and the registered sessions, respectively. 
%

%%  Extract splitter information for each session of interest. 
    regFilepath = regStruct.Location;                                   %Filepath for base image. 
    sessionFilepaths = {baseStruct.Location, sessionStruct.Location};   %Filepaths of considered sessions. 
    sessionDates = {baseStruct.Date, sessionStruct.Date};               %Dates in the format MM_DD_YYYY.
    numSessions = length(sessionFilepaths);                             %Total number of sessions. 
    savepdf = 0;
    
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
    
%% Get registered neurons. 
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
    
%% Find splitters and plot them. 
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
    recurringSplitters = truncMap(recurringSplitterInds,:);
    recur = 1;

    %Plot them. 
    plotMultiDaySplitters(putativeSplitters,recurringSplitters,savepdf,recur);
    
    %Deselect the splitters we've already plotted. 
    truncMapSplitters(recurringSplitterInds,:) = 0; 
    
    %Get splitters that were significant for one session. 
    [transientSplitterInds,~] = find(truncMapSplitters);
    transientSplitters = truncMap(transientSplitterInds,:);
    recur = 0; 

    %Plot the responses for each day. 
    plotMultiDaySplitters(putativeSplitters,transientSplitters,savepdf,recur);
    
end

function plotMultiDaySplitters(putativeSplitters,inds,savepdf,recur)
%% Nested function for plotting splitters across multiple imaging sesssions. 
    savepath = 'E:\Imaging Data\Endoscope\GCaMP6f_30\Alternation\11_12_2014\Register to 11_13';

    %Get data characteristics. 
    [numNeurons,numSessions] = size(inds); 

    for thisNeuron = 1:numNeurons
        f = figure;
        f.Units = 'inches';
        f.Position = [-13 1 5 8];

        for thisSession = 1:numSessions;
            mapID = inds(thisNeuron,thisSession);       %Indexes cellResps.

            try
                maxRate = max([max(putativeSplitters(thisSession).cellRespsByTrialType{mapID,1}),...
                max(putativeSplitters(thisSession).cellRespsByTrialType{mapID,2})]); 

                subplot(2*numSessions,2,1+4*(thisSession-1));
                imagesc(putativeSplitters(thisSession).cellRespsByTrialType{mapID,1})
                    title('Left Trials'); ylabel('Lap'); set(gca,'xtick',[]);
                    caxis([0 maxRate]);
                subplot(2*numSessions,2,2+4*(thisSession-1));  
                imagesc(putativeSplitters(thisSession).cellRespsByTrialType{mapID,2});
                    title('Right Trials'); set(gca,'xtick',[]);
                    colormap('gray'); 
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
                xlim([1 length(deltasign)]); set(gca,'xtick',[],'ytick',[0 0]);
                ylabel('Firing Rate'); legend({'Left','Right'},'location','best');       
            catch
            end
            if thisSession == numSessions; xlabel('Stem Bins'); 
            elseif thisSession == 1; ylabel('Rate'); end
        end
        
        %Save pdf. 
        if savepdf
            %export_fig(['Session #', num2str(thisSession),' Neuron #', num2str(inds(thisNeuron))],'-pdf','-r0'); 
            if recur
                print(fullfile(savepath,['MultiDay Neuron #', num2str(thisNeuron)]),'-dpdf');
            else
                print(fullfile(savepath,['Neuron #', num2str(thisNeuron)]),'-dpdf');
            end
        end
    end

end


