function playAll( schedule )
%PLAYALL ( schedule )
%
% schedule = {...
%     'Control_inOut' 0 ;...
%     'Control_rotation' 1 ;...
%     'Control_global' 0 ;...
%     'Illusion_InOut' 1 ;...
%     'Illusion_rotation' 0 ;...
%     'Control_local_inOut' 1 ;...
%     'Control_local_rot' 0 ;...
%     'NULL' 0 ...
%     };
%


%% Check input arguments

% Number of input arguments
if nargin < 1
    
    schedule = {...
        'Control_inOut' 0 ;...
        'Control_rotation' 1 ;...
        'Control_global' 0 ;...
        'Illusion_InOut' 1 ;...
        'Illusion_rotation' 0 ;...
        'Control_local_inOut' 1 ;...
        'Control_local_rot' 0 ;...
        'NULL' 0 ...
        };
    
else
    
    assert( ...
        iscell(schedule) && ...
        size(schedule,1) > 1 && ...
        size(schedule,2) == 2 , ...
        'schedule must be a cell n x 2 cell' )
    
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

Common.SetAngles;


%% Start PTB window

prepareScreen;


%% Convert everything in pixels

Common.ConvertInPix;


%% Cut out and stores individual frames; save them as openGL textures
nFrames = round(stim.period/scr.fd); %#ok<NODEF>
motionTex2D = zeros(16, nFrames);
motionTex3D = motionTex2D;

for ti = 1:16 % for each patch
    
    for i=1:nFrames % for each frame
        
        motionTex2D(ti,i)=Screen('MakeTexture', scr.main, m_2D{ti}(:,:,i)); %#ok<USENS>
        motionTex3D(ti,i)=Screen('MakeTexture', scr.main, m_3D{ti}(:,:,i)); %#ok<USENS>
        
    end
    
end


%% Compute path coordinates

rectAll_Illusion = coordIllusion(stim, visual, scr);
rectAll_InOut = coordInOut(stim, visual, scr);
rectAll_Rotation = coordRotation(stim, visual, scr);

stim.pathLength = 0;
rectAll_NoPath = coordIllusion(stim, visual, scr);

%% Set sequence index (motion start at trajectory midpoint)

Common.SetSequenceIndex;


%% Parse the schedule

conditions_with_patches = 7;

% shuffleAll = Shuffle(repmat((1:16)',[1 conditions_with_patches]));
shuffleAll = repmat((1:16)',[1 conditions_with_patches]);

for s = 1:size(schedule,1)
    
    switch schedule{s}
        
        case 'Control_inOut'
            schedule{s,3} = rectAll_InOut;
            schedule{s,4} = angles_other;
            schedule{s,5} = motionTex3D(shuffleAll(:,1),:);
            
        case 'Control_rotation'
            schedule{s,3} = rectAll_Rotation;
            schedule{s,4} = angles_other;
            schedule{s,5} = motionTex3D(shuffleAll(:,2),:);
            
        case 'Control_global'
            schedule{s,3} = rectAll_Illusion;
            schedule{s,4} = angles_other;
            schedule{s,5} = motionTex3D(shuffleAll(:,3),:);
            
        case 'Illusion_InOut'
            schedule{s,3} = rectAll_Illusion;
            schedule{s,4} = angles_expanding;
            schedule{s,5} = motionTex2D(shuffleAll(:,4),:);
            
        case 'Illusion_rotation'
            schedule{s,3} = rectAll_Illusion;
            schedule{s,4} = angles_rotating;
            schedule{s,5} = motionTex2D(shuffleAll(:,5),:);
            
        case 'Control_local_inOut'
            schedule{s,3} = rectAll_NoPath;
            schedule{s,4} = angles_rotating;
            schedule{s,5} = motionTex2D(shuffleAll(:,5),:);
            
        case 'Control_local_rot'
            schedule{s,3} = rectAll_NoPath;
            schedule{s,4} = angles_expanding;
            schedule{s,5} = motionTex2D(shuffleAll(:,5),:);
            
        case 'NULL'
            schedule{s,3} = [];
            schedule{s,4} = [];
            schedule{s,5} = [];
            
        otherwise
            error( 'stim unrecognised : %s' , schedule{s} )
            
    end
    
end


%% Display stimulus

showStim = 1;

while showStim
    
    for s = 1:size(schedule,1)
        fprintf( '\n conditon : %s | short path = %d \n' , schedule{s,1} , schedule{s,2} )
        for cycle = 1:nCycles
            
            %             if cycle == tarPos % this determine whether there is path shortening
            %                 as = seq_tar;
            %             else
            %                 as = seq;
            %             end
            
            switch schedule{s,2}
                case 0
                    as = seq;
                case 1
                    as = seq_tar;
            end
            
            for i = as
                if ~strcmp(schedule{s,1},'NULL')
                    Screen('DrawTextures', scr.main, schedule{s,5}(:,i), [], squeeze(schedule{s,3}(:,:,i)), schedule{s,4});
                end
                drawFixation(visual.fgColor,[scr.centerX, scr.centerY],scr,visual)
                DrawFormattedText(scr.main, [ schedule{s,1} , ' ' , num2str(schedule{s,2}) ] );
                Screen('Flip', scr.main);
                [keyIsDown] = KbCheck(-1);
                if keyIsDown
                    
                    showStim = 0;
                    
                    break
                    
                end
            end
        end
    end
end

%% END

END;


end

