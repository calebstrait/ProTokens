function ProTokens(initial) %CES 9/3/2013
global visual; global step; global vars; global color; global onset; global eye;

%***** Initialize variables
setVariables
visual.targX = 512;
visual.targY = 384;
visual.Wxmin = visual.targX - (visual.HorW / 2);                        %Fix dot window
visual.Wxmax = visual.targX + (visual.HorW / 2);
visual.Wymin = visual.targY - (visual.HorW / 2);
visual.Wymax = visual.targY + (visual.HorW / 2);
visual.Dxmin = visual.targX - visual.radius;                            %Fix dot radius
visual.Dxmax = visual.targX + visual.radius;
visual.Dymin = visual.targY - visual.radius;
visual.Dymax = visual.targY + visual.radius;
visual.Lxmin = (visual.targX - (visual.wdth / 2)) - visual.displa;      %Option rectangle
visual.Lxmax = (visual.targX + (visual.wdth / 2)) - visual.displa;
visual.Rxmin = (visual.targX - (visual.wdth / 2)) + visual.displa;
visual.Rxmax = (visual.targX + (visual.wdth / 2)) + visual.displa;
visual.Fymax = visual.targY + (visual.hght / 2);
visual.Fymin = visual.Fymax - visual.hght;
step = 1;
onset = true;
[vars.trial,vars.timeReward,vars.possible,vars.leftCount,eye.fixating,...
    vars.left_gamble,vars.rght_gamble] = deal(0);
vars.startTime = GetSecs;
%**********
               
%***** Set up
[vars.filename, foldername] = createFile('/Data/ProTokens', 'PRO', initial); %Create data file

vars.daysTrials = countDayTrials('/Data/ProTokens', foldername); %Count day's cumulative trials

visual.window = setupEyelink; %Connect to Eyelink

Screen('FillRect', visual.window, color.backgrd); %Set screen color
Screen(visual.window, 'flip');
%**********

%***** Ask to start
go = 0;
disp('Right Arrow to start');
gokey=KbName('RightArrow');
nokey=KbName('ESCAPE');
while(go == 0)
    [keyIsDown,~,keyCode] = KbCheck;
    if keyCode(gokey)
        go = 1;
    elseif keyCode(nokey)
        go = -1;
    end
end
while keyIsDown
    [keyIsDown,~,~] = KbCheck;
end
home
%**********

%***** Run trials
while(go == 1)
   
   switch step,
       case 1, if onset, step_ITI;end
           
       case 2, step_fixate1;
               
       case 3, if onset, step_op1on;end
           
       case 4, if onset, step_op1off;end
   
       case 5, if onset, step_op2on;end
           
       case 6, if onset, step_op2off;end
           
       case 7, step_fixate2;
   
       case 8, step_choice;
           
       case 9, if onset, step_delay;end
   
       case 10, if onset, step_feedback;end
           
       case 11, if onset, step_prizedelay;end
           
       case 12, if onset, step_prize;end
           
       case 13, if onset, paused;end
   end
       
   if ~onset, progress;end
   
   go = keyCapture;
   
end
%**********

sca
end

function setVariables
global visual; global color; global eye; global vars;

eye.side        = 2;                %Tracked eye (L = 1, R = 2)

vars.reward     = [.06 .28];        %Reward sizes
vars.values     = [-2 -1 0 1 2 3 1];%Value of each color in tokens
vars.gambles    = [.1 .3 .5 .7 .9]; %Gambles
vars.tokens     = 0;                %Starting tokens
vars.tokenThrsh = 6;                %Token threshold for reward
vars.chanceSafe = .2;               %Chance of safe option

vars.op1on      = .6;               %Time: option 1 on
vars.op1off     = .15;              %Time: option 1 off
vars.op2on      = .6;               %Time: option 2 on
vars.op2off     = .15;              %Time: option 2 off
vars.minFixDot  = .1;               %Time: fixation min for fixation dot
vars.minFixCho  = .2;               %Time: fixation min fir choice
vars.delay      = .75;              %Time: delay
vars.feedback   = .3;               %Time: feedback
vars.prizedelay = .5;               %Time: delay before prize
vars.prize      = .3;               %Time: prize presentation
vars.ITI        = 1;                %Time: intertrial interval

visual.wiggle   = 60;               %Wiggle room around choice
visual.displa   = 275;              %Rectangles' horizontal displacement from center
visual.wdth     = 80;               %Width of rects
visual.hght     = 300;              %Height of rects
visual.fixcue   = 5;                %Thickness of rect fixation cue
visual.radius   = 10;               %Radius of fixation dot
visual.HorW     = 200;              %Height and width of fixation window
visual.tokenRad = 40;               %Token dot radius
visual.ringWid  = 7;                %Thickness of empty token ring
visual.tokenDsp = 250;              %Token dot vertical displacement from center
visual.numStrpe = 10;               %Number of stripes per loss rect
visual.prizeCueH= 120;              %Prize cue bar height

color.backgrd   = [50   50   50];   %Background color
color.fixcue    = [255  255  255];  %Gamble rect fixation cue color
color.chosen    = [0    255  255];  %Chosen option outline color
color.fixdot    = [255  255  255];  %Fixation dot color
color.token     = [0    255  255];  %Token color
color.prizeCue  = [0    255  255];  %Prize cue bar color
color.stripe    = [80   80   80;    %Darker gray    %Stripe colors
                   215  215  215];  %Off-white
color.rect      = [120  120  120;   %Dark gray      %Option color
                   255  255  255;   %White
                   255  0    0;     %Red
                   0    0    255;   %Blue
                   0    255  0;     %Green
                   255  0    255;   %Purple
                   180  180  180];  %Light gray
end

function step_ITI
global data; global vars; global visual; global onset; global color;
vars.trialStart = GetSecs;

%***** Set screen
o = [(visual.targX - visual.tokenRad) (visual.targY + visual.tokenDsp - visual.tokenRad) (visual.targX + visual.tokenRad) (visual.targY + visual.tokenDsp + visual.tokenRad)];
e = [(o(1) + (1.5 * visual.tokenRad) - (1.5 * vars.tokenThrsh * visual.tokenRad)) o(2) (o(3) + (1.5 * visual.tokenRad) - (1.5 * vars.tokenThrsh * visual.tokenRad)) o(4)];
for i = 0:vars.tokenThrsh-1
    Screen('FillOval', visual.window, color.token, [e(1)+(3*i*visual.tokenRad) e(2) e(3)+(3*i*visual.tokenRad) e(4)]);
    if vars.tokens <= i, Screen('FillOval', visual.window, color.backgrd, [e(1)+(3*i*visual.tokenRad)+visual.ringWid e(2)+visual.ringWid e(3)+(3*i*visual.tokenRad)-visual.ringWid e(4)-visual.ringWid]);end
end
Screen(visual.window, 'flip');
%**********

%***** Save variables
if vars.trial > 0
    if vars.canceled, vars.choice = 'canceled';end
    data{vars.trial} = vars;
    eval(['save ' vars.filename ' data']);
end
%**********

%***** Print to screen
if vars.trial > 0
    disp(' ');
    home;
    if(vars.trial ~= (vars.trial + vars.daysTrials))
        disp(['Trial #' num2str(vars.trial) '/' num2str(vars.trial + vars.daysTrials)]);
    else
        disp(['Trial #' num2str(vars.trial)]);
    end
    if ~vars.canceled
        vars.possible = vars.possible + 1;
        if strcmp(vars.choice, 'left'), vars.leftCount = vars.leftCount + 1;end
    end
    if vars.possible > 0, fprintf('Chose Left: %3.2f%%\n', (100*vars.leftCount/vars.possible));end
    fprintf('Current tokens: %i\n', vars.tokens);
    elapsed = GetSecs - vars.startTime;
    fprintf('Elapsed time: %.0fh %.0fm\n', floor(elapsed/3600), floor((elapsed-(floor(elapsed/3600)*3600))/60));
end
%**********

%***** Set up next trial
vars.canceled = false;
vars.trial = vars.trial + 1;
[vars.leftTop_type,vars.rghtTop_type,vars.leftBot_type,vars.rghtBot_type] = deal(0);
if rand <= vars.chanceSafe
    if rand <= .5
        while vars.rghtTop_type == vars.rghtBot_type ...
                || (vars.rghtTop_type <= 4 && vars.rghtBot_type <= 4) ...
                || (vars.rghtTop_type > 4 && vars.rghtBot_type > 4)
            vars.leftTop_type = 7;
            vars.leftBot_type = 7;
            vars.left_gamble = 1;
            vars.rghtTop_type = randsample(1:6, 1);
            vars.rghtBot_type = randsample(1:6, 1);
            vars.rght_gamble = randsample(vars.gambles, 1);
        end
    else
        while vars.leftTop_type == vars.leftBot_type ...
                || (vars.leftTop_type <= 4 && vars.leftBot_type <= 4) ...
                || (vars.leftTop_type > 4 && vars.leftBot_type > 4)
            vars.rghtTop_type = 7;
            vars.rghtBot_type = 7;
            vars.rght_gamble = 1;
            vars.leftTop_type = randsample(1:6, 1);
            vars.leftBot_type = randsample(1:6, 1);
            vars.left_gamble = randsample(vars.gambles, 1);
        end
    end
else
    while vars.leftTop_type == vars.leftBot_type || vars.rghtTop_type == vars.rghtBot_type ...
            || (vars.leftTop_type <= 2 && vars.leftBot_type <= 2) ...
            || (vars.rghtTop_type <= 2 && vars.rghtBot_type <= 2) ...
            || (vars.leftTop_type > 2 && vars.leftBot_type > 2 && vars.rghtTop_type > 2 && vars.rghtBot_type > 2) ...
            || (vars.leftTop_type < vars.rghtTop_type && vars.leftTop_type < vars.rghtBot_type && vars.leftBot_type < vars.rghtTop_type && vars.leftBot_type < vars.rghtBot_type) ...
            || (vars.rghtTop_type < vars.leftTop_type && vars.rghtTop_type < vars.leftBot_type && vars.rghtBot_type < vars.leftTop_type && vars.rghtBot_type < vars.leftBot_type)
        vars.leftTop_type = randsample(1:6, 1);
        vars.leftBot_type = randsample(1:6, 1);
        vars.rghtTop_type = randsample(1:6, 1);
        vars.rghtBot_type = randsample(1:6, 1);
    end
    vars.left_gamble = randsample(vars.gambles, 1);
    vars.rght_gamble = randsample(vars.gambles, 1);
end
vars.orderOfLeft = randsample([1 2], 1);
%**********

onset = false;
end

function step_fixate1
global color; global step; global onset; global eye; global visual; global vars;

%***** Set screen
if onset
    Screen('FillOval', visual.window, color.fixdot, [visual.Dxmin visual.Dymin visual.Dxmax visual.Dymax]);
    o = [(visual.targX - visual.tokenRad) (visual.targY + visual.tokenDsp - visual.tokenRad) (visual.targX + visual.tokenRad) (visual.targY + visual.tokenDsp + visual.tokenRad)];
    e = [(o(1) + (1.5 * visual.tokenRad) - (1.5 * vars.tokenThrsh * visual.tokenRad)) o(2) (o(3) + (1.5 * visual.tokenRad) - (1.5 * vars.tokenThrsh * visual.tokenRad)) o(4)];
    for i = 0:vars.tokenThrsh-1
        Screen('FillOval', visual.window, color.token, [e(1)+(3*i*visual.tokenRad) e(2) e(3)+(3*i*visual.tokenRad) e(4)]);
        if vars.tokens <= i, Screen('FillOval', visual.window, color.backgrd, [e(1)+(3*i*visual.tokenRad)+visual.ringWid e(2)+visual.ringWid e(3)+(3*i*visual.tokenRad)-visual.ringWid e(4)-visual.ringWid]);end
    end
    Screen(visual.window, 'flip');
    onset = false;
end
%**********

%***** Check eye position
e = Eyelink('newestfloatsample');
if visual.Wxmin < e.gx(eye.side) && visual.Wxmax > e.gx(eye.side) && visual.Wymin < e.gy(eye.side) && visual.Wymax > e.gy(eye.side)
    if eye.fixating ~= 1
        eye.fixtime = GetSecs;
        eye.fixating = 1;
    elseif GetSecs >= (vars.minFixDot + eye.fixtime)
        step = 3;
        vars.choiceStart = GetSecs;
        onset = true;
        eye.fixating = 0;
    end
elseif eye.fixating == 1
    eye.fixating = 0;
end
%**********

end

function step_op1on
global color; global visual; global vars; global onset;

%***** Set screen
if vars.orderOfLeft == 1
    Screen('FillRect', visual.window, color.rect(vars.leftBot_type,:), [visual.Lxmin visual.Fymin visual.Lxmax visual.Fymax]);
    if vars.leftBot_type <= 2
        for i = 1:2:visual.numStrpe
            min = visual.Lxmin + (i * (visual.wdth / visual.numStrpe));
            max = visual.Lxmin + ((i+1) * (visual.wdth / visual.numStrpe));
            Screen('FillRect', visual.window, color.stripe(vars.leftBot_type,:), [min visual.Fymin max visual.Fymax]);
        end
    end
    Screen('FillRect', visual.window, color.rect(vars.leftTop_type,:), [visual.Lxmin visual.Fymin visual.Lxmax (visual.Fymin + (vars.left_gamble * visual.hght))]);
    if vars.leftTop_type <= 2
        for i = 1:2:visual.numStrpe
            min = visual.Lxmin + (i * (visual.wdth / visual.numStrpe));
            max = visual.Lxmin + ((i+1) * (visual.wdth / visual.numStrpe));
            Screen('FillRect', visual.window, color.stripe(vars.leftTop_type,:), [min visual.Fymin max (visual.Fymin + (vars.left_gamble * visual.hght))]);
        end
    end
else
    Screen('FillRect', visual.window, color.rect(vars.rghtBot_type,:), [visual.Rxmin visual.Fymin visual.Rxmax visual.Fymax]);
    if vars.rghtBot_type <= 2
        for i = 1:2:visual.numStrpe
            min = visual.Rxmin + (i * (visual.wdth / visual.numStrpe));
            max = visual.Rxmin + ((i+1) * (visual.wdth / visual.numStrpe));
            Screen('FillRect', visual.window, color.stripe(vars.rghtBot_type,:), [min visual.Fymin max visual.Fymax]);
        end
    end
    Screen('FillRect', visual.window, color.rect(vars.rghtTop_type,:), [visual.Rxmin visual.Fymin visual.Rxmax (visual.Fymin + (vars.rght_gamble * visual.hght))]);
    if vars.rghtTop_type <= 2
        for i = 1:2:visual.numStrpe
            min = visual.Rxmin + (i * (visual.wdth / visual.numStrpe));
            max = visual.Rxmin + ((i+1) * (visual.wdth / visual.numStrpe));
            Screen('FillRect', visual.window, color.stripe(vars.rghtTop_type,:), [min visual.Fymin max (visual.Fymin + (vars.rght_gamble * visual.hght))]);
        end
    end
end
o = [(visual.targX - visual.tokenRad) (visual.targY + visual.tokenDsp - visual.tokenRad) (visual.targX + visual.tokenRad) (visual.targY + visual.tokenDsp + visual.tokenRad)];
e = [(o(1) + (1.5 * visual.tokenRad) - (1.5 * vars.tokenThrsh * visual.tokenRad)) o(2) (o(3) + (1.5 * visual.tokenRad) - (1.5 * vars.tokenThrsh * visual.tokenRad)) o(4)];
for i = 0:vars.tokenThrsh-1
    Screen('FillOval', visual.window, color.token, [e(1)+(3*i*visual.tokenRad) e(2) e(3)+(3*i*visual.tokenRad) e(4)]);
    if vars.tokens <= i, Screen('FillOval', visual.window, color.backgrd, [e(1)+(3*i*visual.tokenRad)+visual.ringWid e(2)+visual.ringWid e(3)+(3*i*visual.tokenRad)-visual.ringWid e(4)-visual.ringWid]);end
end
Screen(visual.window, 'flip');
%**********

%***** Save time
vars.op1onTS = GetSecs;
%**********

onset = false;
end

function step_op1off
global onset; global visual; global vars; global color;

%***** Set screen
o = [(visual.targX - visual.tokenRad) (visual.targY + visual.tokenDsp - visual.tokenRad) (visual.targX + visual.tokenRad) (visual.targY + visual.tokenDsp + visual.tokenRad)];
e = [(o(1) + (1.5 * visual.tokenRad) - (1.5 * vars.tokenThrsh * visual.tokenRad)) o(2) (o(3) + (1.5 * visual.tokenRad) - (1.5 * vars.tokenThrsh * visual.tokenRad)) o(4)];
for i = 0:vars.tokenThrsh-1
    Screen('FillOval', visual.window, color.token, [e(1)+(3*i*visual.tokenRad) e(2) e(3)+(3*i*visual.tokenRad) e(4)]);
    if vars.tokens <= i, Screen('FillOval', visual.window, color.backgrd, [e(1)+(3*i*visual.tokenRad)+visual.ringWid e(2)+visual.ringWid e(3)+(3*i*visual.tokenRad)-visual.ringWid e(4)-visual.ringWid]);end
end
Screen(visual.window, 'flip');
%**********

onset = false;
end

function step_op2on
global color; global visual; global vars; global onset;

%***** Set screen
if vars.orderOfLeft == 2
    Screen('FillRect', visual.window, color.rect(vars.leftBot_type,:), [visual.Lxmin visual.Fymin visual.Lxmax visual.Fymax]);
    if vars.leftBot_type <= 2
        for i = 1:2:visual.numStrpe
            min = visual.Lxmin + (i * (visual.wdth / visual.numStrpe));
            max = visual.Lxmin + ((i+1) * (visual.wdth / visual.numStrpe));
            Screen('FillRect', visual.window, color.stripe(vars.leftBot_type,:), [min visual.Fymin max visual.Fymax]);
        end
    end
    Screen('FillRect', visual.window, color.rect(vars.leftTop_type,:), [visual.Lxmin visual.Fymin visual.Lxmax (visual.Fymin + (vars.left_gamble * visual.hght))]);
    if vars.leftTop_type <= 2
        for i = 1:2:visual.numStrpe
            min = visual.Lxmin + (i * (visual.wdth / visual.numStrpe));
            max = visual.Lxmin + ((i+1) * (visual.wdth / visual.numStrpe));
            Screen('FillRect', visual.window, color.stripe(vars.leftTop_type,:), [min visual.Fymin max (visual.Fymin + (vars.left_gamble * visual.hght))]);
        end
    end
else
    Screen('FillRect', visual.window, color.rect(vars.rghtBot_type,:), [visual.Rxmin visual.Fymin visual.Rxmax visual.Fymax]);
    if vars.rghtBot_type <= 2
        for i = 1:2:visual.numStrpe
            min = visual.Rxmin + (i * (visual.wdth / visual.numStrpe));
            max = visual.Rxmin + ((i+1) * (visual.wdth / visual.numStrpe));
            Screen('FillRect', visual.window, color.stripe(vars.rghtBot_type,:), [min visual.Fymin max visual.Fymax]);
        end
    end
    Screen('FillRect', visual.window, color.rect(vars.rghtTop_type,:), [visual.Rxmin visual.Fymin visual.Rxmax (visual.Fymin + (vars.rght_gamble * visual.hght))]);
    if vars.rghtTop_type <= 2
        for i = 1:2:visual.numStrpe
            min = visual.Rxmin + (i * (visual.wdth / visual.numStrpe));
            max = visual.Rxmin + ((i+1) * (visual.wdth / visual.numStrpe));
            Screen('FillRect', visual.window, color.stripe(vars.rghtTop_type,:), [min visual.Fymin max (visual.Fymin + (vars.rght_gamble * visual.hght))]);
        end
    end
end
o = [(visual.targX - visual.tokenRad) (visual.targY + visual.tokenDsp - visual.tokenRad) (visual.targX + visual.tokenRad) (visual.targY + visual.tokenDsp + visual.tokenRad)];
e = [(o(1) + (1.5 * visual.tokenRad) - (1.5 * vars.tokenThrsh * visual.tokenRad)) o(2) (o(3) + (1.5 * visual.tokenRad) - (1.5 * vars.tokenThrsh * visual.tokenRad)) o(4)];
for i = 0:vars.tokenThrsh-1
    Screen('FillOval', visual.window, color.token, [e(1)+(3*i*visual.tokenRad) e(2) e(3)+(3*i*visual.tokenRad) e(4)]);
    if vars.tokens <= i, Screen('FillOval', visual.window, color.backgrd, [e(1)+(3*i*visual.tokenRad)+visual.ringWid e(2)+visual.ringWid e(3)+(3*i*visual.tokenRad)-visual.ringWid e(4)-visual.ringWid]);end
end
Screen(visual.window, 'flip');
%**********

onset = false;
end

function step_op2off
global onset; global visual; global vars; global color;

%***** Set screen
o = [(visual.targX - visual.tokenRad) (visual.targY + visual.tokenDsp - visual.tokenRad) (visual.targX + visual.tokenRad) (visual.targY + visual.tokenDsp + visual.tokenRad)];
e = [(o(1) + (1.5 * visual.tokenRad) - (1.5 * vars.tokenThrsh * visual.tokenRad)) o(2) (o(3) + (1.5 * visual.tokenRad) - (1.5 * vars.tokenThrsh * visual.tokenRad)) o(4)];
for i = 0:vars.tokenThrsh-1
    Screen('FillOval', visual.window, color.token, [e(1)+(3*i*visual.tokenRad) e(2) e(3)+(3*i*visual.tokenRad) e(4)]);
    if vars.tokens <= i, Screen('FillOval', visual.window, color.backgrd, [e(1)+(3*i*visual.tokenRad)+visual.ringWid e(2)+visual.ringWid e(3)+(3*i*visual.tokenRad)-visual.ringWid e(4)-visual.ringWid]);end
end
Screen(visual.window, 'flip');
%**********

onset = false;
end

function step_fixate2
global color; global step; global onset; global eye; global visual; global vars;

%***** Set screen
if onset
    Screen('FillOval', visual.window, color.fixdot, [visual.Dxmin visual.Dymin visual.Dxmax visual.Dymax]);
    o = [(visual.targX - visual.tokenRad) (visual.targY + visual.tokenDsp - visual.tokenRad) (visual.targX + visual.tokenRad) (visual.targY + visual.tokenDsp + visual.tokenRad)];
    e = [(o(1) + (1.5 * visual.tokenRad) - (1.5 * vars.tokenThrsh * visual.tokenRad)) o(2) (o(3) + (1.5 * visual.tokenRad) - (1.5 * vars.tokenThrsh * visual.tokenRad)) o(4)];
    for i = 0:vars.tokenThrsh-1
        Screen('FillOval', visual.window, color.token, [e(1)+(3*i*visual.tokenRad) e(2) e(3)+(3*i*visual.tokenRad) e(4)]);
        if vars.tokens <= i, Screen('FillOval', visual.window, color.backgrd, [e(1)+(3*i*visual.tokenRad)+visual.ringWid e(2)+visual.ringWid e(3)+(3*i*visual.tokenRad)-visual.ringWid e(4)-visual.ringWid]);end
    end
    Screen(visual.window, 'flip');
    onset = false;
end
%**********

%***** Check eye position
e = Eyelink('newestfloatsample');
if visual.Wxmin < e.gx(eye.side) && visual.Wxmax > e.gx(eye.side) && visual.Wymin < e.gy(eye.side) && visual.Wymax > e.gy(eye.side)
    if eye.fixating ~= 1
        eye.fixtime = GetSecs;
        eye.fixating = 1;
    elseif GetSecs >= (vars.minFixDot + eye.fixtime)
        step = 8;
        vars.choiceStart = GetSecs;
        onset = true;
        eye.fixating = 0;
    end
elseif eye.fixating == 1
    eye.fixating = 0;
end
%**********

end

function step_choice
global vars; global color; global step; global onset; global eye; global visual;

%***** Set screen
if onset
    if eye.fixating == 1, Screen('FillRect', visual.window, color.fixcue, [(visual.Lxmin-visual.fixcue) (visual.Fymin-visual.fixcue) (visual.Lxmax+visual.fixcue) (visual.Fymax+visual.fixcue)]);end
    Screen('FillRect', visual.window, color.rect(vars.leftBot_type,:), [visual.Lxmin visual.Fymin visual.Lxmax visual.Fymax]);
    if vars.leftBot_type <= 2
        for i = 1:2:visual.numStrpe
            min = visual.Lxmin + (i * (visual.wdth / visual.numStrpe));
            max = visual.Lxmin + ((i+1) * (visual.wdth / visual.numStrpe));
            Screen('FillRect', visual.window, color.stripe(vars.leftBot_type,:), [min visual.Fymin max visual.Fymax]);
        end
    end
    Screen('FillRect', visual.window, color.rect(vars.leftTop_type,:), [visual.Lxmin visual.Fymin visual.Lxmax (visual.Fymin + (vars.left_gamble * visual.hght))]);
    if vars.leftTop_type <= 2
        for i = 1:2:visual.numStrpe
            min = visual.Lxmin + (i * (visual.wdth / visual.numStrpe));
            max = visual.Lxmin + ((i+1) * (visual.wdth / visual.numStrpe));
            Screen('FillRect', visual.window, color.stripe(vars.leftTop_type,:), [min visual.Fymin max (visual.Fymin + (vars.left_gamble * visual.hght))]);
        end
    end
    if eye.fixating == 2, Screen('FillRect', visual.window, color.fixcue, [(visual.Rxmin-visual.fixcue) (visual.Fymin-visual.fixcue) (visual.Rxmax+visual.fixcue) (visual.Fymax+visual.fixcue)]);end
    Screen('FillRect', visual.window, color.rect(vars.rghtBot_type,:), [visual.Rxmin visual.Fymin visual.Rxmax visual.Fymax]);
    if vars.rghtBot_type <= 2
        for i = 1:2:visual.numStrpe
            min = visual.Rxmin + (i * (visual.wdth / visual.numStrpe));
            max = visual.Rxmin + ((i+1) * (visual.wdth / visual.numStrpe));
            Screen('FillRect', visual.window, color.stripe(vars.rghtBot_type,:), [min visual.Fymin max visual.Fymax]);
        end
    end
    Screen('FillRect', visual.window, color.rect(vars.rghtTop_type,:), [visual.Rxmin visual.Fymin visual.Rxmax (visual.Fymin + (vars.rght_gamble * visual.hght))]);
    if vars.rghtTop_type <= 2
        for i = 1:2:visual.numStrpe
            min = visual.Rxmin + (i * (visual.wdth / visual.numStrpe));
            max = visual.Rxmin + ((i+1) * (visual.wdth / visual.numStrpe));
            Screen('FillRect', visual.window, color.stripe(vars.rghtTop_type,:), [min visual.Fymin max (visual.Fymin + (vars.rght_gamble * visual.hght))]);
        end
    end
    o = [(visual.targX - visual.tokenRad) (visual.targY + visual.tokenDsp - visual.tokenRad) (visual.targX + visual.tokenRad) (visual.targY + visual.tokenDsp + visual.tokenRad)];
    e = [(o(1) + (1.5 * visual.tokenRad) - (1.5 * vars.tokenThrsh * visual.tokenRad)) o(2) (o(3) + (1.5 * visual.tokenRad) - (1.5 * vars.tokenThrsh * visual.tokenRad)) o(4)];
    for i = 0:vars.tokenThrsh-1
        Screen('FillOval', visual.window, color.token, [e(1)+(3*i*visual.tokenRad) e(2) e(3)+(3*i*visual.tokenRad) e(4)]);
        if vars.tokens <= i, Screen('FillOval', visual.window, color.backgrd, [e(1)+(3*i*visual.tokenRad)+visual.ringWid e(2)+visual.ringWid e(3)+(3*i*visual.tokenRad)-visual.ringWid e(4)-visual.ringWid]);end
    end
    Screen(visual.window, 'flip');
    onset = false;
end
%**********

%***** Check eye position
e = Eyelink('newestfloatsample');
if (visual.Lxmin-visual.wiggle) < e.gx(eye.side) && (visual.Lxmax+visual.wiggle) > e.gx(eye.side) && visual.Fymin < e.gy(eye.side) && visual.Fymax > e.gy(eye.side)
    if eye.fixating ~= 1
        eye.fixtime = GetSecs;
        eye.fixating = 1;
        onset = true;
    elseif GetSecs >= (vars.minFixCho + eye.fixtime)
        vars.choice = 'left';
        step = 9;
        vars.timeChoice = GetSecs;
        onset = true;
        eye.fixating = 0;
    end
elseif eye.fixating == 1
    eye.fixating = 0;
    onset = true;
end
if (visual.Rxmin-visual.wiggle) < e.gx(eye.side) && (visual.Rxmax+visual.wiggle) > e.gx(eye.side) && visual.Fymin < e.gy(eye.side) && visual.Fymax > e.gy(eye.side)
    if eye.fixating ~= 2
        eye.fixtime = GetSecs;
        eye.fixating = 2;
        onset = true;
    elseif GetSecs >= (vars.minFixCho + eye.fixtime)
        vars.choice = 'right';
        step = 9;
        vars.timeChoice = GetSecs;
        onset = true;
        eye.fixating = 0;
    end
elseif eye.fixating == 2
    eye.fixating = 0;
    onset = true;
end
%**********

end

function step_delay
global color; global visual; global vars; global onset;

%***** Set screen
if strcmp(vars.choice, 'left')
    Screen('FillRect', visual.window, color.chosen, [(visual.Lxmin-visual.fixcue) (visual.Fymin-visual.fixcue) (visual.Lxmax+visual.fixcue) (visual.Fymax+visual.fixcue)]);
    Screen('FillRect', visual.window, color.rect(vars.leftBot_type,:), [visual.Lxmin visual.Fymin visual.Lxmax visual.Fymax]);
    if vars.leftBot_type <= 2
        for i = 1:2:visual.numStrpe
            min = visual.Lxmin + (i * (visual.wdth / visual.numStrpe));
            max = visual.Lxmin + ((i+1) * (visual.wdth / visual.numStrpe));
            Screen('FillRect', visual.window, color.stripe(vars.leftBot_type,:), [min visual.Fymin max visual.Fymax]);
        end
    end
    Screen('FillRect', visual.window, color.rect(vars.leftTop_type,:), [visual.Lxmin visual.Fymin visual.Lxmax (visual.Fymin + (vars.left_gamble * visual.hght))]);
    if vars.leftTop_type <= 2
        for i = 1:2:visual.numStrpe
            min = visual.Lxmin + (i * (visual.wdth / visual.numStrpe));
            max = visual.Lxmin + ((i+1) * (visual.wdth / visual.numStrpe));
            Screen('FillRect', visual.window, color.stripe(vars.leftTop_type,:), [min visual.Fymin max (visual.Fymin + (vars.left_gamble * visual.hght))]);
        end
    end
else
    Screen('FillRect', visual.window, color.chosen, [(visual.Rxmin-visual.fixcue) (visual.Fymin-visual.fixcue) (visual.Rxmax+visual.fixcue) (visual.Fymax+visual.fixcue)]);
    Screen('FillRect', visual.window, color.rect(vars.rghtBot_type,:), [visual.Rxmin visual.Fymin visual.Rxmax visual.Fymax]);
    if vars.rghtBot_type <= 2
        for i = 1:2:visual.numStrpe
            min = visual.Rxmin + (i * (visual.wdth / visual.numStrpe));
            max = visual.Rxmin + ((i+1) * (visual.wdth / visual.numStrpe));
            Screen('FillRect', visual.window, color.stripe(vars.rghtBot_type,:), [min visual.Fymin max visual.Fymax]);
        end
    end
    Screen('FillRect', visual.window, color.rect(vars.rghtTop_type,:), [visual.Rxmin visual.Fymin visual.Rxmax (visual.Fymin + (vars.rght_gamble * visual.hght))]);
    if vars.rghtTop_type <= 2
        for i = 1:2:visual.numStrpe
            min = visual.Rxmin + (i * (visual.wdth / visual.numStrpe));
            max = visual.Rxmin + ((i+1) * (visual.wdth / visual.numStrpe));
            Screen('FillRect', visual.window, color.stripe(vars.rghtTop_type,:), [min visual.Fymin max (visual.Fymin + (vars.rght_gamble * visual.hght))]);
        end
    end
end
o = [(visual.targX - visual.tokenRad) (visual.targY + visual.tokenDsp - visual.tokenRad) (visual.targX + visual.tokenRad) (visual.targY + visual.tokenDsp + visual.tokenRad)];
e = [(o(1) + (1.5 * visual.tokenRad) - (1.5 * vars.tokenThrsh * visual.tokenRad)) o(2) (o(3) + (1.5 * visual.tokenRad) - (1.5 * vars.tokenThrsh * visual.tokenRad)) o(4)];
for i = 0:vars.tokenThrsh-1
    Screen('FillOval', visual.window, color.token, [e(1)+(3*i*visual.tokenRad) e(2) e(3)+(3*i*visual.tokenRad) e(4)]);
    if vars.tokens <= i, Screen('FillOval', visual.window, color.backgrd, [e(1)+(3*i*visual.tokenRad)+visual.ringWid e(2)+visual.ringWid e(3)+(3*i*visual.tokenRad)-visual.ringWid e(4)-visual.ringWid]);end
end
Screen(visual.window, 'flip');
%**********

%***** Save time
vars.delayTS = GetSecs;
%**********

onset = false;
end

function step_feedback
global visual; global color; global vars; global onset; global eye;

%***** Resolve gamble
vars.reactionTime = eye.fixtime - vars.choiceStart;
if strcmp(vars.choice, 'left')
    if rand <= vars.left_gamble
        vars.outcome = 'top';
        vars.tokenChange = vars.values(vars.leftTop_type);
    else
        vars.outcome = 'bot';
        vars.tokenChange = vars.values(vars.leftBot_type);
    end
else
    if rand <= vars.rght_gamble
        vars.outcome = 'top';
        vars.tokenChange = vars.values(vars.rghtTop_type);
    else
        vars.outcome = 'bot';
        vars.tokenChange = vars.values(vars.rghtBot_type);
    end
end
vars.tokens = vars.tokens + vars.tokenChange;
if vars.tokens < 0, vars.tokens = 0;end
%**********

%***** Set screen
if strcmp(vars.choice, 'left')
    if strcmp(vars.outcome, 'bot')
        Screen('FillRect', visual.window, color.rect(vars.leftBot_type,:), [visual.Lxmin visual.Fymin visual.Lxmax visual.Fymax]);
        if vars.leftBot_type <= 2
            for i = 1:2:visual.numStrpe
                min = visual.Lxmin + (i * (visual.wdth / visual.numStrpe));
                max = visual.Lxmin + ((i+1) * (visual.wdth / visual.numStrpe));
                Screen('FillRect', visual.window, color.stripe(vars.leftBot_type,:), [min visual.Fymin max visual.Fymax]);
            end
        end
    else
        Screen('FillRect', visual.window, color.rect(vars.leftTop_type,:), [visual.Lxmin visual.Fymin visual.Lxmax visual.Fymax]);
        if vars.leftTop_type <= 2
            for i = 1:2:visual.numStrpe
                min = visual.Lxmin + (i * (visual.wdth / visual.numStrpe));
                max = visual.Lxmin + ((i+1) * (visual.wdth / visual.numStrpe));
                Screen('FillRect', visual.window, color.stripe(vars.leftTop_type,:), [min visual.Fymin max visual.Fymax]);
            end
        end
    end
else
    if strcmp(vars.outcome, 'bot')
        Screen('FillRect', visual.window, color.rect(vars.rghtBot_type,:), [visual.Rxmin visual.Fymin visual.Rxmax visual.Fymax]);
        if vars.rghtBot_type <= 2
            for i = 1:2:visual.numStrpe
                min = visual.Rxmin + (i * (visual.wdth / visual.numStrpe));
                max = visual.Rxmin + ((i+1) * (visual.wdth / visual.numStrpe));
                Screen('FillRect', visual.window, color.stripe(vars.rghtBot_type,:), [min visual.Fymin max visual.Fymax]);
            end
        end
    else
        Screen('FillRect', visual.window, color.rect(vars.rghtTop_type,:), [visual.Rxmin visual.Fymin visual.Rxmax visual.Fymax]);
        if vars.rghtTop_type <= 2
            for i = 1:2:visual.numStrpe
                min = visual.Rxmin + (i * (visual.wdth / visual.numStrpe));
                max = visual.Rxmin + ((i+1) * (visual.wdth / visual.numStrpe));
                Screen('FillRect', visual.window, color.stripe(vars.rghtTop_type,:), [min visual.Fymin max visual.Fymax]);
            end
        end
    end
end
o = [(visual.targX - visual.tokenRad) (visual.targY + visual.tokenDsp - visual.tokenRad) (visual.targX + visual.tokenRad) (visual.targY + visual.tokenDsp + visual.tokenRad)];
e = [(o(1) + (1.5 * visual.tokenRad) - (1.5 * vars.tokenThrsh * visual.tokenRad)) o(2) (o(3) + (1.5 * visual.tokenRad) - (1.5 * vars.tokenThrsh * visual.tokenRad)) o(4)];
for i = 0:vars.tokenThrsh-1
    Screen('FillOval', visual.window, color.token, [e(1)+(3*i*visual.tokenRad) e(2) e(3)+(3*i*visual.tokenRad) e(4)]);
    if vars.tokens <= i, Screen('FillOval', visual.window, color.backgrd, [e(1)+(3*i*visual.tokenRad)+visual.ringWid e(2)+visual.ringWid e(3)+(3*i*visual.tokenRad)-visual.ringWid e(4)-visual.ringWid]);end
end
Screen(visual.window, 'flip');
%**********

%***** Reward
vars.timeSmallReward = GetSecs;
if vars.tokenChange > 0, reward(vars.reward(1) * vars.tokenChange);end %reward(vars.reward(1));
%**********

onset = false;
end

function step_prizedelay
global onset; global visual; global color; global vars;

%***** Set screen
o = [(visual.targX - visual.tokenRad) (visual.targY + visual.tokenDsp - visual.tokenRad) (visual.targX + visual.tokenRad) (visual.targY + visual.tokenDsp + visual.tokenRad)];
e = [(o(1) + (1.5 * visual.tokenRad) - (1.5 * vars.tokenThrsh * visual.tokenRad)) o(2) (o(3) + (1.5 * visual.tokenRad) - (1.5 * vars.tokenThrsh * visual.tokenRad)) o(4)];
for i = 0:vars.tokenThrsh-1
    Screen('FillOval', visual.window, color.token, [e(1)+(3*i*visual.tokenRad) e(2) e(3)+(3*i*visual.tokenRad) e(4)]);
    if vars.tokens <= i, Screen('FillOval', visual.window, color.backgrd, [e(1)+(3*i*visual.tokenRad)+visual.ringWid e(2)+visual.ringWid e(3)+(3*i*visual.tokenRad)-visual.ringWid e(4)-visual.ringWid]);end
end
Screen(visual.window, 'flip');
%**********

onset = false;
end

function step_prize
global onset; global visual; global vars; global color;

%***** Set screen
Screen('FillRect', visual.window, color.prizeCue, [0 (visual.targY + visual.tokenDsp - (.5*visual.prizeCueH)) 2*visual.targX (visual.targY + visual.tokenDsp + (.5*visual.prizeCueH))]);
Screen(visual.window, 'flip');
%**********

%***** Reward
vars.timeBigReward = GetSecs;
reward(vars.reward(2));
vars.tokens = 0;
%**********

onset = false;
end

function paused
global eye; global onset; global vars; global visual;

Screen(visual.window, 'flip');
home
disp(' ');
disp('****   PAUSED   ****');
disp('**** LEFT ARROW ****');
eye.fixating = 0;
vars.canceled = true;
onset = false;

end

function progress
global step; global onset; global vars;

nextStep = step;
if step == 1 && GetSecs >= (vars.trialStart + vars.ITI)
    nextStep = 2;
elseif step == 3 && GetSecs >= (vars.op1onTS + vars.op1on)
    nextStep = 4;
elseif step == 4 && GetSecs >= (vars.op1onTS + vars.op1on + vars.op1off)
    nextStep = 5;
elseif step == 5 && GetSecs >= (vars.op1onTS + vars.op1on + vars.op1off + vars.op2on)
    nextStep = 6;
elseif step == 6 && GetSecs >= (vars.op1onTS + vars.op1on + vars.op1off + vars.op2on + vars.op2off)
    nextStep = 7;
elseif step == 9 && GetSecs >= (vars.delayTS + vars.delay)
    nextStep = 10;
elseif step == 10 && GetSecs >= (vars.delayTS + vars.delay + vars.feedback)
    if vars.tokens >= vars.tokenThrsh
        nextStep = 11;
    else
        nextStep = 1;
    end
elseif step == 11 && GetSecs >= (vars.delayTS + vars.delay + vars.feedback + vars.prizedelay)
    nextStep = 12;
elseif step == 12 && GetSecs >= (vars.delayTS + vars.delay + vars.feedback + vars.prizedelay + vars.prize)
    nextStep = 1;
end

if nextStep ~= step,
    onset = true;
    step = nextStep;
end
        
end

function go = keyCapture
global step; global onset;
go = 1;
stopkey=KbName('ESCAPE');
pause=KbName('LeftArrow');
[keyIsDown,~,keyCode] = KbCheck;
if keyCode(stopkey)
    go = 0;
elseif keyCode(pause) && step ~= 13
    step = 13;
    onset = true;
elseif keyCode(pause) && step == 13
    step = 1;
    onset = true;
end
while keyIsDown
    [keyIsDown,~,~] = KbCheck;
end
end