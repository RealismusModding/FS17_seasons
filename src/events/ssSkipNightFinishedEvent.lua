----------------------------------------------------------------------------------------------------
-- SKIP NIGHT FINISHED EVENT
----------------------------------------------------------------------------------------------------
-- Purpose:  Event indicating skip night finished
-- Authors:  rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssSkipNightFinishedEvent = {}
ssSkipNightFinishedEvent_mt = Class(ssSkipNightFinishedEvent, Event)
InitEventClass(ssSkipNightFinishedEvent, "ssSkipNightFinishedEvent")

function ssSkipNightFinishedEvent:emptyNew()
    local self = Event:new(ssSkipNightFinishedEvent_mt)
    self.className = "ssSkipNightFinishedEvent"
    return self
end

function ssSkipNightFinishedEvent:new(modus)
    local self = ssSkipNightFinishedEvent:emptyNew()

    self.modus = modus

    return self
end

function ssSkipNightFinishedEvent:writeStream(streamId, connection)
end

function ssSkipNightFinishedEvent:readStream(streamId, connection)
    self:run(connection)
end

function ssSkipNightFinishedEvent:run(connection)
    g_seasons.skipNight:finishSkippingNight()
end

function ssSkipNightFinishedEvent.sendEvent(modus)
    if g_currentMission:getIsServer() then
        g_server:broadcastEvent(ssSkipNightFinishedEvent:new(modus))
    else
        error("Client can't send SkipNightFinished event")
    end
end
