function visualizeDecode(pMap,XBin,YBin)
%visualizeDecode(pMap,XBin,YBin)
%
%   This function plots the posterior probability peaks that is output by
%   the Bayesian decoder. Overlaid on top is the mouse's true position. 
%
    nFrames = size(pMap,3); 
    
    colormap gray; 
    for thisFrame = 1:nFrames
        imagesc(pMap(:,:,thisFrame)); 
        hold on;
        plot(XBin(thisFrame),YBin(thisFrame),'ro','linewidth',2);
        caxis([0,0.05]);
        hold off;
        pause(0.02); 
    end
    
end