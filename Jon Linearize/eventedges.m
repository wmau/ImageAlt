function [eventedge] = eventedges(binaryX,metric,metricthrsh)
%EVENTEDGES - Detect the beginning and end of each instance of an event.
%       Applicable to field detection in 1D time or space.
%
%binaryX - Nx1 binary vector.  Indicates instances when an event occured.
%metric - Nx1 vector.  Metric distance (e.g. time or distance) 
%       corresponding to 'binaryX'. Important when the sampling interval 
%       of 'binaryX' is not constant. Entering an empty matrix '[]' will
%       yield the indices of the start and end of each event.
%metricthrsh - Scalar. Minimum metric distance between events for them to 
%       be considered as separate events. If the metric variable is an
%       empty matrix, the minimal distance will be measured in the number
%       of consecutive binary elements.
%
%Jon Rueckemann 2015

%Ensure input is in the correct format
if nargin<2 || isempty(metric)
    metric=1:numel(binaryX);
    assert(~isinteger(metricthrsh),['If there is no ''metric'' vector '...
        'given, then ''metricthrsh'' must be an integer.']);
end

assert(numel(binaryX)==numel(metric),['Unequal sizes of the binary '...
    'vector and the timestamp vector.']);

binaryX=logical(binaryX(:));
metric=metric(:);

if any(binaryX)
    %Find event start and ends
    eventtimes=metric(binaryX);
    shorttime=diff(eventtimes)<metricthrsh; %Find short gaps between events
    eventstart=eventtimes([true; ~shorttime]);
    
    eventendtimes=flip(eventtimes);
    eventend=eventendtimes([true; flip(~shorttime)]);
    eventend=flip(eventend);
    
    eventedge=[eventstart eventend];
else
    eventedge=[];
end
end