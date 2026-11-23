function results = main_spatial_localization_template(screenSizeCm, distanceCm)
% MAIN_SPATIAL_LOCALIZATION_TEMPLATE Run a generic demonstration; results remain in memory.
% Supply measured active screen [width height] in cm and eye distance in cm.
% Example only: results = main_spatial_localization_template([50 30], 60);
if nargin ~= 2
    error('Supply measured screen size [width height] cm and viewing distance cm.');
end
root = fileparts(mfilename('fullpath'));
oldPath = path;
pathGuard = onCleanup(@() path(oldPath)); %#ok<NASGU>
addpath(fullfile(root,'functions'));
% Validate calibration before opening the display.
create_geometry([1 1],screenSizeCm,distanceCm);
assert(exist('Screen','file') ~= 0, 'Install Psychtoolbox separately first.');
oldSync = Screen('Preference','SkipSyncTests',0);
displayGuard = onCleanup(@() cleanup_display(oldSync)); %#ok<NASGU>
[window,g,ifi] = open_display(screenSizeCm,distanceCm);
sigmaDeg = 0.35; % Gaussian standard deviation; support extends to +/-4 sigma.
seed = 1; % Reproducible demonstration, without modifying the caller's RNG state.
oldRng = rng; rngGuard = onCleanup(@() rng(oldRng)); %#ok<NASGU>
rng(seed,'twister');
results = struct('geometry',g,'refreshIntervalSec',ifi,'seed',seed,'sigmaDeg',sigmaDeg);
Screen('TextSize',window,24);
DrawFormattedText(window, 'Remember each target location. After it disappears, click its center.\n\nPress SPACE to start. ESC to stop.', ...
    'center','center',0);
Screen('Flip',window);
wait_for_space;
positions = repmat([-4 2; 4 2; -4 -2; 4 -2],2,1);
positions = positions(randperm(size(positions,1)),:);
for trial = 1:size(positions,1)
    [im,rect] = gaussian_blob_image(g,positions(trial,:),sigmaDeg,1);
    texture = Screen('MakeTexture',window,im);
    timing = present_blob(window,texture,rect,g,0.5,ifi);
    % The target disappears; click its remembered center on this same display.
    cueSec = timing.offsetSec;
    response = collect_location(window,g,cueSec,10);
    results.trials(trial).targetDeg = positions(trial,:);
    results.trials(trial).timing = timing;
    results.trials(trial).response = response;
    results.trials(trial).errorXYDeg = response.positionDeg-positions(trial,:);
    results.trials(trial).errorMagnitudeDeg = norm(results.trials(trial).errorXYDeg);
    Screen('Close',texture);
    wait_seconds(0.5);
end
end
