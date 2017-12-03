----------------------------------------------------------------------------------------------------
-- WEATHER MANAGER DATA SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  to manage data for the Weather Manager
-- Authors:  Rahkiin, reallogger, theSeb
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssWeatherData = {}
g_seasons.weatherData = ssWeatherData

function ssWeatherData:loadMap(name)
    g_currentMission.environment.minRainInterval = 1
    g_currentMission.environment.minRainDuration = 2 * 60 * 60 * 1000 -- 30 hours
    g_currentMission.environment.maxRainInterval = 1
    g_currentMission.environment.maxRainDuration = 24 * 60 * 60 * 1000
    g_currentMission.environment.rainForecastDays = self.forecastLength
    g_currentMission.environment.autoRain = false

    -- Load data from the mod and from a map
    self.temperatureData = {}
    self.rainData = {}
    self.cloudData = {}
    self.hailData = {}
    self.windData = {}
    self.startValues = {}
    self:loadFromXML(g_seasons.modDir .. "data/weather.xml")

    -- Modded
    for _, path in ipairs(g_seasons:getModPaths("weather")) do
        self:loadFromXML(path)
    end

    -- Set snowDepth (can be more than 0 with custom weather)
    g_seasons.weather.snowDepth = Utils.getNoNil(self.snowDepth, self.startValues.snowDepth)

    -- Load germination temperatures
    self.germinateTemp = {}
    self:loadGerminateTemperature(g_seasons.modDir .. "data/growth.xml")

    for _, path in ipairs(g_seasons:getModPaths("growth")) do
        self:loadGerminateTemperature(path)
    end

    if g_currentMission:getIsServer() then
        self:setupStartValues()
    end
end

function ssWeatherData:setupStartValues()
    if g_currentMission:getIsClient() then
        g_seasons.weather.soilTemp = Utils.getNoNil(g_seasons.weather.soilTemp, self.startValues.soilTemp)
        g_seasons.weather.soilTempMax = g_seasons.weather.soilTemp
    end
end

function ssWeatherData:load(savegame, key)
    -- Load or set default values
    ssWeatherManager.snowDepth = ssXMLUtil.getFloat(savegame, key .. ".weather.snowDepth")
    ssWeatherManager.soilTemp = ssXMLUtil.getFloat(savegame, key .. ".weather.soilTemp")
    ssWeatherManager.soilTempMax = ssXMLUtil.getFloat(savegame, key .. ".weather.soilTempMax", self.soilTemp)
    ssWeatherManager.prevHighTemp = ssXMLUtil.getFloat(savegame, key .. ".weather.prevHighTemp")
    ssWeatherManager.cropMoistureContent = ssXMLUtil.getFloat(savegame, key .. ".weather.cropMoistureContent", 15.0)
    ssWeatherManager.soilWaterContent = ssXMLUtil.getFloat(savegame, key .. ".weather.soilWaterContent", 0.1)
    ssWeatherManager.moistureEnabled = ssXMLUtil.getBool(savegame, key .. ".weather.moistureEnabled", true)
    ssWeatherManager.windSpeed = ssXMLUtil.getFloat(savegame, key .. ".weather.windSpeed", 2.0)

    -- load forecast
    ssWeatherForecast.forecast = {}

    local i = 0
    while true do
        local dayKey = string.format("%s.weather.forecast.day(%i)", key, i)
        if not ssXMLUtil.hasProperty(savegame, dayKey) then break end

        local day = {}

        day.day = getXMLInt(savegame, dayKey .. "#day")
        day.season = g_seasons.environment:seasonAtDay(day.day)

        -- keeing name weatherState in savegame for compatibility
        day.weatherType = getXMLString(savegame, dayKey .. "#weatherState")
        day.startTimeIndication = getXMLFloat(savegame, startTimeIndication .. "#startTimeIndication")
        day.ssTmax = getXMLFloat(savegame, dayKey .. "#ssTmax")
        day.highTemp = getXMLFloat(savegame, dayKey .. "#highTemp")
        day.lowTemp = getXMLFloat(savegame, dayKey .. "#lowTemp")
        day.windSpeed = getXMLFloat(savegame, dayKey .. "#windSpeed")
        day.p = getXMLFloat(savegame, dayKey .. "#p")
        day.numEvents = getXMLInt(savegame, dayKey .. "#numEvents")

        table.insert(ssWeatherForecast.forecast, day)
        i = i + 1
    end

    -- load rains
    ssWeatherManager.weather = {}

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

        table.insert(ssWeatherManager.weather, rain)
        i = i + 1
    end
end

function ssWeatherData:save(savegame, key)
    local i = 0

    ssXMLUtil.setFloat(savegame, key .. ".weather.snowDepth", ssWeatherManager.snowDepth)
    ssXMLUtil.setFloat(savegame, key .. ".weather.soilTemp", ssWeatherManager.soilTemp)
    ssXMLUtil.setFloat(savegame, key .. ".weather.soilTempMax", ssWeatherManager.soilTempMax)
    ssXMLUtil.setFloat(savegame, key .. ".weather.prevHighTemp", ssWeatherManager.prevHighTemp)
    ssXMLUtil.setFloat(savegame, key .. ".weather.cropMoistureContent", ssWeatherManager.cropMoistureContent)
    ssXMLUtil.setFloat(savegame, key .. ".weather.soilWaterContent", ssWeatherManager.soilWaterContent)
    ssXMLUtil.setBool(savegame, key .. ".weather.moistureEnabled", ssWeatherManager.moistureEnabled)
    ssXMLUtil.setFloat(savegame, key .. ".weather.windSpeed", ssWeatherManager.windSpeed)

    for i = 0, table.getn(ssWeatherForecast.forecast) - 1 do
        local dayKey = string.format("%s.weather.forecast.day(%i)", key, i)

        local day = ssWeatherForecast.forecast[i + 1]

        setXMLInt(savegame, dayKey .. "#day", day.day)
        -- keeing name weatherState in savegame for compatibility
        setXMLString(savegame, dayKey .. "#weatherState", day.weatherType)
        setXMLFloat(savegame, dayKey .. "#startTimeIndication", day.startTimeIndication)
        setXMLFloat(savegame, dayKey .. "#ssTmax", day.ssTmax)
        setXMLFloat(savegame, dayKey .. "#highTemp", day.highTemp)
        setXMLFloat(savegame, dayKey .. "#lowTemp", day.lowTemp)
        setXMLFloat(savegame, dayKey .. "#windSpeed", day.windSpeed)
        setXMLFloat(savegame, dayKey .. "#p", day.p)
        setXMLInt(savegame, dayKey .. "#numEvents", day.numEvents)
    end

    for i = 0, table.getn(ssWeatherManager.weather) - 1 do
        local rainKey = string.format("%s.weather.forecast.rain(%i)", key, i)

        local rain = ssWeatherManager.weather[i + 1]

        setXMLInt(savegame, rainKey .. "#startDay", rain.startDay)
        setXMLFloat(savegame, rainKey .. "#endDayTime", rain.endDayTime)
        setXMLFloat(savegame, rainKey .. "#startDayTime", rain.startDayTime)
        setXMLInt(savegame, rainKey .. "#endDay", rain.endDay)
        setXMLString(savegame, rainKey .. "#rainTypeId", rain.rainTypeId)
        setXMLFloat(savegame, rainKey .. "#duration", rain.duration)
    end
end

function ssWeatherData:loadGerminateTemperature(path)
    local file = loadXMLFile("germinate", path)

    local i = 0
    while true do
        local key = string.format("growth.germination.fruit(%d)", i)
        if not hasXMLProperty(file, key) then break end

        local fruitName = getXMLString(file, key .. "#fruitName")
        if fruitName == nil then
            logInfo("ssWeatherData:", "Fruit in growth.xml:germination is invalid")
            break
        end

        local germinateTemp = getXMLFloat(file, key .. "#germinateTemp")

        if germinateTemp == nil then
            logInfo("ssWeatherData:", "Temperature data in growth.xml:germination is invalid")
            break
        end

        self.germinateTemp[fruitName] = germinateTemp

        i = i + 1
    end

    -- Close file
    delete(file)
end

function ssWeatherData:loadFromXML(path)
    local file = loadXMLFile("weather", path)

    -- Load start values. This assumes at least 1 file has those values. (Seasons data)
    self.startValues.soilTemp = ssXMLUtil.getFloat(file, "weather.startValues.soilTemp", self.startValues.soilTemp)
    self.startValues.highAirTemp = ssXMLUtil.getFloat(file, "weather.startValues.highAirTemp", self.startValues.highAirTemp)
    self.startValues.snowDepth = ssXMLUtil.getFloat(file, "weather.startValues.snowDepth", self.startValues.snowDepth)

    -- Load temperature data
    local key = "weather.temperature.dailyMaximum"
    if key == nil then
        logInfo("ssWeatherData:", "Error in weather data: Lacking temperature data")
    end
    self.temperatureData = self:loadValuesFromXML(file, key)

    -- Load cloud data
    local key = "weather.clouds.probability"
    if key == nil then
        logInfo("ssWeatherData:", "Error in weather data: Lacking cloud probability data")
    end
    self.cloudProbData = self:loadValuesFromXML(file, key)

    -- Load rain data
    local key = "weather.rain.probability"
    if key == nil then
        logInfo("ssWeatherData:", "Error in weather data: Lacking rain probability data")
    end
    self.rainProbData = self:loadValuesFromXML(file, key)

    local key = "weather.rain.rainfall"
    if key == nil then
        logInfo("ssWeatherData:", "Error in weather data: Lacking rainfall data")
    end
    self.rainfallData = self:loadValuesFromXML(file, key)

    local key = "weather.wind.speed"
    if key == nil then
        logInfo("ssWeatherData:", "Error in weather data: Lacking wind speed data")
    end
    self.windSpeed = self:loadValuesFromXML(file, key)

    delete(file)
end

function ssWeatherData:loadValuesFromXML(file, key)
    local values = {}

    -- Load for each
    local i = 0
    while true do
        local fKey = string.format("%s.value(%d)", key, i)
        if not hasXMLProperty(file, fKey) then break end

        local transition = getXMLInt(file, fKey .. "#transition")
        local value = getXMLFloat(file, fKey)

        values[transition] = value

        i = i + 1
    end

    if table.getn(values) ~= g_seasons.environment.TRANSITIONS_IN_YEAR then
        logInfo("ssWeatherData:", "Error in weather data: not all transitions are configured in " .. key)
    end

    return values
end