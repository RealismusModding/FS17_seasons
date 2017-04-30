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

function ssDaylight:load(savegame, key)
    self.latitude = Utils.clamp(ssXMLUtil.getFloat(savegame, key .. ".environment.latitude", 51.9), 0, 72)
end

function ssDaylight:save(savegame, key)
    ssXMLUtil.setFloat(savegame, key .. ".environment.latitude", self.latitude)
end

function ssDaylight:loadMap(name)
    -- Add day change listener to handle new dayNight system and new events
    g_currentMission.environment:addDayChangeListener(self)


    if g_currentMission:getIsServer() then
        -- if server, do it here. Otherwise do it in :load
        self:setupDayNight()
    end
end

function ssDaylight:readStream(streamId, connection)
    self.latitude = streamReadFloat32(streamId)

    self:setupDayNight()
end

function ssDaylight:writeStream(streamId, connection)
    streamWriteFloat32(streamId, self.latitude)
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
    env.skyCurve = self:generateSkyCurve(nightEnd, dayStart, dayEnd, nightStart)
    env.ambientCurve = self:generateAmbientCurve(nightEnd, dayStart, dayEnd, nightStart)
    env.sunRotCurve = self:generateSunRotCurve(nightEnd, dayStart, dayEnd, nightStart)
    env.sunColorCurve = self:generateSunColorCurve(nightEnd, dayStart, dayEnd, nightStart)
    env.distanceFogCurve = self:generateDistanceFogCurve(nightEnd, dayStart, dayEnd, nightStart)
    env.rainFadeCurve = self:generateRainFadeCurve(nightEnd, dayStart, dayEnd, nightStart)

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
    local sunHeightAngle = self:calculateSunDeclination(julianDay - 176) - (90 - self.latitude) * math.pi / 180

    return sunHeightAngle
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

function ssDaylight:generateAmbientCurve(nightEnd, dayStart, dayEnd, nightStart)
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

function ssDaylight:generateSunColorCurve(nightEnd, dayStart, dayEnd, nightStart)
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

function ssDaylight:generateSkyCurve(nightEnd, dayStart, dayEnd, nightStart)
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

function ssDaylight:generateRainFadeCurve(nightEnd, dayStart, dayEnd, nightStart)
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

function ssDaylight:generateSunRotCurve(nightEnd, dayStart, dayEnd, nightStart)
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

function ssDaylight:generateDistanceFogCurve(nightEnd, dayStart, dayEnd, nightStart)
    local curve = AnimCurve:new(linearInterpolator4) -- degree 2

    local ex = function(rgb)
        return (rgb / 255) ^ 2.2
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

function ssDaylight:dayChanged()
    -- Update the time of the day
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
