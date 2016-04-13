function [] = playStimulus(direction, local,save_patchs)
%
% play stimulus (illusion condition)
%
% input: "direction" is a string, and determines the illusion
%        2 possible values: 'rotate' & 'inout'
%

% if local=1, this gives the local motion only condition
% that is with static noise patches
if nargin < 2
    local=0;
end

if nargin<3
    save_patchs = 0;
end

%% if direction is not set, pick one randomly
if nargin<1
    if randn(1)>0
        direction = 'rotate';
    else
        direction = 'inout';
    end
end

%% load stimulation parameters
setParameters;
if local==1
    stim.pathLength = 0;
end

%%
angles_expanding = [0, 0, 0, 0, 90, 90, 90, 90, 0, 0, 0, 0, 90, 90, 90, 90];
angles_rotating = 180 + angles_expanding;

%% 
prepareScreen;

%% convert everything in pixels
stim.sigma_px = round(visual.ppd * stim.sigma);
stim.gridSize_px = round(visual.ppd * stim.gridSize);
stim.textureSize_px = round(visual.ppd * stim.textureSize);
stim.internalSpeed_px = round(visual.ppd * stim.internalSpeed);
stim.externalSpeed_px = round(visual.ppd * stim.externalSpeed);
if mod(stim.textureSize_px,2) == 0
    stim.textureSize_px = stim.textureSize_px+1;
end

%% generate and store noise images

switch save_patchs
    case 1
        noiseArray = generateNoiseImage(stim,visual, scr.fd);
        for ti = 1:16 % for each of the 16 noise patches
            noiseArray = cat(3, noiseArray, generateNoiseImage(stim,visual,scr.fd));
        end
    case 0
    case -1
end

%% cut out and stores individual frames; save them as openGL textures
nFrames = round(stim.period/scr.fd);
motionTex = zeros(16, nFrames);

switch save_patchs
    case 1
        m_2D = cell(16,1);
    case 0
        load m_2D
    case -1
end

for ti = 1:16 % for each patch
    
    switch save_patchs
        case 1
            m = framesIllusion(stim, visual, noiseArray(:,:,ti), scr.fd);
            m_2D{ti} = uint8(m);
            
            for i=1:nFrames % for each frame
                motionTex(ti,i)=Screen('MakeTexture', scr.main, m(:,:,i));
            end
            
        case 0
            
            for i=1:nFrames % for each frame
                motionTex(ti,i)=Screen('MakeTexture', scr.main, m_2D{ti}(:,:,i));
            end
            
        case -1
    end

end

switch save_patchs
    case 1
        save('m_2D','m_2D');
    case 0
    case -1
end

motionTex = motionTex(Shuffle(1:16),:);


%% compute path coordinates
rectAll = coordIllusion(stim, visual, scr);

%% set sequence index (motion start at trajectory midpoint)
% adjust the order of the sequence by selecting a different starting point
% so that each noise patches initially appear at the middle point of its trajectory
seq = 1:nFrames;
sqShift = round(nFrames/4);
seq = circshift(seq, [0, -sqShift]);

% here, if required, the path shortening is added (if tarPos != 0 and tarPos<nCycles)
% the cycle in which it will appear is given by tarPos (should be 1)
% if tarPos is set to 0 the normal stimulus is presented (whole trajectory)
nFrameSkip = round(tarShort * (nFrames/2));
seq_tar = [seq(1:(sqShift-ceil(nFrameSkip/2))), seq((sqShift+floor(nFrameSkip/2)):end)]; 

%% internal motion angles values
% determine the quality of the illusion, rotation vs expanding-contracting (inout)
switch direction
    case 'inout'
        angles = angles_expanding;
    case 'rotate'
        angles = angles_rotating;
    otherwise
        error('Error: unknown direction value');
end

%% display stimulus
showStim = 1;
while showStim
    for cycle = 1:nCycles
        if cycle == tarPos % this determine whether there is path shortening
            as = seq_tar;
        else
            as = seq;
        end
        for i = as
            Screen('DrawTextures', scr.main, motionTex(:,i), [], squeeze(rectAll(:,:,i)), angles);
            drawFixation(visual.fgColor,[scr.centerX, scr.centerY],scr,visual)
            Screen('Flip', scr.main);
            [keyIsDown] = KbCheck(-1);
            if keyIsDown
                showStim=0;
                break;
            end
        end
    end
end

%% END
Priority(0);
ShowCursor;

% Close all textures. Not strictly needed but avoid warnings
Screen('Close');

% Close window:
Screen('CloseAll');
