---------------------------------------------------------------------------------------------------------
-- FIXFRUIT SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  To adjust fruit properties.
-- Authors:  Akuenzi, ian898, Jarvixes, theSeb
--

Time = {};
Time.lastUpdate = 0;

function Time:loadMap(name)
    g_currentMission.Time = self;

    -- Update time before game start to prevent sudden change of darkness
    self:adaptTime();

    g_currentMission.missionInfo.timeScale = 2400;
end;

function Time:deleteMap()
end;

function Time:mouseEvent(posX, posY, isDown, isUp, button)
end;

function Time:keyEvent(unicode, sym, modifier, isDown)
end;

function Time:update(dt)
    g_currentMission:addExtraPrintText("Light timer '"..g_currentMission.environment.lightTimer..string.format(", sun: %s, lights: %s", tostring(g_currentMission.environment.isSunOn), tostring(g_currentMission.environment.needsLights)));

    if (g_currentMission.SeasonsUtil ~= nil) then
        g_currentMission:addExtraPrintText("Season '"..g_currentMission.SeasonsUtil:seasonName().."', day "..g_currentMission.SeasonsUtil:currentDayNumber());
    end;
end;

function Time:updateTick(dt)
    -- Predict the weather once a day, for a whole week
    -- FIXME(jos): is this the best solution? How about weather over a long period of time, like, one season? Or a year?
    -- FIXME: What is g_currentMission.environment.dayChangeListeners? maybe we can use that
    local today = g_currentMission.SeasonsUtil:currentDayNumber();
    if (self.lastUpdate < today) then
        -- self:adaptTime();
    end;
end;

-- Change the night/day times according to season
-- There are two possible moments this function is called:
-- 1) At start of game, at any moment on the day (but at map load)
-- 2) At start of a new day
function Time:adaptTime()
    -- g_currentMission.environment.nightStart = 1260 | / 60 = 21 = 9PM
    -- g_currentMission.environment.nightEnd = 330 |  / 60 = 5,5 = half past 5

    -- Calculate the new end of night and start of night, for today and tomorrow

    -- if NOW is after end of night and before night (in the night)
    --   end of night = next day
    -- else
    --   end of night = today

    -- if now > end of night and > start of night (in the night)
    --   start of night = next day
    -- else
    --   start of night = today

    print("------------------");

    -- All local values are in minutes
    local startTime = 17 * 60; -- 5PM (9PM)
    local endTime = 8 * 60; -- 8AM (5.5AM)

    local morningSkyAdj = g_currentMission.environment.skyDayTimeStart / 60 / 1000 - g_currentMission.environment.nightEnd;
    local eveningSkyAdj = g_currentMission.environment.skyDayTimeEnd / 60 / 1000 - g_currentMission.environment.nightStart;
    -- This is for the logical night. Not the visual one. Used for turning on lights in houses / streets
    g_currentMission.environment.nightStart = startTime;
    g_currentMission.environment.nightEnd = endTime;

    -- This is for showing the red-sky texture (I think). Jos: nope it does not
    -- g_currentMission.environment.skyDayTimeStart = (endTime + morningSkyAdj) * 60 * 1000; -- 3
    -- g_currentMission.environment.skyDayTimeEnd = (startTime + eveningSkyAdj) * 60 * 1000; --17

    -- This makes the sky all black all the time. Not good, but something
    -- The sky texture position. needs adjustment for longer/shorter nights
    -- for i = 1, #g_currentMission.environment.skyCurve.keyframes do
    --     g_currentMission.environment.skyCurve.keyframes[i].x = 0;
    --     g_currentMission.environment.skyCurve.keyframes[i].y = 0;
    --     g_currentMission.environment.skyCurve.keyframes[i].z = 0;
    -- end;

    -- The light around. Setting it (1,1,1) actually causes an eternal day on the ground (sky still gets dark)
    -- for i = 1, #g_currentMission.environment.sunColorCurve.keyframes do
    --     g_currentMission.environment.sunColorCurve.keyframes[i].x = 1;
    --     g_currentMission.environment.sunColorCurve.keyframes[i].y = 1;
    --     g_currentMission.environment.sunColorCurve.keyframes[i].z = 1;
    -- end;

    -- Ambient light, the amount of actual light. Needs adjustment for longer/shorter nights.
    -- For this, the timestamps in the curve should be adjusted
    -- Does very little, but important too.
    -- for i = 1, #g_currentMission.environment.ambientCurve.keyframes do
    --     g_currentMission.environment.ambientCurve.keyframes[i].x = 0;
    --     g_currentMission.environment.ambientCurve.keyframes[i].y = 0;
    --     g_currentMission.environment.ambientCurve.keyframes[i].z = 0;
    -- end;

    -- Sun rotation is for the shadows. Might also need adjustment, but shadows also exist in the dark due to moon
    -- In the night (23-4) the shadow is 'reversed' for the moon. I think this is fine and we may not change this.
    -- for i = 1, #g_currentMission.environment.sunRotCurve.keyframes do
    --     g_currentMission.environment.sunRotCurve.keyframes[i].v = 0;
    -- end;

    print("------------------");

    -- g_currentMission.environment.dayNightCycle = false;
    -- g_currentMission.environment.water = 30000;

    self.lastUpdate = today;
end;

function Time:draw()
end;

addModEventListener(Time);
