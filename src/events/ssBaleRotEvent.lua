----------------------------------------------------------------------------------------------------
-- BALE FERMENT EVENT
----------------------------------------------------------------------------------------------------
-- Purpose:  Event when a bale rots
-- Authors:  rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssBaleRotEvent = {}
ssBaleRotEvent_mt = Class(ssBaleRotEvent, Event)
InitEventClass(ssBaleRotEvent, "ssBaleRotEvent")

function ssBaleRotEvent:emptyNew()
    local self = Event:new(ssBaleRotEvent_mt)
    self.className = "ssBaleRotEvent"
    return self
end

function ssBaleRotEvent:new(bale)
    local self = ssBaleRotEvent:emptyNew()

    self.bale = bale
    self.fillLevel = bale.fillLevel

    return self
end

function ssBaleRotEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, networkGetObjectId(self.bale))
    streamWriteFloat32(streamId, self.fillLevel)
end

function ssBaleRotEvent:readStream(streamId, connection)
    local objectId = streamReadInt32(streamId)

    self.bale = networkGetObject(objectId)
    self.fillLevel = streamReadFloat32(streamId)

    self:run(connection)
end

function ssBaleRotEvent:run(connection)
    self.bale.fillLevel = self.fillLevel
end

function ssBaleRotEvent:sendEvent(bale)
    if g_server ~= nil then
        g_server:broadcastEvent(ssBaleRotEvent:new(bale), nil, nil, bale)
    end
end
