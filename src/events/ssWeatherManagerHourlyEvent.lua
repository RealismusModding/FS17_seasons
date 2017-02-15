---------------------------------------------------------------------------------------------------
-- WEATHER MANAGER HOURLY EVENT
---------------------------------------------------------------------------------------------------
-- Purpose:  Event sent every hour with snow and moisture data
-- Authors:  Rahkiin
---------------------------------------------------------------------------------------------------

ssWeatherManagerHourlyEvent = {}
ssWeatherManagerHourlyEvent_mt = Class(ssWeatherManagerHourlyEvent, Event)
InitEventClass(ssWeatherManagerHourlyEvent, "ssWeatherManagerHourlyEvent")

function ssWeatherManagerHourlyEvent:emptyNew()
    local self = Event:new(ssWeatherManagerHourlyEvent_mt)
    self.className = "ssWeatherManagerHourlyEvent"
    return self
end

function ssWeatherManagerHourlyEvent:new(cropMoistureContent, snowDepth)
    local self = ssWeatherManagerHourlyEvent:emptyNew()

    self.cropMoistureContent = cropMoistureContent
    self.snowDepth = snowDepth
    self.soilTemp = soilTemp

    return self
end

-- Server: send to client
function ssWeatherManagerHourlyEvent:writeStream(streamId, connection)
    streamWriteFloat32(streamId, self.cropMoistureContent)
    streamWriteFloat32(streamId, self.snowDepth)
end

-- Client: receive from server
function ssWeatherManagerHourlyEvent:readStream(streamId, connection)
    self.cropMoistureContent = streamReadFloat32(streamId)
    self.snowDepth = streamReadFloat32(streamId)

    self:run(connection)
end

function ssWeatherManagerHourlyEvent:run(connection)
    if connection:getIsServer() then
        local oldSnow = ssWeatherManager.snowDepth

        ssWeatherManager.cropMoistureContent = self.cropMoistureContent
        ssWeatherManager.snowDepth = self.snowDepth

        if math.abs(oldSnow - self.snowDepth) > 0.01 then
            -- Call a weather change
            for _, listener in pairs(g_currentMission.environment.weatherChangeListeners) do
                listener:weatherChanged()
            end
        end
    end
end
