function [sigcurve,deltacurve,ci,pvalue,tuningcurves,shufdelta,neuronID] = sigtuningAllCells(x,y,FT)
%[sigcurve,deltacurve,ci,pvalue,tuningcurves,shufdelta,neuronID] =
%sigtuningAllCells(x,y,FT)
%
%   Performs Jon Rueckmann's sigtuning function on all neurons that were
%   active on the center stem. 
%
%   INPUTS
%       X & Y: Tracking data. I used the coordinates from aligned tracking
%       data from batch_align_pos. 
%
%       FT: Trace data, like in ProcOut. 
%
%   OUTPUTS
%       sigcurve, deltacurve, ci, pvalue, tuningcurves, shufdelta: Nx1 cell
%       arrays (N=total number of neurons) containing vectors output from
%       sigtuning (see comments there). Note that these cell arrays are
%       sparsely populated. Some are empty because those neurons were not
%       active on the stem and so we didn't process them. 
%
%       neuronID: Mx1 vector that references the above cell arrays and FT.
%       The elements correspond to the indices of neurons active on the
%       stem.
%


%%  Initialize. 
    try
        load('splitters.mat'); 
    catch
        disp('Sorting stem responses by trial type...'); 
        splitterByTrialType(x,y,FT);
        
        disp('Obtaining stem responses for significance testing...'); 
        [cellResps,splitters,trialtype,active] = splitter(x,y,FT);
    end
    
    %Basic parameters. 
    iter = 1000;        %Change number of bootstrap iterations here!
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
    p = ProgressBar(numActiveNeurons); 
    for thisNeuron = 1:numActiveNeurons
        thisActiveNeuron = active(thisNeuron);

        [sigcurve{thisActiveNeuron},deltacurve{thisActiveNeuron},...
            ci{thisActiveNeuron},pvalue{thisActiveNeuron},...
            tuningcurves{thisActiveNeuron},shufdelta{thisActiveNeuron}] = ...
            sigtuning(splitters{thisNeuron},trialtype,iter); 

        p.progress;
       
    end
    p.stop;
    
    %This is a Nx1 vector (N=number of neurons active on the stem)
    %containing indices that reference FT. It's necessary to keep track of
    %neuron identity. The reason why we take a subset of the cells is to
    %drastically cut down on processing time for the bootstrap.
    neuronID = active; 
    
    numSplitters = length(find(cellfun(@any,sigcurve)));
    
    save('sigSplitters.mat','sigcurve','deltacurve','ci','pvalue',...
        'tuningcurves','shufdelta','neuronID','numSplitters'); 
    
end