----------------------------------------------------------------------------------------------------
-- ssEnvironment
----------------------------------------------------------------------------------------------------
-- Purpose:  Adjust day/night system and implement seasons
--           Definition of a season and growth stage
-- Authors:  Rahkiin, reallogger, theSeb
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssEnvironment = {}
g_seasons.environment = ssEnvironment

----------------------------
-- Constants
----------------------------

ssEnvironment.DAYS_IN_WEEK = 7
ssEnvironment.SEASONS_IN_YEAR = 4
ssEnvironment.MONTHS_IN_YEAR = 12

ssEnvironment.SEASON_SPRING = 0 -- important to start at 0, not 1
ssEnvironment.SEASON_SUMMER = 1
ssEnvironment.SEASON_AUTUMN = 2
ssEnvironment.SEASON_WINTER = 3

ssEnvironment.TRANSITION_EARLY_SPRING = 1
ssEnvironment.TRANSITION_MID_SPRING = 2
ssEnvironment.TRANSITION_LATE_SPRING = 3

ssEnvironment.TRANSITION_EARLY_SUMMER = 4
ssEnvironment.TRANSITION_MID_SUMMER = 5
ssEnvironment.TRANSITION_LATE_SUMMER = 6

ssEnvironment.TRANSITION_EARLY_AUTUMN = 7
ssEnvironment.TRANSITION_MID_AUTUMN = 8
ssEnvironment.TRANSITION_LATE_AUTUMN = 9

ssEnvironment.TRANSITION_EARLY_WINTER = 10
ssEnvironment.TRANSITION_MID_WINTER = 11
ssEnvironment.TRANSITION_LATE_WINTER = 12

function ssEnvironment:preLoad()
    -- Install the snow raintype. This needs to be just after the vanilla
    -- environment did it, because in here (preLoad) it is too early, and
    -- in loadMap it is too late. (both crash)
    Environment.new = Utils.overwrittenFunction(Environment.new, function (self, superFunc, xmlFilename)
        local self = superFunc(self, xmlFilename)

        Environment.RAINTYPE_SNOW = "snow"
        self:loadRainType(Environment.RAINTYPE_SNOW, 1, g_seasons.modDir .. "resources/environment/snow.i3d", false, 0, 0)
        self.rainFogColor[Environment.RAINTYPE_SNOW] = {0.07074, 0.07074, 0.07074, 0.01}

        return self
    end)
end

function ssEnvironment:load(savegame, key)
    self.latitude = ssStorage.getXMLFloat(savegame, key .. ".environment.latitude", 51.9)

    self.daysInSeason = Utils.clamp(ssStorage.getXMLInt(savegame, key .. ".settings.daysInSeason", 9), 3, 12)
    self.latestSeason = ssStorage.getXMLInt(savegame, key .. ".environment.latestSeason", -1)
    self.latestGrowthStage = ssStorage.getXMLInt(savegame, key .. ".environment.latestGrowthStage", 0)
    self.currentDayOffset = ssStorage.getXMLInt(savegame, key .. ".environment.currentDayOffset_DO_NOT_CHANGE", 0)

    self._doInitalDayEvent = savegame == nil
end

function ssEnvironment:save(savegame, key)
    ssStorage.setXMLFloat(savegame, key .. ".environment.latitude", self.latitude)

    ssStorage.setXMLInt(savegame, key .. ".settings.daysInSeason", self.daysInSeason)
    ssStorage.setXMLInt(savegame, key .. ".environment.latestSeason", self.latestSeason)
    ssStorage.setXMLInt(savegame, key .. ".environment.latestGrowthStage", self.latestGrowthStage)
    ssStorage.setXMLInt(savegame, key .. ".environment.currentDayOffset_DO_NOT_CHANGE", self.currentDayOffset)
end

function ssEnvironment:loadMap(name)
    self.seasonChangeListeners = {}
    self.growthStageChangeListeners = {}
    self.seasonLengthChangeListeners = {}

    -- Add day change listener to handle new dayNight system and new events
    g_currentMission.environment:addDayChangeListener(self)


    if g_currentMission:getIsServer() then
        -- if server, do it here. Otherwise do it in :load
        self:setupDayNight()
    end
end

function ssEnvironment:readStream(streamId, connection)
    self.latitude = streamReadFloat32(streamId)

    g_currentMission.environment.currentDay = streamReadInt32(streamId)
    self.daysInSeason = streamReadInt32(streamId)
    self.latestSeason = streamReadInt32(streamId)
    self.latestGrowthStage = streamReadInt32(streamId)
    self.currentDayOffset = streamReadInt32(streamId)

    self:setupDayNight()
end

function ssEnvironment:writeStream(streamId, connection)
    streamWriteFloat32(streamId, self.latitude)

    streamWriteInt32(streamId, g_currentMission.environment.currentDay)
    streamWriteInt32(streamId, self.daysInSeason)
    streamWriteInt32(streamId, self.latestSeason)
    streamWriteInt32(streamId, self.latestGrowthStage)
    streamWriteInt32(streamId, self.currentDayOffset)
end

function ssEnvironment:update(dt)
    -- The first day has already started with a new savegame
    -- Call all the event handlers to update growth, time and anything else
     if self._doInitalDayEvent then
        self:callListeners()
        self._doInitalDayEvent = false
    end
end

----------------------------
-- Seasons events
----------------------------

function ssEnvironment:callListeners()
    if not g_seasons.enabled then return end

    local currentSeason = self:currentSeason()
    local currentGrowthStage = self:currentGrowthStage()

    -- Call season change events
    if currentSeason ~= self.latestSeason then
        self.latestSeason = currentSeason

        for _, listener in pairs(self.seasonChangeListeners) do
            listener:seasonChanged()
        end
    end

    -- Call growth stage events
    if currentGrowthStage ~= self.latestGrowthStage then
        self.latestGrowthStage = currentGrowthStage

        for _, listener in pairs(self.growthStageChangeListeners) do
            listener:growthStageChanged()
        end
    end
end

-- Listeners for a change of season
function ssEnvironment:addSeasonChangeListener(listener)
    if listener ~= nil then
        self.seasonChangeListeners[listener] = listener
    end
end

function ssEnvironment:removeSeasonChangeListener(listener)
    if listener ~= nil then
        self.seasonChangeListeners[listener] = nil
    end
end

-- Listeners for a change of growth stage
function ssEnvironment:addGrowthStageChangeListener(listener)
    if listener ~= nil then
        self.growthStageChangeListeners[listener] = listener
    end
end

function ssEnvironment:removeGrowthStageChangeListener(listener)
    if listener ~= nil then
        self.growthStageChangeListeners[listener] = nil
    end
end

-- Listeners for a change of season length
function ssEnvironment:addSeasonLengthChangeListener(listener)
    if listener ~= nil then
        self.seasonLengthChangeListeners[listener] = listener
    end
end

function ssEnvironment:removeSeasonLengthChangeListener(listener)
    if listener ~= nil then
        self.seasonLengthChangeListeners[listener] = nil
    end
end

----------------------------
-- New day night system based on season
----------------------------

function ssEnvironment:setupDayNight()
    -- Calculate some constants for the daytime calculator
    self.sunRad = self.latitude * math.pi / 180
    self.pNight = 6 * math.pi / 180 -- Suns inclination below the horizon for 'civil twilight'
    self.pDay = -10 * math.pi / 180 -- Suns inclination above the horizon for 'daylight' assumed to be one degree above horizon

    -- Update time before game start to prevent sudden change of darkness
    self:adaptTime()
end

-- Change the night/day times according to season
function ssEnvironment:adaptTime()
    local env = g_currentMission.environment
    julianDay = ssUtil.julianDay(self:currentDay())

    -- All local values are in minutes
    local dayStart, dayEnd, nightEnd, nightStart = self:calculateStartEndOfDay(julianDay)

    -- Restrict the values to prevent errors
    nightEnd = math.max(nightEnd, 1.01) -- nightEnd > 1.0
    if dayStart == dayEnd then
        dayEnd = dayEnd + 0.01
    end
    nightStart = math.min(nightStart, 22.99) -- nightStart < 23

    -- GIANTS values:
    -- nightEnd: 4
    --  - nightEnd (sun): 5.5
    -- dayStart: 9
    -- dayEnd: 17
    --  - nightStart (sun): 21
    -- nightStart: 22

    -- This is for the logical night. Used for turning on lights in houses / streets.
    -- 0.3 and 0.8 determined using vanilla values
    env.nightEnd = Utils.lerp(nightEnd, dayStart, 0.35) * 60
    env.nightStart = Utils.lerp(dayEnd, nightStart, 0.5) * 60

    env.skyDayTimeStart = dayStart * 60 * 60 * 1000
    env.skyDayTimeEnd = dayEnd * 60 * 60 * 1000

    -- For the visual looks
    env.skyCurve = self:generateSkyCurve(nightEnd, dayStart, dayEnd, nightStart)
    env.ambientCurve = self:generateAmbientCurve(nightEnd, dayStart, dayEnd, nightStart)
    env.sunRotCurve = self:generateSunRotCurve(nightEnd, dayStart, dayEnd, nightStart)
    env.sunColorCurve = self:generateSunColorCurve(nightEnd, dayStart, dayEnd, nightStart)
    env.distanceFogCurve = self:generateDistanceFogCurve(nightEnd, dayStart, dayEnd, nightStart)
    env.rainFadeCurve = self:generateRainFadeCurve(nightEnd, dayStart, dayEnd, nightStart)

    env.sunHeightAngle = self:calculateSunHeightAngle(julianDay)
end

-- Output in hours
function ssEnvironment:calculateStartEndOfDay(julianDay)
    local dayStart, dayEnd, theta, eta

    -- Calculate the day
    dayStart, dayEnd = self:_calculateDay(self.pDay, julianDay)

    -- True blackness
    nightStart, nightEnd = self:_calculateDay(self.pNight, julianDay)

    return dayStart, dayEnd, nightStart, nightEnd
end

function ssEnvironment:_calculateDay(p, julianDay)
    local timeStart, timeEnd
    local D = 0, offset, hasDST
    local eta = self:calculateSunDeclination(julianDay)

    local gamma = (math.sin(p) + math.sin(self.sunRad) * math.sin(eta)) / (math.cos(self.sunRad) * math.cos(eta))

    -- Account for polar day and night
    if gamma < -1 then
        D = 0
    elseif gamma > 1 then
        D = 24
    else
        D = 24 - 24 / math.pi * math.acos(gamma)
    end

    -- Daylight saving between 1 April and 31 October as an approcimation
    -- local hasDST = not ((julianDay < 91 or julianDay > 304) or ((julianDay >= 91 and julianDay <= 304) and (gamma < -1 or gamma > 1)))
    -- offset = hasDST and 1 or 0
    offset = 1

    timeStart = 12 - D / 2 + offset
    timeEnd = 12 + D / 2 + offset

    return timeStart, timeEnd
end

function ssEnvironment:calculateSunHeightAngle(julianDay)
    -- Calculate the angle between the sun and the horizon
    local sunHeightAngle = self:calculateSunDeclination(julianDay-176) - (90 - self.latitude)*math.pi/180

    return sunHeightAngle
end

function ssEnvironment:calculateSunDeclination(julianDay)
    -- Calculate the suns declination
    local theta = 0.216 + 2 * math.atan(0.967 * math.tan(0.0086 * (julianDay + 186)))
    local eta = math.asin(0.4 * math.cos(theta))

    return eta
end

function ssEnvironment:generateAmbientCurve(nightEnd, dayStart, dayEnd, nightStart)
    local curve = AnimCurve:new(linearInterpolator3) -- degree 2

    local morningStep = (dayStart - nightEnd) / 5
    local eveningStep = (nightStart - dayEnd) / 5

    curve:addKeyframe({x = 0.020, y = 0.020, z = 0.032, time = 0.00 * 60})
    curve:addKeyframe({x = 0.020, y = 0.020, z = 0.032, time = (nightEnd - 0.25 * morningStep) * 60})
    curve:addKeyframe({x = 0.065, y = 0.065, z = 0.075, time = (nightEnd + 0.01) * 60}) -- light up ambient to compensate for switch to sunlight
    curve:addKeyframe({x = 0.065, y = 0.065, z = 0.075, time = (nightEnd + 0.02) * 60})
    curve:addKeyframe({x = 0.040, y = 0.040, z = 0.060, time = (nightEnd + 0.25 * morningStep) * 60}) -- back to regular ambient settings
    curve:addKeyframe({x = 0.080, y = 0.080, z = 0.140, time = (nightEnd + 1 * morningStep) * 60})
    curve:addKeyframe({x = 0.140, y = 0.140, z = 0.120, time = (nightEnd + 2 * morningStep) * 60})
    curve:addKeyframe({x = 0.200, y = 0.200, z = 0.200, time = dayStart * 60})

    curve:addKeyframe({x = 0.200, y = 0.200, z = 0.200, time = dayEnd * 60})
    curve:addKeyframe({x = 0.160, y = 0.140, z = 0.160, time = (dayEnd + 1 * eveningStep) * 60})
    curve:addKeyframe({x = 0.020, y = 0.020, z = 0.032, time = (dayEnd + 4 * eveningStep) * 60}) -- ambient night
    curve:addKeyframe({x = 0.024, y = 0.024, z = 0.036, time = (nightStart - 0.15 * eveningStep) * 60})
    curve:addKeyframe({x = 0.072, y = 0.072, z = 0.088, time = (nightStart + 0.01) * 60}) -- light up ambient to compensate for switch to moonlight
    curve:addKeyframe({x = 0.072, y = 0.072, z = 0.088, time = (nightStart + 0.02) * 60})
    curve:addKeyframe({x = 0.020, y = 0.020, z = 0.032, time = (nightStart + 0.15 * eveningStep) * 60}) -- back to regular ambient settings
    curve:addKeyframe({x = 0.020, y = 0.020, z = 0.032, time = 24.00 * 60})

    return curve
end

function ssEnvironment:generateSunColorCurve(nightEnd, dayStart, dayEnd, nightStart)
    local curve = AnimCurve:new(linearInterpolator3) -- degree 2

    local morningStep = (dayStart - nightEnd) / 5
    local eveningStep = (nightStart - dayEnd) / 5

    curve:addKeyframe({x = 0.060, y = 0.070, z = 0.150, time = 0.00 * 60})
    curve:addKeyframe({x = 0.060, y = 0.070, z = 0.150, time = (nightEnd - 0.25 * morningStep) * 60})
    curve:addKeyframe({x = 0.000, y = 0.000, z = 0.000, time = (nightEnd + 0.01) * 60}) -- shift to brief complete darkness for switch to sunlight
    curve:addKeyframe({x = 0.000, y = 0.000, z = 0.000, time = (nightEnd + 0.02) * 60})
    curve:addKeyframe({x = 0.060, y = 0.050, z = 0.030, time = (nightEnd + 0.25 * morningStep) * 60})
    curve:addKeyframe({x = 0.700, y = 0.450, z = 0.350, time = (nightEnd + 2 * morningStep) * 60}) -- lighten, red
    curve:addKeyframe({x = 1.100, y = 0.850, z = 0.600, time = (nightEnd + 3 * morningStep) * 60}) -- shift to orange
    curve:addKeyframe({x = 0.750, y = 0.750, z = 0.750, time = dayStart * 60})

    curve:addKeyframe({x = 0.750, y = 0.750, z = 0.750, time = dayEnd * 60})
    curve:addKeyframe({x = 0.750, y = 0.700, z = 0.650, time = (dayEnd + 1 * eveningStep) * 60}) -- darken
    curve:addKeyframe({x = 1.000, y = 0.900, z = 0.300, time = (dayEnd + 2 * eveningStep) * 60}) -- orange sunset
    curve:addKeyframe({x = 0.900, y = 0.400, z = 0.100, time = (dayEnd + 3 * eveningStep) * 60}) -- shift to red
    curve:addKeyframe({x = 0.300, y = 0.250, z = 0.500, time = (dayEnd + 4 * eveningStep) * 60}) -- shift to blue
    curve:addKeyframe({x = 0.050, y = 0.060, z = 0.100, time = (nightStart - 0.15 * eveningStep) * 60})
    curve:addKeyframe({x = 0.000, y = 0.000, z = 0.000, time = (nightStart + 0.01) * 60}) -- shift to brief complete darkness for switch to moonlight
    curve:addKeyframe({x = 0.000, y = 0.000, z = 0.000, time = (nightStart + 0.02) * 60})
    curve:addKeyframe({x = 0.050, y = 0.060, z = 0.100, time = (nightStart + 0.15 * eveningStep) * 60})
    curve:addKeyframe({x = 0.060, y = 0.070, z = 0.150, time = 24.00 * 60}) -- shift to bluish darkness

    return curve
end

function ssEnvironment:generateSkyCurve(nightEnd, dayStart, dayEnd, nightStart)
    local curve = AnimCurve:new(linearInterpolator4) -- degree 2

    local morningStep = (dayStart - nightEnd) / 10
    local eveningStep = (nightStart - dayEnd) / 5

    -- The sum of the 4 elements should always be 1
    -- x = daySky, y = eveningSky, z = nightSky, w = morningSky
    -- 4.5 -> 5.5 -> 6.0 = night morning transition
    -- 6.0 -> 7.0 -> 8.0 = morning day transition
    curve:addKeyframe({x = 0.0, y = 0.0, z = 1.0, w = 0.0, time = 0.0 * 60}) -- night
    curve:addKeyframe({x = 0.0, y = 0.0, z = 1.0, w = 0.0, time = (nightEnd + 1 * morningStep) * 60}) -- night
    curve:addKeyframe({x = 0.0, y = 0.0, z = 0.5, w = 0.5, time = (nightEnd + 3 * morningStep) * 60}) -- night/morning
    curve:addKeyframe({x = 0.0, y = 0.0, z = 0.0, w = 1.0, time = (nightEnd + 4 * morningStep) * 60}) -- morning
    curve:addKeyframe({x = 0.5, y = 0.0, z = 0.0, w = 0.5, time = (nightEnd + 6 * morningStep) * 60}) -- morning/day
    curve:addKeyframe({x = 1.0, y = 0.0, z = 0.0, w = 0.0, time = (nightEnd + 8 * morningStep) * 60}) -- day

    curve:addKeyframe({x = 1.0, y = 0.0, z = 0.0, w = 0.0, time = dayEnd * 60}) -- day
    curve:addKeyframe({x = 0.0, y = 1.0, z = 0.0, w = 0.0, time = (dayEnd + 2 * eveningStep) * 60}) -- evening
    curve:addKeyframe({x = 0.0, y = 1.0, z = 0.0, w = 0.0, time = (dayEnd + 3 * eveningStep) * 60}) -- evening
    curve:addKeyframe({x = 0.0, y = 0.0, z = 1.0, w = 0.0, time = nightStart * 60}) -- night
    curve:addKeyframe({x = 0.0, y = 0.0, z = 1.0, w = 0.0, time = 24.0 * 60}) -- night

    return curve
end

function ssEnvironment:generateRainFadeCurve(nightEnd, dayStart, dayEnd, nightStart)
    local curve = AnimCurve:new(linearInterpolator4) -- degree 2

    local morningStep = (dayStart - nightEnd) / 10
    local eveningStep = (nightStart - dayEnd) / 5

    -- light scale, rain sky scale, rain scale, distance fog scale
    curve:addKeyframe({x = 1.00, y = 0.0, z = 0.0, w = 0.00, time = 0})
    -- 1, 0.6, 0.55, 0.55, 0.55
    curve:addKeyframe({x = 0.60, y = 0.5, z = 0.0, w = 0.35, time = 10})
    curve:addKeyframe({x = 0.55, y = 1.0, z = 0.0, w = 0.70, time = 20})
    curve:addKeyframe({x = 0.55, y = 1.0, z = 0.5, w = 1.00, time = 25})
    curve:addKeyframe({x = 0.55, y = 1.0, z = 1.0, w = 1.00, time = 30})

    return curve
end

function ssEnvironment:generateSunRotCurve(nightEnd, dayStart, dayEnd, nightStart)
    local curve = AnimCurve:new(linearInterpolator1) -- degree 2

    curve:addKeyframe({v = Utils.degToRad(-15), time = 0.00 * 60}) -- start (moon)
    curve:addKeyframe({v = Utils.degToRad(  0), time = 1.00 * 60}) -- 15 per hour
    curve:addKeyframe({v = Utils.degToRad( 45), time = nightEnd * 60}) -- 15 per hour
    curve:addKeyframe({v = Utils.degToRad( 45), time = (nightEnd + 0.01) * 60})
    curve:addKeyframe({v = Utils.degToRad(-70), time = (nightEnd + 0.02) * 60}) -- switch to Sun

    if dayStart > 12.0 then
        curve:addKeyframe({v = Utils.degToRad(0), time = dayStart * 60}) -- rotate over the day
    else
        curve:addKeyframe({v = Utils.degToRad(0), time = 12.00 * 60}) -- rotate over the day
    end

    curve:addKeyframe({v = Utils.degToRad( 70), time = (nightStart + 0.01) * 60}) -- end rotation of sun
    curve:addKeyframe({v = Utils.degToRad(-35), time = (nightStart + 0.02) * 60}) -- switch to moon light
    curve:addKeyframe({v = Utils.degToRad(-15), time = 24.00 * 60}) -- 10 per hour

    return curve
end

function ssEnvironment:generateDistanceFogCurve(nightEnd, dayStart, dayEnd, nightStart)
    local curve = AnimCurve:new(linearInterpolator4) -- degree 2

    local ex = function(rgb)
        return (rgb/255)^2.2
    end

    local morningStep = (dayStart - nightEnd) / 5
    local eveningStep = (nightStart - dayEnd) / 5

    -- Nothing at night (darkness)
    -- When dawn, go red-ish. At 8AM go blue (compensate), at 9AM blue but less intense
    -- Do reverse in the evening,
    curve:addKeyframe({x = 0, y = 0, z = 0, w = 0.003, time = 0 * 60}) -- night
    curve:addKeyframe({x = ex(010), y = ex(012), z = ex(015), w = 0.0008, time = (nightEnd + 1 * morningStep) * 60})
    curve:addKeyframe({x = ex(085), y = ex(060), z = ex(055), w = 0.0006, time = (nightEnd + 2 * morningStep) * 60})
    curve:addKeyframe({x = ex(085), y = ex(070), z = ex(065), w = 0.0005, time = (nightEnd + 3 * morningStep) * 60})
    curve:addKeyframe({x = ex(105), y = ex(130), z = ex(150), w = 0.0006, time = (nightEnd + 4 * morningStep) * 60})
    curve:addKeyframe({x = ex(105), y = ex(130), z = ex(150), w = 0.0003, time = dayStart * 60})

    curve:addKeyframe({x = ex(105), y = ex(130), z = ex(150), w = 0.0003, time = dayEnd * 60})
    curve:addKeyframe({x = ex(070), y = ex(045), z = ex(030), w = 0.0004, time = (dayEnd + 2 * eveningStep) * 60})
    curve:addKeyframe({x = ex(045), y = ex(040), z = ex(050), w = 0.0006, time = (dayEnd + 3 * eveningStep) * 60})
    curve:addKeyframe({x = ex(020), y = ex(020), z = ex(030), w = 0.0008, time = (dayEnd + 4 * eveningStep) * 60})
    curve:addKeyframe({x = 0, y = 0, z = 0, w = 0.003, time = nightStart * 60}) -- night

    return curve
end

----------------------------
-- Events
----------------------------

function ssEnvironment:dayChanged()
    -- Update the time of the day
    self:adaptTime()

    self:callListeners()
end

----------------------------
-- Tools
----------------------------

-- Get the current day number.
-- Always use this function when working with seasons, because it uses the offset
-- for keeping in the correct season when changing season length
function ssEnvironment:currentDay()
    return g_currentMission.environment.currentDay + self.currentDayOffset
end

-- Starts with 0
function ssEnvironment:currentSeason()
    return self:seasonAtDay(self:currentDay())
end

-- Starts with 0
function ssEnvironment:seasonAtDay(dayNumber)
    return math.fmod(math.floor((dayNumber - 1) / self.daysInSeason), self.SEASONS_IN_YEAR)
end

-- Retuns month number based on dayNumber
function ssEnvironment:monthAtDay(dayNumber)
    return self:monthAtGrowthTransitionNumber(self:growthTransitionAtDay(dayNumber))
end

function ssEnvironment:monthAtGrowthTransitionNumber(growthTransitionNumber)
    local monthNumber = math.fmod( growthTransitionNumber, self.MONTHS_IN_YEAR) + 2
    if monthNumber > 12 then --because 11 becomes 13 TODO: brain gone  need to improve
        monthNumber = 1
    end

    return monthNumber
end

-- Returns 1-daysInSeason
function ssEnvironment:dayInSeason(currentDay)
    if (currentDay == nil) then
        currentDay = self:currentDay()
    end

    local season = self:seasonAtDay(currentDay) -- 0-3
    local dayInYear = math.fmod(currentDay - 1, self.daysInSeason * self.SEASONS_IN_YEAR) + 1 -- 1+
    return (dayInYear - 1 - season * self.daysInSeason) + 1 -- 1-daysInSeason
end

-- Starts with 0
function ssEnvironment:currentYear()
    return self:yearAtDay(self:currentDay())
end

-- Starts with 0
function ssEnvironment:yearAtDay(dayNumber)
    return math.floor((dayNumber - 1) / (self.daysInSeason * self.SEASONS_IN_YEAR))
end

function ssEnvironment:nextGrowthTransition()
    local cGT = self:growthTransitionAtDay()
    if cGT == 12 then
        return 1
    else
        return cGT+1
    end
end

--uses currentDay if dayNumber not passed in
function ssEnvironment:growthTransitionAtDay(dayNumber)
    if (dayNumber == nil) then
        dayNumber = self:currentDay()
    end

    local season = self:seasonAtDay(dayNumber)
    local cGS = self:currentGrowthStage(dayNumber)
    return (cGS + (season*3))
end


function ssEnvironment:currentGrowthStage(currentDay)
    if (currentDay == nil) then
        currentDay = self:currentDay()
    end

    -- Length of a state
    local l = self.daysInSeason / 3.0
    local dayInSeason = self:dayInSeason(currentDay)

    if dayInSeason >= mathRound(2 * l) + 1 then -- Turn 3
        return 3
    elseif dayInSeason >= mathRound(1 * l) + 1 then -- Turn 2
        return 2
    else
        return 1
    end

    return nil
end

-- Called when the number of days in a season needs to be changed.
-- A complex algorithm
function ssEnvironment:changeDaysInSeason(newSeasonLength) --15
    local oldSeasonLength = self.daysInSeason -- 6 ELIM
    local actualCurrentDay = self:currentDay() -- 9

    local year = self:currentYear(actualCurrentDay) -- 11 ELIM
    local season = self:currentSeason(actualCurrentDay) -- 12, 18
    local dayInSeason = self:dayInSeason(actualCurrentDay) -- 13 ELIM

    local seasonThatWouldBe = math.fmod(math.floor((actualCurrentDay - 1) / newSeasonLength), self.SEASONS_IN_YEAR) -- 16

    local dayThatNeedsToBe = math.floor((dayInSeason - 1) / oldSeasonLength * newSeasonLength) + 1 -- 19

    local realDifferenceInSeason = season - seasonThatWouldBe -- 21 ELIM

    local relativeYearThatNeedsTobe = realDifferenceInSeason < 0 and 1 or 0 -- 23

    local resultingDayNumber = ((year + relativeYearThatNeedsTobe) * self.SEASONS_IN_YEAR + season) * newSeasonLength + dayThatNeedsToBe -- 26
    local resultingOffset = resultingDayNumber - actualCurrentDay -- 27
    local newOffset = math.fmod(self.currentDayOffset + resultingOffset, self.SEASONS_IN_YEAR * newSeasonLength) -- 28

    self.daysInSeason = newSeasonLength
    self.currentDayOffset = newOffset

    -- Re-do time
    self:adaptTime()

    -- Call season length changed listeners
    for _, listener in pairs(self.seasonLengthChangeListeners) do
        listener:seasonLengthChanged()
    end
end
