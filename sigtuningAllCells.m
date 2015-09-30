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
        disp('Sorting stem responses...'); 
        splitterByTrialType(x,y,FT);
        
        disp('Obtaining stem responses...'); 
        [cellResps,splitters,trialtype,active] = splitter(x,y,FT);
    end
    
    %Number of neurons. 
    iter = 500;   
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
    neuronID = zeros(numNeurons,1); 
    
    disp('Bootstrapping cell responses...'); 
    p = ProgressBar(numNeurons); 
    for thisNeuron = 1:numActiveNeurons
        thisActiveNeuron = active(thisNeuron);
        
        %This is a Nx1 vector (N=number of neurons active on the stem)
        %containing indices that reference the entire collection of
        %neurons. It's necessary to keep track of neuron identity. The
        %reason why we take a subset of the cells is to drastically cut
        %down on processing time for the bootstrap. 
        neuronID(thisNeuron) = active(thisNeuron); 

        [sigcurve{thisActiveNeuron},deltacurve{thisActiveNeuron},...
            ci{thisActiveNeuron},pvalue{thisActiveNeuron},...
            tuningcurves{thisActiveNeuron},shufdelta{thisActiveNeuron}] = ...
            sigtuning(splitters{active(thisActiveNeuron)},trialtype,iter); 

        p.progress;
       
    end
    p.stop;
    
    save('sigSplitters.mat','sigcurve','deltacurve','ci','pvalue',...
        'tuningcurves','shufdelta','neuronID'); 
    
end