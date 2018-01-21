----------------------------------------------------------------------------------------------------
-- WEATHER MANAGER SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  to manage the weather
-- Authors:  Rahkiin, reallogger, theSeb
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssWeatherManager = {}

ssWeatherManager.WEATHERTYPE_SUN = "sun"
ssWeatherManager.WEATHERTYPE_PARTLY_CLOUDY = "partly_cloudy"
ssWeatherManager.WEATHERTYPE_RAIN_SHOWERS = "rain_showers"
ssWeatherManager.WEATHERTYPE_SNOW_SHOWERS = "snow_showers"
ssWeatherManager.WEATHERTYPE_SLEET = "sleet"
ssWeatherManager.WEATHERTYPE_CLOUDY = "cloudy"
ssWeatherManager.WEATHERTYPE_RAIN = "rain"
ssWeatherManager.WEATHERTYPE_SNOW = "snow"
ssWeatherManager.WEATHERTYPE_FOG = "fog"
ssWeatherManager.WEATHERTYPE_THUNDER = "thunder"
ssWeatherManager.WEATHERTYPE_HAIL = "hail"

ssWeatherManager.RAINTYPE_SUN = "sun"
ssWeatherManager.RAINTYPE_CLOUDY = "cloudy"
ssWeatherManager.RAINTYPE_RAIN = "rain"
ssWeatherManager.RAINTYPE_SNOW = "snow"
ssWeatherManager.RAINTYPE_FOG = "fog"
ssWeatherManager.RAINTYPE_HAIL = "hail"

-- Load events
source(ssSeasonsMod.directory .. "src/events/ssWeatherManagerDailyEvent.lua")
source(ssSeasonsMod.directory .. "src/events/ssWeatherManagerHourlyEvent.lua")
source(ssSeasonsMod.directory .. "src/events/ssWeatherManagerHailEvent.lua")

function ssWeatherManager:preLoad()
    g_seasons.weather = self
end

function ssWeatherManager:load(savegame, key)
    self.forecast = {} --day of week, low temp, high temp, weather condition
    self.forecastLength = 8
    self.weather = {}
    self.weatherData = {}
end

function ssWeatherManager:loadMap(name)
    ssUtil.overwrittenFunction(Environment, "calculateGroundWetness", ssWeatherManager.calculateSoilWetness)

    g_currentMission.environment:addHourChangeListener(self)
    g_currentMission.environment:addDayChangeListener(self)
    g_seasons.environment:addSeasonLengthChangeListener(self)
    g_seasons.environment:addTransitionChangeListener(self)

end

function ssWeatherManager:loadGameFinished()
    if g_currentMission:getIsServer() then
        if g_seasons.isNewSavegame and self.snowDepth > 0 then
            g_seasons.snow:applySnow(self.snowDepth)
        end
    end
end

--function ssWeatherManager:readStream(streamId, connection)
--    self.snowDepth = streamReadFloat32(streamId)
--    self.soilTemp = streamReadFloat32(streamId)
--    self.cropMoistureContent = streamReadFloat32(streamId)
--    self.moistureEnabled = streamReadBool(streamId)
--    self.prevHighTemp = streamReadFloat32(streamId)
--    self.soilWaterContent = streamReadFloat32(streamId)

--    self.forecastLength = streamReadUInt8(streamId)
--    local numRains = streamReadUInt8(streamId)

    -- load forecast
--    self.forecast = {}

--    for i = 1, self.forecastLength do
--        local day = {}

--        day.day = streamReadInt16(streamId)
--        day.season = streamReadUInt8(streamId)

--        day.weatherType = streamReadString(streamId)
--        day.highTemp = streamReadFloat32(streamId)
--        day.lowTemp = streamReadFloat32(streamId)

--        table.insert(self.forecast, day)
--    end

    -- load rains
--    self.weather = {}

--    for i = 1, numRains do
--        local rain = {}

--        rain.startDay = streamReadInt16(streamId)
--        rain.endDayTime = streamReadFloat32(streamId)
--        rain.startDayTime = streamReadFloat32(streamId)
--        rain.endDay = streamReadInt16(streamId)
--        rain.rainTypeId = streamReadString(streamId)
--        rain.duration = streamReadFloat32(streamId)

--        table.insert(self.weather, rain)
--    end

--    self:overwriteRaintable()
--    self:setupStartValues()
--end

--function ssWeatherManager:writeStream(streamId, connection)
--    streamWriteFloat32(streamId, self.snowDepth)
--    streamWriteFloat32(streamId, self.soilTemp)
--    streamWriteFloat32(streamId, self.cropMoistureContent)
--    streamWriteBool(streamId, self.moistureEnabled)
--    streamWriteFloat32(streamId, self.prevHighTemp)
--    streamWriteFloat32(streamId, self.soilWaterContent)

--    streamWriteUInt8(streamId, table.getn(self.forecast))
--    streamWriteUInt8(streamId, table.getn(self.weather))

--    for _, day in pairs(self.forecast) do
--        streamWriteInt16(streamId, day.day)
--        streamWriteUInt8(streamId, day.season)

--        streamWriteString(streamId, day.weatherType)
--        streamWriteFloat32(streamId, day.highTemp)
--        streamWriteFloat32(streamId, day.lowTemp)
--    end

--    for _, rain in pairs(self.weather) do
--        streamWriteInt16(streamId, rain.startDay)
--        streamWriteFloat32(streamId, rain.endDayTime)
--        streamWriteFloat32(streamId, rain.startDayTime)
--        streamWriteInt16(streamId, rain.endDay)
--        streamWriteString(streamId, rain.rainTypeId)
--        streamWriteFloat32(streamId, rain.duration)
--    end
--end

function ssWeatherManager:update(dt)
    local currentRain = g_currentMission.environment.currentRain

    if currentRain ~= nil then
        local currentTemp = mathRound(self:currentTemperature(), 0)

        -- If temperature is 1 or higher and it would be snowing, rain instead. Same for other way around
        if currentTemp > 1 and currentRain.rainTypeId == self.RAINTYPE_SNOW then
            setVisibility(g_currentMission.environment.rainTypeIdToType.snow.rootNode, false)
            currentRain.rainTypeId = self.RAINTYPE_RAIN
            setVisibility(g_currentMission.environment.rainTypeIdToType.rain.rootNode, true)

        elseif currentTemp < 0 and currentRain.rainTypeId == self.RAINTYPE_RAIN then
            setVisibility(g_currentMission.environment.rainTypeIdToType.rain.rootNode, false)
            currentRain.rainTypeId = self.RAINTYPE_SNOW
            setVisibility(g_currentMission.environment.rainTypeIdToType.snow.rootNode, true)
        end
    end

    -- updating visual wind
    setSharedShaderParameter(0, self.windSpeed / 15)
end

function ssWeatherManager:seasonLengthChanged()
    if g_currentMission:getIsServer() then
        local isFrozen = self:isGroundFrozen()

        self:buildForecast()

        -- The new forecast is sent with the ssSettings event.
    end
end

function ssWeatherManager:dayChanged()
    if g_currentMission:getIsServer() then
        local isFrozen = self:isGroundFrozen()

        ssWeatherForecast:updateForecast()
        self:calculateSoilTemp(ssWeatherForecast.forecast[1].lowTemp, ssWeatherForecast.forecast[1].highTemp, g_seasons.environment.daysInSeason, self.soilTemp, false)

        if isFrozen ~= self:isGroundFrozen() then
            -- Call a weather change
            for _, listener in pairs(g_currentMission.environment.weatherChangeListeners) do
                listener:weatherChanged()
            end
        end

        g_seasons.growthManager:rebuildWillGerminateData()
    end
end

function ssWeatherManager:transitionChanged()
    if g_currentMission:getIsServer() then
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

    self:updateWindSpeed()
end

-- function to output the temperature during the day and night
function ssWeatherManager:diurnalTemp(currentTime, highTempPrev, lowTemp, highTemp, lowTempNext)

    if highTempPrev == nil or lowTemp == nil or highTemp == nil or lowTempNext == nil then
        lowTemp = ssWeatherForecast.forecast[1].lowTemp
        highTemp = ssWeatherForecast.forecast[1].highTemp
        lowTempNext = ssWeatherForecast.forecast[2].lowTemp
        highTempPrev = ssWeatherManager.prevHighTemp
    end

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
    local seasonLengthFactor = math.max(9 / g_seasons.environment.daysInSeason, 1.0)
    local currentTemp = self:currentTemperature()
    local effectiveMeltTemp = math.max(currentTemp, 0) + math.max(self.soilTemp, 0)
    local windMeltFactor = 1 + math.max(self.windSpeed - 5, 0) / 25

    -- calculating snow melt as a function of radiation
    local snowMelt = math.max(0.001 * effectiveMeltTemp ) * (1 + g_seasons.daylight:calculateSolarRadiation() / 5) * seasonLengthFactor * windMeltFactor

    -- melting snow
    if currentTemp >= 0 then
        if currentRain == nil then
            self.meltedSnow = snowMelt

        elseif currentRain.rainTypeId == self.RAINTYPE_RAIN or currentRain.rainTypeId == self.RAINTYPE_SNOW then
            -- assume snow melts 50% faster if it rains. Warm snow acts as rain.
            self.meltedSnow = snowMelt * 1.5

        elseif currentRain.rainTypeId == self.RAINTYPE_CLOUDY or currentRain.rainTypeId == self.RAINTYPE_FOG then
            self.meltedSnow = snowMelt
        end

        self.snowDepth = self.snowDepth - self.meltedSnow

    -- accumulating snow
    elseif currentTemp < 0 and currentRain ~= nil then
        if currentRain.rainTypeId == self.RAINTYPE_RAIN or currentRain.rainTypeId == self.RAINTYPE_SNOW then
            -- cold rain acts as snow
            -- Initial value of 10 mm/hr accumulation rate. Higher rate when there is little snow to get the visual effect
            if self.snowDepth < 0 then
                self.snowDepth = 0
            elseif self.snowDepth > 0.06 then
                self.snowDepth = self.snowDepth + 10 / 1000 * seasonLengthFactor
            else
                self.snowDepth = self.snowDepth + 31 / 1000
            end
        end
    end
end

--- function for calculating soil temperature
--- Based on Rankinen et al. (2004), A simple model for predicting soil temperature in snow-covered and seasonally frozen soil: model description and testing
function ssWeatherManager:calculateSoilTemp(lowTemp, highTemp, daysInSeason, soilTemp, simulation)
    local avgAirTemp = (highTemp * 8 + lowTemp * 16) / 24
    local deltaT = 365 / g_seasons.environment.SEASONS_IN_YEAR / daysInSeason / 2

    -- average soil thermal conductivity, unit: kW/m/deg C, typical value s0.4-0.8
    local facKT = 0.6
    -- average thermal conductivity of soil and ice C_S + C_ICE, unit: kW/m/deg C, typical values C_S = 1-1.3, C_ICE = 4-15
    local facCA = 10
    -- empirical snow damping parameter, unit 1/m, typical values -2 - -7
    local facfs = -5

    soilTemp = soilTemp + math.min(deltaT * facKT / (0.81 * facCA), 0.8) * (avgAirTemp - soilTemp) * math.exp(facfs * math.max(self.snowDepth, 0))

    if not simulation and self.soilTemp > self.soilTempMax then
        self.soilTempMax = self.soilTemp
    end

    return soilTemp
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

--- function for predicting when soil is too cold for crops to germinate
function ssWeatherManager:germinationTemperature(fruit)
    return Utils.getNoNil(ssWeatherData.germinateTemp[fruit], ssWeatherData.germinateTemp["barley"])
end

-- On server this uses the max temp.
-- Otherwise, returns nil
function ssWeatherManager:canSow(fruit)
    if g_currentMission:getIsServer() then
        return self.soilTempMax >= self:germinationTemperature(fruit)
    else
        return nil
    end
end

-- function to calculate relative humidity
-- http://onlinelibrary.wiley.com/doi/10.1002/met.258/pdf
function ssWeatherManager:calculateRelativeHumidity(currentTemp, lowTemp, rainType)
    if currentTemp == nil then
        currentTemp = self:currentTemperature()
    end

    if lowTemp == nil then
        lowTemp = ssWeatherForecast.forecast[1].lowTemp
    end

    if rainType == nil then
        if g_currentMission.environment.currentRain ~= nil then
            rainType = g_currentMission.environment.currentRain.rainTypeId
        else
            rainType = ssWeatherManager.RAINTYPE_SUN
        end
    end

    local relativeHumidity = 80
    local dewPointTemp = lowTemp - 2
    local es = 6.1078 - math.exp(17.2669 * dewPointTemp / ( dewPointTemp + 237.3 ) )
    local e = 6.1078 - math.exp(17.2669 * currentTemp / ( currentTemp + 237.3 ) )

    relativeHumidity = 100 * e / es

    if rainType == ssWeatherManager.RAINTYPE_RAIN or rainType == ssWeatherManager.RAINTYPE_FOG or rainType == ssWeatherManager.RAINTYPE_HAIL then
        relativeHumidity = 95
    end

    return Utils.clamp(relativeHumidity, 5, 100)
end

function ssWeatherManager:updateCropMoistureContent()
    local dayTime = g_currentMission.environment.dayTime

    local prevCropMoist = self.cropMoistureContent
    local relativeHumidity = self:calculateRelativeHumidity()
    local solarRadiation = g_seasons.daylight:calculateSolarRadiation()

    local tmpMoisture = prevCropMoist + (relativeHumidity - prevCropMoist - 10) / 25
    local deltaMoisture = math.min(self.windSpeed * (1.1 - 0.3 * g_currentMission.missionInfo.difficulty) + solarRadiation / 1.5 * (tmpMoisture - 10), self.cropMoistureContent - 13, 5)

    self.cropMoistureContent = math.min(tmpMoisture - deltaMoisture, 40)

    -- increase crop Moisture when it rains with 4% every hour it rains, with cap at 40%
    if g_currentMission.environment.timeSinceLastRain == 0 then
        self.cropMoistureContent = math.min(self.cropMoistureContent + 4, 40)
    end

end

function ssWeatherManager:updateSoilWaterContent()
    --Soil moisture bucket model
    --Guswa, A. J., M. A. Celia, and I. Rodriguez-Iturbe, Models of soil moisture dynamics in ecohydrology: A comparative study,
    --Water Resour. Res., 38(9), 1166, doi:10.1029/2001WR000826, 2002

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
    local soilWaterInfiltration = self:calculateWaterInfiltration()

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

    soilWaterLeakage = math.max(Ksat * (math.exp(beta*(prevSoilWaterCont - Sfc)) - 1) / (math.exp(beta*(1 - Sfc)) - 1),0)
    self.soilWaterContent = math.min(prevSoilWaterCont + 1 / (soilPorosity * depthRootZone) * (soilWaterInfiltration - soilWaterLeakage - soilWaterTranspiration - soilWaterEvaporation), 1)
end

function ssWeatherManager:calculateRainAmount()
    local amount = 0
    local seasonLengthFactor = (3.0 * g_seasons.environment.daysInSeason)^0.1
    local weatherTypeFactor = 1

    -- less intensity with "all day" rain
    if self.currentWeatherType == self.WEATHERTYPE_RAIN then
        weatherTypeFactor = 0.5
    -- strong rain when thunder
    elseif self.currentWeatherType == self.WEATHERTYPE_THUNDER then
        weatherTypeFactor = 2
    end

    if g_currentMission.environment.currentRain ~= nil then
        currentRainId = g_currentMission.environment.currentRain.rainTypeId

        if currentRainId == self.RAINTYPE_RAIN then
            amount = 0.5
        elseif currentRainId == self.RAINTYPE_HAIL then
            amount = 0.75
        end

        return amount * weatherTypeFactor * seasonLengthFactor
    else
        return 0
    end
end

function ssWeatherManager:calculateWaterInfiltration()
    local snowMelt = 0
    local rainAmount = self:calculateRainAmount()

    -- not add water from melted snow if only piles are melting or if the ground is not frozen
    if self.meltedSnow ~= 0 and self.snowDepth > 0 and not self:isGroundFrozen() then
        -- 30% of melted snow infiltrates, meltedSnow in meter, snow density 400 kg/m3
        -- dividing by 10 due to unit cm
        snowMelt = 0.3 * self.meltedSnow * 400 / 10
    end

    return snowMelt + rainAmount
end

function ssWeatherManager:calculateSoilWetness()
    if ssWeatherManager:isGroundFrozen() then
        return 0
    else
        return ssWeatherManager.soilWaterContent
    end
end

-- updating wind hourly
function ssWeatherManager:updateWindSpeed()
    if g_currentMission.environment.currentHour < ssWeatherForecast.forecast[1].startTimeIndication and
            g_currentMission.environment.currentHour + 1 >= ssWeatherForecast.forecast[1].startTimeIndication then
        g_seasons.weather.windSpeedDelta = self:calculateDeltaWindSpeed()

        -- to avoid rounding errors with a long savegame
        self.windSpeed = ssWeatherForecast.forecast[1].windSpeed
    else
        self.windSpeed = self.windSpeed + g_seasons.weather.windSpeedDelta
    end
end

function ssWeatherManager:calculateDeltaWindSpeed()
    local speedNow = ssWeatherForecast.forecast[1].windSpeed
    local speedNext = ssWeatherForecast.forecast[2].windSpeed
    local deltaTime = 24 - ssWeatherForecast.forecast[1].startTimeIndication + ssWeatherForecast.forecast[2].startTimeIndication

    return (speedNext - speedNow) / deltaTime
end

function ssWeatherManager:calculateWindSpeed(p, pPrev, gt)
    -- wind speed is related to changing barometric pressure
    -- simulated as a change in weather
    -- weibull distribution for wind speed for 10 min average wind speed
    -- assumed shape parameter for all locations
    -- if using hourly average multiply all values with 1.5
    local shape = 2.0
    local scale = ssWeatherData.windData[gt]
    local pressureGradient = math.abs(pPrev - p)^0.35

    return scale * (-1 * math.log(1 - pressureGradient)) ^ (1 / shape)
end

function ssWeatherManager:soilTooColdForGrowth(germinationTemperature)
    local tooColdSoil = {}
    local lowSoilTemp = {}
    local soilTemp = {}

    local daysInSeason = 9
    local tempLimit = germinationTemperature - 1

    for i = 1,12 do
        lowSoilTemp[i] = -math.huge
    end

    -- run after loading data from xml so self.soilTemp will be initial value at this point
    soilTemp[1] = ssWeatherData.startValues.soilTemp
    -- building table with hard coded 9 day season
    for i = 2, 4 * daysInSeason do
        local gt = g_seasons.environment:transitionAtDay(i, daysInSeason)
        local gtPrevDay = g_seasons.environment:transitionAtDay(i - 1, daysInSeason)

        local averageDailyMaximum = ssWeatherData.temperatureData[gt]
        local lowTemp, highTemp = ssWeatherForecast:calculateTemp(averageDailyMaximum, true)

        soilTemp[i], _ = self:calculateSoilTemp(lowTemp, highTemp, daysInSeason, soilTemp[i - 1], true)
        if soilTemp[i] > lowSoilTemp[gt] then
            lowSoilTemp[gt] = soilTemp[i]
        end

        if gt > gtPrevDay and soilTemp[i] > soilTemp[i - 1] then
            lowSoilTemp[gt - 1] = soilTemp[i]
        end
    end

    for i = 1, 12 do
        tooColdSoil[i] = lowSoilTemp[i] < tempLimit
    end

    return tooColdSoil
end