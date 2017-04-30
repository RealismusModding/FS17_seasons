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
        g_seasons.weather:writeStream(streamId, connection)
    end
end

-- Client: receive from server
function ssSettingsEvent:readStream(streamId, connection)
    self.snowMode = streamReadInt16(streamId)
    self.seasonLength = streamReadInt16(streamId)
    self.snowTracksEnabled = streamReadBool(streamId)
    self.moistureEnabled = streamReadBool(streamId)

    if connection:getIsServer() then
        g_seasons.weather:readStream(streamId, connection)
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
