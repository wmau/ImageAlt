function onset = getFEpochs(FT)
%[onset,offset] = getFEpochs(FT)
%
%   Get the onsets and offsets of calcium events given a trace matrix. 
%
%   INPUT
%       FT: From TENASPIS.
%
%   OUTPUTS
%       onset/offset: Time indices for when a spike starts/stops. Each cell
%       is a neuron. Each element in the cell is a vector containing
%       indices. 
%

%% Get the onset and offsets of fluorescence. 
    %Preallocate. 
    nNeurons = size(FT,1); 
    onset = cell(nNeurons,1);
    
    %For each neuron, find the onsets and offsets using diff. 
    dspk = diff([zeros(nNeurons,1) FT],[],2);
    
    %Get all rising events. 
    [neuron,ts] = find(dspk==1);
    
    if nNeurons>1
        neuron = neuron';
        ts = ts';
    end
    
    for n=neuron
        %Find onsets where the train changes from 0 to 1.
        onset{n} = ts(neuron==n);
    end
    
end