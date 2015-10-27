function visualizeDecode(pMap,XBin,YBin)
%
%
%

%% 
    nFrames = size(pMap,3); 
    
    for thisFrame = 1:nFrames
        imagesc(pMap(:,:,thisFrame)); 
        hold on;
        plot(XBin(thisFrame),YBin(thisFrame),'ro','linewidth',2);
        hold off;
        pause(0.05); 
    end
    
end