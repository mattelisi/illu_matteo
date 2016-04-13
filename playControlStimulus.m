function [] = playControlStimulus(direction,save_patchs)
%
% play stimulus (illusion condition)
%
% input: "direction" is a string, and determines the illusion
%        3 possible values: 'rotate' & 'inout' & 'global'
%

%% if direction is not set, pick one randomly
if nargin<1
    if randn(1)>0
        direction = 'rotate';
    else
        direction = 'inout';
    end
end

if nargin<2
    save_patchs = 0;
end

%% load stimulation parameters
setParameters;

%% 
prepareScreen;

%% convert everything in pixels
stim.sigma_px = round(visual.ppd * stim.sigma); %#ok<*NODEF>
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
        
        noiseArray = generateNoiseVolume(stim,visual, scr.fd);
        for ti = 1:16
            noiseArray = cat(4, noiseArray, generateNoiseVolume(stim,visual,scr.fd));
        end
        
    case 0
    case -1
end

%% cut out and stores individual frames; save them as openGL textures
nFrames = round(stim.period/scr.fd);
motionTex = zeros(16, nFrames);

switch save_patchs
    case 1
        m_3D = cell(16,1);
    case 0
        load m_3D
    case -1
end

for ti = 1:16 % for each patch
    
    switch save_patchs
        case 1
            m = framesControl(stim, visual, noiseArray(:,:,:,ti), scr.fd);
            m_3D{ti} = uint8(m);
            
            for i=1:nFrames % for each frame
                motionTex(ti,i)=Screen('MakeTexture', scr.main, m(:,:,i));
            end
            
        case 0
            
            for i=1:nFrames % for each frame
                motionTex(ti,i)=Screen('MakeTexture', scr.main, m_3D{ti}(:,:,i));
            end
            
        case -1
    end

end

switch save_patchs
    case 1
        save('m_3D','m_3D');
    case 0
    case -1
end

motionTex = motionTex(Shuffle(1:16),:);


%% compute path coordinates
switch direction
    case 'inout'
        rectAll = coordInOut(stim, visual, scr);
    case 'rotate'
        rectAll = coordRotation(stim, visual, scr);
    case 'global'
        rectAll = coordIllusion(stim, visual, scr);
    otherwise
        error('Error: unknown direction value');
end


%% set sequence index (motion start at trajectory midpoint)
seq = 1:nFrames;
sqShift = round(nFrames/4);
seq = circshift(seq, [0, -sqShift]);

% this shorten the path (if tarPos != 0 and tarPos<nCycles)
nFrameSkip = round(tarShort * (nFrames/2));
seq_tar = [seq(1:(sqShift-ceil(nFrameSkip/2))), seq((sqShift+floor(nFrameSkip/2)):end)]; 


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
            Screen('DrawTextures', scr.main, motionTex(:,i), [], squeeze(rectAll(:,:,i)));
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
