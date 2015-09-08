function showboxes(im, boxes)

him = imshow(im, 'XData',[1 640],'YData',[480 1]);
set(gca,'YDir','normal','YTick',[1 480],'XTick',[1 640],'Visible','on');

scale = 5/8;
ylim = get(gca,'YLim');
axh = ylim(2)-ylim(1);

if(nargin == 2); nboxes = length(boxes);
else nboxes = 0;
end

for ii = 1:nboxes;
    x = scale.*boxes{ii}.xv;
    y = scale.*boxes{ii}.yv;
    cx = (max(x)+min(x))/2;
    cy = (max(y)+min(y))/2;
    bh = max(y)-min(y);
    fontscale = bh/axh;
    
    line(x,y,'LineWidth',2,'Color','green','HitTest','off');
    text(cx,cy,0,num2str(ii),'FontUnits','normalized','FontWeight','bold',...
        'HorizontalAlignment','center','VerticalAlignment','middle',...
        'FontSize',0.8*fontscale,'Color','green','HitTest','off');
end

t = text(0,480,0,'','FontUnits','normalized','FontSize',0.05,'FontWeight','bold',...
    'HorizontalAlignment','left','VerticalAlignment','top',...
    'Color','green','HitTest','off');
set(gca,'UserData',t);
set(gca,'ButtonDownFcn',@updatepoint);
set(him,'ButtonDownFcn',@updatepoint);

end

function updatepoint(obj, ~)
    scale = 8/5;
    while(obj ~= 0 && ~strcmp(get(obj,'Type'),'axes'))
        obj = get(obj,'Parent');
    end
    if(strcmp(get(obj,'Type'),'axes'))
        t = get(obj,'UserData');
        p = get(obj,'CurrentPoint');
        p = p(1,1:2);
        p2 = p.*scale;
        set(t,'String',sprintf(' (%3.0d,%3.0d)\n (%3.0d,%3.0d)',...
            round(p(1)),round(p(2)),round(p2(1)),round(p2(2))));
    end
end
