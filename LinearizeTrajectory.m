function X = LinearizeTrajectory(x,y,mazetype)
%X = LinearizeTrajectory(x,y,mazetype)
%
%   Takes X and Y coordinates from aligned Cinexplex data (output of
%   batch_align_pos or rotated trajectory from rotate_traj) and outputs
%   linearized position on a continuous T-maze or circle maze (loop). 
%
%   INPUTS:
%       X & Y: Cineplex coordinates that have been processed (aligned and
%       rotated). 
%
%       mazetype: String specifying 'tmaze' for continuous alternation or
%       'loop' for running laps around one arm. 
%
%   OUTPUT: 
%       X: Vector containing the position of the mouse in one dimensional
%       space. 
%


%%  
    nbins = 80;
    
    switch mazetype
        case 'tmaze'
            %Get timestamps for left and right trials and when mouse is on
            %stem or at the goal location. 
            try 
                load(fullfile(pwd,'Alternation.mat'));
            catch
                Alt = postrials(x,y,0,'skip_rot_check',1);
            end
            onstem = Alt.section==2;        %Logical. 
             
            %Get the centroid and length of the stem. 
            centroidx = mean(x(onstem));
            centroidy = mean(y(onstem));
            stemlength = max(x(onstem)) - min(x(onstem)); 
            
            %Convert from Cartesian coordinates to polar coordinates. 
            [angs,radii] = cart2pol(x-centroidx, y-centroidy); 
            
            %Orient the stem so that its angle is 0.
            dblangs = 2*angs;
            dblangs = mod(dblangs,2*pi);
            avgang = circ_mean(dblangs'); 
            angs = angs - avgang;      
            angs = mod(angs,2*pi); 
             
            %Get the extreme radii on the stem. 
            cosang = cos(angs);
            behind = onstem & cosang>0;
            ahead = onstem & cosang<0;
            maxback = max(radii(behind) .* cosang(behind)); 
            maxfront = -min(radii(ahead) .* cosang(ahead)); 

            %Create a polar definition of the maze based on the mean of the
            %radius at each angle bin. 
            angdef=(pi/nbins:2*pi/nbins:2*pi)';
            sparseang = [angs(~onstem)'; 0; pi];
            sparserad = [radii(~onstem)'; maxback; maxfront]; 
            [~,angidx] = histc(sparseang,0:2*pi/nbins:2*pi);
            meanrad = accumarray(angidx,sparserad,[nbins,1],@mean);
            mazedef = [meanrad((round(nbins/2)+1):nbins); meanrad; ...
                meanrad(1:round(nbins/2))]; 
            
            %Smooth the vector of radii.  
            mazedef = smooth(mazedef,10,'rlowess'); 
            mazedef = mazedef((round(nbins/2)+1):round(nbins/2)+nbins);
            
            %Build angdef vector from 0 to 2pi. The first and last elements
            %of mazedef are the extrema of the maze. Take the mean of them
            %and pad onto the extreme angles. Now it corresponds to the
            %linearized distance based off angdef. 
            mazedef = [mean(mazedef([1 end])); mazedef; mean(mazedef([1 end]))];
            angdef = [0; angdef; 2*pi]; 
            
            %Find the cumulative distances to build look-up table. 
            rightside=angdef<=pi;   %Right turns on top given our viewing angle.
            leftside=angdef>=pi;
            [l_x,l_y]=pol2cart(angdef(leftside),mazedef(leftside));
            [r_x,r_y]=pol2cart(angdef(rightside),mazedef(rightside));
            
            %Use hypot to get the distance between points. 
            leftdist=[0; cumsum(hypot(diff(l_x),diff(l_y)))];   
            rightdist=[0; cumsum(hypot(diff(r_x),diff(r_y)))];
            
            %Create radian-ordered cumulative distance look-up table.
            cumdist(leftside) = leftdist; 
            cumdist(rightside) = flip(rightdist);   %Right turns go in reverse order.
            
            %BELOW COMMENTED CODE IS A HACK. For some reason, cumulative
            %distance on left arm is shorter than right arm. Perhaps due to
            %camera angle. 
            %cumdist(rightside) = flip(leftdist);
            
            %When using radian-ordered look-up table, distance must be at least stem length.
            cumdist = cumdist + stemlength;         
            
            %Find linearized distance by angular interpolation. 
            X=interp1(angdef,cumdist,angs,'pchip');
            
            %Use radius for when the mouse is on the stem. 
            %Max radius minus linearized radius is the distance already
            %traversed. 
            X(onstem) = maxback + radii(onstem) .* -cosang(onstem); 
            X(X(onstem)<0) = 0;                     %Distance can't be less than 0.
            X(X(onstem)>stemlength) = stemlength;   %Distance on stem can't be longer than length of stem. 
            
        %To do.
        case 'loop'
            disp('Loop code not finished yet!'); 
    end
        
end