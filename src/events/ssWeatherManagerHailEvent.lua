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
    streamWriteInt32(streamId, self.hail.endDayTime)
    streamWriteInt32(streamId, self.hail.startDayTime)
    streamWriteInt32(streamId, self.hail.duration)
end

function ssWeatherManagerHailEvent:readStream(streamId, connection)
    local hail = {}

    hail.startDay = streamReadInt16(streamId)
    hail.endDayTime = streamReadInt32(streamId)
    hail.startDayTime = streamReadInt32(streamId)
    hail.duration = streamReadInt32(streamId)
    hail.endDay = hail.startDay
    hail.rainTypeId = "hail"

    self.hail = hail

    self:run(connection)
end

function ssWeatherManagerHailEvent:run(connection)
    if connection:getIsServer() then

        -- Day sometimes (always?) mismatch when this event is called. So after day is updated,
        -- the weather[1] is removed
        if g_seasons.weather.weather[1].startDay == g_seasons.environment:currentDay() then
            g_seasons.weather.weather[1] = self.hail
        else
            g_seasons.weather.weather[2] = self.hail
        end

        g_seasons.weather:overwriteRaintable()
    end
end
