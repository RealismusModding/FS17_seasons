----------------------------------------------------------------------------------------------------
-- DAYLIGHT
----------------------------------------------------------------------------------------------------
-- Purpose:  Adjust day/night system
-- Authors:  Rahkiin, reallogger
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssDaylight = {}
g_seasons.daylight = ssDaylight

function ssDaylight:loadMap(name)
    -- Add day change listener to handle new dayNight system and new events
    g_currentMission.environment:addDayChangeListener(self)
    g_seasons.environment:addVisualSeasonChangeListener(self)

    self.data = {}
    self.latitude = 51.9

    self:loadFromXML(g_seasons.modDir .. "data/daylight.xml")

    -- Modded
    for _, path in ipairs(g_seasons:getModPaths("daylight")) do
        self:loadFromXML(path)
    end

    if g_currentMission:getIsServer() then
        self:setupDayNight()
    end
end

function ssDaylight:readStream()
    self:setupDayNight()
end

function ssDaylight:loadFromXML(path)
    local file = loadXMLFile("daylight", path)

    self.latitude = Utils.clamp(ssXMLUtil.getFloat(file, "daylight.latitude", self.latitude), 0, 70)

    local curves = {
        ["ambient"] = {3, 16},
        ["sunColor"] = {3, 18},
        ["distanceFog"] = {4, 11},
        -- volumeFog 3
        ["dustDensity"] = {1, 9}
    }

    for seasonName, seasonId in pairs(g_seasons.util.seasonKeyToId) do
        for curve, num in pairs(curves) do
            local key = string.format("daylight.seasons.%s.%s", seasonName, curve)

            if self.data[curve] == nil then
                self.data[curve] = {}
            end

            self.data[curve][seasonId] = Utils.getNoNil(self:loadCurveFromXML(file, key, num[1], num[2]), self.data[curve][seasonId])
        end
    end

    delete(file)
end

function ssDaylight:loadCurveFromXML(file, key, numDims, numKeys)
    local data = {}
    local names = {"x", "y", "z", "w"}

    local i = 0
    while true do
        local skey = string.format("%s.key(%d)", key, i)
        if not hasXMLProperty(file, skey) then break end

        local values = Utils.splitString(" ", ssXMLUtil.getString(file, skey .. "#values", nil))
        local result = {}

        if numDims == 1 then
            result.v = Utils.evaluateFormula(values[1])
        else
            for j = 1, numDims do
                result[names[j]] = Utils.evaluateFormula(values[j])
            end
        end

        data[i + 1] = result;

        i = i + 1
    end

    if table.getn(data) == numKeys then
        return data
    end

    return nil
end

----------------------------
-- New day night system based on season
----------------------------

function ssDaylight:setupDayNight()
    -- Calculate some constants for the daytime calculator
    self.sunRad = self.latitude * math.pi / 180
    self.pNight = 6 * math.pi / 180 -- Suns inclination below the horizon for 'civil twilight'
    self.pDay = -10 * math.pi / 180 -- Suns inclination above the horizon for 'daylight' assumed to be one degree above horizon

    -- Update time before game start to prevent sudden change of darkness
    self:adaptTime()
end

-- Change the night/day times according to season
function ssDaylight:adaptTime()
    local env = g_currentMission.environment
    julianDay = ssUtil.julianDay(g_seasons.environment:currentDay())

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
    local season = g_seasons.environment:currentVisualSeason()

    env.skyCurve = self:generateSkyCurve(season, nightEnd, dayStart, dayEnd, nightStart)
    env.ambientCurve = self:generateAmbientCurve(season, nightEnd, dayStart, dayEnd, nightStart)
    env.sunRotCurve = self:generateSunRotCurve(season, nightEnd, dayStart, dayEnd, nightStart)
    env.sunColorCurve = self:generateSunColorCurve(season, nightEnd, dayStart, dayEnd, nightStart)
    env.distanceFogCurve = self:generateDistanceFogCurve(season, nightEnd, dayStart, dayEnd, nightStart)
    env.rainFadeCurve = self:generateRainFadeCurve(season, nightEnd, dayStart, dayEnd, nightStart)
    env.dustDensityCurve = self:generateDustDensityCurve(season, nightEnd, dayStart, dayEnd, nightStart)

    env.sunHeightAngle = self:calculateSunHeightAngle(julianDay)
end

-- Output in hours
function ssDaylight:calculateStartEndOfDay(julianDay)
    local dayStart, dayEnd, theta, eta

    -- Calculate the day
    dayStart, dayEnd = self:_calculateDay(self.pDay, julianDay)

    -- True blackness
    nightStart, nightEnd = self:_calculateDay(self.pNight, julianDay)

    return dayStart, dayEnd, nightStart, nightEnd
end

function ssDaylight:_calculateDay(p, julianDay)
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

function ssDaylight:calculateSunHeightAngle(julianDay)
    -- Calculate the angle between the sun and the horizon
    if self.latitude < 0 then
        -- for southern hemisphere
        return self:calculateSunDeclination(julianDay - 176) + (90 + self.latitude) * math.pi / 180
    else
        -- for northern hemisphere
        return self:calculateSunDeclination(julianDay - 176) - (90 - self.latitude) * math.pi / 180
end

function ssDaylight:calculateSunDeclination(julianDay)
    -- Calculate the suns declination
    local theta = 0.216 + 2 * math.atan(0.967 * math.tan(0.0086 * (julianDay + 186)))
    local eta = math.asin(0.4 * math.cos(theta))

    return eta
end

----------------------------
-- Curve generators
----------------------------

function addKeyframeTime(curve, data, time)
    data.time = time

    curve:addKeyframe(data)
end

function ssDaylight:generateAmbientCurve(season, nightEnd, dayStart, dayEnd, nightStart)
    local curve = AnimCurve:new(linearInterpolator3) -- degree 2

    local morningStep = (dayStart - nightEnd) / 5
    local eveningStep = (nightStart - dayEnd) / 5

    local data = self.data.ambient[season]

    addKeyframeTime(curve, data[1], 0.00 * 60)
    addKeyframeTime(curve, data[2], (nightEnd - 0.25 * morningStep) * 60)
    addKeyframeTime(curve, data[3], (nightEnd + 0.01) * 60) -- light up ambient to compensate for switch to sunlight
    addKeyframeTime(curve, data[4], (nightEnd + 0.02) * 60)
    addKeyframeTime(curve, data[5], (nightEnd + 0.25 * morningStep) * 60) -- back to regular ambient settings
    addKeyframeTime(curve, data[6], (nightEnd + 1 * morningStep) * 60) --5
    addKeyframeTime(curve, data[7], (nightEnd + 2 * morningStep) * 60) --6
    addKeyframeTime(curve, data[8], dayStart * 60) --9

    addKeyframeTime(curve, data[9], dayEnd * 60) --17
    addKeyframeTime(curve, data[10], (dayEnd + 1 * eveningStep) * 60) --18
    addKeyframeTime(curve, data[11], (dayEnd + 4 * eveningStep) * 60) -- ambient night 21
    addKeyframeTime(curve, data[12], (nightStart - 0.15 * eveningStep) * 60)
    addKeyframeTime(curve, data[13], (nightStart + 0.01) * 60) -- light up ambient to compensate for switch to moonlight
    addKeyframeTime(curve, data[14], (nightStart + 0.02) * 60)
    addKeyframeTime(curve, data[15], (nightStart + 0.15 * eveningStep) * 60) -- back to regular ambient settings -- 22.15
    addKeyframeTime(curve, data[16], 24.00 * 60)

    return curve
end

function ssDaylight:generateSunColorCurve(season, nightEnd, dayStart, dayEnd, nightStart)
    local curve = AnimCurve:new(linearInterpolator3) -- degree 2

    local morningStep = (dayStart - nightEnd) / 5
    local eveningStep = (nightStart - dayEnd) / 5

    local data = self.data.sunColor[season]

    addKeyframeTime(curve, data[1], 0.00 * 60)
    addKeyframeTime(curve, data[2], (nightEnd - 0.25 * morningStep) * 60)
    addKeyframeTime(curve, data[3], (nightEnd + 0.01) * 60) -- shift to brief complete darkness for switch to sunlight
    addKeyframeTime(curve, data[4], (nightEnd + 0.02) * 60)
    addKeyframeTime(curve, data[5], (nightEnd + 0.25 * morningStep) * 60)
    addKeyframeTime(curve, data[6], (nightEnd + 2 * morningStep) * 60) -- lighten, red
    addKeyframeTime(curve, data[7], (nightEnd + 3 * morningStep) * 60) -- shift to orange
    addKeyframeTime(curve, data[8], dayStart * 60)

    addKeyframeTime(curve, data[9], dayEnd * 60)
    addKeyframeTime(curve, data[10], (dayEnd + 1 * eveningStep) * 60) -- darken
    addKeyframeTime(curve, data[11], (dayEnd + 2 * eveningStep) * 60) -- orange sunset
    addKeyframeTime(curve, data[12], (dayEnd + 3 * eveningStep) * 60) -- shift to red
    addKeyframeTime(curve, data[13], (dayEnd + 4 * eveningStep) * 60) -- shift to blue
    addKeyframeTime(curve, data[14], (nightStart - 0.15 * eveningStep) * 60)
    addKeyframeTime(curve, data[15], (nightStart + 0.01) * 60) -- shift to brief complete darkness for switch to moonlight
    addKeyframeTime(curve, data[16], (nightStart + 0.02) * 60)
    addKeyframeTime(curve, data[17], (nightStart + 0.15 * eveningStep) * 60)
    addKeyframeTime(curve, data[18], 24.00 * 60) -- shift to bluish darkness

    return curve
end

function ssDaylight:generateSkyCurve(season, nightEnd, dayStart, dayEnd, nightStart)
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

function ssDaylight:generateRainFadeCurve(season, nightEnd, dayStart, dayEnd, nightStart)
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

function ssDaylight:generateSunRotCurve(season, nightEnd, dayStart, dayEnd, nightStart)
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

function ssDaylight:generateDistanceFogCurve(season, nightEnd, dayStart, dayEnd, nightStart)
    local curve = AnimCurve:new(linearInterpolator4) -- degree 2

    local ex = function(rgb)
        return (rgb / 255) ^ 2.2
    end

    local morningStep = (dayStart - nightEnd) / 5
    local eveningStep = (nightStart - dayEnd) / 5

    local data = self.data.distanceFog[season]

    -- Nothing at night (darkness)
    -- When dawn, go red-ish. At 8AM go blue (compensate), at 9AM blue but less intense
    -- Do reverse in the evening,
    addKeyframeTime(curve, data[1], 0 * 60) -- night
    addKeyframeTime(curve, data[2], (nightEnd + 1 * morningStep) * 60)
    addKeyframeTime(curve, data[3], (nightEnd + 2 * morningStep) * 60)
    addKeyframeTime(curve, data[4], (nightEnd + 3 * morningStep) * 60)
    addKeyframeTime(curve, data[5], (nightEnd + 4 * morningStep) * 60)
    addKeyframeTime(curve, data[6], dayStart * 60)

    addKeyframeTime(curve, data[7], dayEnd * 60)
    addKeyframeTime(curve, data[8], (dayEnd + 2 * eveningStep) * 60)
    addKeyframeTime(curve, data[9], (dayEnd + 3 * eveningStep) * 60)
    addKeyframeTime(curve, data[10], (dayEnd + 4 * eveningStep) * 60)
    addKeyframeTime(curve, data[11], nightStart * 60) -- night

    return curve
end

function ssDaylight:generateDustDensityCurve(season, nightEnd, dayStart, dayEnd, nightStart)
    local curve = AnimCurve:new(linearInterpolator1)

    local morningStep = (dayStart - nightEnd) / 10
    local eveningStep = (nightStart - dayEnd) / 5

    local data = self.data.dustDensity[season]

    addKeyframeTime(curve, data[1], 0 * 60)
    addKeyframeTime(curve, data[2], (nightEnd + 2 * morningStep) * 60)
    addKeyframeTime(curve, data[3], (nightEnd + 7.5 * morningStep) * 60)
    addKeyframeTime(curve, data[4], (nightEnd + 8 * morningStep) * 60)
    addKeyframeTime(curve, data[5], dayStart * 60)
    addKeyframeTime(curve, data[6], (dayEnd + 1 * eveningStep) * 60)
    addKeyframeTime(curve, data[7], (dayEnd + 2 * eveningStep) * 60)
    addKeyframeTime(curve, data[8], (dayEnd + 3.25 * eveningStep) * 60)
    addKeyframeTime(curve, data[9], 24 * 60)

    return curve
end

----------------------------
-- Events
----------------------------

function ssDaylight:dayChanged()
    -- Update the time of the day
    self:adaptTime()
end

function ssDaylight:visualSeasonChanged()
    self:adaptTime()
end

-- function to calculate solar radiation
function ssDaylight:calculateSolarRadiation()
    -- http://swat.tamu.edu/media/1292/swat2005theory.pdf
    local dayTime = g_currentMission.environment.dayTime / 60 / 60 / 1000 --current time in hours

    local julianDay = ssUtil.julianDay(g_seasons.environment:currentDay())
    local eta = self:calculateSunDeclination(julianDay)
    local sunHeightAngle = self:calculateSunHeightAngle(julianDay)
    local sunZenithAngle = math.pi / 2 + sunHeightAngle --sunHeightAngle always negative due to FS convention

    dayStart, dayEnd, _, _ = self:calculateStartEndOfDay(julianDay)

    local lengthDay = dayEnd - dayStart
    local midDay = dayStart + lengthDay / 2

    local solarRadiation = 0
    local Isc = 4.921 --MJ / (m2 * h)

    if dayTime < dayStart or dayTime > dayEnd then
        -- no radiation before sun rises
        solarRadiation = 0

    else
        solarRadiation = Isc * math.cos(sunZenithAngle) * math.cos(( dayTime - midDay ) / ( lengthDay / 2 ))

    end

    -- lower solar radiation if it is overcast
    if g_currentMission.environment.timeSinceLastRain == 0 then
        local tmpSolRad = solarRadiation

        solarRadiation = tmpSolRad * 0.05
    end

    return solarRadiation
end
