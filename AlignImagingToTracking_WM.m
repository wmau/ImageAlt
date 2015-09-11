function [x,y,speed,FT,FToffset,FToffsetRear] = AlignImagingToTracking_WM2(Pix2Cm,FT)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
SR = 20;

try
    load Pos.mat
    x = xpos_interp;
    y = ypos_interp;
catch
    [xpos_interp,ypos_interp,start_time,MoMtime] = PreProcessMousePosition('Video.DVT');
end

x = xpos_interp;
y = ypos_interp;

x = x.*Pix2Cm;
y = y.*Pix2Cm;
dx = diff(x);
dy = diff(y);
speed = hypot(dx,dy)*SR;

% align starts of Fluorescence video and Plexon tracking to the arrival of
% the mouse of the maze
fTime = (1:size(FT,2))/SR;
fStart = findclosest(MoMtime,fTime);
FT = FT(:,fStart:end);
fTime = (1:size(FT,2))/SR;

plexTime = (0:length(x)-1)/SR+start_time;
pStart = findclosest(MoMtime,plexTime);
x = x(pStart:end);
y = y(pStart:end);
%aviFrame = AVItime_interp(pStart:end);

speed = speed(pStart:end);
plexTime = (1:length(x))/SR;

Flength = size(FT,2);
FToffsetRear = 0;

% if Inscopix or Plexon is longer than the other, chop
if (length(plexTime) <= Flength)
    % Chop the FL
    FT  = FT(:,1:length(plexTime));
    FToffsetRear = length(plexTime) - Flength;
    Flength = length(plexTime);
    
else
    speed = speed(1:Flength);
    x = x(1:Flength);
    y = y(1:Flength);
    %aviFrame = aviFrame(1:Flength);
end

if (length(speed) < length(x))
    speed(end+1) = 0;
end

speed(1:100) = 0; % a hack, but otherwise screwy things happen

%%%%%%%%% adjust by half the movie smoothing window
HalfWindow = 10;

% shift position and speed right
x = [zeros(1,HalfWindow),x(1:end-HalfWindow)];
y = [zeros(1,HalfWindow),y(1:end-HalfWindow)];
%aviFrame = [zeros(1,HalfWindow),aviFrame(1:end-HalfWindow)];
speed = [zeros(1,HalfWindow),speed(1:end-HalfWindow)];

% chop the first HalfWindow
x = x(HalfWindow+1:end);
y = y(HalfWindow+1:end);
%aviFrame = aviFrame(HalfWindow+1:end);
speed = speed(HalfWindow+1:end);
FT = FT(:,HalfWindow+1:end);

FToffset = fStart + HalfWindow + 1;

end

