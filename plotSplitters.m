function plotSplitters(splitters,active)
%plotSplitters(splitters,active)
%
%   Plots splitters lap by lap. 
%
%   INPUTS:
%       splitters: Cell array output from splitterbyLaps.
%
%       active: Vector output from splitterByLaps.
%

for i=1:length(active)
    figure(active(i));
    subplot(1,2,1);
        imagesc(splitters{active(i),1});
        title('Left Trials');
        xlabel('Stem Bins');
        ylabel('Lap');
    subplot(1,2,2); 
        imagesc(splitters{active(i),2});
        title('Right Trials');
        xlabel('Stem Bins');
        ylabel('Lap'); 
end