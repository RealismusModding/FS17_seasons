----------------------------------------------------------------------------------------------------
-- WEATHER FORECAST SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  to create and update the weather forecast
-- Authors:  Rahkiin, reallogger, theSeb
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssWeatherForecast = {}
ssWeatherForecast.UNITTIME = 60 * 60 * 1000 -- ms to hours

function ssWeatherForecast:preLoad()
    g_seasons.forecast = self
end

function ssWeatherForecast:loadMap(name)
    ssUtil.overwrittenFunction(Environment, "calculateGroundWetness", ssWeatherManager.calculateSoilWetness)

    self.forecastLength = 8

    if g_currentMission:getIsServer() then
        if table.getn(self.forecast) == 0 or self.forecast[1].day ~= g_seasons.environment:currentDay() then
            self:buildForecast()
        end
        --self.weather = g_currentMission.environment.rains -- should only be done for a fresh savegame, otherwise read from savegame
        --self:setupStartValues()
    end
-- self.forecast = {} --day of week, low temp, high temp, weather condition
-- self.weather = {}
end

-- Only run this the very first time or if season length changes
function ssWeatherForecast:buildForecast()
    local startDayNum = g_seasons.environment:currentDay()

    if ssWeatherManager.prevHighTemp == nil then
        ssWeatherManager.prevHighTemp = ssWeatherData.startValues.highAirTemp -- initial assumption high temperature during last day of winter.
    end

    self.forecast = {}

    for i = 1, self.forecastLength do
        local forecastItem = self:oneDayForecast(i, self.forecast[table.getn(self.forecast)])

        table.insert(self.forecast, forecastItem)
    end

    --print_r(self.forecast)
    self:buildWeather()
    --print_r(ssWeatherManager.weather)
    self:overwriteRaintable()
end

function ssWeatherForecast:updateForecast()
    local forecastItem = self:oneDayForecast(self.forecastLength, self.forecast[table.getn(self.forecast)])

    ssWeatherManager.prevHighTemp = self.forecast[1].highTemp  -- updating prev high temp before updating forecast table

    table.remove(self.forecast, 1)
    table.insert(self.forecast, forecastItem)

    self:updateWeather()
    --self:updateHail()
    self:overwriteRaintable()

    --TODO: fix event
    --g_server:broadcastEvent(ssWeatherManagerDailyEvent:new(oneDayForecast, oneDayRain, ssWeatherManager.prevHighTemp, ssWeatherManager.soilTemp))
end

function ssWeatherForecast:oneDayForecast(i,prevDayForecast)
    local dayForecast = {}
    local pPrev = 0.5

    dayForecast.day = g_seasons.environment:currentDay() + i - 1
    dayForecast.season = g_seasons.environment:seasonAtDay(dayForecast.day)

    local growthTransition = g_seasons.environment:transitionAtDay(dayForecast.day)
    local transitionLength = g_seasons.environment.daysInSeason / 3
    local dayInTransition = (g_seasons.environment:dayInSeason(dayForecast.day) - 1) % transitionLength + 1

    if dayInTransition == 1 then
        dayForecast.ssTmax = self:calculateAverageTransitionTemp(growthTransition)
    else
        dayForecast.ssTmax = prevDayForecast.ssTmax
    end

    local lowTemp, highTemp = self:calculateTemp(dayForecast.ssTmax)
    dayForecast.lowTemp = lowTemp
    dayForecast.highTemp = highTemp
    dayForecast.p = self:_randomRain(dayForecast.ssTmax, dayForecast.season, highTemp)

    dayForecast.startTimeIndication = math.random() * 22 + 1 -- avoiding 1 hour before and after midnight
    local startTimeTemp = ssWeatherManager:diurnalTemp(dayForecast.startTimeIndication, highTemp, lowTemp, highTemp, lowTemp)
    local avgTemp = (lowTemp + highTemp) / 2

    if i ~= 1 then
        pPrev = prevDayForecast.p
    end

    dayForecast.windSpeed = ssWeatherManager:calculateWindSpeed(dayForecast.p, pPrev, growthTransition)
    dayForecast.weatherType = self:getWeatherType(dayForecast.day, dayForecast.p, startTimeTemp, avgTemp, dayForecast.windSpeed)
    dayForecast.numEvents = self:_getNumEvents(dayForecast.weatherType)

    -- lower temperatures if it is rain, fog or snow
    if dayForecast.weatherType == ssWeatherManager.WEATHERTYPE_FOG or
            dayForecast.weatherType== ssWeatherManager.WEATHERTYPE_RAIN or
            dayForecast.weatherType== ssWeatherManager.WEATHERTYPE_SNOW then
        highTemp = avgTemp
    end

    return dayForecast
end

function ssWeatherForecast:_getNumEvents(wt)
    if wt == ssWeatherManager.WEATHERTYPE_PARTLY_CLOUDY or
            wt == ssWeatherManager.WEATHERTYPE_RAIN_SHOWERS or
            wt == ssWeatherManager.WEATHERTYPE_SNOW_SHOWERS or
            wt == ssWeatherManager.WEATHERTYPE_SLEET then
        return math.floor(ssUtil.triDist(1, 2, 4))

    elseif wt == ssWeatherManager.WEATHERTYPE_CLOUDY or
            wt == ssWeatherManager.WEATHERTYPE_RAIN or
            wt == ssWeatherManager.WEATHERTYPE_SNOW or
            wt == ssWeatherManager.WEATHERTYPE_FOG then
        return 1

    else
        return 0

    end
end

function ssWeatherForecast:buildHourlyForecast()
    self.hourlyForecast = {}

    for i = 1, 48 do
        local forecastItem = self:oneHourForecast(i)
        table.insert(self.hourlyForecast, forecastItem)
    end
end

function ssWeatherForecast:updateHourlyForecast()
    local forecastItem = self:oneHourForecast(48)
    table.insert(self.hourlyForecast, forecastItem)
    table.remove(self.hourlyForecast, 1)
end

function ssWeatherForecast:oneHourForecast(i)
    local oneHourForecast = {}

    local hour = (g_currentMission.environment.currentHour + i) % 24
    local dayIndex = math.floor((g_currentMission.environment.currentHour + i) / 24)
    local day = g_seasons.environment:currentDay() + dayIndex

    local lowTemp = g_seasons.forecast[dayIndex + 1].lowTemp
    local highTemp = g_seasons.forecast[dayIndex + 1].highTemp
    local lowTempNext = g_seasons.forecast[dayIndex + 2].lowTemp

    oneHourForecast.day = day
    oneHourForecast.hour = hour
    oneHourForecast.rainType = self.getRainType(day, hour)
    oneHourForecast.temperature = ssWeatherManager:diurnalTemp(hour, highTemp, lowTemp, highTemp, lowTempNext) -- TODO: use highTempPrev
    oneHourForecast.windSpeed = ssWeatherManager:calculateWindSpeed()

    return oneHourForecast
end

-- Change rain into snow when it is freezing, and snow into rain if it is too hot
function ssWeatherForecast:switchRainSnow()
    for index, rain in ipairs(g_currentMission.environment.rains) do
        for jndex, fCast in ipairs(self.forecast) do
             if rain.startDay == fCast.day then
                local startTime = rain.startDayTime / 60 / 60 / 1000
                local tempStartRain = ssWeatherManager:diurnalTemp(startTime, fCast.highTemp, fCast.lowTemp, fCast.highTemp, fCast.lowTemp)

                if tempStartRain < -1 and rain.rainTypeId == ssWeatherManager.RAINTYPE_RAIN then
                    g_currentMission.environment.rains[index].rainTypeId = ssWeatherManager.RAINTYPE_SNOW
                    self.forecast[jndex].weatherType = ssWeatherManager.RAINTYPE_SNOW

                elseif tempStartRain >= -1 and rain.rainTypeId == ssWeatherManager.RAINTYPE_SNOW then
                    g_currentMission.environment.rains[index].rainTypeId = ssWeatherManager.RAINTYPE_RAIN
                    self.forecast[jndex].weatherType = ssWeatherManager.RAINTYPE_.RAIN
                end
            end
        end
    end
end

function ssWeatherForecast:_randomRain(ssTmax, season, highTemp)

    if season == g_seasons.environment.SEASON_WINTER or season == g_seasons.environment.SEASON_AUTUMN then
        if highTemp > ssTmax then
            p = math.random() ^ 1.5 --increasing probability for precipitation if the temp is high
        else
            p = math.random() ^ 0.75 --decreasing probability for precipitation if the temp is high
        end
    elseif season == g_seasons.environment.SEASON_SPRING or season == g_seasons.environment.SEASON_SUMMER then
        if highTemp < ssTmax then
            p = math.random() ^ 1.5 --increasing probability for precipitation if the temp is high
        else
            p = math.random() ^ 0.75 --decreasing probability for precipitation if the temp is high
        end
    end

    return p
end

function ssWeatherForecast:getRainEvent(dayForecast, prevEndDayTime, i)
    local oneRainEvent = {}

    local earlyRainTime = prevEndDayTime + 1 * ssWeatherForecast.UNITTIME
    if earlyRainTime > 24 * ssWeatherForecast.UNITTIME then
        earlyRainTime = earlyRainTime - 24 * ssWeatherForecast.UNITTIME
    end

    oneRainEvent.startDay = dayForecast.day
    oneRainEvent.endDay = oneRainEvent.startDay
    local season = dayForecast.season
    local gt = g_seasons.environment:transitionAtDay(dayForecast.day)
    local season = g_seasons.environment:seasonAtDay(dayForecast.day)

    local pRain = ssWeatherData.rainProbData[growthTransition]
    local wt = dayForecast.weatherType
    local events = dayForecast.numEvents
    local lowTemp = dayForecast.lowTemp
    local highTemp = dayForecast.highTemp

    -- setting startTime, endTime and duration
    -- shorter, multiple events
    if wt == ssWeatherManager.WEATHERTYPE_PARTLY_CLOUDY or
            wt == ssWeatherManager.WEATHERTYPE_RAIN_SHOWERS or
            wt == ssWeatherManager.WEATHERTYPE_SNOW_SHOWERS or
            wt == ssWeatherManager.WEATHERTYPE_SLEET then

        oneRainEvent.startDayTime = (math.random() * 24 / (events + 1) * (i + 1) + earlyRainTime / ssWeatherForecast.UNITTIME) * ssWeatherForecast.UNITTIME
        --oneRainEvent.duration = (math.min(math.max(math.exp(ssUtil.lognormDist(beta, gamma, math.random())) / events, 2), 24 / (events + 4))) * ssWeatherForecast.UNITTIME -- capping length of each event
        oneRainEvent.duration = ssUtil.triDist(1,2,24 / (events + 4)) * ssWeatherForecast.UNITTIME
        oneRainEvent.endDayTime = oneRainEvent.startDayTime + oneRainEvent.duration

    -- one longer event
    elseif wt == ssWeatherManager.WEATHERTYPE_CLOUDY or
            wt == ssWeatherManager.WEATHERTYPE_RAIN or
            wt == ssWeatherManager.WEATHERTYPE_SNOW or
            wt == ssWeatherManager.WEATHERTYPE_FOG then

        oneRainEvent.startDayTime = (math.random() * 10 + 1) * ssWeatherForecast.UNITTIME
        oneRainEvent.endDayTime = (math.random() * 5 + 18) * ssWeatherForecast.UNITTIME
        oneRainEvent.duration = oneRainEvent.endDayTime - oneRainEvent.startDayTime
    end

    -- correcting endTime if event ends next day
    if oneRainEvent.endDayTime > 24 * ssWeatherForecast.UNITTIME then
        oneRainEvent.endDayTime = oneRainEvent.endDayTime - 24 * ssWeatherForecast.UNITTIME
        oneRainEvent.endDay = oneRainEvent.endDay + 1 * ssWeatherForecast.UNITTIME
    end

    local tempIndication = ssWeatherManager:diurnalTemp((oneRainEvent.startDayTime + oneRainEvent.endDayTime)/2, highTemp, lowTemp, highTemp, lowTemp)

    -- setting rainTypeId
    if wt == ssWeatherManager.WEATHERTYPE_PARTLY_CLOUDY or wt == ssWeatherManager.WEATHERTYPE_CLOUDY then
        oneRainEvent.rainTypeId = ssWeatherManager.RAINTYPE_CLOUDY

    elseif wt == ssWeatherManager.WEATHERTYPE_RAIN_SHOWERS or
            wt == ssWeatherManager.WEATHERTYPE_RAIN or
            wt == ssWeatherManager.WEATHERTYPE_SNOW_SHOWERS or
            wt == ssWeatherManager.WEATHERTYPE_SNOW or
            wt == ssWeatherManager.WEATHERTYPE_SLEET then

        if tempIndication < 0 then
            oneRainEvent.rainTypeId = ssWeatherManager.RAINTYPE_SNOW
        else
            oneRainEvent.rainTypeId = ssWeatherManager.RAINTYPE_RAIN
        end

    elseif wt == ssWeatherManager.WEATHERTYPE_FOG then
        oneRainEvent.rainTypeId = ssWeatherManager.RAINTYPE_FOG
    end

    return oneRainEvent
end

-- TODO Per: why is this here and not in WM?
function ssWeatherForecast:buildWeather()
    local weather = {}
    local prevEndDayTime = 1 * self.UNITTIME

    for j = 1, 3 do --make weather for the next three days
        local events = self.forecast[j].numEvents

        if events > 0 then
            for i = 1, events do
                local oneRainEvent = self:getRainEvent(self.forecast[j], prevEndDayTime, i)
                table.insert(weather, oneRainEvent)

                prevEndDayTime = oneRainEvent.endDayTime

                -- if last event and events are within the same day reset prevRainTime
                -- if next day is sunny reset prevRainTime
                if i == events and (oneRainEvent.endDay == oneRainEvent.startDay or self.forecast[j + 1].weatherType == ssWeatherManager.WEATHERTYPE_SUN) then
                    prevEndDayTime = 1 * self.UNITTIME
                end
            end
        end
    end

    --self:foggyMorning()
    ssWeatherManager.weather = weather
end

-- adding weather events
-- run after updateForecast
function ssWeatherForecast:updateWeather()
    local prevEndDayTime = 1 * self.UNITTIME
    local events = self.forecast[2].numEvents

    if table.getn(ssWeatherManager.weather) > 0 then
        if ssWeatherManager.weather[1].startDay < g_seasons.environment:currentDay() then
            self:removeWeather()
        end
    end

    if events > 0 then
        for i = 1, events do
            local oneRainEvent = self:getRainEvent(self.forecast[2], prevEndDayTime, i)
            table.insert(ssWeatherManager.weather, oneRainEvent)

            prevEndDayTime = oneRainEvent.endDayTime

            if i == events and endDay == oneRainEvent.startDay then
                prevEndDayTime = 1 * self.UNITTIME
            end
        end
    end

    --self:foggyMorning()
end

function ssWeatherForecast:removeWeather()
    -- update weather do not return anything
end

-- Possible unforcasted morning fog on day 2
function ssWeatherForecast:foggyMorning()
    local lowTempDay = self.forecast[2].lowTemp
    local lowTempPrev = self.forecast[1].lowTemp
    local rh = ssWeatherManager:calculateRelativeHumidity(lowTempDay, (lowTempDay + lowTempPrev) * 0.5, ssWeatherManager.RAINTYPE_SUN)
    local forecastedWind = self.forecast[2].windSpeed

    if rh > 95 and forecastedWind < 3 then
        local potentialFog = true

        -- possible morning fog from 1 am to noon
        for hour = 1, 12 do
            local rt = self:getRainType(self.forecast[2].day, hour)

            if rt ~= ssWeatherManager.RAINTYPE_SUN then
                potentialFog = false
            end
        end

        if potentialFog then
            oneFogEvent = self:_getFogEvent(forecast)
            --local pos = -- TODO: find the right place to include the fog event
            --table.insert(weather, pos, oneFogEvent)
        end
    end
end

function ssWeatherForecast:_getFogEvent()
    local oneFogEvent = {}
    local lowTemp = self.forecast[2].lowTemp
    local highTemp = self.forecast[2].highTemp
    local lowTempPrev= self.forecast[1].lowTemp
    local highTempPrev = self.forecast[1].highTemp
    local lowTempNext = self.forecast[3].lowTemp

    local rhPrev, rh, temp = 0

    local startFogTime = 2
    local endFogTime = 10

    oneFogEvent.startDay = self.forecast[2].day
    oneFogEvent.endDay = self.forecast[2].day


    for hour = 1, 11 do
        temp = ssWeatherManager:diurnalTemperature(hour, highTempPrev,lowTemp,highTemp, lowTempNext)
        rh = ssWeatherManager:calculateRelativeHumidity(temp, (lowTemp + lowTempPrev) * 0.5, ssWeatherManager.RAINTYPE_SUN)

        -- fog if the relative humidity is above 95%
        if rh >= 95 and rhPrev < 95 then
            startFogTime = hour
        elseif rh <= 95 and rhPrev > 95 then
            endFogTime = hour
        end

        rhPrev = rh
    end

    oneFogEvent.startRainTime = startFogTime * ssWeatherForecast.UNITTIME
    oneFogEvent.endRainTime = endFogTime * ssWeatherForecast.UNITTIME
    oneFogEvent.duration = oneFogEvent.endRainTime - oneFogEvent.startRainTime
    oneFogEvent.rainType = ssWeatherManager.RAINTYPE_FOG

    return oneFogEvent
end

-- Overwrite the vanilla rains table using our own forecast
function ssWeatherForecast:overwriteRaintable()
    local env = g_currentMission.environment
    local tmpWeather = {}
    env.numRains = table.getn(ssWeatherManager.weather)

    for index = 1, env.numRains do
        if ssWeatherManager.weather[index].rainTypeId ~= ssWeatherManager.RAINTYPE_SUN then
            local tmpSingleWeather = deepCopy(ssWeatherManager.weather[index])
            table.insert(tmpWeather, tmpSingleWeather)
        end
    end

    env.rains = tmpWeather

    if g_seasons.environment.currentDayOffset ~= nil then
        for index = 1, env.numRains do
            local newStartDay = env.rains[index].startDay - g_seasons.environment.currentDayOffset
            local newEndDay = env.rains[index].endDay - g_seasons.environment.currentDayOffset
            env.rains[index].startDay = newStartDay
            env.rains[index].endDay = newEndDay
        end
    end

    --self:switchRainSnow()
end

-- inserting a hail event
function ssWeatherForecast:updateHail(day)
    local rainFactors = ssWeatherData.rainData[self.forecast[1].season]
    local p = math.random()

    if p < rainFactors.probHail and self.forecast[1].weatherType == ssWeatherManager.RAINTYPE_SUN then
        local julianDay = ssUtil.julianDay(g_seasons.environment:currentDay())
        dayStart, dayEnd, _, _ = g_seasons.daylight:calculateStartEndOfDay(julianDay)

        ssWeatherManager.weather[1].rainTypeId = ssWeatherManager.RAINTYPE_HAIL
        ssWeatherManager.weather[1].startDayTime = ssUtil.triDist(dayStart, dayStart + 4, dayEnd - 6) * ssWeatherForecast.UNITTIME
        ssWeatherManager.weather[1].duration = ssUtil.triDist(1, 2, 3) * ssWeatherForecast.UNITTIME
        ssWeatherManager.weather[1].endDayTime = ssWeatherManager.weather[1].startDayTime + ssWeatherManager.weather[1].duration
        ssWeatherManager.weather[1].startDay = self.forecast[1].day
        ssWeatherManager.weather[1].endDay = self.forecast[1].day

        g_server:broadcastEvent(ssWeatherManagerHailEvent:new(ssWeatherManager.weather[1]))
    end
end

function ssWeatherForecast:getRainType(day, hour)
    local rainType = ssWeatherManager.RAINTYPE_SUN

    for _, rain in ipairs(ssWeatherManager.weather) do
        local startHour = mathRound(rain.startDayTime / 60 / 60 / 1000, 0)
        local endHour = mathRound((rain.endDayTime) / 60 / 60 / 1000 , 0)

        if rain.startDay == day and startHour <= hour and endHour > hour then
            rainType = rain.rainTypeId
        elseif rain.startDay + 1 == day and rain.endDay == day and endHour > hour then
            rainType = rain.rainTypeId
        end
    end

    return rainType
end

function ssWeatherForecast:getWeatherType(day, p, temp, avgTemp, windSpeed)
    local growthTransition = g_seasons.environment:transitionAtDay(day)
    local season = g_seasons.environment:seasonAtDay(day)

    local pRain = ssWeatherData.rainProbData[growthTransition]
    local pClouds = 1 - ssWeatherData.cloudProbData[growthTransition]
    --local pHail = ssWeatherData.hailProbData[season]

    -- assuming definitions consistent with what is used on weatherspark.com TODO: write manual for weather files
    local probPartlyCloudy = math.min(pClouds + 0.1, 1.0)
    local probCloudy = math.max(pClouds - 0.1, 0.1)
    local probRain = pRain * probCloudy / probPartlyCloudy
    local probShowers = pRain

    local tempLimit = 3
    local wType = ssWeatherManager.WEATHERTYPE_SUN

    if p <= probPartlyCloudy and p > probCloudy then
        wType = ssWeatherManager.WEATHERTYPE_PARTLY_CLOUDY

    elseif p <= probCloudy and p > probShowers and temp >= tempLimit then
        wType = ssWeatherManager.WEATHERTYPE_CLOUDY

    elseif p <= probShowers and p > probRain and temp >= tempLimit then
        wType = ssWeatherManager.WEATHERTYPE_RAIN_SHOWERS

    elseif p <= probRain and temp >= tempLimit then
        wType = ssWeatherManager.WEATHERTYPE_RAIN

    elseif p <= probShowers and temp >= -tempLimit and temp < tempLimit then
        wType = ssWeatherManager.WEATHERTYPE_SLEET

    elseif p <= probShowers and p > probRain and temp < -tempLimit then
        wType = ssWeatherManager.WEATHERTYPE_SNOW_SHOWERS

    elseif p <= probRain and temp < -tempLimit then
        wType = ssWeatherManager.WEATHERTYPE_SNOW

    elseif p > probPartlyCloudy and avgTemp >= -tempLimit and temp < tempLimit and windSpeed < 3.0 then
        if random.random > 0.3 then
            wType = ssWeatherManager.WEATHERTYPE_FOG
        end
    end

    return wType

end

function ssWeatherForecast:calculateAverageTransitionTemp(gt, deterministic)
    local averageDailyMaximum = ssWeatherData.temperatureData[gt]

    if not deterministic then
        local seasonalTempVar = 0.009 * gt ^ 2 - 0.1 * gt + 1.15
        return ssUtil.normDist(averageDailyMaximum, seasonalTempVar)
    else
        return averageDailyMaximum
    end
end

function ssWeatherForecast:calculateTemp(meanMaxTemp, deterministic)
    local highTemp = meanMaxTemp
    local lowTemp = 0.75 * meanMaxTemp - 5

    if not deterministic then
        highTemp = ssUtil.normDist(meanMaxTemp, 2)
        lowTemp = ssUtil.normDist(0, 1.5) + 0.75 * meanMaxTemp - 5
    end

    return lowTemp, highTemp
end
