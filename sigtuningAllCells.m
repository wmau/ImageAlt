function [sigcurve,deltacurve,ci,pvalue,tuningcurves,shufdelta,neuronID] = sigtuningAllCells(x,y,FT)
%[sigcurve,deltacurve,ci,pvalue,tuningcurves,shufdelta] =
%sigtuningAllCells(x,y,FT)
%
%   Performs Jon Rueckmann's sigtuning function on all neurons that were
%   active on the center stem. 
%
%   INPUTS 
%       X & Y: Tracking data. 
%
%       FT: Output from ProcOut.mat. 
%
%   OUTPUTS: 
%       Cell arrays containing outputs of sigtuning for each cell. See
%       sigtuning.m. 
%

%%  Initialize. 
    try
        load('splitters.mat'); 
    catch
        disp('Obtaining stem responses...'); 
        [cellResps,splitters,trialtype,active] = splitter(x,y,FT);
    end
    
    %Number of neurons. 
    numActiveNeurons = length(active);
    numNeurons = length(cellResps); 
     
%% Perform bootstrapping. 
    %Preallocate. 
    sigcurve = cell(numNeurons,1);
    deltacurve = cell(numNeurons,1);
    ci = cell(numNeurons,1);
    pvalue = cell(numNeurons,1);
    tuningcurves = cell(numNeurons,1);
    shufdelta = cell(numNeurons,1);
    
    disp('Bootstrapping cell responses...'); 
    p = ProgressBar(numNeurons); 
    for thisNeuron = 1:numActiveNeurons
        thisActiveNeuron = active(thisNeuron);
        
        [sigcurve{thisActiveNeuron},deltacurve{thisActiveNeuron},...
            ci{thisActiveNeuron},pvalue{thisActiveNeuron},...
            tuningcurves{thisActiveNeuron},shufdelta{thisActiveNeuron}] = ...
            sigtuning(splitters{active(thisActiveNeuron)},trialtype,500); 
        p.progress;
       
    end
    p.stop;
    
end