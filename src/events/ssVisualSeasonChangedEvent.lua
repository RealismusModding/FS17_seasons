----------------------------------------------------------------------------------------------------
-- VISUAL SEASON CHANGED EVENT
----------------------------------------------------------------------------------------------------
-- Purpose:  Event sent when the visual season changes
-- Authors:  Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssVisualSeasonChangedEvent = {}
ssVisualSeasonChangedEvent_mt = Class(ssVisualSeasonChangedEvent, Event)
InitEventClass(ssVisualSeasonChangedEvent, "ssVisualSeasonChangedEvent")

function ssVisualSeasonChangedEvent:emptyNew()
    local self = Event:new(ssVisualSeasonChangedEvent_mt)
    self.className = "ssVisualSeasonChangedEvent"
    return self
end

function ssVisualSeasonChangedEvent:new(season)
    local self = ssVisualSeasonChangedEvent:emptyNew()

    self.season = season

    return self
end

-- Server: send to client
function ssVisualSeasonChangedEvent:writeStream(streamId, connection)
    streamWriteUInt8(streamId, self.season)
end

-- Client: receive from server
function ssVisualSeasonChangedEvent:readStream(streamId, connection)
    self.season = streamReadUInt8(streamId)

    self:run(connection)
end


function ssVisualSeasonChangedEvent:run(connection)
    if g_seasons.environment.latestVisualSeason ~= self.season then
        g_seasons.environment.latestVisualSeason = self.season

        for _, listener in pairs(g_seasons.environment.visualSeasonChangeListeners) do
            listener:visualSeasonChanged(self.season)
        end
    end
end

function ssVisualSeasonChangedEvent.sendEvent(season)
    if g_currentMission:getIsServer() then
        -- Send to all clients
        g_server:broadcastEvent(ssVisualSeasonChangedEvent:new(season), false)
    end
end
