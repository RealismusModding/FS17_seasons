----------------------------------------------------------------------------------------------------
-- SKIP NIGHT EVENT
----------------------------------------------------------------------------------------------------
-- Purpose:  Event for skipping night
-- Authors:  rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssSkipNightEvent = {}
ssSkipNightEvent_mt = Class(ssSkipNightEvent, Event)
InitEventClass(ssSkipNightEvent, "ssSkipNightEvent")

function ssSkipNightEvent:emptyNew()
    local self = Event:new(ssSkipNightEvent_mt)
    self.className = "ssSkipNightEvent"
    return self
end

function ssSkipNightEvent:new(modus)
    local self = ssSkipNightEvent:emptyNew()

    self.modus = modus

    return self
end

function ssSkipNightEvent:writeStream(streamId, connection)
    streamWriteInt8(streamId, self.modus)
end

function ssSkipNightEvent:readStream(streamId, connection)
    self.modus = streamReadInt8(streamId)

    self:run(connection)
end

function ssSkipNightEvent:run(connection)
    if not connection:getIsServer() then
        if g_currentMission:getIsMasterUserConnection(connection) and not g_seasons.skipNight.skippingNight then
            -- Send event to clients, not to us
            g_server:broadcastEvent(ssSkipNightEvent:new(self.modus))

            --- Start skipping. This will also show the dialog on clients
            g_seasons.skipNight:startSkippingNight(self.modus)
        end
    else
        g_seasons.skipNight:startSkippingNight(self.modus)
    end
end

function ssSkipNightEvent.sendEvent(modus)
    if g_currentMission:getIsServer() then
        --- Start skipping. This will also show the dialog on clients
        g_server:broadcastEvent(ssSkipNightEvent:new(modus))
        g_seasons.skipNight:startSkippingNight(modus)
    else
        g_client:getServerConnection():sendEvent(ssSkipNightEvent:new(modus));
    end
end
