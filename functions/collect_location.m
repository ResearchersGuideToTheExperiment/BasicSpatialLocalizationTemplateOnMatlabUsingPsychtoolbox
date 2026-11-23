function response = collect_location(window, g, cueSec, timeoutSec)
% COLLECT_LOCATION Fresh left click in the stimulus window; return angular position.
% Click time is sampled by polling, not a hardware event timestamp.
[~,~,buttons] = GetMouse(window);
armed = ~buttons(1);
response = struct('positionPx',[NaN NaN],'positionDeg',[NaN NaN], ...
    'clickSec',NaN,'reactionSec',NaN,'status','timeout');
ShowCursor('Arrow',window);
while GetSecs < cueSec+timeoutSec
    check_escape;
    [x,y,buttons] = GetMouse(window);
    sampleSec = GetSecs;
    if ~buttons(1), armed = true; end
    if armed && buttons(1) && x>=0 && y>=0 && x<g.resolutionPx(1) && y<g.resolutionPx(2)
        response.positionPx = [x y];
        response.positionDeg = px_to_deg([x y],g);
        response.clickSec = sampleSec;
        response.reactionSec = sampleSec-cueSec;
        response.status = 'ok';
        HideCursor;
        return;
    end
    WaitSecs('YieldSecs',0.001);
end
HideCursor;
end
