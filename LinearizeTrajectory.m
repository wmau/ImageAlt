function [t,X] = LinearizeTrajectory(x,y,mazetype)
%
%
%

%%
    switch mazetype
        case 'tmaze'
            %Get the boundaries and the centroid of the stem. 
            bounds = sections(x,y,1); 
            centroidx = mean(unique(bounds.center.x));
            centroidy = mean(unique(bounds.center.y)); 
            
            %Convert from Cartesian coordinates to polar coordinates. 
            [angs,radii] = cart2pol(x-centroidx, y-centroidy); 
            
        case 'loop'
    end
    
end