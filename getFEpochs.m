function [onset,offset] = getFEpochs(FT)
%[onset,offset] = getFEpochs(FT)
%
%   Get thet onsets and offsets of calcium events given a trace matrix. 
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
    offset = cell(nNeurons,1); 
    
    %For each neuron, find the onsets and offsets using diff. 
    for n=1:nNeurons
        spk = FT(n,:);
        
        %Difference of binary spike train.
        dspk = diff([0,spk]); 
        
        %Find onsets where the train changes from 0 to 1 and offsets from 1
        %to 0. 
        onset{n} = find(dspk==1); 
        offset{n} = find(dspk==-1);
    end
    
end