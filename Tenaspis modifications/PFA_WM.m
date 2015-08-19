function [] = PFA(roomstr,rawfile,lengthcrit)
% [] = PFA(roomstr)
% roomstr is the name of the room e.g. '201a'
% rawfile is the same of the .h5 file containing the original movie


% Step 1: Calculate Placefields
CalculatePlacefields_WM(roomstr,lengthcrit);

% Step 2: Calculate Placefield stats
PFstats_WM(lengthcrit);

% Step 3: Extract Traces
%ExtractTracesProc_WM('D1Movie.h5',rawfile,lengthcrit)

clear all;
%load(['PlaceMaps',num2str(lengthcrit),'.mat']);

% Step 4: Browse placefields
%PFbrowse_WM('D1Movie.h5',find(pval > 0.9));

end

