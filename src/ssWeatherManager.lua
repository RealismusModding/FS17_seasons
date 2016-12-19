---------------------------------------------------------------------------------------------------------
-- WEATHER MANAGER SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  to create and manage the weather
-- Authors:  Authors:  ian898, Jarvixes, theSeb, reallogger
--

ssWeatherManager = {}
ssWeatherManager.forecast = {} --day of week, low temp, high temp, weather condition
ssWeatherManager.forecastLength = 8
ssWeatherManager.snowDepth = 0
ssWeatherManager.soilTemp = 6
ssWeatherManager.rains = {}

function ssWeatherManager:load(savegame, key)
    if savegame == nil then return end
    local i

    self.snowDepth = ssStorage.getXMLFloat(savegame, key .. ".weather.snowDepth", 0.0)
    self.soilTemp = ssStorage.getXMLFloat(savegame, key .. ".weather.soilTemp", 0.0)

    -- load forecast
    self.forecast = {}

    local i = 0
    while true do
        local dayKey = string.format("%s.weather.forecast.day(%i)", key, i)
        if not hasXMLProperty(savegame, dayKey) then break end

        local day = {}

        day.day = getXMLInt(savegame, dayKey .. "#day")
        day.season = ssSeasonsUtil:season(day.day)

        day.weatherState = getXMLString(savegame, dayKey .. "#weatherState")
        day.highTemp = getXMLFloat(savegame, dayKey .. "#highTemp")
        day.lowTemp = getXMLFloat(savegame, dayKey .. "#lowTemp")

        table.insert(self.forecast, day)
        i = i + 1
    end

    -- load rains
    self.rains = {}

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

        table.insert(self.rains, rain)
        i = i + 1
    end
end

function ssWeatherManager:save(savegame, key)
    local i = 0

    ssStorage.setXMLFloat(savegame, key .. ".weather.snowDepth", self.snowDepth)
    ssStorage.setXMLFloat(savegame, key .. ".weather.soilTemp", self.soilTemp)

    for i = 0, table.getn(self.forecast) - 1 do
        local dayKey = string.format("%s.weather.forecast.day(%i)", key, i)

        local day = self.forecast[i + 1]

        setXMLInt(savegame, dayKey .. "#day", day.day)
        setXMLString(savegame, dayKey .. "#weatherState", day.weatherState)
        setXMLFloat(savegame, dayKey .. "#highTemp", day.highTemp)
        setXMLFloat(savegame, dayKey .. "#lowTemp", day.lowTemp)
    end

    for i = 0, table.getn(self.rains) - 1 do
        local rainKey = string.format("%s.weather.forecast.rain(%i)", key, i)

        local rain = self.rains[i + 1]

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

    g_currentMission.environment.minRainInterval = 1
    g_currentMission.environment.minRainDuration = 30 * 60 * 60 * 1000 -- 30 hours
    g_currentMission.environment.maxRainInterval = 1
    g_currentMission.environment.maxRainDuration = 30 * 60 * 60 * 1000
    g_currentMission.environment.rainForecastDays = self.forecastLength
    g_currentMission.environment.autoRain = 'false'

    self:loadTemperature()
    self:loadRain()

    if g_currentMission:getIsServer() then
        if table.getn(self.forecast) == 0 then
            self:buildForecast()
        end
        --self.snowDepth = -- Enable read from savegame
        --self.rains = g_currentMission.environment.rains -- should only be done for a fresh savegame, otherwise read from savegame
    end
end

function ssWeatherManager:deleteMap()
end

function ssWeatherManager:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssWeatherManager:keyEvent(unicode, sym, modifier, isDown)
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
        day.season = ssSeasonsUtil:season(day.day)

        day.weatherState = streamReadString(streamId)
        day.highTemp = streamReadFloat32(streamId)
        day.lowTemp = streamReadFloat32(streamId)

        table.insert(self.forecast, day)
    end

    -- load rains
    self.rains = {}

    for i = 1, numRains do
        local rain = {}

        rain.startDay = streamReadInt16(streamId)
        rain.endDayTime = streamReadFloat32(streamId)
        rain.startDayTime = streamReadFloat32(streamId)
        rain.endDay = streamReadInt16(streamId)
        rain.rainTypeId = streamReadString(streamId)
        rain.duration = streamReadFloat32(streamId)

        table.insert(self.rains, rain)
    end
end

function ssWeatherManager:writeStream(streamId, connection)
    streamWriteFloat32(streamId, self.snowDepth)

    streamWriteUInt8(streamId, table.getn(self.forecast))
    streamWriteUInt8(streamId, table.getn(self.rains))

    for _, day in pairs(self.forecast) do
        streamWriteInt16(streamId, day.day)
        streamWriteString(streamId, day.weatherState)
        streamWriteFloat32(streamId, day.highTemp)
        streamWriteFloat32(streamId, day.lowTemp)
    end

    for _, rain in pairs(self.rains) do
        streamWriteInt16(streamId, rain.startDay)
        streamWriteFloat32(streamId, rain.endDayTime)
        streamWriteFloat32(streamId, rain.startDayTime)
        streamWriteInt16(streamId, rain.endDay)
        streamWriteString(streamId, rain.rainTypeId)
        streamWriteFloat32(streamId, rain.duration)
    end
end

function ssWeatherManager:update(dt)
end

function ssWeatherManager:draw()
end

-- Only run this the very first time
function ssWeatherManager:buildForecast()
    local startDayNum = ssSeasonsUtil:currentDayNumber()
    local ssTmax

    self.forecast = {}

    for n = 1, self.forecastLength do
        oneDayForecast = {}
        local oneDayRain = {}
        local ssTmax = {}
        local Tmaxmean = {}

        oneDayForecast.day = startDayNum + n - 1 -- To match forecast with actual game
        oneDayForecast.season = ssSeasonsUtil:season(startDayNum + n - 1)

        ssTmax = self.temperatureData[ssSeasonsUtil:currentGrowthTransition(oneDayForecast.day)]
    
        oneDayForecast.highTemp = ssSeasonsUtil:ssNormDist(ssTmax.mode,2.5)
        oneDayForecast.lowTemp = ssSeasonsUtil:ssNormDist(0,2) + 0.75 * ssTmax.mode-5
        --oneDayForecast.weatherState = self:getWeatherStateForDay(startDayNum + n)

        if n == 1 then
            oneDayRain = self:updateRain(oneDayForecast,0)
        else
            if oneDayForecast.day == self.rains[n-1].endDay then
                oneDayRain = self:updateRain(oneDayForecast,self.rains[n-1].endDayTime)
            else
                oneDayRain = self:updateRain(oneDayForecast,0)
            end
        end

        oneDayForecast.weatherState = oneDayRain.rainTypeId

        table.insert(self.forecast, oneDayForecast)
        table.insert(self.rains, oneDayRain)

    end

    g_currentMission.environment.rains = {}
    self:switchRainHail()
    self:owRaintable()

end

function ssWeatherManager:updateForecast()
    local dayNum = ssSeasonsUtil:currentDayNumber() + self.forecastLength-1
    local oneDayRain = {}

    table.remove(self.forecast,1)

    oneDayForecast = {}
    local ssTmax = {}

    oneDayForecast.day = dayNum -- To match forecast with actual game
    oneDayForecast.season = ssSeasonsUtil:season(dayNum)

    ssTmax = self.temperatureData[ssSeasonsUtil:currentGrowthTransition(dayNum)]

    if self.forecast[self.forecastLength-1].season == oneDayForecast.season then
        --Seasonal average for a day in the current season
        oneDayForecast.Tmaxmean = self.forecast[self.forecastLength-1].Tmaxmean

    elseif self.forecast[self.forecastLength-1].season ~= oneDayForecast.season then
        --Seasonal average for a day in the next season
        oneDayForecast.Tmaxmean = ssSeasonsUtil:ssTriDist(ssTmax)

    end

    oneDayForecast.highTemp = ssSeasonsUtil:ssNormDist(ssTmax.mode,2.5)
    oneDayForecast.lowTemp = ssSeasonsUtil:ssNormDist(0,2) + 0.75 * ssTmax.mode-5
    oneDayForecast.weatherState = self:getWeatherStateForDay(dayNum)

    if oneDayForecast.day == self.rains[self.forecastLength-1].endDay then
        oneDayRain = self:updateRain(oneDayForecast,self.rains[self.forecastLength-1].endDayTime)
    else
        oneDayRain = self:updateRain(oneDayForecast,0)
    end

    oneDayForecast.weatherState = oneDayRain.rainTypeId

    table.insert(self.forecast, oneDayForecast)
    table.insert(self.rains, oneDayRain)

    self:switchRainHail()
    self:owRaintable()
    self:calculateSoilTemp()

    table.remove(self.rains, 1)

    g_server:broadcastEvent(ssWeatherForecastEvent:new(oneDayForecast, oneDayRain))

end

function ssWeatherManager:getWeatherStateForDay(dayNumber)
    local weatherState = "sun"
    local ssTmax = {}
    local Tmaxmean = {}

    for index, rain in ipairs(g_currentMission.environment.rains) do
        --log("Bad weather predicted for day: " .. tostring(rain.startDay) .. " weather type: " .. rain.rainTypeId .. " index: " .. tostring(index))
        if rain.startDay > dayNumber then
            break
        end
        if (rain.startDay == dayNumber) then
            weatherState = rain.rainTypeId
        end
    end

    return weatherState
end

function ssWeatherManager:dayChanged()
    if g_currentMission:getIsServer() then
        self:updateForecast()
    end
end

-- Jos note: no randomness here. Must run on client for snow.
function ssWeatherManager:hourChanged()
    self:calculateSnowAccumulation()
end

-- function to output the temperature during the day and night
function ssWeatherManager:diurnalTemp(hour, minute)
    -- need to have the high temp of the previous day
    -- hour is hour in the day from 0 to 23
    -- minute is minutes from 0 to 59

    prevDayTemp = self.forecast[1].highTemp -- not completely correct, but instead of storing the temp of the previous day

    local currentTime = hour*60 + minute

    if currentTime < 420 then
        currentTemp = (math.cos(((currentTime + 540) / 960) * math.pi / 2)) ^ 3 * (prevDayTemp - self.forecast[1].lowTemp) + self.forecast[1].lowTemp
    elseif currentTime > 900 then
        currentTemp = (math.cos(((currentTime - 900) / 960) * math.pi / 2)) ^ 3 * (self.forecast[1].highTemp - self.forecast[2].lowTemp) + self.forecast[1].lowTemp
    else
        currentTemp = (math.cos((1 - (currentTime -  420) / 480) * math.pi / 2) ^ 3) * (self.forecast[1].highTemp - self.forecast[1].lowTemp) + self.forecast[1].lowTemp
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
    if self.forecast[1].season ~= ssSeasonsUtil.SEASON_WINTER then
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

    elseif currentRain.rainTypeId == "hail" and currentTemp < 0 then
        -- Initial value of 10 mm/hr accumulation rate
        if self.snowDepth < 0 then
            self.snowDepth = 0
        end
        self.snowDepth = self.snowDepth + 10/1000

    elseif currentRain.rainTypeId == "hail" and currentTemp >= 0 then
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
    local deltaT = 365 / ssSeasonsUtil.seasonsInYear / ssSeasonsUtil.daysInSeason / 2
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

--- function for predicting when soil is too cold for crops to germinate
function ssWeatherManager:canSow()
    if  self.soilTemp < 5 then
        return false
    else
        return true
    end
end

--- function for predicting when soil is frozen
function ssWeatherManager:isGroundFrozen()
    if  self.soilTemp < 0 then
        return false
    else
        return true
    end
end

function ssWeatherManager:getSnowHeight()
    return self.snowDepth
end

function ssWeatherManager:switchRainHail()
    for index, rain in ipairs(g_currentMission.environment.rains) do
        for jndex, fCast in ipairs(self.forecast) do
             if (rain.startDay == fCast.day) then
                if fCast.lowTemp < -1 and rain.rainTypeId == 'rain' then
                    g_currentMission.environment.rains[index].rainTypeId = 'hail'
                    self.forecast[jndex].weatherState = 'hail'
                elseif fCast.lowTemp >= -1 and rain.rainTypeId == 'hail' then
                    g_currentMission.environment.rains[index].rainTypeId = 'rain'
                    self.forecast[jndex].weatherState = 'rain'
                end
            end
        end
    end
end

function ssWeatherManager:updateRain(oneDayForecast,endRainTime)
    rainFactors = self.rainData[ssSeasonsUtil:seasonName(oneDayForecast.day)]

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
        oneRainEvent = self:_rainStartEnd(p,endRainTime)

        if oneDayForecast.lowTemp < 1 then
            oneRainEvent.rainTypeId = "hail" -- forecast snow if temp < 1
        else
            oneRainEvent.rainTypeId = "rain"
        end

    elseif p > rainFactors.probRain and p < rainFactors.probClouds then
        oneRainEvent = self:_rainStartEnd(p,endRainTime)
        oneRainEvent.rainTypeId = "cloudy"
    elseif oneDayForecast.lowTemp > -1 and oneDayForecast.lowTemp < 2 and endRainTime < 10800000 then
        -- morning fog
        oneRainEvent.startDay = oneDayForecast.day
        oneRainEvent.endDay = oneDayForecast.day
        local dayStart, dayEnd, nightEnd, nightStart = ssTime:calculateStartEndOfDay(oneDayForecast.day)

        oneRainEvent.startDayTime = nightEnd*60*60*1000
        oneRainEvent.endDayTime = (dayStart+1)*60*60*1000+0.000001
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

function ssWeatherManager:_rainStartEnd(p,endRainTime)
    local oneRainEvent = {}

    oneRainEvent.startDay = oneDayForecast.day
    oneRainEvent.duration = math.exp(ssSeasonsUtil:ssLognormDist(rainFactors.beta,rainFactors.gamma,p))*60*60*1000
    -- rain can start from 01:00 (or 1 hour after last rain ended) to 23.00
    oneRainEvent.startDayTime = math.random(3600 + endRainTime,82800) *1000+0.1

    if oneRainEvent.startDayTime + oneRainEvent.duration < 86400000 then
        oneRainEvent.endDay = oneRainEvent.startDay
        oneRainEvent.endDayTime =  oneRainEvent.startDayTime + oneRainEvent.duration + 0.000001
    else
        oneRainEvent.endDay = oneRainEvent.startDay + 1
        oneRainEvent.endDayTime =  oneRainEvent.startDayTime + oneRainEvent.duration - 86400000 + 0.000001
    end

    return oneRainEvent
end

function ssWeatherManager:_randomRain(day)
    math.random() -- to initiate random number generator

    ssTmax = self.temperatureData[ssSeasonsUtil:currentGrowthTransition(day)]

    if oneDayForecast.season == ssSeasonsUtil.SEASON_WINTER or oneDayForecast.season == ssSeasonsUtil.SEASON_AUTUMN then
        if oneDayForecast.highTemp > ssTmax.mode then
            p = math.random()^1.5 --increasing probability for precipitation if the temp is high
        else
            p = math.random()^0.75 --decreasing probability for precipitation if the temp is high
        end
    elseif oneDayForecast.season == ssSeasonsUtil.SEASON_SPRING or oneDayForecast.season == ssSeasonsUtil.SEASON_SUMMER then
        if oneDayForecast.highTemp < ssTmax.mode then
            p = math.random()^1.5 --increasing probability for precipitation if the temp is high
        else
            p = math.random()^0.75 --decreasing probability for precipitation if the temp is high
        end
    end

    return p
end

function ssWeatherManager:owRaintable()
    local rain = {}

    for index = 1, self.forecastLength do
        if self.rains[index].rainTypeId ~= "sun" then
            table.insert(rain, self.rains[index])
        end
    end

    g_currentMission.environment.rains = rain
end

function ssWeatherManager:loadTemperature()
    self.temperatureData = {}

    -- Open file
    local file = loadXMLFile("weather", ssSeasonsMod.modDir .. "data/weather.xml")

    local i = 0;
    while true do
        local key = string.format("weather.temperature.p(%d)", i);
        if not hasXMLProperty(file, key) then break end

        local period = getXMLInt(file, key .. "#period");
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

    -- Close file
    delete(file)
end

function ssWeatherManager:loadRain()
    ssWeatherManager.rainData = {}

    -- Open file
    local file = loadXMLFile("weather", ssSeasonsMod.modDir .. "data/weather.xml")

    local i = 0;
    while true do
        local key = string.format("weather.rain.s(%d)", i);
        if not hasXMLProperty(file, key) then break end

        local season = getXMLString(file, key .. "#season");
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

    -- Close file
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
    day.season = ssSeasonsUtil:season(day.day)
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

        ssWeatherManager:switchRainHail()
        ssWeatherManager:owRaintable()

        table.remove(ssWeatherManager.rains, 1)
    end
end
