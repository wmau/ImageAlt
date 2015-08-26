function [output]=polarlinearize(xydata,varargin)
%
%
%stemtol - lateral distance from origin that classifies the center stem.
%           Measured in pixels.
%dectol - distance in front of origin that classifies the decision area.
%           Measured in pixels.
%choicetol - distance in front of origin that classifies the side arms.
%           Defines when rat leaves the decision area.  Measured in pixels.
%

checkpos=false;
namevars=extractvarargin(varargin,true);
stem= true;


%Find maze position that will act as the origin for polar coordinates
switch lower(mazetype)
    case 'tmaze'
        %Find the tracking centroid when animal is on the center stem
        ctrpos=confirmpos(xydata,ctreventts,checkpos, false);
        
        %Convert tracking to polar coordinates
        [angs,radii]=cart2pol(xydata(:,2)-ctrpos(1),xydata(:,3)-ctrpos(2));
        
        %Find the angle of the center stem, i.e. the most occupied angle.
        %Two steps: 1)Because angles should approximate diametric
        %bimodality, angles are doubled to create a unimodal distribution.
        %2) A narrow area around the center stem is defined and then the
        %optimal angle to orient the center stem is found from mean vector.
        
        if ~stem
            [~,unqang,~]=unique(angs);
            dblangs=2*angs(unqang);
            dblangs=mod(dblangs,2*pi);
            avgang=circ_mean(dblangs)/2;
            for a=1:500 %Refine by taking mean angle of vectors in the center
                tempang=angs-avgang;
                %index preliminary ctr
                tempctrstem=stemtol>abs(sin(tempang).*radii);
                tempang=angs(tempctrstem);
                %reflect angles of vec behind center
                tempang(cos(tempang)<0)=tempang(cos(tempang)<0)-pi;
                tempang=mod(tempang,2*pi);
                avgang=circ_mean(tempang,radii(tempctrstem));
            end
        else %manually enter stem
%             [x, y, w, h, avgang]=confirmpos(xydata,[], false, true);
%             boxCoords=convRect2Coords(x,y,w,h,avgang);
%             %height of box is 2x stemtol, but check if tall or wide first
%             if w>h
%                 stemtol=h/2;
%             else
%                 stemtol =w/2;
%             end
            pos =confirmpos(xydata,[], false, true);
            

           [avgang,~]=cart2pol(pos(2,1)-pos(1,1),pos(2,2)-pos(1,2));
          
           
        end
        
        
        
        %Rotate the polar coordinate system so the center stem is at 0.
        angs=angs-avgang;
        angs=mod(angs,2*pi);
        
        %Use sin to find position relative to center axis (positive=left)
        sinang=sin(angs);
        
        %Use cos to find position relative to center axis (negative=behind)
        cosang=cos(angs);
        
        %Find times when the animal is on the center stem
        ctrstem=stemtol>abs(sinang.*radii);
        
        if stem
         ctrstem=inpolygon(xydata(:,2),xydata(:,3),pos(:,1),pos(:,2));    
            
        end
        
        %Determine the maximum dimensions of the center stem
        maxfront=max(radii(ctrstem & sign(cosang)>0)...
            .*cosang(ctrstem & sign(cosang)>0));
        maxback=-min(radii(ctrstem & sign(cosang)<0)...
            .*cosang(ctrstem & sign(cosang)<0));
        
        %Modify "ctrstem" identification to include head swings outside of
        %"stemtol"
        ctrevt=eventedges(ctrstem,[],2);%Group timestamps with 2 sample gap
        for e=1:size(ctrevt)-1
            curidx=ctrevt(e,2):ctrevt(e+1,1);
            %Identify epochs of "off center stem" that are sandwiched
            %between times when the animal is on the center stem (tracking
            %stays within central 80%(appx) of the center stem).
            if all(radii(curidx).*cosang(curidx)>=-maxback*0.9 & ...
                    radii(curidx).*cosang(curidx)<=maxfront*0.9);
                ctrstem(curidx)=true;
            end
        end
        output.ctrstem=ctrstem;

        
        %Create a polar definition of the maze based on the mean of the
        %tracking position at each angle bin
        angdef=((1/mazepts)*pi:2*pi/mazepts:2*pi)';
        sparseang=[angs(~ctrstem); 0; pi];
        sparserad=[radii(~ctrstem); maxfront; maxback];
        [~,angidx]=histc(sparseang,0:2*pi/mazepts:2*pi);
        meanrad=accumarray(angidx,sparserad,[numel(angdef) 1],@mean);
        mazedef=[meanrad((round(mazepts/2)+1):mazepts); meanrad; ...
            meanrad(1:round(mazepts/2))];
        
        %Fit a smoothed line to the radii at each position
        mazedef=smooth(mazedef,10,'rlowess');
        mazedef=mazedef((round(mazepts/2)+1):(round(mazepts/2)+mazepts));
        
        %Store maps (raw and smoothed) for map verification plotting
        output.rawmap=[angdef meanrad];
        angdef=[0;angdef;2*pi];
        mazedef=[mean(mazedef([1 end])); mazedef; mean(mazedef([1 end]))];
        output.smoothmap=[angdef mazedef];
        
        %Find the length of the center stem
        frontctrdist=mazedef(angdef==0);
        backctrdist=interp1(angdef,mazedef,pi,'pchip');
        ctrdist=frontctrdist+backctrdist;
        output.ctrdistpxl=ctrdist;
        
        %Determine the cumulative distance around each side of the maze
        leftside=angdef<=pi;
        rightside=angdef>=pi;
        [l_x,l_y]=pol2cart(angdef(leftside),mazedef(leftside));
        [r_x,r_y]=pol2cart(angdef(rightside),mazedef(rightside));
        r_x=flip(r_x); r_y=flip(r_y); %right laps go clockwise
        leftdist=[0; cumsum(hypot(diff(l_x),diff(l_y)))];
        rightdist=[0; cumsum(hypot(diff(r_x),diff(r_y)))];
        output.leftdistpxl=leftdist;
        output.rightdistpxl=rightdist;
        leftdist=leftdist*sidelength/leftdist(end);%Scaled to true distance
        rightdist=rightdist*sidelength/rightdist(end);
        output.leftdist=leftdist;
        output.rightdist=rightdist;
        
        %Create radian ordered cumulative distance look up table
%         cumdist(leftside)=output.leftdist;
%         cumdist(rightside)=flip(output.rightdist);
%         cumdist=cumdist+ctrlength;
%         
        cumdist(leftside)=output.leftdist+ctrlength;
        cumdist(rightside)=-flip(output.rightdist);

        
        %Find linearized distance for all tracking
        lapdist=interp1(angdef,cumdist,angs,'pchip');
        %Center stem (bounded by linearized maze definition)
        lapdist(ctrstem)=(backctrdist+radii(ctrstem).*...
            cos(angs(ctrstem)))*ctrlength/ctrdist;%Scaled to true distance
        lapdist(lapdist(ctrstem)<0)=0;
        lapdist(lapdist(ctrstem)>ctrlength)=ctrlength;
        output.lindist=lapdist;
        
        %Find the tracking index at which the animal gets to the reward
        %site for each lap
        lapevt=sort([leftlapevt(:);rightlapevt(:)]);
        lapstartidx=interp1(xydata(:,1),1:size(xydata,1),lapevt,'nearest');
        
        %Identify the lap ID for each tracking timestamp. Laps start at the
        %center stem.
        lapid=zeros(size(xydata(:,1)));
        for x=1:numel(lapstartidx)
            %Find the first time the animal is on the center stem after
            %getting a reward
            temp=false(size(lapid));
            temp(lapstartidx:end)=true;
            curlapidx=find(ctrstem&temp,1,'first');
            lapid(curlapidx)=1;
        end
        lapid(1)=1;
        lapid=cumsum(lapid);
        output.lapid=lapid;
        
        %Find side for all linearized tracking (0=center, 1=left, -1=right)
        linside=sign(sinang);
        linside(ctrstem)=0;
        output.linside=linside;
        
        output.lapdirection=zeros(size(xydata(:,1)));
        output.lapcount=zeros(size(xydata(:,1)));
        for ii=1:length(ctreventts)
           trialStart =find(xydata(:,1)<ctreventts(ii),1,'first');
           if ii==length(ctreventts)
               trialEnd=(length(xydata(:,1)));
           else
               trialEnd =find(xydata(:,1)<ctreventts(ii+1),1,'first');
           end
            [~,idx,~]=unique(lapdist(trialStart:trialEnd));
            tmp=linside(idx);
            tmp=tmp(tmp~=0);
            output.lapdirection(trialStart:trialEnd)=mode(tmp);
            output.lapcount(trialStart:trialEnd)=ii;
        end
        
        
        
        %Find the distance of the reward sites on the idealized maze
        leftRpos=confirmpos(xydata,leftlapevt,checkpos, false);
        leftRang=cart2pol(leftRpos(1)-ctrpos(1),leftRpos(2)-ctrpos(2));
        leftRdist=interp1(angdef,cumdist,leftRang,'pchip');
        rightRpos=confirmpos(xydata,rightlapevt,checkpos, false);
        rightRang=cart2pol(rightRpos(1)-ctrpos(1),rightRpos(2)-ctrpos(2));
        rightRdist=interp1(angdef,cumdist,rightRang,'pchip');
        output.leftrewarddist=leftRdist;
        output.rightrewarddist=rightRdist;
        
        %Confirm thresholds dividing regions are in correct order
        assert(dectol>choicetol,['The threshold marking the decision '...
            'must be farther away from the center point than the side '...
            'arm threshold.']);
        
        %Find times when the animal is in the decision area
        output.decision=dectol<radii.*cosang & ~ctrstem;
        
        %Find times when the animal is on the side arms
        output.sidearm=choicetol>radii.*cosang & ~ctrstem;
        
    case 'circle'
        %Find center of tracking
        ctrpos=confirmpos(xydata);
        
        if ~exist('startpos','var')
            %Confirm the position of the maze start
            startpos=confirmpos(xydata,ctreventts,checkpos, false);
        end
        
        %Convert the position of lap starts to polar coordinates
        startang=cart2pol(startpos(1)-ctrpos(1),startpos(2)-ctrpos(2));
        
        %Convert tracking to polar coordinates
        [angs,radii]=cart2pol(xydata(:,2)-ctrpos(1),xydata(:,3)-ctrpos(2));
        
        %Rotate polar coordinate system so that lap start is at 0 degrees
        angs=angs-startang;
        rev=diff(angs);
        revangs(1)=angs(1);
        for i=2:length(angs)
            revangs(i) = revangs(i-1) - rev(i-1);
        end
        angs=revangs';
        angs=mod(angs,2*pi);
        
        
        output.angs=angs;
        
        
        %Find the tracking index at which the animal first passes the
        %threshold for each lap.  (Backtracking is considered part of lap)
        cumangs=(unwrap(angs));
 
        
        nstartcross=floor(max(cumangs)/(2*pi));%number of start crossings
        startidx=nan(nstartcross,1);
        for x=1:abs(nstartcross)
            startidx(x)=find(cumangs>=2*pi*x,1,'first');
        end
        startidx=[1; startidx(:)];
        
        %Identify the lap ID for each tracking timestamp
        lapid=zeros(size(cumangs));
        lapid(startidx)=1;
        lapid=cumsum(lapid);
        
        %Create a polar definition of the maze based on the mean of the
        %tracking position at each angle bin
        angdef=((1/mazepts)*pi:2*pi/mazepts:2*pi)';
        [~,angidx]=histc(angs,0:2*pi/mazepts:2*pi);
        meanrad=accumarray(angidx,radii,[numel(angdef) 1],@mean);
        mazedef=[meanrad(round(mazepts/2)+1:mazepts); meanrad; ...
            meanrad(1:round(mazepts/2))];
        
        %Fit a smoothed line to the radii at each position
        mazedef=smooth(mazedef,10,'rlowess');
        mazedef=mazedef(51:150);
        
        %Store maps (raw and smoothed) for map verification plotting
        output.rawmap=[angdef meanrad];
        angdef=[0;angdef;2*pi];
        mazedef=[mean(mazedef([1 end])); mazedef; mean(mazedef([1 end]))];
        output.smoothmap=[angdef mazedef];
        
        %Determine the cumulative distance around the maze
        [xcoord,ycoord]=pol2cart(angdef,mazedef);
        cumdist=[flip(-cumsum(flip(hypot(diff(xcoord),diff(ycoord)))));...
            0; cumsum(hypot(diff(xcoord),diff(ycoord)))];
        angdef=[-flip(angdef(2:end)); angdef];
        output.distmap=[angdef cumdist];
        
        %Find linearized distance for each lap
        lapdist=nan(size(lapid));
        for x=1:max(lapid)
            curangs=unwrap([0; angs(lapid==x)]);
            curangs(1)=[];
            lapdist(lapid==x)=interp1(angdef,cumdist,curangs,'pchip');
        end
        output.lapdist=[lapid lapdist];
end
end

function pos=confirmpos(xydata,eventts,checkpos, stem)
%Find the centroid of tracking during a particular event.

if  nargin>1 && stem
    
    %
   
    str='Y';
    while (upper(str)=='Y')
         figh=figure('name','Select both ends of the stem.');
         hold
           line(xydata(:,2),xydata(:,3),'color',[0.7 0.7 0.7]);
        % this code works to make rectangle which includes width of stem
        
        %         [hPatch,api] = imRectRot('rotate', 1, 'color', [1, 0.1 0.1]);
        %         str=input('If you would like to try again? Y/N [N]: ', 's')
        %         if isempty(str)
        %             str= 'N';
        %         end
        %         delete(hPatch);
        %     end
        %     pos=api.getPos();
        %     delete(hPatch);
        %     delete(figh);
        %     return
        
        %This code takes in four points, and uses that box to define stem
        pos=ginput(4);
        line([pos(:,1);pos(1,1)],[pos(:,2);pos(1,2)],'color',[1 0.1 0.1],'LineWidth',7);
        str=input('If you would like to try again? Y/N [N]: ', 's')
        if isempty(str)
            str= 'N';
        end
       delete(figh);
    end
    return
    
    %If there is an event, find x and y position of each event timestamp
elseif nargin>1 && ~isempty(eventts)
    eventx=interp1(xydata(:,1),xydata(:,2),eventts);
        eventx(isnan(eventx(:,1)),:) = [];
        
    eventy=interp1(xydata(:,1),xydata(:,3),eventts);
        eventy(isnan(eventy(:,1)),:) = [];
    %Find temporary center
    
    tempctr=mean([eventx(:) eventy(:)]);
else
    %Use entire tracking record
    eventx=xydata(:,2);
    eventx(isnan(eventx(:,1)),:) = [];
    eventy=xydata(:,3);
    eventy(isnan(eventy(:,1)),:) = [];
    
    %Find temporary center
    firstctr=mean(unique([eventx(:) eventy(:)],'rows'));
    
    %Find the mean radius for regularly defined intervals around the center
    [ang,radii]=cart2pol(eventx-firstctr(1),eventy-firstctr(2));
    angbins=-pi:pi/12.5:pi; %25 angular bins
    [~,angidx]=histc(ang,angbins);
    binradii=accumarray(angidx,radii,[],@mean);
    binradii=smooth(binradii);
    [tempx,tempy]=pol2cart(-pi*.96:0.08*pi:pi,binradii');
    tempctr=[range(tempx)/2+min(tempx)+firstctr(1)...
        range(tempy)/2+min(tempy)+firstctr(2)];
end

%Convert tracking to polar coordinates
[~,radii]=cart2pol(eventx-tempctr(1),eventy-tempctr(2));

%Get user input if positions are not normally distributed around center
if ~lillietest(radii)
    figh=figure('name','Select center of event.');
    hold
    line(xydata(:,2),xydata(:,3),'color',[0.7 0.7 0.7]);
    scatter(eventx,eventy,10,'r');
    pos=ginput(1);
    delete(figh);
else
    pos=tempctr;
end
end

% 
% function [stemCoords] = convRect2Coords(x,y,w,h,a)
% %x y is originally upper left coord of unrotated box, this function
% %calculates the actual coordinate after rotation, then precedes to do this
% %for every other corner of the box
% x0= (x+.5*w);
% y0=(y+.5*h); %find center of rectangle
% x1 = (x-x0)*cos(a) - (y-y0)*sin(a)+x0;
% y1 = (x-x0)*sin(a) + (y-y0)*cos(a)+y0;
% 
% x=x+w;
% x2 = (x-x0)*cos(a) - (y-y0)*sin(a)+x0;
% y2 = (x-x0)*sin(a) + (y-y0)*cos(a)+y0;
% 
% y=y-h;
% x3 = (x-x0)*cos(a) - (y-y0)*sin(a)+x0;
% y3 = (x-x0)*sin(a) + (y-y0)*cos(a)+y0;
% 
% x=x-w;
% x4 = (x-x0)*cos(a) - (y-y0)*sin(a)+x0;
% y4 = (x-x0)*sin(a) + (y-y0)*cos(a)+y0;
% 
% 
% stemCoords=[x1,y1; x2,y2; x3,y3; x4,y4];
% 
% end