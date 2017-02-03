---------------------------------------------------------------------------------------------------------
-- WEATHER MANAGER SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  to create and manage the weather
-- Authors:  ian898, Rahkiin, reallogger, theSeb
--

ssWeatherManager = {}
g_seasons.weatherManager = ssWeatherManager

ssWeatherManager.forecast = {} --day of week, low temp, high temp, weather condition
ssWeatherManager.forecastLength = 8
ssWeatherManager.snowDepth = 0
ssWeatherManager.soilTemp = 4.9
ssWeatherManager.weather = {}

function ssWeatherManager:preLoad()
end

function ssWeatherManager:load(savegame, key)
    if savegame == nil then return end
    local i

    self.snowDepth = ssStorage.getXMLFloat(savegame, key .. ".weather.snowDepth", 0.0)
    self.soilTemp = ssStorage.getXMLFloat(savegame, key .. ".weather.soilTemp", 0.0)
    self.prevHighTemp = ssStorage.getXMLFloat(savegame, key .. ".weather.prevHighTemp", 0.0)

    -- load forecast
    self.forecast = {}

    local i = 0
    while true do
        local dayKey = string.format("%s.weather.forecast.day(%i)", key, i)
        if not hasXMLProperty(savegame, dayKey) then break end

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
        if not hasXMLProperty(savegame, rainKey) then break end

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

    ssStorage.setXMLFloat(savegame, key .. ".weather.snowDepth", self.snowDepth)
    ssStorage.setXMLFloat(savegame, key .. ".weather.soilTemp", self.soilTemp)
    ssStorage.setXMLFloat(savegame, key .. ".weather.prevHighTemp", self.prevHighTemp)

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
    self:loadFromXML(g_seasons.modDir .. "data/weather.xml")

    local modPath = ssUtil.getModMapDataPath("seasons_weather.xml")
    if modPath ~= nil then
        self:loadFromXML(modPath)
    end

    -- Load germination temperatures
    self.germinateTemp = {}
    self:loadGerminateTemperature(g_seasons.modDir .. "data/growth.xml")

    local modPath = ssUtil.getModMapDataPath("seasons_growth.xml")
    if modPath ~= nil then
        self:loadGerminateTemperature(modPath)
    end


    if g_currentMission:getIsServer() or self.forecast[1].day ~= g_currentMission.environment.currentDay then
        if table.getn(self.forecast) == 0 then
            self:buildForecast()
        end
        --self.snowDepth = -- Enable read from savegame
        --self.weather = g_currentMission.environment.rains -- should only be done for a fresh savegame, otherwise read from savegame
    end

    self:owRaintable()
end

function ssWeatherManager:readStream(streamId, connection)
    self.snowDepth = streamReadFloat32(streamId)
    local numDays = streamReadUInt8(streamId)
    local numRains = streamReadUInt8(streamId)

    -- load forecast
    self.forecast = {}

    for i = 1, numDays do
        local day = {}

        day.day = streamReadInt16(streamId)
        day.season = g_seasons.environment:seasonAtDay(day.day)

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
end

function ssWeatherManager:writeStream(streamId, connection)
    streamWriteFloat32(streamId, self.snowDepth)

    streamWriteUInt8(streamId, table.getn(self.forecast))
    streamWriteUInt8(streamId, table.getn(self.weather))

    for _, day in pairs(self.forecast) do
        streamWriteInt16(streamId, day.day)
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

function ssWeatherManager:update(dt)
    local currentRain = g_currentMission.environment.currentRain

    if currentRain ~= nil then
        local currentTemp = mathRound(ssWeatherManager:diurnalTemp(g_currentMission.environment.currentHour, g_currentMission.environment.currentMinute), 0)

        if currentTemp > 1 and currentRain.rainTypeId == 'snow' then
            setVisibility(g_currentMission.environment.rainTypeIdToType.snow.rootNode, false)
            g_currentMission.environment.currentRain.rainTypeId = 'rain'
            setVisibility(g_currentMission.environment.rainTypeIdToType.rain.rootNode, true)
        elseif currentTemp < 0 and currentRain.rainTypeId == 'rain' then
            setVisibility(g_currentMission.environment.rainTypeIdToType.rain.rootNode, false)
            g_currentMission.environment.currentRain.rainTypeId = 'snow'
            setVisibility(g_currentMission.environment.rainTypeIdToType.snow.rootNode, true)
        end
    end
end

-- Only run this the very first time or if season length changes
function ssWeatherManager:buildForecast()
    local startDayNum = g_seasons.environment:currentDay()
    local ssTmax

    self.prevHighTemp = 5 -- initial assumption high temperature during last day of winter. May not be correct if rebuilding forecast.
    self.forecast = {}
    self.weather = {}

    for n = 1, self.forecastLength do
        oneDayForecast = {}
        local oneDayRain = {}
        local ssTmax = {}
        local Tmaxmean = {}

        oneDayForecast.day = startDayNum + n - 1 -- To match forecast with actual game
        oneDayForecast.season = g_seasons.environment:seasonAtDay(startDayNum + n - 1)

        ssTmax = self.temperatureData[g_seasons.environment:currentGrowthTransition(oneDayForecast.day)]

        oneDayForecast.highTemp = ssUtil.normDist(ssTmax.mode,2.5)
        oneDayForecast.lowTemp = ssUtil.normDist(0,2) + 0.75 * ssTmax.mode-5

        if n == 1 then
            oneDayRain = self:updateRain(oneDayForecast,0)
        else
            if oneDayForecast.day == self.weather[n-1].endDay then
                oneDayRain = self:updateRain(oneDayForecast,self.weather[n-1].endDayTime)
            else
                oneDayRain = self:updateRain(oneDayForecast,0)
            end
        end

        oneDayForecast.weatherState = oneDayRain.rainTypeId

        table.insert(self.forecast, oneDayForecast)
        table.insert(self.weather, oneDayRain)
    end

    self:owRaintable()
    self:switchRainHail()
end

function ssWeatherManager:updateForecast()
    local dayNum = g_seasons.environment:currentDay() + self.forecastLength-1
    local oneDayRain = {}

    self.prevHighTemp = self.forecast[1].highTemp  -- updating prev high temp before updating forecast table

    table.remove(self.forecast,1)

    oneDayForecast = {}
    local ssTmax = {}

    oneDayForecast.day = dayNum -- To match forecast with actual game
    oneDayForecast.season = g_seasons.environment:seasonAtDay(dayNum)

    ssTmax = self.temperatureData[g_seasons.environment:currentGrowthTransition(dayNum)]

    if self.forecast[self.forecastLength-1].season == oneDayForecast.season then
        --Seasonal average for a day in the current season
        oneDayForecast.Tmaxmean = self.forecast[self.forecastLength-1].Tmaxmean

    elseif self.forecast[self.forecastLength-1].season ~= oneDayForecast.season then
        --Seasonal average for a day in the next season
        oneDayForecast.Tmaxmean = ssUtil.triDist(ssTmax)

    end

    oneDayForecast.highTemp = ssUtil.normDist(ssTmax.mode,2.5)
    oneDayForecast.lowTemp = ssUtil.normDist(0,2) + 0.75 * ssTmax.mode-5

    if oneDayForecast.day == self.weather[self.forecastLength-1].endDay then
        oneDayRain = self:updateRain(oneDayForecast,self.weather[self.forecastLength-1].endDayTime)
    else
        oneDayRain = self:updateRain(oneDayForecast,0)
    end

    oneDayForecast.weatherState = oneDayRain.rainTypeId

    table.insert(self.forecast, oneDayForecast)
    table.insert(self.weather, oneDayRain)

    table.remove(self.weather, 1)

    self:owRaintable()
    self:switchRainHail()

    self:calculateSoilTemp()

    g_server:broadcastEvent(ssWeatherForecastEvent:new(oneDayForecast, oneDayRain))
end

function ssWeatherManager:seasonLengthChanged()
    self:buildForecast()
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
end

-- Jos note: no randomness here. Must run on client for snow.
function ssWeatherManager:hourChanged()
    local oldSnow = self.snowDepth

    self:calculateSnowAccumulation()

    if math.abs(oldSnow - self.snowDepth) > 0.01 then
        -- Call a weather change
        for _, listener in pairs(g_currentMission.environment.weatherChangeListeners) do
            listener:weatherChanged()
        end
    end
end

-- function to output the temperature during the day and night
function ssWeatherManager:diurnalTemp(hour, minute,lowTemp,highTemp,lowTempNext)
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

    local currentTime = hour + minute/60

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
function ssWeatherManager:calculateSnowAccumulation()
    local currentRain = g_currentMission.environment.currentRain
    local currentTemp = self:diurnalTemp(g_currentMission.environment.currentHour, g_currentMission.environment.currentMinute)
    local currentSnow = self.snowDepth

    --- more radiation during spring
    local meltFactor = 1
    if self.forecast[1].season ~= g_seasons.environment.SEASON_WINTER then
        meltFactor = 5
    end


    if currentRain == nil then
        if currentTemp > -1 then
        -- snow melts at -1 if the sun is shining
        self.snowDepth = self.snowDepth - math.max((currentTemp+1)/1000,0)*meltFactor
        end

    elseif currentRain.rainTypeId == "rain" and currentTemp > 0 then
        -- assume snow melts three times as fast if it rains
        self.snowDepth = self.snowDepth - math.max((currentTemp+1)*3/1000,0)*meltFactor

    elseif currentRain.rainTypeId == "rain" and currentTemp <= 0 then
        -- cold rain acts as hail
        if self.snowDepth < 0 then
            self.snowDepth = 0
        end
        self.snowDepth = self.snowDepth + 10/1000

    elseif currentRain.rainTypeId == "snow" and currentTemp < 0 then
        -- Initial value of 10 mm/hr accumulation rate. Higher rate when there is little snow to get the visual effect
        if self.snowDepth < 0 then
            self.snowDepth = 0
        elseif self.snowDepth > 0.06 then
            self.snowDepth = self.snowDepth + 10/1000
        else
            self.snowDepth = self.snowDepth + 30/1000
        end

    elseif currentRain.rainTypeId == "snow" and currentTemp >= 0 then
        -- warm hail acts as rain
        self.snowDepth = self.snowDepth - math.max((currentTemp+1)*3/1000,0)*meltFactor
        --g_currentMission.environment.currentRain.rainTypeId = nil
        --currentRain.rainTypeId = 'rain'

    elseif currentRain.rainTypeId == "cloudy" and currentTemp > 0 then
        -- 75% melting (compared to clear conditions) when there is cloudy and fog
        self.snowDepth = self.snowDepth - math.max((currentTemp+1)*0.75/1000,0)*meltFactor

    elseif currentRain.rainTypeId == "fog" and currentTemp > 0 then
        -- 75% melting (compared to clear conditions) when there is cloudy and fog
        self.snowDepth = self.snowDepth - math.max((currentTemp+1)*0.75/1000,0)*meltFactor

    end

    return self.snowDepth
end

--- function for calculating soil temperature
--- Based on Rankinen et al. (2004), A simple model for predicting soil temperature in snow-covered and seasonally frozen soil: model description and testing
function ssWeatherManager:calculateSoilTemp()
    local avgAirTemp = (self.forecast[1].highTemp*8 + self.forecast[1].lowTemp*16) / 24
    local deltaT = 365 / g_seasons.environment.SEASONS_IN_YEAR / g_seasons.environment.daysInSeason / 2
    local soilTemp = self.soilTemp
    local snowDamp = 1

    -- average soil thermal conductivity, unit: kW/m/deg C, typical value s0.4-0.8
    local facKT = 0.6
    -- average thermal conductivity of soil and ice C_S + C_ICE, unit: kW/m/deg C, typical values C_S=1-1.3, C_ICE=4-15
    local facCA = 10
    -- empirical snow damping parameter, unit 1/m, typical values -2 - -7
    local facfs = -5

    -- dampening effect of snow cover
    if self.snowDepth > 0 then
        snowDamp = math.exp(facfs*self.snowDepth)
    end

    self.soilTemp = soilTemp + (deltaT * facKT / facCA * (avgAirTemp - soilTemp)) * snowDamp
    --log('self.soilTemp=',self.soilTemp,' soilTemp=',soilTemp,' avgAirTemp=',avgAirTemp,' snowDamp=',snowDamp,' snowDepth=',snowDepth)
end

--- function for predicting when soil is frozen
function ssWeatherManager:isGroundFrozen()
    return self.soilTemp < 0
end

function ssWeatherManager:getSnowHeight()
    return self.snowDepth
end

function ssWeatherManager:switchRainHail()
    for index, rain in ipairs(g_currentMission.environment.rains) do
        for jndex, fCast in ipairs(self.forecast) do
             if rain.startDay == fCast.day then
                local hour = math.floor(rain.startDayTime/60/60/1000)
                local minute = math.floor(rain.startDayTime/60/1000)-hour*60

                local tempStartRain = self:diurnalTemp(hour, minute, fCast.lowTemp,fCast.highTemp,fCast.lowTemp)

                if tempStartRain < -1 and rain.rainTypeId == 'rain' then
                    g_currentMission.environment.rains[index].rainTypeId = 'snow'
                    self.forecast[jndex].weatherState = 'snow'

                elseif tempStartRain >= -1 and rain.rainTypeId == 'snow' then
                    g_currentMission.environment.rains[index].rainTypeId = 'rain'
                    self.forecast[jndex].weatherState = 'rain'
                end
            end
        end
    end
end

function ssWeatherManager:updateRain(oneDayForecast,endRainTime)
    local rainFactors = self.rainData[g_seasons.environment:seasonAtDay(oneDayForecast.day)]

    local mu = rainFactors.mu
    local sigma = rainFactors.sigma
    local cov = sigma/mu

    rainFactors.beta = 1 / math.sqrt(math.log(1+cov*cov))
    rainFactors.gamma = mu / math.sqrt(1+cov*cov)

    local noTime = 'false'
    local oneDayRain = {}

    local oneRainEvent = {}

    p = self:_randomRain(oneDayForecast.day)

    if p < rainFactors.probRain then
        oneRainEvent = self:_rainStartEnd(p,endRainTime,rainFactors)

        if oneDayForecast.lowTemp < 1 then
            oneRainEvent.rainTypeId = "snow" -- forecast snow if temp < 1
        else
            oneRainEvent.rainTypeId = "rain"
        end

    elseif p > rainFactors.probRain and p < rainFactors.probClouds then
        oneRainEvent = self:_rainStartEnd(p,endRainTime,rainFactors)
        oneRainEvent.rainTypeId = "cloudy"
    elseif oneDayForecast.lowTemp > -1 and oneDayForecast.lowTemp < 2 and endRainTime < 10800000 then
        -- morning fog
        oneRainEvent.startDay = oneDayForecast.day
        oneRainEvent.endDay = oneDayForecast.day
        local dayStart, dayEnd, nightEnd, nightStart = ssEnvironment:calculateStartEndOfDay(oneDayForecast.day)

        oneRainEvent.startDayTime = nightEnd*60*60*1000
        oneRainEvent.endDayTime = (dayStart+1)*60*60*1000
        oneRainEvent.duration = oneRainEvent.endDayTime - oneRainEvent.startDayTime
        oneRainEvent.rainTypeId = "fog"
    else
        oneRainEvent.rainTypeId = 'sun'
        oneRainEvent.duration = 0
        oneRainEvent.startDayTime = 0
        oneRainEvent.endDayTime = 0
        oneRainEvent.startDay = oneDayForecast.day
        oneRainEvent.endDay = oneDayForecast.day
    end

    oneDayRain = oneRainEvent
    return oneDayRain
end

function ssWeatherManager:_rainStartEnd(p,endRainTime,rainFactors)
    local oneRainEvent = {}

    oneRainEvent.startDay = oneDayForecast.day
    oneRainEvent.duration = math.min(math.max(math.exp(ssUtil.lognormDist(rainFactors.beta,rainFactors.gamma,p)),2),24)*60*60*1000
    -- rain can start from 01:00 (or 1 hour after last rain ended) to 23.00
    oneRainEvent.startDayTime = math.random(3600 + endRainTime/1000,82800) *1000
    --log('Start time for rain = ', oneRainEvent.startDayTime)

    if oneRainEvent.startDayTime + oneRainEvent.duration < 86400000 then
        oneRainEvent.endDay = oneRainEvent.startDay
        oneRainEvent.endDayTime =  oneRainEvent.startDayTime + oneRainEvent.duration
    else
        oneRainEvent.endDay = oneRainEvent.startDay + 1
        oneRainEvent.endDayTime =  oneRainEvent.startDayTime + oneRainEvent.duration - 86400000
    end

    return oneRainEvent
end

function ssWeatherManager:_randomRain(day)
    ssTmax = self.temperatureData[g_seasons.environment:currentGrowthTransition(day)]

    if oneDayForecast.season == g_seasons.environment.SEASON_WINTER or oneDayForecast.season == g_seasons.environment.SEASON_AUTUMN then
        if oneDayForecast.highTemp > ssTmax.mode then
            p = math.random()^1.5 --increasing probability for precipitation if the temp is high
        else
            p = math.random()^0.75 --decreasing probability for precipitation if the temp is high
        end
    elseif oneDayForecast.season == g_seasons.environment.SEASON_SPRING or oneDayForecast.season == g_seasons.environment.SEASON_SUMMER then
        if oneDayForecast.highTemp < ssTmax.mode then
            p = math.random()^1.5 --increasing probability for precipitation if the temp is high
        else
            p = math.random()^0.75 --decreasing probability for precipitation if the temp is high
        end
    end

    return p
end

function ssWeatherManager:owRaintable()
    local env = g_currentMission.environment
    g_currentMission.environment.rains = {}
    local tmpWeather = {}

    for index = 1, self.forecastLength do
        if self.weather[index].rainTypeId ~= "sun" then
            local tmpSingleWeather = deepCopy(self.weather[index])
            table.insert(tmpWeather, tmpSingleWeather)
        end
    end

    g_currentMission.environment.numRains = table.getn(tmpWeather)
    g_currentMission.environment.rains = tmpWeather

    if g_seasons.environment.currentDayOffset ~= nil then
        for index = 1, env.numRains do
            local newStartDay = env.rains[index].startDay - g_seasons.environment.currentDayOffset
            local newEndDay = env.rains[index].endDay - g_seasons.environment.currentDayOffset
            g_currentMission.environment.rains[index].startDay = newStartDay
            g_currentMission.environment.rains[index].endDay = newEndDay
        end
    end
end

--- function for predicting when soil is too cold for crops to germinate
function ssWeatherManager:germinationTemperature(fruit)
    local gTemp = 5

    if self.germinateTemp[fruit] ~= nil then
        gTemp = self.germinateTemp[fruit]
    else
        -- Default to barley for unknown crops
        gTemp = self.germinateTemp["barley"]
    end

    return gTemp
end

function ssWeatherManager:canSow(fruit)
    if self.soilTemp >= self:germinationTemperature(fruit) then
        return true
    else
        return false
    end
end

function ssWeatherManager:loadGerminateTemperature(path)
    local file = loadXMLFile("germinate", path)

    local i = 0
    while true do
        local key = string.format("growth.germination.fruit(%d)", i)
        if not hasXMLProperty(file, key) then break end

        local fruitName = getXMLString(file, key .. "#fruitName")
        if fruitName == nil then
            logInfo("Fruit in growth.xml:germination is invalid")
            break
        end

        local gTemp = getXMLFloat(file, key .. "#temp")

        if gTemp == nil then
            logInfo("Temperature data in growth.xml:germination is invalid")
            break
        end

        self.germinateTemp[fruitName] = gTemp

        i = i + 1
    end

    -- Close file
    delete(file)
end

function ssWeatherManager:loadFromXML(path)
    local file = loadXMLFile("weather", path)

    -- Load temperature data
    local i = 0
    while true do
        local key = string.format("weather.temperature.p(%d)", i)
        if not hasXMLProperty(file, key) then break end

        local period = getXMLInt(file, key .. "#period")
        if period == nil then
            logInfo("Period in weather.xml is invalid")
            break
        end

        local min = getXMLFloat(file, key .. ".min#value")
        local mode = getXMLFloat(file, key .. ".mode#value")
        local max = getXMLFloat(file, key .. ".max#value")

        if min == nil or mode == nil or max == nil then
            logInfo("Temperature data in weather.xml is invalid")
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
            logInfo("Season in weather.xml is invalid")
            break
        end

        local mu = getXMLFloat(file, key .. ".mu#value")
        local sigma = getXMLFloat(file, key .. ".sigma#value")
        local probRain = getXMLFloat(file, key .. ".probRain#value")
        local probClouds = getXMLFloat(file, key .. ".probClouds#value")

        if mu == nil or sigma == nil or probRain == nil or probClouds == nil then
            logInfo("Rain data in weather.xml is invalid")
            break
        end

        local config = {
            ["mu"] = mu,
            ["sigma"] = sigma,
            ["probRain"] = probRain,
            ["probClouds"] = probClouds
        }

        self.rainData[season] = config

        i = i + 1
    end

    delete(file)
end

-- MP EVENT
-- Server: Send a new day (with day number)
-- Client: remove first, add new at end


ssWeatherForecastEvent = {}
ssWeatherForecastEvent_mt = Class(ssWeatherForecastEvent, Event)
InitEventClass(ssWeatherForecastEvent, "ssWeatherForecastEvent")

-- client -> server: hey! I repaired X
--> server -> everyone: hey! X got repaired!

function ssWeatherForecastEvent:emptyNew()
    local self = Event:new(ssWeatherForecastEvent_mt)
    self.className = "ssWeatherForecastEvent"
    return self
end

function ssWeatherForecastEvent:new(day, rain)
    local self = ssWeatherForecastEvent:emptyNew()

    self.day = day
    self.rain = rain

    return self
end

-- Server: send to client
function ssWeatherForecastEvent:writeStream(streamId, connection)
    streamWriteInt16(streamId, self.day.day)
    streamWriteString(streamId, self.day.weatherState)
    streamWriteFloat32(streamId, self.day.highTemp)
    streamWriteFloat32(streamId, self.day.lowTemp)

    if self.rain ~= nil then
        streamWriteBool(streamId, true)

        streamWriteInt16(streamId, self.rain.startDay)
        streamWriteFloat32(streamId, self.rain.endDayTime)
        streamWriteFloat32(streamId, self.rain.startDayTime)
        streamWriteInt16(streamId, self.rain.endDay)
        streamWriteString(streamId, self.rain.rainTypeId)
        streamWriteFloat32(streamId, self.rain.duration)
    else
        streamWriteBool(streamId, false)
    end
end

-- Client: receive from server
function ssWeatherForecastEvent:readStream(streamId, connection)
    local day = {}

    day.day = streamReadInt16(streamId)
    day.season = g_seasons.environment:seasonAtDay(day.day)
    day.weatherState = streamReadString(streamId)
    day.highTemp = streamReadFloat32(streamId)
    day.lowTemp = streamReadFloat32(streamId)

    self.day = day

    if streamReadBool(streamId) then
        local rain = {}

        rain.startDay = streamReadInt16(streamId)
        rain.endDayTime = streamReadFloat32(streamId)
        rain.startDayTime = streamReadFloat32(streamId)
        rain.endDay = streamReadInt16(streamId)
        rain.rainTypeId = streamReadString(streamId)
        rain.duration = streamReadFloat32(streamId)

        self.rain = rain
    end

    self:run(connection)
end

function ssWeatherForecastEvent:run(connection)
    if connection:getIsServer() then
        table.remove(ssWeatherManager.forecast, 1)
        table.insert(ssWeatherManager.forecast, self.day)


        table.insert(ssWeatherManager.rains, self.rain)

        ssWeatherManager:owRaintable()
        ssWeatherManager:switchRainHail()

        table.remove(ssWeatherManager.rains, 1)
    end
end
