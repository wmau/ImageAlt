function [centroid, c] = PL_GetCoords(s)
%
% AUTHOR: Benjamin Kraus (bkraus@bu.edu, ben@benkraus.com)
% Copyright (c) 2008-2009, , Benjamin Kraus
% $Id: PL_GetCoords.m 743 2009-01-27 23:25:24Z bkraus $

    if(size(s,2) == 4); t = s;
    else [n, t] = PL_GetTS(s);
    end
    
    [nCoords, nDim, nVTMode, c] = PL_VTInterpret(t);
    
    switch nDim
        case {3,4}
            centroid = c(:,1:3);
        case {5,6}
            led1zero = (c(:,2)==0 | c(:,3)==0);
            led2zero = (c(:,4)==0 | c(:,5)==0);
            led12zero = led1zero & led2zero;
            
            centroid = [c(:,1),mean(c(:,[2 4]),2),mean(c(:,[3 5]),2)];
            centroid(led2zero,:) = c(led2zero,[1 2 3]);
            centroid(led1zero,:) = c(led1zero,[1 4 5]);
            
            centroid = centroid(~led12zero,:);
            c = c(~led12zero,:);
        case 7
            led1zero = (c(:,2)==0 | c(:,3)==0);
            led2zero = (c(:,4)==0 | c(:,5)==0);
            led3zero = (c(:,6)==0 | c(:,7)==0);
            led12zero = led1zero & led2zero;
            led13zero = led1zero & led3zero;
            led23zero = led2zero & led3zero;
            led123zero = led1zero & led2zero & led3zero;
            
            centroid = [c(:,1),mean(c(:,[2 4 6]),2),mean(c(:,[3 5 7]),2)];
            centroid(led3zero,:) = [c(led3zero,1),mean(c(led3zero,[2 4]),2),mean(c(led3zero,[3 5]),2)];
            centroid(led2zero,:) = [c(led2zero,1),mean(c(led2zero,[2 6]),2),mean(c(led2zero,[3 7]),2)];
            centroid(led1zero,:) = [c(led1zero,1),mean(c(led1zero,[4 6]),2),mean(c(led1zero,[5 7]),2)];
            centroid(led23zero,:) = c(led23zero,[1 2 3]);
            centroid(led13zero,:) = c(led13zero,[1 4 5]);
            centroid(led12zero,:) = c(led12zero,[1 6 7]);
            
            centroid = centroid(~led123zero,:);
            c = c(~led123zero,:);
        otherwise
            centroid = c(:,1:3);
    end
end
