%
% This initialize screen and display a gray display
%

%% set display
Screen('Preference', 'SkipSyncTests', 0);
scr.colDept = 32; % color depth
scr.allScreens = Screen('Screens');         % If there are multiple displays guess that one without the menu bar is the
if IsOSX || IsLinux
    scr.expScreen  = max(scr.allScreens);       % best choice.  Dislay 0 has the menu bar
end
if IsWindows
    scr.expScreen = 1; % config @ CENIR-ICM human MRI
end
Screen('Resolution', scr.expScreen, ScreenRes(1), ScreenRes(2)); % set resolution
[scr.main,scr.rect] = Screen('OpenWindow',scr.expScreen, [0.5 0.5 0.5],[],scr.colDept,2,0,4); % open a window
% [scr.main,scr.rect] = Screen('OpenWindow',scr.expScreen, [0.5 0.5 0.5],[],scr.colDept,2,0,0); % open a window
% Screen('BlendFunction', scr.main, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA'); % another to do anti-aliasing, but not with the "multisample"

% get information about  screen
[scr.xres, scr.yres]    = Screen('WindowSize', scr.main); % heigth and width of screen [pix]
[scr.centerX, scr.centerY] = WindowCenter(scr.main);      % determine th main window's center
scr.fd = Screen('GetFlipInterval',scr.main);              % frame duration [s]

WaitSecs(2); % make sure the monitor has time to resync after change in display mode
% HideCursor;

% visual settings
visual.ppd = va2pix(1,scr);   % pixel per degree
visual.black = BlackIndex(scr.main);
visual.white = WhiteIndex(scr.main);
visual.bgColor = round((visual.black + visual.white) / 2);     % background color
visual.fgColor = visual.black;

priorityLevel=MaxPriority(scr.main); % set priority of window activities to maximum
Priority(priorityLevel);

Screen('FillRect', scr.main, visual.bgColor);
Screen('Flip', scr.main);
