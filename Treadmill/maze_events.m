function [eventcodes] = maze_events()
    % These event codes are hard-wired inputs from the button-box.
    eventcodes.TL = 3;      % Top Left button
    eventcodes.TR = 4;      % Top Right button
    eventcodes.ML = 5;      % Middle Left button
    eventcodes.MR = 6;      % Middle Right button
    eventcodes.BL = 7;      % Bottom Left button
    eventcodes.BR = 8;      % Bottom Right button
 
    
    % These event codes are hard-wired from other devices.
    eventcodes.RVALVE = 9;  % The right valve opening
    eventcodes.LVALVE = 10; % The left valve opening
    eventcodes.DACLD  = 11; % DAC updated to new value
    eventcodes.SPEED1 = 12; % First speed sensor
    eventcodes.SPEED2 = 13; % Second speed sensor
    eventcodes.MVALVE = 14; % The middle valve opening
    eventcodes.EVALVE = 15; % The extra valve opening

    
    % These event codes just set a convention for recording eventcodes.
    eventcodes.RL  = 101;	% Entered the right reward area using a valid path.
    eventcodes.LL  = 102;	% Entered the left reward area using a valid path.
    eventcodes.RW  = 103;	% Entered the right reward area using an invalid path.
    eventcodes.LW  = 104;	% Entered the left reward area using an invalid path.
    eventcodes.RV  = 105;    % Button press used to open right valve.
    eventcodes.LV  = 106;    % Button press used to open left valve.
    eventcodes.TM  = 107;	% Entered the treadmill from the correct direction.
    eventcodes.TMS = 108;   % Button press used to stop the treadmill.
    eventcodes.MV  = 109;   % Middle valve opened before or after treadmill run.
    eventcodes.INCSPEED =110;
    eventcodes.DECSPEED =111;
    eventcodes.BZT = 112;   %buzzer when jump off treadmill
    eventcodes.BZC = 113;   %buzzer when makes choice then switches towards other arm. 
    % MAP System (hard coded)
    eventcodes.CINEPLEX = 257;
    eventcodes.START = 258;
    eventcodes.STOP = 259;
end
