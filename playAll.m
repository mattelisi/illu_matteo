function playAll( schedule )
%PLAYALL ( schedule )
%
% schedule = {...
%     'inout' 'stimulus';...
%     'inout' 'stimulus';...
%     'inout' 'stimulus';...
%     
%     'inout' 'control';...
%     'inout' 'control';...
%     'inout' 'control';...
%     
%     'rotate' 'stimulus';...
%     'rotate' 'stimulus';...
%     'rotate' 'stimulus';...
%     
%     'rotate' 'control';...
%     'rotate' 'control';...
%     'rotate' 'control';...
%     
%     'global' 'control';...
%     'global' 'control';...
%     'global' 'control';...
%     };
%


%% Check input arguments

% Number of input arguments
if nargin < 1
    schedule = {...
        
        'inout' 'stimulus';...
        
        'inout' 'control';...
        
        'rotate' 'stimulus';...
        
        'rotate' 'control';...
        
        'global' 'control';...

        };
    
else
    
    assert( ...
        iscell(schedule) && ...
        size(schedule,1) > 1 && ...
        size(schedule,2) == 2 , ...
        'schedule must be a cell n x 2 cell' )
    
end

for s = 1:size(schedule,1)
    
    % Path
    switch lower(schedule{s,1})
        case ''
        case 'inout'
        case 'rotate'
        case 'global'
        otherwise
            error('unknown path')
    end
    
    % Condition
    switch lower(schedule{s,2})
        case ''
        case 'stimulus'
        case 'control'
        otherwise
            error('unknown condition')
    end
    
end

% Load the noise patches
try
    load('m_2D.mat')
    load('m_3D.mat')
catch err
    disp('execute playIllusion(''inout'',''stimulus'') to generate the 2D noise patches')
    disp('execute playIllusion(''inout'',''control'') to generate the 3D noise patches')
    rethrow(err)
end


%% Load stimulation parameters

setParameters;

% No path ?
if strcmp( path , '' )
    stim.pathLength = 0;
end

Common.SetAngles;


%% Start PTB window

prepareScreen;


%% Convert everything in pixels

Common.ConvertInPix;


%% Cut out and stores individual frames; save them as openGL textures
nFrames = round(stim.period/scr.fd);
motionTex2D = zeros(16, nFrames);
motionTex3D = motionTex2D;

for ti = 1:16 % for each patch
    
    for i=1:nFrames % for each frame
        
        motionTex2D(ti,i)=Screen('MakeTexture', scr.main, m_2D{ti}(:,:,i)); %#ok<USENS>
        motionTex3D(ti,i)=Screen('MakeTexture', scr.main, m_3D{ti}(:,:,i)); %#ok<USENS>
        
    end
    
end


%% Compute path coordinates

rectAll_Illusion = coordIllusion(stim, visual, scr); % basic value
rectAll_InOut = coordInOut(stim, visual, scr);
rectAll_Rotation = coordRotation(stim, visual, scr);


%% Set sequence index (motion start at trajectory midpoint)

Common.SetSequenceIndex;


%% Parse the schedule

shuffleAll = Shuffle(repmat((1:16)',[1 3]));

for s = 1:size(schedule,1)
    
    switch lower(schedule{s,1})
        case 'inout'
            switch lower(schedule{s,2})
                case 'stimulus'
                    schedule{s,3} = rectAll_Illusion;
                    schedule{s,4} = angles_expanding;
                    schedule{s,5} = motionTex2D(shuffleAll(:,1),:);
                case 'control'
                    schedule{s,3} = rectAll_InOut;
                    schedule{s,4} = angles_other;
                    schedule{s,5} = motionTex3D(shuffleAll(:,1),:);
            end
        case 'rotate'
            switch lower(schedule{s,2})
                case 'stimulus'
                    schedule{s,3} = rectAll_Illusion;
                    schedule{s,4} = angles_rotating;
                    schedule{s,5} = motionTex2D(shuffleAll(:,2),:);
                case 'control'
                    schedule{s,3} = rectAll_Rotation;
                    schedule{s,4} = angles_other;
                    schedule{s,5} = motionTex3D(shuffleAll(:,2),:);
            end
        case 'global'
            switch lower(schedule{s,2})
                case 'control'
                    schedule{s,3} = rectAll_Illusion;
                    schedule{s,4} = angles_other;
                    schedule{s,5} = motionTex3D(shuffleAll(:,3),:);
            end
    end
end


%% Display stimulus


for s = 1:size(schedule,1)
    for cycle = 1:nCycles
        if cycle == tarPos % this determine whether there is path shortening
            as = seq_tar;
        else
            as = seq;
        end
        for i = as
            Screen('DrawTextures', scr.main, schedule{s,5}(:,i), [], squeeze(schedule{s,3}(:,:,i)), schedule{s,4});
            drawFixation(visual.fgColor,[scr.centerX, scr.centerY],scr,visual)
            Screen('Flip', scr.main);
            [keyIsDown] = KbCheck(-1);
            if keyIsDown
                
                END;
                
                return

            end
        end
    end
end


%% END

END;


end

