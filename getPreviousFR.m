function [FRtoday,FRyesterday] = getPreviousFR(sessionStructs,neuronInds,sessionMap)
%[FRtoday,FRyesterday] =
%getPreviousFR(sessionStructs,neuronInds,sessionMap)
%
%   Gets the "firing rate" of the same neurons for today and the day
%   before. Firing rate is currently a rough metric and in reality is the
%   number of calcium events divided by the number of frames. 
%
%   INPUTS
%       sessionStructs: 2-element struct where the SECOND element is the MD
%       entry for the reference day and the FIRST is the entry for the day
%       before. 
%   
%       neuronInds: Indices referencing FT corresponding to the neurons you
%       want to investigate. 
%
%       sessionMap: Output from neuron_reg_batch. 
%
%   OUTPUTS
%       FRtoday: N-element vector (N=number of neurons).Relative activity
%       for the reference date.
%
%       FRyesterday: Relative activity for the day before the reference
%       date. 
%

%% Compute reference activity. 
    currdir = pwd; 
    todayPath = sessionStructs(2).Location; 
    yesterdayPath = sessionStructs(1).Location; 
    today = sessionStructs(2).Date; 
    yesterday = sessionStructs(1).Date;  
    
    %Where neurons map onto other neurons. 
    map = sessionMap.map; 
    
    %Column of map that corresponds to the base date. 
    todayColumn = find(strcmp(today,{sessionMap.session.date})) + 1; 
    yesterdayColumn = find(strcmp(yesterday,{sessionMap.session.date})) + 1; 
    
    %Load the spike train data and get the mean.
    FT = loadFT(todayPath);  
    FRtoday = mean(FT(neuronInds,:),2); 

%% Find mapped neurons. 
    %Find the row containing the neuron entry. 
    [~,row] = ismember(neuronInds,map(:,todayColumn)); 
    row(row==0) = []; 
    nNeurons = length(row); 
    yesterdayInds = map(row,yesterdayColumn); 

%% Compute activity history. 
    %Load yesterday's spike trains. 
    FT = loadFT(yesterdayPath);
    FRyesterday = zeros(size(FRtoday)); 
    
    %Get the number of calcium events divided by the number of frames. 
    for thisNeuron = 1:nNeurons
        if yesterdayInds(thisNeuron) > 0 
            FRyesterday(thisNeuron) = mean(FT(yesterdayInds(thisNeuron),:)); 
        elseif yesterdayInds(thisNeuron) == 0   %For neurons that don't map, nan. 
            FRyesterday(thisNeuron) = nan;      
        end
    end
    
    cd(currdir); 
end

%% For loading FT.mat. 
function FT = loadFT(path)
    cd(path);
    
    try
        load('Pos_align.mat','FT'); 
    catch
        load('ProcOut.mat','FT'); 
        Pix2Cm = 0.15; 
        [~,~,~,FT] = AlignImagingToTracking_WM2(Pix2Cm,FT);
    end
end