----------------------------------------------------------------------------------------------------
-- WEATHER MANAGER DAILY EVENT
----------------------------------------------------------------------------------------------------
-- Purpose:  Event sent daily with new forecast
-- Authors:  Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssWeatherManagerDailyEvent = {}
ssWeatherManagerDailyEvent_mt = Class(ssWeatherManagerDailyEvent, Event)
InitEventClass(ssWeatherManagerDailyEvent, "ssWeatherManagerDailyEvent")

function ssWeatherManagerDailyEvent:emptyNew()
    local self = Event:new(ssWeatherManagerDailyEvent_mt)
    self.className = "ssWeatherManagerDailyEvent"
    return self
end

function ssWeatherManagerDailyEvent:new(day, rain, prevHighTemp, soilTemp)
    local self = ssWeatherManagerDailyEvent:emptyNew()

    self.day = day
    self.rain = rain
    self.prevHighTemp = prevHighTemp
    self.soilTemp = soilTemp

    return self
end

function ssWeatherManagerDailyEvent:writeStream(streamId, connection)
    streamWriteFloat32(streamId, self.prevHighTemp)
    streamWriteFloat32(streamId, self.soilTemp)

    streamWriteInt16(streamId, self.day.day)
    streamWriteInt16(streamId, self.day.season)
    streamWriteString(streamId, self.day.weatherState)
    streamWriteFloat32(streamId, self.day.highTemp)
    streamWriteFloat32(streamId, self.day.lowTemp)

    streamWriteInt16(streamId, self.rain.startDay)
    streamWriteFloat32(streamId, self.rain.endDayTime)
    streamWriteFloat32(streamId, self.rain.startDayTime)
    streamWriteInt16(streamId, self.rain.endDay)
    streamWriteString(streamId, self.rain.rainTypeId)
    streamWriteFloat32(streamId, self.rain.duration)
end

function ssWeatherManagerDailyEvent:readStream(streamId, connection)
    local day = {}
    local rain = {}

    self.prevHighTemp = streamReadFloat32(streamId)
    self.soilTemp = streamReadFloat32(streamId)

    day.day = streamReadInt16(streamId)
    day.season = streamReadInt16(streamId)
    day.weatherState = streamReadString(streamId)
    day.highTemp = streamReadFloat32(streamId)
    day.lowTemp = streamReadFloat32(streamId)

    rain.startDay = streamReadInt16(streamId)
    rain.endDayTime = streamReadFloat32(streamId)
    rain.startDayTime = streamReadFloat32(streamId)
    rain.endDay = streamReadInt16(streamId)
    rain.rainTypeId = streamReadString(streamId)
    rain.duration = streamReadFloat32(streamId)

    self.rain = rain
    self.day = day

    self:run(connection)
end

function ssWeatherManagerDailyEvent:run(connection)
    if connection:getIsServer() then
        ssWeatherManager.prevHighTemp = self.prevHighTemp

        -- Update soiltemp and call the
        local wasFrozen = ssWeatherManager:isGroundFrozen()

        ssWeatherManager.soilTemp = self.soilTemp

        if wasFrozen ~= ssWeatherManager:isGroundFrozen() then
            -- Call a weather change
            for _, listener in pairs(g_currentMission.environment.weatherChangeListeners) do
                listener:weatherChanged()
            end
        end


        table.remove(ssWeatherManager.forecast, 1)
        table.insert(ssWeatherManager.forecast, self.day)

        table.insert(ssWeatherManager.weather, self.rain)
        table.remove(ssWeatherManager.weather, 1)

        ssWeatherManager:overwriteRaintable()
    end
end
