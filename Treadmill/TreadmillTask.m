function TreadmillTask(settings)
% $Id: waterports.m 3705 2012-03-10 21:20:20Z bkraus $
daq.reset;
rstream = RandStream('mt19937ar','Seed', mod(prod(clock()),2^32));
RandStream.setGlobalStream(rstream);
tr= Treadmill('COM2');
defsettings.valves = true;
defsettings.protocol = 'Normal';
defsettings.protocol = 'No Alternation';
defsettings.leftporttime = 200;
defsettings.rightporttime = 200;
defsettings.mapserver = false;
defsettings.joystick = true;
defsettings.tracking = false;
defsettings.blocking = inf;
defsettings.maze = 'Treadmill';
defsettings.training= true;
defsettings.deltaspeed = 5;


defsettings.treadmill.on = true;
defsettings.treadmill.speeds = 30;
defsettings.treadmill.times = 20 ;
defsettings.treadmill.distances = 1500;
defsettings.treadmill.fixed = 'time'; % Fixed parameter
defsettings.treadmill.vary = 'speed'; % Independant parameter
defsettings.treadmill.blocksize = 1; % Number of repeats before switching
defsettings.treadmill.randomize = true; % False = sequential
defsettings.treadmill.range = false; % True means use continuous range.
% False means use provided values.

defsettings.treadmill.rewardbefore = 0; % Give water reward before starting treadmill
defsettings.treadmill.delay = 0; % Delay before starting treadmill (after water, sec)
defsettings.treadmill.rewardafter  = 200; % Give water reward after stopping treadmill
defsettings.treadmill.lapbefore = false; % Record lap when treadmilll starts
defsettings.treadmill.lapafter = false; % Record lap when treadmill stops
defsettings.treadmill.pausenotstop = true; % Remember settings when manually stopping treadmill


% Initialize variables for use later.
LEFT_VALVE = 3;               % Output bit for left valve
MIDD_VALVE = 4;               % Output bit for treadmill valve
RIGH_VALVE = 5;               % Output bit for right valve
EXTR_VALVE = 6;               % Output bit for extra valve
TONE =    15;
BUZZER = 14;
PLX_LEFT_VALVE = 17;
PLX_MIDD_VALVE = 18;
PLX_RIGH_VALVE = 19;
PLX_TREADMILL_ON = 21;
PLX_TREADMILL_OFF = 22;
PLX_STOP_BUTTON = 23;

if (~isempty(daqfind))
    stop(daqfind)
end
[~, msgid] = lastwarn;
%state = warning('off',msgid);
dio=daq.createSession('ni');
addDigitalChannel(dio, 'dev6', 'Port0/Line0:7', 'OutputOnly');
addDigitalChannel(dio, 'dev6', 'Port1/Line0:7', 'OutputOnly');
addDigitalChannel(dio, 'dev6', 'Port2/Line0:7', 'OutputOnly');
%warning(state)  % restore state


% Set all bits high (negative logic, high = off)
outputSingleScan(dio,ones(1,24));

INVERT_VALVES = false;        % Pulse high-low-high (inverted)?

tim = timer('StartFcn',@startfcn,'TimerFcn',@timerfcn,...
    'StopFcn',@stopfcn,'ErrorFcn',@errorfcn,'Period',0.01,...
    'ExecutionMode','fixedDelay');
s = 0;
deviceNum = 1;
needtosave=false;
jumpedOffTreadmill = false;



EVENTCODES = maze_events();       % Load the event codes.
buttonmap = [EVENTCODES.TL, EVENTCODES.LL, 0;...
    EVENTCODES.TR, EVENTCODES.RL, 0;...
    EVENTCODES.ML, EVENTCODES.LV, 0;...
    EVENTCODES.MR, EVENTCODES.RV, 0;...
    EVENTCODES.BL, EVENTCODES.LW, 0;...
    EVENTCODES.BR, EVENTCODES.RW, 0];
%
% buttonmap = [eventcodes.LV, eventcodes.LV, 0;...
%     eventcodes.RV, eventcodes.RV, 0;...
%     eventcodes.LL, eventcodes.LL, 8;...
%     eventcodes.RL, eventcodes.RL, 5;...
%     eventcodes.TM, eventcodes.TM, 2;...
%     eventcodes.TMS, eventcodes.TMS, 0];


%     MIN_SBI = 1.5;                % Minimum number of seconds between presses of the same button.
%     MIN_ABI = 0.5;                % Minimum number of seconds between presses of any buttons.

history = [];
needtosave = false;
%     last_time = ones(6,1).*(0-MIN_SBI);

lap = -1;
errors = 0;
last_turn = 'S';

sessionnum = 0;
session.date = now();
session.zerothlap = '';
session.comment='';
session.laps = [];
session.turns = '';
session.blocks = [];
session.correct = [];
session.wrongpath = [];
session.treadmill = [];

timeref = tic;
time = 0;
timeoffset = 0;
havetimeoffset = false;

treadmillinit = false;
treadmilldelay = 0;
treadmillrunning = false;
treadmillstart = 0;
treadmillcount = 0;
treadmillind = 0;
treadmillcurspeed = 0;
treadmillcurtime = 0;
treadmillpausestate = 0;
middleporttime = 0;

trackstat.ready = false;
joy = 0;

if(nargin == 0)
    settings = checksettings();
else
    settings = checksettings(settings);
end
savetrackstat = trackstat; % DEBUGGING

%For syncing treadmill start times with Cineplex. 
treadmillStartts = cell(1,1);   treadmillStopts = cell(1,1);
treadmillStartTrial = 1;        treadmillStopTrial = 1; 

h = waterportsGUI();
set(h.controls,'CloseRequestFcn',@closeButton)
set(h.timer,'CloseRequestFcn',@toggleTimer);
set(h.ll,'Callback',{@(x,y) process_event(EVENTCODES.LL,'computer')});
set(h.rl,'Callback',{@(x,y) process_event(EVENTCODES.RL,'computer')});
set(h.lv,'Callback',{@(x,y) process_event(EVENTCODES.LV,'computer')});
set(h.rv,'Callback',{@(x,y) process_event(EVENTCODES.RV,'computer')});
set(h.lw,'Callback',{@(x,y) process_event(EVENTCODES.LW,'computer')});
set(h.rw,'Callback',{@(x,y) process_event(EVENTCODES.RW,'computer')});
set(h.tmillstart,'Callback',{@(x,y) process_event(EVENTCODES.TM,'computer')});
set(h.tmillstop,'Callback',{@(x,y) process_event(EVENTCODES.TMS,'computer')});
set(h.open,'Callback',@openHist);
set(h.save,'Callback',@saveHist);
set(h.pause,'Callback',@playpause);
set(h.reset,'Callback',@resetchecker);
set(h.settings,'Callback',@settingscallback);
set(h.showtimer,'Callback',@toggleTimer);
applysettings;

    function startfcn(varargin)
        output(h.maindsp, 'Disabling Screen Saver...');
        [status, result] = dos('FlipSS /off');
        if(status == 0); output(h.maindsp, 'Screen Saver Disabled.');
        else output(h.maindsp, regexprep(result,'\n',' '));
        end
        
        % Open connection with the Plexon Server
        if(settings.mapserver)
            output(h.maindsp,'Connecting to Plexon MAP Server...');
            try s = PL_InitClient(0);
            catch %#ok<CTCH>
                s = 0;
            end
            
            if s == 0
                output(h.maindsp,'Failed to connect to Plexon MAP Server');
            end
        end
        
        if(s ~= 0)
            output(h.maindsp, 'Connected to Plexon MAP Server.');
            
            pars = PL_GetPars(s);
            if(~pars(11))
                output(h.maindsp, 'Sort Client is not running.');
                warndlg('Sort Client must be running to use the button box or video tracking. Disconnecting from MAP Server.','Sort Client not running.');
                output(h.maindsp, 'Closing connection to Plexon MAP Server...');
                PL_Close(s);
                s = 0;
            end
        end
        
        set(h.pause,'String','Pause');
        set(h.pause,'Enable','on');
    end

    function errorfcn(varargin)
        output(h.maindsp, 'Error encountered.');
    end

    function stopfcn(varargin)
        output(h.maindsp, sprintf('Pausing...'));
        
        if (s ~= 0);
            output(h.maindsp, 'Closing connection to Plexon MAP Server...');
            PL_Close(s);
            s = 0;
        end
        
        output(h.maindsp, 'Enabling Screen Saver...');
        [status, result] = dos('FlipSS /on');
        if(status == 0); output(h.maindsp, 'Screen Saver Enabled.');
        else output(h.maindsp, regexprep(result,'\n',' '));
        end
        
        set(h.pause,'String','Start');
        set(h.pause,'Enable','on');
    end

    function timerfcn(varargin)
        if(settings.joystick && joy ~= 0 && isvalid(joy))
            joyevents = getEvents(joy);
            for k = 1:size(joyevents,1)
                joystick_event(joyevents(k,1),joyevents(k,2));
            end
        end
        
        if(s ~= 0)
            res = PL_WaitForServer(s, 10);
            if(res ~= 0)
                [~, t] = PL_GetTS(s);
                events = t(t(:,1) == 4,[2 4]);
                events = sortrows(events, 2);
                
                for j = 1:size(events,1);
                    %                  system_event(events(j,1),'button',events(j,2));
                end
                
                if(settings.tracking)
                    coords = PL_GetCoords(t);
                    
                    savetrackstat = trackstat; % DEBUGGING
                    
                    [trackstat,trackevents] = tracking('track',trackstat,coords);
                    
                    % DEBUGGING
                    if(size(trackevents,1)> 0); disp(trackevents); end
                    if(isfield(trackstat,'history') && isfield(savetrackstat,'history'))
                        if(any(trackstat.history ~= savetrackstat.history))
                            if(length(trackstat.history) >= 10)
                                disp(trackstat.history(end:-1:end-9));
                            else
                                disp(trackstat.history(end:-1:1));
                            end
                        end
                    end
                    % END DEBUGGING
                    
                    for j = 1:size(trackevents,1);
                        process_event(trackevents(j,2),'tracking',trackevents(j,1));
                    end
                end
            end
        end
        
        checkTreadmill();
        updateTimers();
    end

    function joystick_event(event_num,event_time)
        jsmap = joystickmap;
        ind = find(event_num == jsmap(:,1));
        if(~isempty(ind))
            event_num = jsmap(ind,2);
            process_event(event_num,'button',event_time);
        end
    end

    function system_event(event_num,source,event_time)
        %                 if(strcmp(source,'button') && event_num >= 3 && event_num <= 6)
        %                     earliest_any = max(last_time) + MIN_ABI;
        %                     earliest_this = last_time(event_num) + MIN_SBI;
        %                     if(event_time_in < max(earliest_any, earliest_this)); return; end
        %                     last_time(event_num) = event_time_in;
        %                 end
        
        ind = find(event_num == buttonmap(:,1));
        if(~isempty(ind));
            event_num = buttonmap(ind,2);
            process_event(event_num,source,event_time)
        end
    end

    function process_event(event_num,source,event_time)
        if(nargin~=3); event_time = now(); end
        sessionts = (event_time - session.date)*24*60*60;
        
        switch event_num
            case EVENTCODES.LV
                output(h.maindsp, sprintf('Left Water Valve (%.2f)', sessionts));
                if(s ~= 0); PL_SendUserEvent(s, event_num); end
                left_valve();
            case EVENTCODES.RV
                output(h.maindsp, sprintf('Right Water Valve (%.2f)', sessionts));
                if(s ~= 0); PL_SendUserEvent(s, event_num); end
                right_valve();
            case EVENTCODES.MV
                output(h.maindsp, sprintf('Middle Water Valve (%.2f)', sessionts));
                if(s ~= 0); PL_SendUserEvent(s, event_num); end
                middleporttime = settings.treadmill.rewardbefore;
                if(middleporttime == 0)
                    middleporttime = settings.treadmill.rewardafter;
                elseif(settings.treadmill.rewardafter > 0)
                    middleporttime = min(middleporttime, settings.treadmill.rewardafter);
                end
                middle_valve();
            case EVENTCODES.BZC
                output(h.maindsp, sprintf('Reversed on maze', sessionts));
                pulseBit(BUZZER, 500);
            case EVENTCODES.BZT
                if(treadmillrunning)
                    output(h.maindsp, sprintf('Jumped off running Treadmill', sessionts));
                    stopTreadmill();
                    jumpedOffTreadmill= true;
                    pulseBit(TONE, 4000);
                    
                end
                
                
            case {EVENTCODES.LL, EVENTCODES.RL, EVENTCODES.LW, EVENTCODES.RW}
                % If you press the button every lap, ignoring the tracking
                % system, then on every lap one of four conditions could
                % exist:
                % (1) The system is off-track. Pressing the button will
                %     cause 'updated' to be set true, an therefore
                %     alternate will be called, recording the lap.
                % (2) The system is on-track, but you pressed the button a
                %     little bit early. Pressing the button will cause
                %     'updated' to be set true, an therefore alternate will
                %     be called and the lap will be recorded. You will also
                %     push the tracking ahead a little, preventing it from
                %     recording the event twice.
                % (3) The system is on-track and it beat you to the punch.
                %     In this case, theoretically, updated will be set to
                %     false, which means that the tracking system should
                %     have already generated the event and there is no need
                %     to do it again.
                % (4) The system is on-track, but didn't think the water
                %     ports should be opened. This could be because the
                %     tracking system thought the rat used the wrong path.
                %     In this case, 'updated' should be set true.
                if(settings.tracking && ~strcmp(source,'tracking'))
                    [trackstat, updated] = tracking('update',trackstat,event_num);
                else
                    updated = true;
                end
                if  (jumpedOffTreadmill)
                     jumpedOffTreadmill=false;
                     output(h.maindsp, 'turn ignored because jumped off treadmill');
                elseif(updated)
                    alternate(event_num,event_time);
                    if(s ~= 0); PL_SendUserEvent(s, event_num); end
                    
                else 
                    output(h.maindsp, 'Button press ignored');
                end
            case EVENTCODES.TM
                output(h.maindsp, sprintf('Starting treadmill (%.2f)', sessionts));
                
                treadmillStartts{treadmillStartTrial} = datestr(now,14); 
                treadmillStartTrial = treadmillStartTrial + 1; 
                
                initTreadmill(event_num,event_time);
                
                if(s ~= 0); PL_SendUserEvent(s, event_num); end
            case EVENTCODES.TMS
                output(h.maindsp, sprintf('Stopping treadmill (%.2f)', sessionts));
                
                treadmillStopts{treadmillStopTrial} = datestr(now,14);
                treadmillStopTrial = treadmillStopTrial + 1; 
                
                stopTreadmill();
                if(s ~= 0); PL_SendUserEvent(s, event_num); end
            case EVENTCODES.DECSPEED
                if(settings.training~=0)
                    settings.treadmill.speeds = settings.treadmill.speeds -settings.deltaspeed;
                    if(settings.treadmill.speeds < 0); settings.treadmill.speeds = 0; end
                    output(h.maindsp, sprintf('Speed= %d', settings.treadmill.speeds));
                    tr.SetSpeed=settings.treadmill.speeds;
                end
            case EVENTCODES.INCSPEED
                if(settings.training~=0)
                    settings.treadmill.speeds = settings.treadmill.speeds +settings.deltaspeed;
                    if(settings.treadmill.speeds > tr.MaxSpeed); settings.treadmill.speeds = tr.MaxSpeed; end
                    output(h.maindsp, sprintf('Speed= %d', settings.treadmill.speeds));
                    tr.SetSpeed=settings.treadmill.speeds;
                end
        end
    end

    function alternate(event_num,event_time)
        correctpath = true;
        
        switch event_num
            case {EVENTCODES.LL, EVENTCODES.LW}; this_turn = 'L'; str = 'Left';
            case {EVENTCODES.RL, EVENTCODES.RW}; this_turn = 'R'; str = 'Right';
            case {EVENTCODES.MV}; this_turn = 'M'; str = 'Middle';
        end
        
        switch event_num
            case {EVENTCODES.LL, EVENTCODES.RL, EVENTCODES.MV}
                lap = lap + 1;
                output(h.maindsp, sprintf('Lap %d, %s Lap (%.2f)', lap, str, event_time));
                correctpath = true;
            case {EVENTCODES.LW, EVENTCODES.RW}
                session.wrongpath(end+1) = event_time;
                output(h.maindsp, sprintf('%s Wrong Path (%.2f)', str, event_time));
                correctpath = false;
        end
        
        if(lap <= 0 && correctpath)
            %timeref = tic;
            havetimeoffset = false;
            session.date = now;
            session.zerothlap = this_turn;
            time = 0;
            
            if(strcmp(settings.protocol,'Normal') || ...
                    strcmp(settings.protocol,'No Alternation'))
                switch this_turn
                    case 'L'; left_valve();
                    case 'R'; right_valve();
                    case 'M'; middle_valve();
                end
            end
        elseif(correctpath)
            needtosave = true;
            session.laps(lap) = toc(timeref);
            time = session.laps(lap)/60;
            session.turns(lap) = this_turn;
            if(strcmp(settings.protocol,'No Alternation'))
                session.correct(lap) = true;
            elseif(strcmp(settings.protocol,'Manual Reward'))
                session.correct(lap) = false;
            else session.correct(lap) = ~strcmp(last_turn,this_turn);
            end
            if(session.correct(lap))
                if(errors >= settings.blocking); session.blocks(lap) = true;
                else session.blocks(lap) = false;
                end
                errors = 0;
                switch settings.protocol
                    case {'Normal', 'No Alternation'}
                        switch this_turn
                            case 'L'; left_valve();
                            case 'R'; right_valve();
                            case 'M'; middle_valve();
                        end
                    case 'Opposite'
                        switch this_turn
                            case 'L'; right_valve();
                            case 'R'; left_valve();
                            case 'M'; middle_valve();
                        end
                end
            else
                session.blocks(lap) = false;
                errors = errors + 1;
                if(errors >= settings.blocking)
                    output(h.maindsp, 'Block on Next Turn');
                end
            end
        end
        
        last_turn = this_turn;
        updateDisplay();
        if(correctpath); updateCounter(); end
    end

    function left_valve(varargin) %#ok<VANUS>
        if(settings.valves && deviceNum > 0)
            output(h.maindsp, sprintf('Left Valve (%0.0f ms)',settings.leftporttime));
            pulseBit(LEFT_VALVE, settings.leftporttime);
            pulseBit(PLX_LEFT_VALVE,1);
        else
            output(h.maindsp, 'Left Valve (test)');
        end
    end

    function right_valve(varargin) %#ok<VANUS>
        if(settings.valves && deviceNum > 0)
            output(h.maindsp, sprintf('Right Valve (%0.0f ms)',settings.rightporttime));
            
            pulseBit(RIGH_VALVE, settings.rightporttime);
            pulseBit(PLX_RIGH_VALVE,1);
        else
            output(h.maindsp, 'Right Valve (test)');
        end
    end

    function middle_valve(varargin)
        if(settings.valves && deviceNum > 0)
            output(h.maindsp, sprintf('Middle Valve (%0.0f ms)',middleporttime));
            
            pulseBit(MIDD_VALVE, middleporttime);
            pulseBit(PLX_MIDD_VALVE,1);
        else
            output(h.maindsp, 'Middle Valve (test)');
        end
    end

    function extra_valve(varargin)
        if(settings.valves && deviceNum > 0)
            output(h.maindsp, sprintf('Extra Valve (%0.0f ms)',middleporttime));
            
            pulseBit(EXTR_VALVE, settings.leftporttime);
        else
            output(h.maindsp, 'Extra Valve (test)');
        end
    end

% initTreadmill starts the treadmill sequence, which could include a
% waterport opening, followed by a pause, followed by the actual start
% of the treadmill.
    function initTreadmill(event_num, event_time)
        if(treadmillinit)
            output(h.maindsp, 'Treadmill sequence has already been initiated.');
        elseif(treadmillrunning)
            output(h.maindsp, 'Treadmill is already running.');
        else
            if(settings.treadmill.rewardbefore > 0)
                middleporttime = settings.treadmill.rewardbefore;
                if(treadmillpausestate > 0); %do nothing
                elseif(settings.treadmill.lapbefore)
                    alternate(EVENTCODES.MV, event_time);
                else middle_valve();
                end
                treadmilldelay = toc(timeref);
                treadmillinit = true;
                
            else
                treadmillinit = false;
                % pulseBit(PLX_TREADMILL_ON, 1);
                startTreadmill();
            end
        end
    end

% startTreadmill actually starts the treadmill running. This is where
% the speed and time are determined.
    function startTreadmill()
        if(treadmillrunning)
            output(h.maindsp, 'Treadmill already running.');
        else
            pulseBit(PLX_TREADMILL_ON, 1);
            if(treadmillpausestate > 1)
                output(h.maindsp, 'Treadmill resuming previous speed and restarting time.');
                treadmillpausestate = 0;
            else
                treadmillpausestate = 0;
                num = max([length(settings.treadmill.speeds),length(settings.treadmill.times)]);
                if(treadmillcount >= settings.treadmill.blocksize || treadmillcount <= 0)
                    treadmillcount = 0;
                    if(settings.treadmill.randomize)
                        treadmillind = ceil(rand(1).*num);
                    else
                        treadmillind = mod(treadmillind,num)+1;
                    end
                end
                treadmillcount = treadmillcount + 1;
                
                if(settings.treadmill.range && length(settings.treadmill.speeds) == 2)
                    % If there are two values for treadmill speed, then compute a
                    % random speed based on the allowed range.
                    treadmillcurspeed = rand(1)*diff(settings.treadmill.speeds)+settings.treadmill.speeds(1);
                elseif(length(settings.treadmill.speeds)>1)
                    treadmillcurspeed = settings.treadmill.speeds(treadmillind);
                else
                    treadmillcurspeed = settings.treadmill.speeds;
                end
                
                if(settings.treadmill.range && length(settings.treadmill.times) == 2)
                    if(length(settings.treadmill.speeds) == 2)
                        % If there are two values for both treadmill speed and
                        % time, then distance must be fixed, so compute time based
                        % on the speed chosen earlier.
                        treadmillcurtime = settings.treadmill.distances./treadmillcurspeed;
                    else
                        % If only time has two values, then speed must be fixed,
                        % so compute a random time based on the allowed range.
                        treadmillcurtime = rand(1)*diff(settings.treadmill.times)+settings.treadmill.times(1);
                    end
                elseif(length(settings.treadmill.times)>1)
                    treadmillcurtime = settings.treadmill.times(treadmillind);
                else
                    treadmillcurtime = settings.treadmill.times;
                end
            end
            
            treadmillstart = toc(timeref);
            treadmillrunning = true;
            if(settings.treadmill.on && deviceNum > 0)
                tr.SetSpeed= treadmillcurspeed;
                output(h.maindsp, sprintf('Treadmill set to %0.2f cm/s for %0.2f s and %0.2f cm',...
                    treadmillcurspeed,treadmillcurtime,treadmillcurspeed*treadmillcurtime));
            else
                output(h.maindsp, sprintf('Treadmill set to %0.2f cm/s for %0.2f s and %0.2f cm (test)',...
                    treadmillcurspeed,treadmillcurtime,treadmillcurspeed*treadmillcurtime));
            end
            tr.start(treadmillcurtime)
        end
    end

% stopTreadmill is called to force the treadmill to stop immediately.
    function stopTreadmill()
        if(strcmp(tr.Running,'on'))
            treadmillinit = false;
            treadmilldelay = 0;
            if(settings.treadmill.pausenotstop)
                treadmillpausestate = 1;
                output(h.maindsp, 'Treadmill sequence forced to pause');
            else
                output(h.maindsp, 'Treadmill sequence forced to stop');
            end
        end
        
        if(treadmillrunning)
            session.treadmill(end+1,:) = [treadmillstart, toc(timeref), ...
                treadmillcurspeed, treadmillcurtime, false];
            if(settings.treadmill.pausenotstop)
                treadmillpausestate = 2;
                output(h.maindsp, 'Treadmill paused');
            end
        end
        treadmillrunning = false;
        if(settings.treadmill.on && deviceNum > 0)
            pulseBit(PLX_STOP_BUTTON, 1);
            tr.stop();
            output(h.maindsp, 'Treadmill forced to stop');
        else
            output(h.maindsp, 'Treadmill forced to stop (test)');
        end
    end

% checkTreadmill is the "timerfcn" that will either start or stop the
% treadmill after the appropriate delay, and open a waterport after the
% treadmill stops if necessary.
    function checkTreadmill()
        if(treadmillinit && toc(timeref) - treadmilldelay >= settings.treadmill.delay)
            treadmillinit = false;
            treadmilldelay = 0;
            startTreadmill();
        elseif(treadmillrunning && toc(timeref) - treadmillstart >= treadmillcurtime)
            treadmillrunning = false;
            session.treadmill(end+1,:) = [treadmillstart, toc(timeref), ...
                treadmillcurspeed, treadmillcurtime, true];
            if(deviceNum > 0)
                tr.stop();
                pulseBit(PLX_TREADMILL_OFF, 1);
                output(h.maindsp, sprintf('Treadmill automatically stopped (%.2f)', toc(timeref)));
            else
                output(h.maindsp, 'Treadmill automatically stopped (test)');
            end
            
            if(settings.treadmill.rewardafter > 0)
                middleporttime = settings.treadmill.rewardafter;
                if(settings.treadmill.lapafter)
                    alternate(EVENTCODES.MV, toc(timeref));
                else middle_valve();
                end
            end
        end
    end

    function output(display, str)
        output_list = get(display,'String');
        output_list = output_list(end:-1:1);
        num = length(output_list)+1;
        str = strtrim(str);
        output_list{end+1} = sprintf('%3d  %s',num,str);
        set(display,'String',output_list(end:-1:1));
        drawnow
    end

    function settingscallback(varargin) %#ok<VANUS>
        settings = changesettings(settings, h);
        settings = checksettings(settings);
        applysettings;
    end

    function applysettings()
        
        if(strcmp('treadmill',regexprep(lower(settings.maze),'[^a-z]','')))
            set(h.tmillstart,'Enable','on');
            set(h.tmillstop,'Enable','on');
        else
            set(h.tmillstart,'Enable','off');
            set(h.tmillstop,'Enable','off');
        end
        
        updateDisplay();
    end

    function settings = checksettings(settings)
        if(nargin==0); settings = defsettings;
        else
            % First check to see if old settings are hanging around. If so,
            % use them to set defaults for their replacements.
            % At the moment the only setting is "duration", which is
            % replaced by both leftporttime and rightporttime.
            if(~isfield(settings,'leftporttime') || ~isnumeric(settings.leftporttime))
                settings.leftporttime = defsettings.leftporttime;
            end
            
            
            if(~isfield(settings,'rightporttime') || ~isnumeric(settings.rightporttime))
                settings.rightporttime = defsettings.rightporttime;
            end
            
            
            
            
            % Now check all the rest of the settings, making sure they are
            % at least present and the correct variable type.
            settings = checkfieldtypes(settings, defsettings);
            
            % Special case, if blocking is set to zero, change it to inf.
            if(settings.blocking == 0); settings.blocking = inf; end
        end
        
        % Get the assignments for the remote buttons based on maze type.
        fname = sprintf('mazeinfo_%s',regexprep(lower(settings.maze),'[^a-z]',''));
        if(exist(fname,'file')==2)
            fcn = str2func(fname);
            buttonmap = fcn();
        else
            buttonmap = [EVENTCODES.TL, EVENTCODES.LL, 0;...
                EVENTCODES.TR, EVENTCODES.RL, 0;...
                EVENTCODES.ML, EVENTCODES.LV, 0;...
                EVENTCODES.MR, EVENTCODES.RV, 0;...
                EVENTCODES.BL, EVENTCODES.LW, 0;...
                EVENTCODES.BR, EVENTCODES.RW, 0];
        end
        
        % If Joystick control is activated, then initialize the joystick
        % listener. Otherwise stop it and delete it.
        if(settings.joystick)
            if(joy == 0 || ~isvalid(joy));
                try
                    joy = joysticklistener(1);
                    start(joy);
                catch
                    joy = 0;
                    warndlg('Joystick failed to initialize.','Joystick Disabled');
                    settings.joystick = false;
                    
                end
            end
        elseif(joy ~= 0)
            if(isvalid(joy)); delete(joy); end
            joy = 0;
        end
        
        % If MAP Server access is disabled, then disable tracking.
        if(~settings.mapserver && settings.tracking)
            warndlg('Tracking will not work with MAP Server access disabled.','Tracking Disabled');
            settings.tracking = false;
        end
        
        % If tracking is currently off, then reset the tracking
        % information, leave trackstat.ready = false.
        if(~settings.tracking)
            tmptrackstat.ready = false;
            trackstat = tmptrackstat;
            clear tmptrackstat
            
            % If tracking is currently on, but trackstat.ready isn't a field,
            % then re-initalize the tracking status.
        elseif(~isfield(trackstat,'ready') || ~islogical(trackstat.ready))
            trackstat = tracking('initialize',settings.maze);
            
            % If tracking is currently on, and the trackstat variable has valid
            % data, then keep that data, but validate it.
        else
            trackstat = tracking('validate',trackstat,settings.maze);
        end
        
        % If trackstat.ready is false, then disable tracking.
        if(settings.tracking && ~trackstat.ready);
            settings.tracking = false;
            warndlg('Tracking could not initialize.','Tracking Disabled');
        end
        
        % Check the treadmill settings
        switch settings.treadmill.fixed
            case 'distance'
                settings.treadmill.distances = settings.treadmill.distances(1);
                if(strcmp(settings.treadmill.vary,'time'))
                    % Distance Fixed, Time Varying, Compute Speed
                    settings.treadmill.times = sort(settings.treadmill.times);
                    settings.treadmill.speeds = settings.treadmill.distances./settings.treadmill.times;
                else
                    % Distance Fixed, Speed Varying, Compute Time
                    settings.treadmill.vary = 'speed';
                    settings.treadmill.speeds = sort(settings.treadmill.speeds);
                    settings.treadmill.times = settings.treadmill.distances./settings.treadmill.speeds;
                end
                if(settings.treadmill.range)
                    settings.treadmill.speeds = settings.treadmill.speeds([1,end]);
                    settings.treadmill.times = settings.treadmill.times([1,end]);
                end
            case 'speed'
                settings.treadmill.speeds = settings.treadmill.speeds(1);
                if(strcmp(settings.treadmill.vary,'distance'))
                    % Speed Fixed, Distance Varying, Compute Time
                    settings.treadmill.distances = sort(settings.treadmill.distances);
                    settings.treadmill.times = settings.treadmill.distances./settings.treadmill.speeds;
                else
                    % Speed Fixed, Time Varying, Compute Distance
                    settings.treadmill.vary = 'time';
                    settings.treadmill.times = sort(settings.treadmill.times);
                    settings.treadmill.distances = settings.treadmill.speeds.*settings.treadmill.times;
                end
                if(settings.treadmill.range)
                    settings.treadmill.times = settings.treadmill.times([1,end]);
                    settings.treadmill.distances = settings.treadmill.distances([1,end]);
                end
            case 'time'
                settings.treadmill.times = settings.treadmill.times(1);
                if(strcmp(settings.treadmill.vary,'distance'))
                    % Time Fixed, Distance Varying, Compute Speed
                    settings.treadmill.distances = sort(settings.treadmill.distances);
                    settings.treadmill.speeds = settings.treadmill.distances./settings.treadmill.times;
                else
                    % Time Fixed, Speed Varying, Computer Time
                    settings.treadmill.vary = 'speed';
                    settings.treadmill.speeds = sort(settings.treadmill.speeds);
                    settings.treadmill.distances = settings.treadmill.speeds.*settings.treadmill.times;
                end
                if(settings.treadmill.range)
                    settings.treadmill.speeds = settings.treadmill.speeds([1,end]);
                    settings.treadmill.distances = settings.treadmill.distances([1,end]);
                end
            otherwise
                settings.treadmill.fixed = defsettings.treadmill.fixed;
                settings.treadmill.vary = defsettings.treadmill.vary;
                settings.treadmill.distances = settings.treadmill.distances(1);
                settings.treadmill.times = settings.treadmill.distances./settings.treadmill.speeds;
        end
        
        if(max([length(settings.treadmill.times) length(settings.treadmill.speeds)])<treadmillind)
            treadmillcount = 0;
            treadmillind = 0;
        end
    end

    function newstruct = checkfieldtypes(newstruct, refstruct)
        fields = fieldnames(refstruct);
        
        for j = 1:size(fields,1)
            if(~isfield(newstruct,fields{j}) || ...
                    ~isa(newstruct.(fields{j}),class(refstruct.(fields{j}))))
                newstruct.(fields{j}) = refstruct.(fields{j});
            elseif(isnumeric(newstruct.(fields{j})) && ...
                    (isempty(newstruct.(fields{j})) || ...
                    any(isnan(newstruct.(fields{j})))))
                newstruct.(fields{j}) = refstruct.(fields{j});
                warning(['Invalid number entered for ' fields{j} ', resetting to default value.'],'Invalid Entry');
            elseif(isstruct(newstruct.(fields{j})))
                newstruct.(fields{j}) = checkfieldtypes(newstruct.(fields{j}), refstruct.(fields{j}));
            end
        end
    end

    function openHist(varargin) %#ok<VANUS>
        if(~needtosave || (needtosave && resetchecker(true)))
            historytmp = loadHistory();
            if(~isempty(historytmp))
                history = historytmp;
                sessionnum = 0;
            end
            
            if(~isempty(history))
                if(isfield(history,'sessions') && ...
                        isfield(history.sessions,'settings') && ...
                        ~isempty(history.sessions(end).settings))
                    settings = checksettings(history.sessions(end).settings);
                elseif(isfield(history,'settings') && ...
                        ~isempty(history.settings))
                    settings = checksettings(history.settings);
                end
                output(h.maindsp, sprintf('History for %s loaded.',history.ratid));
                applysettings;
                textreport(history);
            end
        end
    end

    function success = saveHist(varargin) %#ok<VANUS>
        session.TreadmillLog = tr.Log;
        if(needtosave)
            if(~isfield(session,'comment'))
                session.comment = char(inputdlg({'Session Comments'},...
                    'Session Comments',10));
            else
                session.comment = char(inputdlg({'Session Comments'},...
                    'Session Comments',10,{session.comment}));
            end
            
            session.maze = settings.maze;
            session.settings = settings;
            
            [history, success, sessionnum] = addSession(session, history, sessionnum);
            
            if(success)
                [success, history] = saveHistory(history);
                
                %Navigate to directory containing other data and save text
                %file with treadmill start/stop timestamps. 
                
                
                if(success)
                    output(h.maindsp, sprintf('History for %s saved.',history.ratid));
                    needtosave = false;
                    %textreport(history,sessionnum);
                end
            else
                sessionnum = 0;
            end
            
        else msgbox('Nothing to save.');
        end
        updateDisplay();
    end

    function updateDisplay()
        settingsstr = sprintf('%s, %s, %d ms, Valves: ',...
            settings.maze, settings.protocol, mean([settings.rightporttime, settings.leftporttime]));
        if(settings.valves); settingsstr = [settingsstr 'on'];
        else settingsstr = [settingsstr 'off'];
        end
        
        if(settings.blocking == inf)
            settingsstr = [settingsstr ', Blocking: off'];
        else settingsstr = sprintf('%s, Blocking: %d',settingsstr,settings.blocking);
        end
        
        if(settings.tracking); settingsstr = [settingsstr ', Tracking: on'];
        else settingsstr = [settingsstr ', Tracking: off'];
        end
        
        if(settings.treadmill.on); settingsstr = [settingsstr ', Treadmill: on'];
        else settingsstr = [settingsstr ', Treadmill: off'];
        end
        
        set(h.settingsdsp,'String',settingsstr);
        
        if(lap < 0)
            sessionstr = sprintf('Not Started');
        elseif(lap == 0)
            sessionstr = sprintf('Time: %.2f, Lap: %d, T1: %g, T2: %g',time,lap,tim.AveragePeriod,joy.AveragePeriod);
        else
            sessionstr = 'Time: %.2f, Lap: %d, Correct: %d (%.2f%%), T1: %g, T2: %g';
            sessionstr = sprintf(sessionstr,time,lap,sum(session.correct),...
                sum(session.correct)/lap*100,tim.AveragePeriod,joy.AveragePeriod);
        end
        
        if(~isempty(history))
            sessionstr = ['Rat ID: ' history.ratid ', ' sessionstr];
        end
        
        set(h.sessiondsp,'String',sessionstr);
        
        if(needtosave)
            set(h.save,'Enable','on');
        else
            set(h.save,'Enable','off');
        end
    end

    function updateTimers()
        timer =  toc(timeref);
        if(ishandle(h.timerstr))
            timestr = sprintf('%2.0f:%02.0f',floor(timer/60),mod(floor(timer),60));
            set(h.timerstr,'String',timestr);
        end
    end

    function updateCounter()
        if(ishandle(h.counter))
            set(h.counter,'String',num2str(lap));
            if(errors >= settings.blocking)
                set(h.counter,'ForegroundColor','red');
                set(h.timerstr,'ForegroundColor','red');
            else
                set(h.counter,'ForegroundColor','white');
                set(h.timerstr,'ForegroundColor','white');
            end
        end
    end

    function success = resetchecker(varargin)
        if(islogical(varargin{1}) && varargin{1})
            button = 'Yes';
        else
            button = questdlg('Are you sure you want to reset?','Reset Confirmation...','Yes','No','Yes');
        end
        
        if(strcmp(button,'Yes') && promptSaveSession)
            success = reset();
        else
            output(h.maindsp, 'Save failed or reset cancelled');
            success = false;
        end
    end

    function success = reset()
        needtosave = false;
        try
            tr.stop();
        catch ME
            fwrite(2,ME.getReport());
        end
        tr.clearLog();
        
        timeref = tic;
        
        lap = -1;
        errors = 0;
        last_turn = 'S';
        
        sessionnum = 0;
        session.comment = '';
        session.date = now;
        session.zerothlap = '';
        session.laps = [];
        session.turns = '';
        session.blocks = [];
        session.correct = [];
        session.wrongpath = [];
        session.treadmill = [];
        
        stopTreadmill();
        
        treadmillinit = false;
        treadmilldelay = 0;
        treadmillrunning = false;
        treadmillstart = 0;
        treadmillcount = 0;
        treadmillind = 0;
        treadmillcurspeed = 0;
        treadmillcurtime = 0;
        treadmillpausestate = 0;
        
        tic;
        time = 0;
        timeoffset = 0;
        havetimeoffset = false;
        
        % If tracking is on, we want to clear the tracking information but
        % leave trackstat ready for tracking.
        if(settings.tracking)
            trackstat = tracking('initialize',settings.maze);
            
            % If tracking is off, we want to clear the tracking information,
            % but we don't need to bother trying to reinitialize trackstat.
        else
            tmptrackstat.ready = false;
            trackstat = tmptrackstat;
            clear tmptrackstat
        end
        
        % If trackstat.ready is false, then disable tracking.
        if(settings.tracking && ~trackstat.ready);
            settings.tracking = false;
            warndlg('Tracking could not reinitialize.','Tracking Disabled');
        end
        
        set(h.maindsp,'String',{'  1  Session Reset.'});
        
        if(ishandle(h.counter))
            set(h.timerstr,'String','');
            set(h.counter,'String','');
            set(h.timerstr,'ForegroundColor','white');
            set(h.counter,'ForegroundColor','white');
        end
        
        updateDisplay();
        success = true;
    end

    function success = promptSaveSession()
        if(needtosave);
            button = questdlg('Save unsaved session?','Saving Session...');
            switch button
                case {'Yes'}
                    success = saveHist();
                case {'No'}
                    button2 = questdlg('Are you sure? You will lose your unsaved session.','Clear Session Confirmation...','Yes','No','No');
                    switch button2
                        case {'Yes'}
                            success = true;
                        otherwise
                            success = false;
                    end
                otherwise
                    success = false;
            end
        else
            success = true;
        end
    end

    function playpause(varargin) %#ok<VANUS>
        % If currently running, then stop.
        if(strcmp(tim.Running,'on'))
            set(h.pause,'Enable','off');
            stop(tim);
            % If stopped, then start running.
        else
            set(h.pause,'Enable','off');
            start(tim);
        end
    end

    function closeButton(source, varargin) %#ok<VANUS>
        if(strcmp(tim.Running,'off') && promptSaveSession)
            if(joy ~= 0 && isvalid(joy)); delete(joy); end
            delete(source);
            if(ishandle(h.timer))
                delete(h.timer);
            end
            if(isvalid(tim))
                delete(tim);
            end
            tr.delete;
            Treadmill.deleteSerial;
%            delete dio;
            clear dio;
            daq.reset;
            dio=daq.createSession('ni');
            addDigitalChannel(dio, 'dev6', 'Port0/Line0:7', 'InputOnly');
            addDigitalChannel(dio, 'dev6', 'Port1/Line0:7', 'InputOnly');
            addDigitalChannel(dio, 'dev6', 'Port2/Line0:7', 'InputOnly');
            inputSingleScan(dio, ones(1,24));
        else warndlg('You must click ''Pause'' before closing this window.','Cannot Close');
        end
    end

    function toggleTimer(varargin) %#ok<VANUS>
        switch get(h.timer,'Visible');
            case 'on'
                set(h.timer,'Visible','off');
                set(h.showtimer,'String','Show Timer');
            case 'off'
                set(h.timer,'Visible','on');
                set(h.showtimer,'String','Hide Timer');
        end
    end
    function pulseBit(output, time)
       outVector=ones(1,24);
       outVector(output)=0;
       outputSingleScan(dio,outVector);
        java.lang.Thread.sleep(time);
        outputSingleScan(dio,ones(1,24));
    end
end

function h = waterportsGUI()
screen = get(0,'ScreenSize');
winsize = [450 600];

h.controls = figure('Name','Treadmill Task',...
    'NumberTitle','off','MenuBar','none',...
    'Position', [10 (screen(4)-winsize(2)-30) winsize]);

h.buttons = uipanel('Parent',h.controls,...
    'Units','normalized','Position',[0.01 0.82 0.35 0.17]);

h.ll = uicontrol(h.buttons,'Style','pushbutton',...
    'Units','normalized','Position',[0.02 0.67 0.47 0.30],...
    'String','Left Lap');
h.rl = uicontrol(h.buttons,'Style','pushbutton',...
    'Units','normalized','Position',[0.51 0.67 0.47 0.30],...
    'String','Right Lap');
h.lv = uicontrol(h.buttons,'Style','pushbutton',...
    'Units','normalized','Position',[0.02 0.35 0.47 0.30],...
    'String','Left Valve');
h.rv = uicontrol(h.buttons,'Style','pushbutton',...
    'Units','normalized','Position',[0.51 0.35 0.47 0.30],...
    'String','Right Valve');
h.lw = uicontrol(h.buttons,'Style','pushbutton',...
    'Units','normalized','Position',[0.02 0.03 0.47 0.30],...
    'String','Left Wrong');
h.rw = uicontrol(h.buttons,'Style','pushbutton',...
    'Units','normalized','Position',[0.51 0.03 0.47 0.30],...
    'String','Right Wrong');

h.open = uicontrol(h.controls,'Style','pushbutton',...
    'Units','normalized','Position',[0.37 0.94 0.20 0.05],...
    'String','Open');

h.save = uicontrol(h.controls,'Style','pushbutton',...
    'Units','normalized','Position',[0.37 0.88 0.20 0.05],...
    'String','Save','Enable','off');

h.tmillstart = uicontrol(h.controls,'Style','pushbutton',...
    'Units','normalized','Position',[0.37 0.82 0.20 0.05],...
    'String','Start Treadmill','Enable','off');

h.pause = uicontrol(h.controls,'Style','pushbutton',...
    'Units','normalized','Position',[0.58 0.94 0.20 0.05],...
    'String','Start');

h.reset = uicontrol(h.controls,'Style','pushbutton',...
    'Units','normalized','Position',[0.58 0.88 0.20 0.05],...
    'String','Reset');

h.tmillstop = uicontrol(h.controls,'Style','pushbutton',...
    'Units','normalized','Position',[0.58 0.82 0.20 0.05],...
    'String','Stop Treadmill','Enable','off');

h.settings = uicontrol(h.controls,'Style','pushbutton',...
    'Units','normalized','Position',[0.79 0.94 0.20 0.05],...
    'String','Settings');

h.showtimer = uicontrol(h.controls,'Style','pushbutton',...
    'Units','normalized','Position',[0.79 0.88 0.20 0.05],...
    'String','Show Timer');

h.settingsdsp = uicontrol(h.controls,'Style','text',...
    'Units','normalized','Position',[0.01 0.79 0.98 0.02]);

h.sessiondsp = uicontrol(h.controls,'Style','text',...
    'Units','normalized','Position',[0.01 0.76 0.98 0.02]);

h.maindsp = uicontrol(h.controls,'Style','edit',...
    'Units','normalized','Position',[0.01 0.01 0.98 0.74],...
    'BackgroundColor','white','HorizontalAlignment','left',...
    'Max',2,'Enable','inactive');

h.timer = figure('Name','Lap Counter',...
    'NumberTitle','off','MenuBar','none','Visible','off',...
    'Position', [5 39 screen(3)-11 screen(4)-63]);

h.counter = uicontrol(h.timer,'Style','text',...
    'Units','normalized','Position',[0 0.0 1 .65],...
    'BackgroundColor','black','ForegroundColor','white',...
    'FontUnits','normalized','FontSize',0.95);

h.timerstr = uicontrol(h.timer,'Style','text',...
    'Units','normalized','Position',[0 0.5 1 .65],...
    'BackgroundColor','black','ForegroundColor','white',...
    'FontUnits','normalized','FontSize',0.95);
end

function settings = changesettings(settings, h)
PROTS = {'Normal','Opposite','No Alternation'};
MAZES = {'Tmaze','Treadmill','Long-Loop','Short-Loop'};
FIXED = {'distance','speed','time'};

currentprot = 1;
for j = 1:length(PROTS)
    if(strcmpi(settings.protocol,PROTS{j})); currentprot = j; break; end
end

currentmaze = 1;
for j = 1:length(MAZES)
    if(strcmpi(settings.maze,MAZES{j})); currentmaze = j; break; end
end

currentfixed = 1;
for j = 1:length(FIXED)
    if(strcmpi(settings.treadmill.fixed,FIXED{j})); currentfixed = j; break; end
end

currentvary = 1;
for j = 1:length(FIXED)
    if(strcmpi(settings.treadmill.vary,FIXED{j})); currentvary = j; break; end
end

parentwin = get(h.controls,'Position');

setwin = dialog('Name','Settings',...
    'NumberTitle','off','MenuBar','none');

labels.maze = uicontrol(setwin,'Style','text',...
    'String','Maze:');

controls.maze = uicontrol(setwin,'Style','popupmenu',...
    'String',MAZES,'Value',currentmaze);

labels.protocol = uicontrol(setwin,'Style','text',...
    'String','Protocol:');

controls.protocol = uicontrol(setwin,'Style','popupmenu',...
    'String',PROTS,'Value',currentprot);

labels.mapserver = uicontrol(setwin,'Style','text',...
    'String','MAP Server:');

controls.mapserver = uicontrol(setwin,'Style','checkbox','Min',0,'Max',1,...
    'Value',settings.mapserver);


labels.joystick = uicontrol(setwin,'Style','text',...
    'String','Joystick:');

controls.joystick = uicontrol(setwin,'Style','checkbox','Min',0','Max',1,...
    'Value',settings.joystick);

labels.tracking = uicontrol(setwin,'Style','text',...
    'String','Video Tracking:');

controls.tracking = uicontrol(setwin,'Style','checkbox','Min',0,'Max',1,...
    'Value',settings.tracking);

labels.valves = uicontrol(setwin,'Style','text',...
    'String','Valves:');

controls.valves = uicontrol(setwin,'Style','checkbox','Min',0,'Max',1,...
    'Value',settings.valves);

labels.rightporttime = uicontrol(setwin,'Style','text',...
    'String','Right Port (ms):');

controls.rightporttime = uicontrol(setwin,'Style','edit',...
    'BackgroundColor','white','String',num2str(settings.rightporttime));

labels.leftporttime = uicontrol(setwin,'Style','text',...
    'String','Left Port (ms):');

controls.leftporttime = uicontrol(setwin,'Style','edit',...
    'BackgroundColor','white','String',num2str(settings.leftporttime));

labels.blocking = uicontrol(setwin,'Style','text',...
    'String','Block After:');

controls.blocking = uicontrol(setwin,'Style','edit',...
    'BackgroundColor','white','String',num2str(settings.blocking));

labels.treadmillon = uicontrol(setwin,'Style','text',...
    'String','Treadmill:');

controls.treadmillon = uicontrol(setwin,'Style','checkbox','Min',0,'Max',1,...
    'Value',settings.treadmill.on);

labels.tmillspeeds = uicontrol(setwin,'Style','text',...
    'String','Speeds (cm/s):');

controls.tmillspeeds = uicontrol(setwin,'Style','edit',...
    'BackgroundColor','white','String',num2str(settings.treadmill.speeds));

labels.tmilltimes = uicontrol(setwin,'Style','text',...
    'String','Times (s):');

controls.tmilltimes = uicontrol(setwin,'Style','edit',...
    'BackgroundColor','white','String',num2str(settings.treadmill.times));

labels.tmilldists = uicontrol(setwin,'Style','text',...
    'String','Distances (cm):');

controls.tmilldists = uicontrol(setwin,'Style','edit',...
    'BackgroundColor','white','String',num2str(settings.treadmill.distances));

labels.tmillfixed = uicontrol(setwin,'Style','text',...
    'String','Fixed Variable:');

controls.tmillfixed = uicontrol(setwin,'Style','popupmenu',...
    'String',FIXED,'Value',currentfixed);

labels.tmillvary = uicontrol(setwin,'Style','text',...
    'String','Independant:');

controls.tmillvary = uicontrol(setwin,'Style','popupmenu',...
    'String',FIXED,'Value',currentvary);

labels.tmillblocksize = uicontrol(setwin,'Style','text',...
    'String','Block Size:');

controls.tmillblocksize = uicontrol(setwin,'Style','edit',...
    'BackgroundColor','white','String',num2str(settings.treadmill.blocksize));

labels.tmillrandom = uicontrol(setwin,'Style','text',...
    'String','Randomize:');

controls.tmillrandom = uicontrol(setwin,'Style','checkbox','Min',0,'Max',1,...
    'Value',settings.treadmill.randomize);

labels.tmillrange = uicontrol(setwin,'Style','text',...
    'String','Range:');

controls.tmillrange = uicontrol(setwin,'Style','checkbox','Min',0,'Max',1,...
    'Value',settings.treadmill.range);

labels.rewardbefore = uicontrol(setwin,'Style','text',...
    'String','Reward Before (ms):');

controls.rewardbefore = uicontrol(setwin,'Style','edit',...
    'BackgroundColor','white','String',num2str(settings.treadmill.rewardbefore));

labels.delay = uicontrol(setwin,'Style','text',...
    'String','Delay (sec):');

controls.delay = uicontrol(setwin,'Style','edit',...
    'BackgroundColor','white','String',num2str(settings.treadmill.delay));

labels.rewardafter = uicontrol(setwin,'Style','text',...
    'String','Reward After (ms):');

controls.rewardafter = uicontrol(setwin,'Style','edit',...
    'BackgroundColor','white','String',num2str(settings.treadmill.rewardafter));

labels.lapbefore = uicontrol(setwin,'Style','text',...
    'String','Lab Before:');

controls.lapbefore = uicontrol(setwin,'Style','checkbox','Min',0,'Max',1,...
    'Value',settings.treadmill.lapbefore);

labels.lapafter = uicontrol(setwin,'Style','text',...
    'String','Lap After:');

controls.lapafter = uicontrol(setwin,'Style','checkbox','Min',0,'Max',1,...
    'Value',settings.treadmill.lapafter);

labels.pausenotstop = uicontrol(setwin,'Style','text',...
    'String','Pause (not Stop):');

controls.pausenotstop = uicontrol(setwin,'Style','checkbox','Min',0,'Max',1,...
    'Value',settings.treadmill.pausenotstop);

labels.training = uicontrol(setwin,'Style','text',...
    'String','Training Mode');
controls.training = uicontrol(setwin,'Style','checkbox','Min',0,'Max',1,...
    'Value',settings.training);

labels.deltaspeed = uicontrol(setwin,'Style','text',...
    'String','Change Speed amount');
controls.deltaspeed = uicontrol(setwin,'Style','edit',...
    'BackgroundColor','white','String',num2str(settings.deltaspeed));

settingnames = fieldnames(controls);

numrows = length(settingnames);

winsize = [200 30+25*numrows];
set(setwin,'Position',[parentwin(1)+50,...
    parentwin(2)+parentwin(4)-winsize(2)-150,winsize]);

for j = 1:numrows
    ypos = winsize(2)-j*25;
    set(labels.(settingnames{j}),'Position',[05 ypos 90 16]);
    set(controls.(settingnames{j}),'Position',[100 ypos 95 20]);
end

uicontrol(setwin,'Style','pushbutton','String','OK',...
    'Position',[110 05 30 20],'Callback',{@(x,y) uiresume(setwin)});
uicontrol(setwin,'Style','pushbutton','String','Cancel',...
    'Position',[145 05 50 20],'Callback',{@(x,y) delete(setwin)});

uiwait(setwin);

if(ishandle(setwin))
    settings.maze = MAZES{get(controls.maze,'Value')};
    settings.protocol = PROTS{get(controls.protocol,'Value')};
    settings.rightporttime = str2double(get(controls.rightporttime,'String'));
    settings.leftporttime = str2double(get(controls.leftporttime,'String'));
    settings.valves = logical(get(controls.valves,'Value'));
    settings.mapserver = logical(get(controls.mapserver,'Value'));
    settings.joystick = logical(get(controls.joystick,'Value'));
    settings.tracking = logical(get(controls.tracking,'Value'));
    settings.blocking = str2double(get(controls.blocking,'String'));
    if(settings.blocking == 0); settings.blocking = inf; end
    settings.treadmill.on = logical(get(controls.treadmillon,'Value'));
    settings.treadmill.speeds = str2num(get(controls.tmillspeeds,'String')); %#ok<ST2NM>
    settings.treadmill.times = str2num(get(controls.tmilltimes,'String')); %#ok<ST2NM>
    settings.treadmill.distances = str2num(get(controls.tmilldists,'String')); %#ok<ST2NM>
    settings.treadmill.fixed = FIXED{get(controls.tmillfixed,'Value')};
    settings.treadmill.vary = FIXED{get(controls.tmillvary,'Value')};
    settings.treadmill.blocksize = str2double(get(controls.tmillblocksize,'String'));
    settings.treadmill.randomize = logical(get(controls.tmillrandom,'Value'));
    settings.treadmill.range = logical(get(controls.tmillrange,'Value'));
    settings.treadmill.rewardbefore = str2double(get(controls.rewardbefore,'String'));
    settings.treadmill.delay = str2double(get(controls.delay,'String'));
    settings.treadmill.rewardafter = str2double(get(controls.rewardafter,'String'));
    settings.treadmill.lapbefore = logical(get(controls.lapbefore,'Value'));
    settings.treadmill.lapafter = logical(get(controls.lapafter,'Value'));
    settings.treadmill.pausenotstop = logical(get(controls.pausenotstop,'Value'));
    settings.training = logical(get(controls.training, 'Value'));
    settings.deltaspeed = str2double(get(controls.deltaspeed,'String'));
    delete(setwin);
end
end

function showerror(err)
warning(err.message);
for j = 1:size(err.stack,1)
    fprintf(2,'Error in ==> %s at %d\n',...
        err.stack(j).name,err.stack(j).line);
end

end

