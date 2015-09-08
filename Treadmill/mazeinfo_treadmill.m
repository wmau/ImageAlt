function [buttonmap, boxes] = mazeinfo_treadmill()
    eventcodes = maze_events();
    
    buttonmap = [eventcodes.LV, eventcodes.LV, 0;...
                 eventcodes.RV, eventcodes.RV, 0;...
                 eventcodes.LL, eventcodes.LL, 8;...
                 eventcodes.RL, eventcodes.RL, 5;...
                 eventcodes.TM, eventcodes.TM, 2;...
                 eventcodes.TMS, eventcodes.TMS, 0];

    % Stem Start:
    % x: 700
    % y: 195
    boxes{1}.str = 'stem start';
    boxes{1}.xv = [780, 1000, 1000, 780, 780];
    boxes{1}.yv = [500, 500, 280, 280, 500];
    boxes{1}.neighbors = [0 2 6 9];
    boxes{1}.goal = false;
    boxes{1}.paths = {};
    boxes{1}.events = [0 0];
    
    % Treadmill
    % x: 700
    % y: 385
    boxes{2}.str = 'treadmill';
    boxes{2}.xv = [510, 620, 620, 510, 510];
    boxes{2}.yv = [490, 490, 280, 280, 490];
    boxes{2}.neighbors = [0 1 3];
    boxes{2}.goal = true;
    boxes{2}.paths = {[1 2]};
    boxes{2}.events = [eventcodes.TM 0];
    
    
    % Choice:
    % x: 700
    % y: 645
    boxes{3}.str = 'choice';
    boxes{3}.xv = [60, 390, 390, 60, 60];
    boxes{3}.yv = [430, 430, 330, 330, 430];
    boxes{3}.neighbors = [0 2 4 7];
    boxes{3}.goal = true;
    boxes{3}.paths = {[1 2 3]};
    boxes{3}.events = [eventcodes.BZT 0];

    % Right Choice
    % x: 510
    % y: 640
    boxes{4}.str = 'right choice';
    boxes{4}.xv = [60, 200, 200, 60, 60];
    boxes{4}.yv = [720, 720,  580,  580, 720];
    boxes{4}.neighbors = [0 3 5];
    boxes{4}.goal = false;
    boxes{4}.paths = {[7 3 4]};
    boxes{4}.events = [eventcodes.BZC 0];

    % Right Reward
    % x: 505
    % y: 195
    boxes{5}.str = 'right reward';
    boxes{5}.xv = [350, 500, 500, 350, 350];
    boxes{5}.yv = [760, 760, 620, 620, 760];
    boxes{5}.neighbors = [0 4 6];
    boxes{5}.goal = true;
    boxes{5}.paths = {[5 6 1 2 3 4 5],...
                      [8 9 1 2 3 4 5],...
                      [0 0 1 2 3 4 5]};
    boxes{5}.events = [eventcodes.RL eventcodes.RW];

    % Right Return
    % x: 580
    % y: 125
    boxes{6}.str = 'right return';

    boxes{6}.xv = [780, 1000, 1000, 780, 780];
    boxes{6}.yv = [760, 760, 620, 620, 760];
    boxes{6}.neighbors = [0 1 5];
    boxes{6}.goal = false;
    boxes{6}.paths = {};
    boxes{6}.events = [0 0];
    
    % Left Choice
    % x: 870
    % y: 625
    boxes{7}.str = 'left choice';
    boxes{7}.xv = [60, 200, 200, 60, 60];
    boxes{7}.yv = [40, 40, 180, 180, 40];
    boxes{7}.neighbors = [0 3 8];
    boxes{7}.goal = false;
    boxes{7}.paths = {[4 3 7]};
    boxes{7}.events = [eventcodes.BZC 0];

    % Left Reward
    % x: 875
    % y: 210
    boxes{8}.str = 'left reward';
    boxes{8}.xv = [350, 500, 500, 350, 350];
    boxes{8}.yv = [5, 5, 145, 145, 5];
    boxes{8}.neighbors = [0 7 9];
    boxes{8}.goal = true;
    boxes{8}.paths = {[8 9 1 2 3 7 8],...
                      [5 6 1 2 3 7 8],...
                      [0 0 1 2 3 7 8]};
    boxes{8}.events = [eventcodes.LL eventcodes.LW];

    % Left Return
    % x: 800
    % y: 140
    boxes{9}.str = 'left return';
    boxes{9}.xv = [780, 1000, 1000, 780, 780];
    boxes{9}.yv = [5, 5, 145, 145, 5];
    boxes{9}.neighbors = [0 1 8];
    boxes{9}.goal = false;
    boxes{9}.paths = {};
    boxes{9}.events = [0 0];
end
