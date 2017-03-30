----------------------------------------------------------------------------------------------------
-- WEATHER MANAGER DAILY EVENT
----------------------------------------------------------------------------------------------------
-- Purpose:  Event sent daily with new forecast
-- Authors:  Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssSettingsEvent = {}
ssSettingsEvent_mt = Class(ssSettingsEvent, Event)
InitEventClass(ssSettingsEvent, "ssSettingsEvent")

-- client -> server: hey! I repaired X
--> server -> everyone: hey! X got repaired!

function ssSettingsEvent:emptyNew()
    local self = Event:new(ssSettingsEvent_mt)
    self.className = "ssSettingsEvent"
    return self
end

function ssSettingsEvent:new()
    local self = ssSettingsEvent:emptyNew()

    self.settings = {} -- NEW TABLE WITH ALL VALUES

    self.snowMode = g_seasons.mainMenu.settingElements.snow:getState()
    self.seasonLength = g_seasons.mainMenu.settingElements.seasonLength:getState() * 3
    self.snowTracksEnabled = g_seasons.mainMenu.settingElements.snowTracks:getIsChecked()
    self.moistureEnabled = g_seasons.mainMenu.settingElements.moisture:getIsChecked()

    return self
end

-- Server: send to client
function ssSettingsEvent:writeStream(streamId, connection)
    streamWriteInt16(streamId, self.snowMode)
    streamWriteInt16(streamId, self.seasonLength)
    streamWriteBool(streamId, self.snowTracksEnabled)
    streamWriteBool(streamId, self.moistureEnabled)

    if not connection:getIsServer() then
        -- Write the new (current on server) forecast
        streamWriteUInt8(streamId, table.getn(g_seasons.weather.forecast))
        streamWriteUInt8(streamId, table.getn(g_seasons.weather.weather))

        for _, day in pairs(g_seasons.weather.forecast) do
            streamWriteInt16(streamId, day.day)

            -- Include season, season on client is not in sync
            streamWriteInt16(streamId, day.season)

            streamWriteString(streamId, day.weatherState)
            streamWriteFloat32(streamId, day.highTemp)
            streamWriteFloat32(streamId, day.lowTemp)
        end

        for _, rain in pairs(g_seasons.weather.weather) do
            streamWriteInt16(streamId, rain.startDay)
            streamWriteFloat32(streamId, rain.endDayTime)
            streamWriteFloat32(streamId, rain.startDayTime)
            streamWriteInt16(streamId, rain.endDay)
            streamWriteString(streamId, rain.rainTypeId)
            streamWriteFloat32(streamId, rain.duration)
        end
    end
end

-- Client: receive from server
function ssSettingsEvent:readStream(streamId, connection)
    self.snowMode = streamReadInt16(streamId)
    self.seasonLength = streamReadInt16(streamId)
    self.snowTracksEnabled = streamReadBool(streamId)
    self.moistureEnabled = streamReadBool(streamId)

    if connection:getIsServer() then
        local numDays = streamReadUInt8(streamId)
        local numRains = streamReadUInt8(streamId)

        g_seasons.weather.forecast = {}

        for i = 1, numDays do
            local day = {}

            day.day = streamReadInt16(streamId)
            day.season = streamReadInt16(streamId)

            day.weatherState = streamReadString(streamId)
            day.highTemp = streamReadFloat32(streamId)
            day.lowTemp = streamReadFloat32(streamId)

            table.insert(g_seasons.weather.forecast, day)
        end

        -- load rains
        g_seasons.weather.weather = {}

        for i = 1, numRains do
            local rain = {}

            rain.startDay = streamReadInt16(streamId)
            rain.endDayTime = streamReadFloat32(streamId)
            rain.startDayTime = streamReadFloat32(streamId)
            rain.endDay = streamReadInt16(streamId)
            rain.rainTypeId = streamReadString(streamId)
            rain.duration = streamReadFloat32(streamId)

            table.insert(g_seasons.weather.weather, rain)
        end
    end

    self:run(connection)
end


function ssSettingsEvent:run(connection)
    -- Update local settings with values
    g_seasons.snow:setMode(self.snowMode)

    g_seasons.environment:changeDaysInSeason(self.seasonLength)
    g_seasons.vehicle.snowTracksEnabled = self.snowTracksEnabled
    g_seasons.weather.moistureEnabled = self.moistureEnabled

    g_seasons.mainMenu:updateGameSettings()
    g_seasons.mainMenu:updateApplySettingsButton()

    -- If this was sent to the server, broadcast this to all clients
    if not connection:getIsServer() then
        g_server:broadcastEvent(ssSettingsEvent:new(), false)
    end
end

function ssSettingsEvent.sendEvent()
    if g_currentMission:getIsServer() then
        -- Send to all clients
        g_server:broadcastEvent(ssSettingsEvent:new(), false)
    else
        -- Send to the server
        g_client:getServerConnection():sendEvent(ssSettingsEvent:new());
    end
end
