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

    self:copyDefaultKeyframes();

    -- Calculate some constants for the daytime calculator
    local L = 51.9; -- FIXME(jos): Get from savegame
    self.sunRad = L * math.pi / 180;
    self.pNight = 6 * math.pi / 180; -- Suns inclination below the horizon for 'civil twilight'
    self.pDay = -1 * math.pi / 180; -- Suns inclination above the horizon for 'daylight' assumed to be one degree above horizon

    -- Update time before game start to prevent sudden change of darkness
    self:adaptTime();

    g_currentMission.missionInfo.timeScale = 120*6;
end;

function Time:deleteMap()
end;

function Time:mouseEvent(posX, posY, isDown, isUp, button)
end;

function Time:keyEvent(unicode, sym, modifier, isDown)
end;

function Time:draw()
end;

function Time:update(dt)
    -- Predict the weather once a day, for a whole week
    -- FIXME(jos): is this the best solution? How about weather over a long period of time, like, one season? Or a year?
    -- FIXME: What is g_currentMission.environment.dayChangeListeners? maybe we can use that
    local today = g_currentMission.SeasonsUtil:currentDayNumber();
    if (self.lastUpdate < today) then
        self:adaptTime();
        self.lastUpdate = today;
    end;

    -- Visual
    g_currentMission:addExtraPrintText("Light timer '"..g_currentMission.environment.lightTimer..string.format(", sun: %s, lights: %s", tostring(g_currentMission.environment.isSunOn), tostring(g_currentMission.environment.needsLights)));

    if g_currentMission.SeasonsUtil then
        g_currentMission:addExtraPrintText("Season '"..g_currentMission.SeasonsUtil:seasonName().."', day "..g_currentMission.SeasonsUtil:currentDayNumber());
    end;
end;

-- Change the night/day times according to season
function Time:adaptTime()
    -- This is for showing the red-sky texture (I think). Jos: nope it does not
    -- g_currentMission.environment.skyDayTimeStart = (endTime + morningSkyAdj) * 60 * 1000; -- 3
    -- g_currentMission.environment.skyDayTimeEnd = (startTime + eveningSkyAdj) * 60 * 1000; --17

    print("------------------");

    -- All local values are in minutes
    -- local startTime, endTime = self:calculateStartEndOfDay(g_currentMission.SeasonsUtil:currentDayNumber());
    local startTime, endTime = self:calculateStartEndOfDay(15);

    print(string.format("day %f -> %f", startTime/60, endTime/60));

    -- This is for the logical night. Used for turning on lights in houses / streets. Might need some more adjustment.
    -- FIXME(jos): Maybe turn them on between the beginOfNight and fullNight?
    g_currentMission.environment.nightStart = startTime;
    g_currentMission.environment.nightEnd = endTime;

    -- For the visual looks
    g_currentMission.environment.skyCurve.keyframes = self:compressedNightKeyframes(self.skyCurveOriginal, endTime, startTime);
    g_currentMission.environment.ambientCurve.keyframes = self:compressedNightKeyframes(self.ambientCurveOriginal, endTime, startTime);
    g_currentMission.environment.sunRotCurve.keyframes = self:compressedNightKeyframes(self.sunRotOriginal, endTime, startTime);
    g_currentMission.environment.sunColorCurve.keyframes = self:compressedNightKeyframes(self.sunColorCurveOriginal, endTime, startTime);

    print("------------------");
end;

function Time:calculateStartEndOfDay(dayNumber)
    local dayStart, dayEnd, julianDay, theta, eta;

    julianDay = g_currentMission.SeasonsUtil:julianDay(dayNumber);

    -- Call radii for current day
    theta = 0.216 + 2 * math.atan(0.967 * math.tan(0.0086 * (julianDay - 186)));
    eta = math.asin(0.4 * math.cos(theta));

    -- Calculate the day
    dayStart, dayEnd = self:_calculateDay(self.pDay, eta, julianDay);

    -- True blackness
    -- nightStart, nightEnd = self:_calculateDay(self.pNight, eta, julianDay);

    return dayStart * 60, dayEnd * 60;
end;

function Time:_calculateDay(p, eta, julianDay)
    local timeStart, timeEnd;
    local D = 0, offset, hasDST;
    local gamma = (math.sin(p) + math.sin(self.sunRad) * math.sin(eta)) / (math.cos(self.sunRad) * math.cos(eta));

    -- Account for polar day and night
    if gamma < -1 then
        D = 0;
    elseif gamma > 1 then
        D = 24;
    else
        D = 24 - 24 / math.pi * math.acos(gamma);
    end;

    -- Daylight saving between 1 April and 31 October as an approcimation
    local hasDST = not ((julianDay < 91 or julianDay > 304) or ((julianDay >= 91 and julianDay <= 304) and (gamma < -1 or gamma > 1)));
    offset = hasDST and 1 or 0;

    timeStart = 12 - D / 2 + offset;
    timeEnd = 12 + D / 2 + offset;

    return timeStart, timeEnd;
end;

function Time:copyDefaultKeyframes()
    self.skyCurveOriginal = deepCopy(g_currentMission.environment.skyCurve.keyframes);
    self.ambientCurveOriginal = deepCopy(g_currentMission.environment.ambientCurve.keyframes);
    self.sunRotOriginal = deepCopy(g_currentMission.environment.sunRotCurve.keyframes);
    self.sunColorCurveOriginal = deepCopy(g_currentMission.environment.sunColorCurve.keyframes);
end;

function Time:compressedNightKeyframes(keyframes, beginNight, endNight)
    local newFrames = deepCopy(keyframes);
    local numFrames = arrayLength(keyframes);
    local oldNightEnd, oldNightBegin;
    local pivot, pivotGap = nil, 0;

    -- Verify first frame = time 0, last = time 1440
    -- FIXME: move this all to somewhere else, it all needs to be done just once.
    if keyframes[1].time ~= 0 or keyframes[numFrames].time ~= 1440 then
        -- Todo: make this a UTIL
        print("[Seasons] Could not change keyframes due to unknown keyframes format");
        return;
    end;

    -- Find the pivot (center) by looking between 5:00 and 21:00 for the biggest gap
    for i = 1, numFrames do
        if keyframes[i].time >= 5 * 60 and keyframes[i].time <= 21 * 60 then
            local newGap = keyframes[i + 1].time - keyframes[i].time;

            if newGap > pivotGap then
                pivotGap = newGap;
                pivot = i;
            end;
        end;
    end;

    if not pivot then
        print("[Seasons] Could not find pivot");
        return;
    end;
    -- END OF FIXME

    -- Find old begin and end time of night
    oldNightEnd = keyframes[pivot].time; -- in minutes (early)
    oldNightBegin = keyframes[pivot + 1].time; -- in minutes (late)

    -- Calculate compression rate for early and late
    local compressionEarly = endNight / oldNightEnd;
    local compressionLate = (1440 - beginNight) / (1440 - oldNightBegin);

    -- print("compression early "..tostring(compressionEarly)..", late "..tostring(compressionLate));

    -- Rewrite times for early and late
    for i = 1, numFrames do
        if i <= pivot then -- early
            newFrames[i].time = keyframes[i].time * compressionEarly;
        else -- late
            newFrames[i].time = 1440 - ((1440 - keyframes[i].time) * compressionLate);
        end;
    end;

    return newFrames;
end;

-- http://lua-users.org/wiki/CopyTable
function deepCopy(obj, seen)
    local orig_type = type(obj);

    if orig_type ~= 'table' then return obj end;
    if seen and seen[obj] then return seen[obj] end;

    local s = seen or {}
    local res = setmetatable({}, getmetatable(obj));
    s[obj] = res;

    for k, v in pairs(obj) do
        res[deepCopy(k, s)] = deepCopy(v, s);
    end;

    return res;
end;

function arrayLength(arr)
    local n = 0;
    for i = 1, #arr do
        n = n + 1;
    end;
    return n;
end;

addModEventListener(Time);
