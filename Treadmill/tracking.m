function [status, events, moves] = tracking(varargin)
%   'initialize'  - status = tracking('initialize',maze)
%                   Two arguments, 'maze' is a character string indicating
%                   the maze for tracking. 'buttons' should be a structure
%                   which includes the fields TL (top left), TR (top
%                   right), BL (bottom left), BR (bottom right), WR (wrong
%                   right), and WL (wrong left). These are the event
%                   numbers used by the tracking software to notify the
%                   system what has happened.
%
%   'validate'    - status = tracking('validate',status,maze)
%
%   'track'       - [status,events,moves] = tracking('track',status,coords)
%
%   'update'      - [status,updated] = tracking('update',status,event)

    if(nargin < 1 || ~ischar(varargin{1}))
        error('Tracking:InvalidInput','First argument should always be a string.');
    end
    
    switch varargin{1}
        case {'initialize'}
            error(nargchk(2, 2, nargin, 'struct'));
            error(nargoutchk(1, 1, nargout, 'struct'));
        case {'validate'}
            error(nargchk(3, 3, nargin, 'struct'));
            error(nargoutchk(1, 1, nargout, 'struct'));
        case {'track'}
            error(nargchk(3, 3, nargin, 'struct'));
            error(nargoutchk(2, 3, nargout, 'struct'));
        case {'update'}
            error(nargchk(3, 3, nargin, 'struct'));
            error(nargoutchk(2, 2, nargout, 'struct'));            
        otherwise
            warning('Unrecognized action.'); %#ok<WNTAG>
    end
    
    fcn = str2func(varargin{1});
    [status,events,moves] = fcn(varargin{2:end});
end
    
% Define the initial conditions.
function [status, events, moves] = initialize(maze)
    events = []; moves = []; % Unused output from this function.
    
    if(nargin < 1 || ~ischar(maze)); maze = ''; end
    
    status.ready = false;   % Do we have everything we need to track?
    status.maze = maze;     % What kind of maze is this tracking for?
    
    status.eventcodes = maze_events();
    
    % The boxes structure contains all the maze specific information.
    fname = sprintf('mazeinfo_%s',regexprep(lower(maze),'[^a-z]',''));
    if(exist(fname,'file')==2)
        fcn = str2func(fname);
        [status.buttonmap, status.boxes] = fcn();
    else
        status.boxes = [];
        status.buttonmap = [];
    end

    % The "lastbox" is a fine-scale (per sample) record of the location
    % of the animal.
    status.lastbox = 0;
    
    % The "lastevent" is the last event that was returned by tracking
    % system.
    status.lastevent = 0;

    % The "history" is a listing of the past locations the animal has
    % visited. The "historyj" is used when the animal "backtracks",
    % which could be due to the animal turning around, or could be an
    % artifact of the tracking system.
    status.history = zeros(1,20);
    status.historyj = length(status.history);

    % If we have valid maze information and valid buttons, then set the
    % tracking status to true.
    if(~isempty(status.boxes) && ~isempty(status.buttonmap))
        status.ready = true;
    end
end

% Validate the status.
function [status, events, moves] = validate(status, maze)
    events = []; moves = []; % Unused output from this function.
    
    % Get a copy of the initial status for reference.
    if(nargin >= 2 && ischar(maze)); initstatus = initialize(maze);
    else initstatus = initialize();
    end
    
    % If we don't even have a structure, just use the initial status.
    if(~isstruct(status)); status = initstatus;
    else
        % We aren't ready until we pass validation.
        status.ready = false;
        
        % Check that we have a valid maze field in the status.
        % If not, then use the maze from the initstatus (if defined).
        if(~isfield(status,'maze') || ~ischar(status.maze))
            status.maze = initstatus.maze;
            
        % If we already had a maze field, then check if one was provided as
        % an argument. If not, then recreate initstatus using status.maze
        elseif(isempty(initstatus.maze))
            initstatus = initialize(status.maze);
        end
        
        if(~isfield(status,'eventcodes') || ~isstruct(status.eventcodes))
            status.eventcodes = initstatus.eventcodes;
        end
        
        if(~isfield(status,'boxes') || ~isstruct(status.boxes))
            status.boxes = initstatus.boxes;
        end
        
        if(~isfield(status,'buttonmap') || ~isnumeric(status.buttonmap))
            status.buttonmap = initstatus.buttonmap;
        end
        
        if(~isfield(status,'lastbox') || ~isnumeric(status.lastbox))
            status.lastbox  = initstatus.lastbox;
        end
        
        if(~isfield(status,'lastevent') || ~isnumeric(status.lastevent))
            status.lastevent = initstatus.lastevent;
        end

        if(~isfield(status,'history') || ~isnumeric(status.history))
            status.history = initstatus.history;
            status.historyj = initstatus.historyj;
        end

        if(~isfield(status,'historyj') || ~isnumeric(status.historyj))
            status.historyj = initstatus.historyj;
        end
        
        % Check that the maze provided (if provided) matches with this
        % tracking function.
        if(~strcmp(status.maze,initstatus.maze))
            warndlg('Incorrect tracking function in use.');

        % If we have valid buttons and the correct maze, then set the
        % tracking status to true.
        elseif(~isempty(status.boxes) && ~isempty(status.buttonmap))
            status.ready = true;
        end
    end
end

% Track the position of the animal and generate the events that happened.
function [status, events, moves] = track(status,coords)
    status = validate(status);
    events = zeros(0,2);
    moves = zeros(0,2);
    if(status.ready && ~isempty(coords))
        % Find out which boxes the animal has visited
        whichbox = inbox(coords, status.boxes);
        
        % Remove any coordinates that are not within boxes.
        coords = coords(whichbox ~= 0,:);
        whichbox = whichbox(whichbox ~= 0);
        
        % If there are any coordinates left, remove any duplicate entries
        % (we aren't interested in how long the animal stays in each box,
        % just what boxes were visited).
        if(size(whichbox,1) > 0)
            boxdiff = logical([1; diff(whichbox)]);
            whichbox = whichbox(boxdiff);
            coords = coords(boxdiff);
        end
        
        % Process each box coordinate that isn't the same as the previous
        % box coordinate.
        for j = 1:length(whichbox)
            if(whichbox(j) ~= status.lastbox)
                if(sanityCheck(status, whichbox(j), coords(j,1)))
                    moves(end+1,:) = [coords(j,1), whichbox(j)]; %#ok<AGROW>
                    [status,event] = processMove(status, whichbox(j));
                    if(event ~= 0)
                        events(end+1,:) = [coords(j,1),event]; %#ok<AGROW>
                        status.lastevent = event;
                    else
                        status.lastevent = 0;
                    end
                end
            end
        end
    end
end

% Feed this coordinate in to the system without a sanity check.
% This function is called when a button is pressed even though tracking was
% enabled. In other words, the tracking has failed, so kick it in to gear.
% If the coordinates were wrong, then return 'updated'.
% If the coordinates were right, then check the last event the system
% returned. If the last event doesn't match the supplied event, then set
% the last event and send updated. If the last event does match, then
% return 'false' for updated.
% We don't pay attention to the event generated by processMove because we
% are supplying the event, so we are ignoring the tracking generated event.
function [status, updated, moves] = update(status,event)
    moves = []; % Unused output from this function.
    status = validate(status);
    updated = false;
    box = 0;
    
    if(status.ready && isnumeric(event))
        eind = find(event == status.buttonmap(:,1),1,'first');
        if(~isempty(eind))
            event = status.buttonmap(eind,2);
            box = status.buttonmap(eind,3);
        else eind = find(event == status.buttonmap(:,2),1,'first');
        end
        
        if(~isempty(eind))
            box = status.buttonmap(eind,3);
        end
        
        if(box ~= 0 && box ~= status.lastbox)
            status = processMove(status,box);
            updated = true;
        end

        if(event ~= status.lastevent)
            status.lastevent = event;
            updated = true;
        end
    end
end

% This function checks to make sure that the current position is adjacent
% to the previous location. If that isn't true, then it is possible that
% the tracking system picked up a temporary artifact. The rat shouldn't be
% able to get from one box to another if they aren't adjacent.
function sane = sanityCheck(status,box,ts)
    sane = false;
    
    if(any(status.lastbox == status.boxes{box}.neighbors)); sane = true; end
    
    fprintf(1,'%7.2f: Lastbox: %d, This Box: %d. ',ts,status.lastbox, box);
    
    if(sane); fprintf(1,'  Sane Coordinate. ');
    else fprintf(1,'Insane Coordinate. ');
    end
    
    fprintf(1,'In the %s area.\n',status.boxes{box}.str);
end

% Process a single move from one box to another box.
function [status,event] = processMove(status, box)
    eventcodes = maze_events();
    ind = status.historyj;
    historylen = length(status.history);
    event = 0;

    if(ind == historylen-1)
        if(box ~= status.history(end))
            status.history(end) = box;
        end
        ind = historylen;
    elseif(ind == historylen)
        if(box ~= status.history(end) && box == status.history(end-1))
            ind = ind-1;
            event= eventcodes.BZC;
        else
            status.history = [status.history(2:end) box];
        end
    end

    if(status.boxes{box}.goal && ind == status.historyj)
        goodpath = false;
        for j = 1:length(status.boxes{box}.paths)
            path = status.boxes{box}.paths{j};
            if(all(status.history(end-length(path)+1:end) == path))
                goodpath = true;
            end
        end
        if(goodpath); event = status.boxes{box}.events(1);
        else event = status.boxes{box}.events(2);
        end
    end
    
    status.lastbox = box;
    status.historyj = ind;
end
