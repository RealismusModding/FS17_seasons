----------------------------------------------------------------------------------------------------
-- WEATHER MANAGER SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  to create and manage the weather
-- Authors:  Rahkiin, reallogger, theSeb
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssWeatherManager = {}
g_seasons.weather = ssWeatherManager

ssWeatherManager.forecast = {} --day of week, low temp, high temp, weather condition
ssWeatherManager.forecastLength = 8
ssWeatherManager.weather = {}

-- Load events
source(g_seasons.modDir .. "src/events/ssWeatherManagerDailyEvent.lua")
source(g_seasons.modDir .. "src/events/ssWeatherManagerHourlyEvent.lua")
source(g_seasons.modDir .. "src/events/ssWeatherManagerHailEvent.lua")

function ssWeatherManager:load(savegame, key)
    -- Load or set default values
    self.snowDepth = ssXMLUtil.getFloat(savegame, key .. ".weather.snowDepth")
    self.soilTemp = ssXMLUtil.getFloat(savegame, key .. ".weather.soilTemp")
    self.soilTempMax = ssXMLUtil.getFloat(savegame, key .. ".weather.soilTempMax",self.soilTemp)
    self.prevHighTemp = ssXMLUtil.getFloat(savegame, key .. ".weather.prevHighTemp")
    self.cropMoistureContent = ssXMLUtil.getFloat(savegame, key .. ".weather.cropMoistureContent", 15.0)
    self.soilWaterContent = ssXMLUtil.getFloat(savegame, key .. ".weather.soilWaterContent", 0.1)
    self.moistureEnabled = ssXMLUtil.getBool(savegame, key .. ".weather.moistureEnabled", true)

    -- load forecast
    self.forecast = {}

    local i = 0
    while true do
        local dayKey = string.format("%s.weather.forecast.day(%i)", key, i)
        if not ssXMLUtil.hasProperty(savegame, dayKey) then break end

        local day = {}

        day.day = getXMLInt(savegame, dayKey .. "#day")
        day.season = g_seasons.environment:seasonAtDay(day.day)

        day.weatherState = getXMLString(savegame, dayKey .. "#weatherState")
        day.highTemp = getXMLFloat(savegame, dayKey .. "#highTemp")
        day.lowTemp = getXMLFloat(savegame, dayKey .. "#lowTemp")

        table.insert(self.forecast, day)
        i = i + 1
    end

    -- load rains
    self.weather = {}

    i = 0
    while true do
        local rainKey = string.format("%s.weather.forecast.rain(%i)", key, i)
        if not ssXMLUtil.hasProperty(savegame, rainKey) then break end

        local rain = {}

        rain.startDay = getXMLInt(savegame, rainKey .. "#startDay")
        rain.endDayTime = getXMLFloat(savegame, rainKey .. "#endDayTime")
        rain.startDayTime = getXMLFloat(savegame, rainKey .. "#startDayTime")
        rain.endDay = getXMLInt(savegame, rainKey .. "#endDay")
        rain.rainTypeId = getXMLString(savegame, rainKey .. "#rainTypeId")
        rain.duration = getXMLFloat(savegame, rainKey .. "#duration")

        table.insert(self.weather, rain)
        i = i + 1
    end
end

function ssWeatherManager:save(savegame, key)
    local i = 0

    ssXMLUtil.setFloat(savegame, key .. ".weather.snowDepth", self.snowDepth)
    ssXMLUtil.setFloat(savegame, key .. ".weather.soilTemp", self.soilTemp)
    ssXMLUtil.setFloat(savegame, key .. ".weather.soilTempMax", self.soilTempMax)
    ssXMLUtil.setFloat(savegame, key .. ".weather.prevHighTemp", self.prevHighTemp)
    ssXMLUtil.setFloat(savegame, key .. ".weather.cropMoistureContent", self.cropMoistureContent)
    ssXMLUtil.setFloat(savegame, key .. ".weather.soilWaterContent", self.soilWaterContent)
    ssXMLUtil.setBool(savegame, key .. ".weather.moistureEnabled", self.moistureEnabled)

    for i = 0, table.getn(self.forecast) - 1 do
        local dayKey = string.format("%s.weather.forecast.day(%i)", key, i)

        local day = self.forecast[i + 1]

        setXMLInt(savegame, dayKey .. "#day", day.day)
        setXMLString(savegame, dayKey .. "#weatherState", day.weatherState)
        setXMLFloat(savegame, dayKey .. "#highTemp", day.highTemp)
        setXMLFloat(savegame, dayKey .. "#lowTemp", day.lowTemp)
    end

    for i = 0, table.getn(self.weather) - 1 do
        local rainKey = string.format("%s.weather.forecast.rain(%i)", key, i)

        local rain = self.weather[i + 1]

        setXMLInt(savegame, rainKey .. "#startDay", rain.startDay)
        setXMLFloat(savegame, rainKey .. "#endDayTime", rain.endDayTime)
        setXMLFloat(savegame, rainKey .. "#startDayTime", rain.startDayTime)
        setXMLInt(savegame, rainKey .. "#endDay", rain.endDay)
        setXMLString(savegame, rainKey .. "#rainTypeId", rain.rainTypeId)
        setXMLFloat(savegame, rainKey .. "#duration", rain.duration)
    end
end

function ssWeatherManager:loadMap(name)
    Environment.calculateGroundWetness = Utils.overwrittenFunction(Environment.calculateGroundWetness, ssWeatherManager.calculateSoilWetness)

    g_currentMission.environment:addHourChangeListener(self)
    g_currentMission.environment:addDayChangeListener(self)
    g_seasons.environment:addSeasonLengthChangeListener(self)

    g_currentMission.environment.minRainInterval = 1
    g_currentMission.environment.minRainDuration = 2 * 60 * 60 * 1000 -- 30 hours
    g_currentMission.environment.maxRainInterval = 1
    g_currentMission.environment.maxRainDuration = 24 * 60 * 60 * 1000
    g_currentMission.environment.rainForecastDays = self.forecastLength
    g_currentMission.environment.autoRain = false

    -- Load data from the mod and from a map
    self.temperatureData = {}
    self.rainData = {}
    self.startValues = {}
    self:loadFromXML(g_seasons.modDir .. "data/weather.xml")

    -- Modded
    for _, path in ipairs(g_seasons:getModPaths("weather")) do
        self:loadFromXML(path)
    end

    -- Set snowDepth (can be more than 0 with custom weather)
    self.snowDepth = Utils.getNoNil(self.snowDepth, self.startValues.snowDepth)

    -- Load germination temperatures
    self.germinateTemp = {}
    self:loadGerminateTemperature(g_seasons.modDir .. "data/growth.xml")

    for _, path in ipairs(g_seasons:getModPaths("growth")) do
        self:loadGerminateTemperature(path)
    end

    if g_currentMission:getIsServer() then
        if table.getn(self.forecast) == 0 or self.forecast[1].day ~= g_seasons.environment:currentDay() then
            self:buildForecast()
        end
        --self.weather = g_currentMission.environment.rains -- should only be done for a fresh savegame, otherwise read from savegame

        self:overwriteRaintable()
        self:setupStartValues()
    end
end

function ssWeatherManager:loadGameFinished()
    if g_currentMission:getIsServer() then
        if g_seasons.isNewSavegame and self.snowDepth > 0 then
            g_seasons.snow:applySnow(self.snowDepth)
        end
    end
end

function ssWeatherManager:readStream(streamId, connection)
    self.snowDepth = streamReadFloat32(streamId)
    self.soilTemp = streamReadFloat32(streamId)
    self.soilTempMax = streamReadFloat32(streamId)
    self.cropMoistureContent = streamReadFloat32(streamId)
    self.moistureEnabled = streamReadBool(streamId)
    self.prevHighTemp = streamReadFloat32(streamId)
    self.soilWaterContent = streamReadFloat32(streamId)

    self.forecastLength = streamReadUInt8(streamId)
    local numRains = streamReadUInt8(streamId)

    -- load forecast
    self.forecast = {}

    for i = 1, self.forecastLength do
        local day = {}

        day.day = streamReadInt16(streamId)
        day.season = streamReadUInt8(streamId)

        day.weatherState = streamReadString(streamId)
        day.highTemp = streamReadFloat32(streamId)
        day.lowTemp = streamReadFloat32(streamId)

        table.insert(self.forecast, day)
    end

    -- load rains
    self.weather = {}

    for i = 1, numRains do
        local rain = {}

        rain.startDay = streamReadInt16(streamId)
        rain.endDayTime = streamReadFloat32(streamId)
        rain.startDayTime = streamReadFloat32(streamId)
        rain.endDay = streamReadInt16(streamId)
        rain.rainTypeId = streamReadString(streamId)
        rain.duration = streamReadFloat32(streamId)

        table.insert(self.weather, rain)
    end

    self:overwriteRaintable()
    self:setupStartValues()
end

function ssWeatherManager:writeStream(streamId, connection)
    streamWriteFloat32(streamId, self.snowDepth)
    streamWriteFloat32(streamId, self.soilTemp)
    streamWriteFloat32(streamId, self.soilTempMax)
    streamWriteFloat32(streamId, self.cropMoistureContent)
    streamWriteBool(streamId, self.moistureEnabled)
    streamWriteFloat32(streamId, self.prevHighTemp)
    streamWriteFloat32(streamId, self.soilWaterContent)

    streamWriteUInt8(streamId, table.getn(self.forecast))
    streamWriteUInt8(streamId, table.getn(self.weather))

    for _, day in pairs(self.forecast) do
        streamWriteInt16(streamId, day.day)
        streamWriteUInt8(streamId, day.season)

        streamWriteString(streamId, day.weatherState)
        streamWriteFloat32(streamId, day.highTemp)
        streamWriteFloat32(streamId, day.lowTemp)
    end

    for _, rain in pairs(self.weather) do
        streamWriteInt16(streamId, rain.startDay)
        streamWriteFloat32(streamId, rain.endDayTime)
        streamWriteFloat32(streamId, rain.startDayTime)
        streamWriteInt16(streamId, rain.endDay)
        streamWriteString(streamId, rain.rainTypeId)
        streamWriteFloat32(streamId, rain.duration)
    end
end

function ssWeatherManager:setupStartValues()
    if g_currentMission:getIsClient() then
        self.soilTemp = Utils.getNoNil(self.soilTemp, self.startValues.soilTemp)
        self.soilTempMax = self.soilTemp
    end
end

function ssWeatherManager:update(dt)
    local currentRain = g_currentMission.environment.currentRain

    if currentRain ~= nil then
        local currentTemp = mathRound(self:currentTemperature(), 0)

        -- If temperature is 1 or higher and it would be snowing, rain instead. Same for other way around
        if currentTemp > 1 and currentRain.rainTypeId == "snow" then
            setVisibility(g_currentMission.environment.rainTypeIdToType.snow.rootNode, false)
            currentRain.rainTypeId = "rain"
            setVisibility(g_currentMission.environment.rainTypeIdToType.rain.rootNode, true)
        elseif currentTemp < 0 and currentRain.rainTypeId == "rain" then
            setVisibility(g_currentMission.environment.rainTypeIdToType.rain.rootNode, false)
            currentRain.rainTypeId = "snow"
            setVisibility(g_currentMission.environment.rainTypeIdToType.snow.rootNode, true)
        end
    end
end

-- Only run this the very first time or if season length changes
function ssWeatherManager:buildForecast()
    local startDayNum = g_seasons.environment:currentDay()

    if self.prevHighTemp == nil then
        self.prevHighTemp = self.startValues.highAirTemp -- initial assumption high temperature during last day of winter.
    end

    self.forecast = {}
    self.weather = {}

    for n = 1, self.forecastLength do
        local oneDayForecast = {}
        local oneDayRain = {}
        local ssTmax = {}

        oneDayForecast.day = startDayNum + n - 1 -- To match forecast with actual game
        oneDayForecast.season = g_seasons.environment:seasonAtDay(oneDayForecast.day)

        ssTmax = self.temperatureData[g_seasons.environment:transitionAtDay(oneDayForecast.day)]

        oneDayForecast.highTemp = ssUtil.normDist(ssTmax.mode, 2.5)
        oneDayForecast.lowTemp = ssUtil.normDist(0, 2) + 0.75 * ssTmax.mode - 5

        if n == 1 then
            oneDayRain = self:updateRain(oneDayForecast, 0)
        else
            if oneDayForecast.day == self.weather[n - 1].endDay then
                oneDayRain = self:updateRain(oneDayForecast, self.weather[n - 1].endDayTime)
            else
                oneDayRain = self:updateRain(oneDayForecast, 0)
            end
        end

        oneDayForecast.weatherState = oneDayRain.rainTypeId

        table.insert(self.forecast, oneDayForecast)
        table.insert(self.weather, oneDayRain)
    end

    self:overwriteRaintable()
end

function ssWeatherManager:updateForecast()
    local dayNum = g_seasons.environment:currentDay() + self.forecastLength - 1
    local oneDayRain = {}

    self.prevHighTemp = self.forecast[1].highTemp  -- updating prev high temp before updating forecast table

    table.remove(self.forecast, 1)

    local oneDayForecast = {}
    local ssTmax = {}

    oneDayForecast.day = dayNum -- To match forecast with actual game
    oneDayForecast.season = g_seasons.environment:seasonAtDay(dayNum)

    ssTmax = self.temperatureData[g_seasons.environment:transitionAtDay(dayNum)]

    if self.forecast[self.forecastLength - 1].season == oneDayForecast.season then
        --Seasonal average for a day in the current season
        oneDayForecast.Tmaxmean = self.forecast[self.forecastLength - 1].Tmaxmean

    elseif self.forecast[self.forecastLength - 1].season ~= oneDayForecast.season then
        --Seasonal average for a day in the next season
        oneDayForecast.Tmaxmean = ssUtil.triDist(ssTmax)
    end

    oneDayForecast.highTemp = ssUtil.normDist(ssTmax.mode, 2.5)
    oneDayForecast.lowTemp = ssUtil.normDist(0, 2) + 0.75 * ssTmax.mode - 5

    if oneDayForecast.day == self.weather[self.forecastLength - 1].endDay then
        oneDayRain = self:updateRain(oneDayForecast, self.weather[self.forecastLength - 1].endDayTime)
    else
        oneDayRain = self:updateRain(oneDayForecast, 0)
    end

    oneDayForecast.weatherState = oneDayRain.rainTypeId

    table.insert(self.forecast, oneDayForecast)
    table.insert(self.weather, oneDayRain)
    table.remove(self.weather, 1)

    self:updateHail()
    self:overwriteRaintable()
    self:updateSoilTemp()

    g_server:broadcastEvent(ssWeatherManagerDailyEvent:new(oneDayForecast, oneDayRain, self.prevHighTemp, self.soilTemp))
end

function ssWeatherManager:seasonLengthChanged()
    if g_currentMission:getIsServer() then
        local isFrozen = self:isGroundFrozen()

        self:buildForecast()

        -- The new forecast is sent with the ssSettings event.
    end

    self.soilTempMax = self.soilTemp

end

function ssWeatherManager:dayChanged()
    if g_currentMission:getIsServer() then
        local isFrozen = self:isGroundFrozen()

        self:updateForecast()

        if isFrozen ~= self:isGroundFrozen() then
            -- Call a weather change
            for _, listener in pairs(g_currentMission.environment.weatherChangeListeners) do
                listener:weatherChanged()
            end
        end
    end

    if self.soilTemp > self.soilTempMax then
        self.soilTempMax = self.soilTemp
    end

end

-- Jos note: no randomness here. Must run on client for snow.
function ssWeatherManager:hourChanged()
    if g_currentMission:getIsServer() then
        local oldSnow = self.snowDepth

        self.meltedSnow = 0
        self:updateSnowDepth()

        if math.abs(oldSnow - self.snowDepth) > 0.01 then
            -- Call a weather change
            for _, listener in pairs(g_currentMission.environment.weatherChangeListeners) do
                listener:weatherChanged()
            end
        end

        self:updateCropMoistureContent()

        if not self:isGroundFrozen() then
            self:updateSoilWaterContent()
        end

        g_server:broadcastEvent(ssWeatherManagerHourlyEvent:new(self.cropMoistureContent, self.snowDepth, self.soilWaterContent))
    end
end

-- function to output the temperature during the day and night
function ssWeatherManager:diurnalTemp(hour, minute, lowTemp, highTemp, lowTempNext)
    local highTempPrev = 0

    -- need to have the high temp of the previous day
    -- hour is hour in the day from 0 to 23
    -- minute is minutes from 0 to 59

    if lowTemp == nil and highTemp == nil and lowTempNext == nil then
        lowTemp = self.forecast[1].lowTemp
        highTemp = self.forecast[1].highTemp
        lowTempNext = self.forecast[2].lowTemp
        highTempPrev = self.prevHighTemp
    else
        highTempPrev = highTemp
    end

    local currentTime = hour + minute / 60

    if currentTime < 7 then
        currentTemp = (math.cos(((currentTime + 9) / 16) * math.pi / 2)) ^ 2 * (highTempPrev - lowTemp) + lowTemp
    elseif currentTime > 15 then
        currentTemp = (math.cos(((currentTime - 15) / 16) * math.pi / 2)) ^ 2 * (highTemp - lowTempNext) + lowTempNext
    else
        currentTemp = (math.cos((1 - (currentTime -  7) / 8) * math.pi / 2) ^ 2) * (highTemp - lowTemp) + lowTemp
    end

    return currentTemp
end

--- function to keep track of snow accumulation
--- snowDepth in meters
function ssWeatherManager:updateSnowDepth()
    local currentRain = g_currentMission.environment.currentRain
    local currentTemp = self:currentTemperature()
    local effectiveMeltTemp = math.max(currentTemp, 0) + math.max(self.soilTemp, 0)

    -- calculating snow melt as a function of radiation
    local snowMelt = math.max(0.001 * effectiveMeltTemp ) * (1 + g_seasons.daylight:calculateSolarRadiation() / 5) * 9 / g_seasons.environment.daysInSeason

    -- melting snow
    if currentTemp >= 0 then
        if currentRain == nil then
            -- snow melts at faster if the sun is shining
            self.meltedSnow = snowMelt 

        elseif currentRain.rainTypeId == "rain" or currentRain.rainTypeId == "snow" then
            -- assume snow melts 50% faster if it rains. Warm snow acts as rain.
            self.meltedSnow = snowMelt * 1.5

        elseif currentRain.rainTypeId == "cloudy" or currentRain.rainTypeId == "fog" then
            self.meltedSnow = snowMelt
        end

        self.snowDepth = self.snowDepth - self.meltedSnow

    -- accumulating snow
    elseif currentTemp < 0 and currentRain ~= nil then
        if currentRain.rainTypeId == "rain" or currentRain.rainTypeId == "snow" then
            -- cold rain acts as snow
            -- Initial value of 10 mm/hr accumulation rate. Higher rate when there is little snow to get the visual effect
            if self.snowDepth < 0 then
                self.snowDepth = 0
            elseif self.snowDepth > 0.06 then
                self.snowDepth = self.snowDepth + 20 / 1000 * math.max(9 / g_seasons.environment.daysInSeason, 1)
            else
                self.snowDepth = self.snowDepth + 31 / 1000
            end
        end
    end

    return self.snowDepth
end

--- function for calculating soil temperature
--- Based on Rankinen et al. (2004), A simple model for predicting soil temperature in snow-covered and seasonally frozen soil: model description and testing
function ssWeatherManager:updateSoilTemp()
    local avgAirTemp = (self.forecast[1].highTemp * 8 + self.forecast[1].lowTemp * 16) / 24
    local deltaT = 365 / g_seasons.environment.SEASONS_IN_YEAR / g_seasons.environment.daysInSeason / 2
    local soilTemp = self.soilTemp
    local snowDamp = 1

    -- average soil thermal conductivity, unit: kW/m/deg C, typical value s0.4-0.8
    local facKT = 0.6
    -- average thermal conductivity of soil and ice C_S + C_ICE, unit: kW/m/deg C, typical values C_S = 1-1.3, C_ICE = 4-15
    local facCA = 10
    -- empirical snow damping parameter, unit 1/m, typical values -2 - -7
    local facfs = -5

    -- dampening effect of snow cover
    if self.snowDepth > 0 then
        snowDamp = math.exp(facfs * self.snowDepth)
    end

    self.soilTemp = soilTemp + math.min(deltaT * facKT / (0.81 * facCA), 0.8) * (avgAirTemp - soilTemp) * snowDamp
    --log("self.soilTemp=", self.soilTemp, " soilTemp=", soilTemp, " avgAirTemp=", avgAirTemp, " snowDamp=", snowDamp, " snowDepth=", snowDepth)
end

--- function for predicting when soil is frozen
function ssWeatherManager:isGroundFrozen()
    return self.soilTemp < 0
end

function ssWeatherManager:isCropWet()
    if self.moistureEnabled then
        return self.cropMoistureContent > 20 or g_currentMission.environment.timeSinceLastRain == 0
    else
        return g_currentMission.environment.timeSinceLastRain < 2 * 60
    end
end

function ssWeatherManager:getSnowHeight()
    return self.snowDepth
end

function ssWeatherManager:currentTemperature()
    local curHour = g_currentMission.environment.currentHour
    local curMin = g_currentMission.environment.currentMinute
    if self.latestCurrentTempHour == curHour and self.latestCurrentTempMinute == curMin then
        return self.latestCurrentTemp
    end

    self.latestCurrentTempHour = curHour
    self.latestCurrentTempMinute = curMin
    self.latestCurrentTemp = self:diurnalTemp(curHour, curMin)

    return self.latestCurrentTemp
end

-- Change rain into snow when it is freezing, and snow into rain if it is too hot
function ssWeatherManager:switchRainSnow()
    for index, rain in ipairs(g_currentMission.environment.rains) do
        for jndex, fCast in ipairs(self.forecast) do
             if rain.startDay == fCast.day then
                local hour = math.floor(rain.startDayTime / 60 / 60 / 1000)
                local minute = math.floor(rain.startDayTime / 60 / 1000) - hour * 60

                local tempStartRain = self:diurnalTemp(hour, minute, fCast.lowTemp, fCast.highTemp, fCast.lowTemp)

                if tempStartRain < -1 and rain.rainTypeId == "rain" then
                    g_currentMission.environment.rains[index].rainTypeId = "snow"
                    self.forecast[jndex].weatherState = "snow"

                elseif tempStartRain >= -1 and rain.rainTypeId == "snow" then
                    g_currentMission.environment.rains[index].rainTypeId = "rain"
                    self.forecast[jndex].weatherState = "rain"
                end
            end
        end
    end
end

function ssWeatherManager:updateRain(oneDayForecast, endRainTime)
    local rainFactors = self.rainData[g_seasons.environment:seasonAtDay(oneDayForecast.day)]

    local mu = rainFactors.mu
    local sigma = rainFactors.sigma
    local cov = sigma / mu

    rainFactors.beta = 1 / math.sqrt(math.log(1 + cov * cov))
    rainFactors.gamma = mu / math.sqrt(1 + cov * cov)

    local noTime = "false"
    local oneDayRain = {}

    local oneRainEvent = {}

    p = self:_randomRain(oneDayForecast)

    if p < rainFactors.probRain then
        oneRainEvent = self:_rainStartEnd(p, endRainTime, rainFactors, oneDayForecast)

        if oneDayForecast.lowTemp < 1 then
            oneRainEvent.rainTypeId = "snow" -- forecast snow if temp < 1
        else
            oneRainEvent.rainTypeId = "rain"
        end

    elseif p > rainFactors.probRain and p < rainFactors.probClouds then
        oneRainEvent = self:_rainStartEnd(p, endRainTime, rainFactors, oneDayForecast)
        oneRainEvent.rainTypeId = "cloudy"
    elseif oneDayForecast.lowTemp > -1 and oneDayForecast.lowTemp < 4 and endRainTime < 10800000 then
        -- morning fog
        oneRainEvent.startDay = oneDayForecast.day
        oneRainEvent.endDay = oneDayForecast.day
        local dayStart, dayEnd, nightEnd, nightStart = g_seasons.daylight:calculateStartEndOfDay(oneDayForecast.day)

        -- longer fog in winter and autumn
        if oneDayForecast.season == g_seasons.environment.SEASON_WINTER or oneDayForecast.season == g_seasons.environment.SEASON_AUTUMN then
            oneRainEvent.startDayTime = nightEnd * 60 * 60 * 1000
            oneRainEvent.endDayTime = (dayStart + 4) * 60 * 60 * 1000
        else
            oneRainEvent.startDayTime = nightEnd * 60 * 60 * 1000
            oneRainEvent.endDayTime = (dayStart + 1) * 60 * 60 * 1000
        end
        oneRainEvent.duration = oneRainEvent.endDayTime - oneRainEvent.startDayTime
        oneRainEvent.rainTypeId = "fog"
    else
        oneRainEvent.rainTypeId = "sun"
        oneRainEvent.duration = 0
        oneRainEvent.startDayTime = 0
        oneRainEvent.endDayTime = 0
        oneRainEvent.startDay = oneDayForecast.day
        oneRainEvent.endDay = oneDayForecast.day
    end

    oneDayRain = oneRainEvent
    return oneDayRain
end

function ssWeatherManager:_rainStartEnd(p, endRainTime, rainFactors, oneDayForecast)
    local oneRainEvent = {}

    oneRainEvent.startDay = oneDayForecast.day
    oneRainEvent.duration = math.min(math.max(math.exp(ssUtil.lognormDist(rainFactors.beta, rainFactors.gamma, p)), 2), 24) * 60 * 60 * 1000
    -- rain can start from 01:00 (or 1 hour after last rain ended) to 23.00
    oneRainEvent.startDayTime = math.random(3600 + endRainTime / 1000, 82800) * 1000

    if oneRainEvent.startDayTime + oneRainEvent.duration < 86400000 then
        oneRainEvent.endDay = oneRainEvent.startDay
        oneRainEvent.endDayTime =  oneRainEvent.startDayTime + oneRainEvent.duration
    else
        oneRainEvent.endDay = oneRainEvent.startDay + 1
        oneRainEvent.endDayTime =  oneRainEvent.startDayTime + oneRainEvent.duration - 86400000
    end

    return oneRainEvent
end

function ssWeatherManager:_randomRain(oneDayForecast)
    ssTmax = self.temperatureData[g_seasons.environment:transitionAtDay(oneDayForecast.day)]

    if oneDayForecast.season == g_seasons.environment.SEASON_WINTER or oneDayForecast.season == g_seasons.environment.SEASON_AUTUMN then
        if oneDayForecast.highTemp > ssTmax.mode then
            p = math.random() ^ 1.5 --increasing probability for precipitation if the temp is high
        else
            p = math.random() ^ 0.75 --decreasing probability for precipitation if the temp is high
        end
    elseif oneDayForecast.season == g_seasons.environment.SEASON_SPRING or oneDayForecast.season == g_seasons.environment.SEASON_SUMMER then
        if oneDayForecast.highTemp < ssTmax.mode then
            p = math.random() ^ 1.5 --increasing probability for precipitation if the temp is high
        else
            p = math.random() ^ 0.75 --decreasing probability for precipitation if the temp is high
        end
    end

    return p
end

-- Overwrite the vanilla rains table using our own forecast
function ssWeatherManager:overwriteRaintable()
    local env = g_currentMission.environment
    local tmpWeather = {}

    for index = 1, self.forecastLength do
        if self.weather[index].rainTypeId ~= "sun" then
            local tmpSingleWeather = deepCopy(self.weather[index])
            table.insert(tmpWeather, tmpSingleWeather)
        end
    end

    env.numRains = table.getn(tmpWeather)
    env.rains = tmpWeather

    if g_seasons.environment.currentDayOffset ~= nil then
        for index = 1, env.numRains do
            local newStartDay = env.rains[index].startDay - g_seasons.environment.currentDayOffset
            local newEndDay = env.rains[index].endDay - g_seasons.environment.currentDayOffset
            env.rains[index].startDay = newStartDay
            env.rains[index].endDay = newEndDay
        end
    end

    self:switchRainSnow()
end

--- function for predicting when soil is too cold for crops to germinate
function ssWeatherManager:germinationTemperature(fruit)
    return Utils.getNoNil(self.germinateTemp[fruit], self.germinateTemp["barley"])
end

function ssWeatherManager:canSow(fruit)
    return self.soilTempMax >= self:germinationTemperature(fruit)
end

function ssWeatherManager:loadGerminateTemperature(path)
    local file = loadXMLFile("germinate", path)

    local i = 0
    while true do
        local key = string.format("growth.germination.fruit(%d)", i)
        if not hasXMLProperty(file, key) then break end

        local fruitName = getXMLString(file, key .. "#fruitName")
        if fruitName == nil then
            logInfo("ssWeatherManager:", "Fruit in growth.xml:germination is invalid")
            break
        end

        local germinateTemp = getXMLFloat(file, key .. "#germinateTemp")

        if germinateTemp == nil then
            logInfo("ssWeatherManager:", "Temperature data in growth.xml:germination is invalid")
            break
        end

        self.germinateTemp[fruitName] = germinateTemp

        i = i + 1
    end

    -- Close file
    delete(file)
end

function ssWeatherManager:loadFromXML(path)
    local file = loadXMLFile("weather", path)

    -- Load start values. This assumes at least 1 file has those values. (Seasons data)
    self.startValues.soilTemp = ssXMLUtil.getFloat(file, "weather.startValues.soilTemp", self.startValues.soilTemp)
    self.startValues.highAirTemp = ssXMLUtil.getFloat(file, "weather.startValues.highAirTemp", self.startValues.highAirTemp)
    self.startValues.snowDepth = ssXMLUtil.getFloat(file, "weather.startValues.snowDepth", self.startValues.snowDepth)

    -- Load temperature data
    local i = 0
    while true do
        local key = string.format("weather.temperature.p(%d)", i)
        if not hasXMLProperty(file, key) then break end

        local period = getXMLInt(file, key .. "#period")
        if period == nil then
            logInfo("ssWeatherManager:", "Period in weather.xml is invalid")
            break
        end

        local min = getXMLFloat(file, key .. ".min#value")
        local mode = getXMLFloat(file, key .. ".mode#value")
        local max = getXMLFloat(file, key .. ".max#value")

        if min == nil or mode == nil or max == nil then
            logInfo("ssWeatherManager:", "Temperature data in weather.xml is invalid")
            break
        end

        local config = {
            ["min"] = min,
            ["mode"] = mode,
            ["max"] = max
        }

        self.temperatureData[period] = config

        i = i + 1
    end

    -- Load rain data
    i = 0
    while true do
        local key = string.format("weather.rain.s(%d)", i)
        if not hasXMLProperty(file, key) then break end

        local season = getXMLInt(file, key .. "#season")
        if season == nil then
            logInfo("ssWeatherManager:", "Season in weather.xml is invalid")
            break
        end

        local mu = getXMLFloat(file, key .. ".mu#value")
        local sigma = getXMLFloat(file, key .. ".sigma#value")
        local probRain = getXMLFloat(file, key .. ".probRain#value")
        local probClouds = getXMLFloat(file, key .. ".probClouds#value")
        local probHail = getXMLFloat(file, key .. ".probHail#value")

        if mu == nil or sigma == nil or probRain == nil or probClouds == nil or probHail == nil then
            logInfo("ssWeatherManager:", "Rain data in weather.xml is invalid")
            break
        end

        local config = {
            ["mu"] = mu,
            ["sigma"] = sigma,
            ["probRain"] = probRain,
            ["probClouds"] = probClouds,
            ["probHail"] = probHail
        }

        self.rainData[season] = config

        i = i + 1
    end

    delete(file)
end

-- function to calculate relative humidity
-- http://onlinelibrary.wiley.com/doi/10.1002/met.258/pdf
function ssWeatherManager:calculateRelativeHumidity()
    local dewPointTemp = self.forecast[1].lowTemp - 2
    local es = 6.1078 - math.exp(17.2669 * dewPointTemp / ( dewPointTemp + 237.3 ) )
    local relativeHumidity = 80
    local currentTemp = self:currentTemperature()
    local e = 6.1078 - math.exp(17.2669 * currentTemp / ( currentTemp + 237.3 ) )

    relativeHumidity = 100 * e / es

    if relativeHumidity < 5 then
        relativeHumidity = 5
    end

    if g_currentMission.environment.timeSinceLastRain == 0 then
        relativeHumidity = 95
    end

    return relativeHumidity
end

function ssWeatherManager:updateCropMoistureContent()
    local dayTime = g_currentMission.environment.dayTime

    local prevCropMoist = self.cropMoistureContent
    local relativeHumidity = self:calculateRelativeHumidity()
    local solarRadiation = g_seasons.daylight:calculateSolarRadiation()

    local tmpMoisture = prevCropMoist + (relativeHumidity - prevCropMoist) / 1000
    -- added effect of some wind drying crops. Reduced for normal and hard difficulty
    local deltaMoisture = (0.3 - 0.1 * g_currentMission.missionInfo.difficulty) + solarRadiation / 40 * (tmpMoisture - 10) * math.sqrt(math.max(9 / g_seasons.environment.daysInSeason, 1))

    self.cropMoistureContent = tmpMoisture - deltaMoisture

    -- increase crop Moisture in the first hour after rain has started
    if g_currentMission.environment.timeSinceLastRain == 0 and self.cropMoistureContent < 25 then
        if dayTime > self.weather[1].startDayTime and (dayTime - 60) > self.weather[1].startDayTime then
            self.cropMoistureContent = 25
        end
    end
end

-- inserting a hail event
function ssWeatherManager:updateHail(day)
    local rainFactors = self.rainData[self.forecast[1].season]
    local p = math.random()

    if p < rainFactors.probHail and self.forecast[1].weatherState == "sun" then
        local julianDay = ssUtil.julianDay(g_seasons.environment:currentDay())
        dayStart, dayEnd, _, _ = g_seasons.daylight:calculateStartEndOfDay(julianDay)

        self.weather[1].rainTypeId = "hail"
        self.weather[1].startDayTime = ssUtil.triDist({["min"] = dayStart, ["mode"] = dayStart + 4, ["max"] = dayEnd - 6}) * 60 * 60 * 1000
        self.weather[1].duration = ssUtil.triDist({["min"] = 1, ["mode"] = 2, ["max"] = 3}) * 60 * 60 * 1000
        self.weather[1].endDayTime = self.weather[1].startDayTime + self.weather[1].duration
        self.weather[1].startDay = self.forecast[1].day
        self.weather[1].endDay = self.forecast[1].day

        g_server:broadcastEvent(ssWeatherManagerHailEvent:new(self.weather[1]))
    end
end

function ssWeatherManager:updateSoilWaterContent()
    if g_currentMission.environment.currentRain ~= nil then
        currentRainId = g_currentMission.environment.currentRain.rainTypeId
    end
    
    --Soil moisture bucket model
    --Guswa, A. J., M. A. Celia, and I. Rodriguez-Iturbe, Models of soil moisture dynamics in ecohydrology: A comparative study,
    --Water Resour. Res., 38(9), 1166, doi:10.1029/2001WR000826, 2002

    -- every hour with rain add 10 mm of waterInfriltation
    -- every hour snow melts: add 30% of melted snowDepth as waterInfriltation
    -- every hour air temperature < 5 deg, or solarRadiation < 1.5, no transpiration


    -- constants
    local depthRootZone = 20 -- cm
    local Ksat = 109.8 / 24 -- saturated conductivity cm/day | divided by 24 due to update every hour
    local Sfc = 0.29 -- field capacity, gravity drainage becomes negligible compared to evotranspiration when saturation is above
    local beta = 9.0 -- drainage curve parameter
    local soilPorosity = 0.42
    local stomatalSaturation = 0.105 -- evotranspiration reaches maximum when saturation is above this value
    local wiltingSaturation = 0.036 -- if saturation is below this value the plant wilts
    local hygroscopicSaturation = 0.02 -- if saturation is below this value evaporation stops
    local maxEvaporation = 0.15 / g_seasons.environment.daysInSeason -- cm/day | gameification with daysInSeason
    local maxTranspiration = 0.325 / g_seasons.environment.daysInSeason -- cm/day | gameification with daysInSeason

    -- update variables
    local relativeHumidity = self:calculateRelativeHumidity()
    local currentTemp = self:currentTemperature()
    local solarRadiation = g_seasons.daylight:calculateSolarRadiation()
    local prevSoilWaterCont = self.soilWaterContent
    local soilWaterInfiltration = 0

    -- calculate evaporation, if relativeHumidity > 90% or snow on the ground, no evaporation
    if prevSoilWaterCont <= hygroscopicSaturation or relativeHumidity > 90 or self.snowDepth > 0 then
        soilWaterEvaporation = 0
    elseif prevSoilWaterCont >= stomatalSaturation then
        soilWaterEvaporation = maxEvaporation
    else
        soilWaterEvaporation = (prevSoilWaterCont - hygroscopicSaturation) / (stomatalSaturation - hygroscopicSaturation) * maxEvaporation / 24
    end

    -- calculate transpiration, if air temperature < 5 deg, no transpiration
    if prevSoilWaterCont <= wiltingSaturation or currentTemp < 5 then
        soilWaterTranspiration = 0
    elseif prevSoilWaterCont >= stomatalSaturation then
        soilWaterTranspiration = maxTranspiration
    else
        soilWaterTranspiration = (prevSoilWaterCont - wiltingSaturation) / (stomatalSaturation - wiltingSaturation) * maxTranspiration / 24
    end

    -- add water if it rains or if snow melts
    if g_currentMission.environment.timeSinceLastRain == 0 and currentRainId == 'rain' then
        soilWaterInfiltration = 1 -- 10 mm/hr infiltration

    elseif g_currentMission.environment.timeSinceLastRain == 0 and currentRainId == 'hail' then
        soilWaterInfiltration = 1.5 -- 15 mm/hr infiltration

    -- not add water from melted snow if only piles are melting or if the ground is not frozen
    elseif self.meltedSnow ~= 0 and self.snowDepth > 0 and not self:isGroundFrozen() then
        -- 30% of melted snow infiltrates, meltedSnow in meter, snow density 400 kg/m3
        -- dividing by 10 due to unit cm
        soilWaterInfiltration = 0.3 * self.meltedSnow * 400 / 10
    end

    soilWaterLeakage = math.max(Ksat * (math.exp(beta*(prevSoilWaterCont - Sfc)) - 1) / (math.exp(beta*(1 - Sfc)) - 1),0)
    self.soilWaterContent = math.min(prevSoilWaterCont + 1 / (soilPorosity * depthRootZone) * (soilWaterInfiltration - soilWaterLeakage - soilWaterTranspiration - soilWaterEvaporation), 1)
end

function ssWeatherManager:calculateSoilWetness()
    if ssWeatherManager:isGroundFrozen() then
        return 0
    else
        return ssWeatherManager.soilWaterContent
    end
end
