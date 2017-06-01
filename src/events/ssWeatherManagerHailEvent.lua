----------------------------------------------------------------------------------------------------
-- WEATHER MANAGER HAIL EVENT
----------------------------------------------------------------------------------------------------
-- Purpose:  Event sent when a hail is created
-- Authors:  Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssWeatherManagerHailEvent = {}
ssWeatherManagerHailEvent_mt = Class(ssWeatherManagerHailEvent, Event)
InitEventClass(ssWeatherManagerHailEvent, "ssWeatherManagerHailEvent")

function ssWeatherManagerHailEvent:emptyNew()
    local self = Event:new(ssWeatherManagerHailEvent_mt)
    self.className = "ssWeatherManagerHailEvent"
    return self
end

function ssWeatherManagerHailEvent:new(hail)
    local self = ssWeatherManagerHailEvent:emptyNew()

    self.hail = hail

    return self
end

function ssWeatherManagerHailEvent:writeStream(streamId, connection)
    streamWriteInt16(streamId, self.hail.startDay)
    streamWriteFloat32(streamId, self.hail.endDayTime)
    streamWriteFloat32(streamId, self.hail.startDayTime)
    streamWriteInt16(streamId, self.hail.endDay)
    streamWriteFloat32(streamId, self.hail.duration)
end

function ssWeatherManagerHailEvent:readStream(streamId, connection)
    local hail = {}

    hail.startDay = streamReadInt16(streamId)
    hail.endDayTime = streamReadFloat32(streamId)
    hail.startDayTime = streamReadFloat32(streamId)
    hail.endDay = streamReadInt16(streamId)
    hail.rainTypeId = "hail"
    hail.duration = streamReadFloat32(streamId)

    self.hail = hail

    self:run(connection)
end

function ssWeatherManagerHailEvent:run(connection)
    if connection:getIsServer() then
        g_seasons.weather.weather[1] = self.hail

        ssWeatherManager:overwriteRaintable()
    end
end
