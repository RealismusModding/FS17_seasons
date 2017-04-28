----------------------------------------------------------------------------------------------------
-- BALE FERMENT EVENT
----------------------------------------------------------------------------------------------------
-- Purpose:  Event when a new silage bale is created and fermentation starts
-- Authors:  reallogger (based on script by fatov)
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssBaleFermentEvent = {}
ssBaleFermentEvent_mt = Class(ssBaleFermentEvent, Event)
InitEventClass(ssBaleFermentEvent, "ssBaleFermentEvent")

function ssBaleFermentEvent:emptyNew()
    local self = Event:new(ssBaleFermentEvent_mt)
    self.className = "ssBaleFermentEvent"
    return self
end

function ssBaleFermentEvent:new(bale)
    local self = ssBaleFermentEvent:emptyNew()

    self.bale = bale
    self.isFermenting = self.bale.fermentingProcess ~= nil and true or false

    return self
end

function ssBaleFermentEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, networkGetObjectId(self.bale))
    streamWriteBool(streamId, self.isFermenting)
end

function ssBaleFermentEvent:readStream(streamId, connection)
    local objectId = streamReadInt32(streamId)

    self.bale = networkGetObject(objectId)
    self.isFermenting = streamReadBool(streamId)

    self:run(connection)
end

function ssBaleFermentEvent:run(connection)
    if self.isFermenting then
        self.bale.fillType = FillUtil.FILLTYPE_GRASS_WINDROW
    else
        self.bale.fillType = FillUtil.FILLTYPE_SILAGE
    end
end

function ssBaleFermentEvent:sendEvent(bale)
    if g_server ~= nil then
        g_server:broadcastEvent(ssBaleFermentEvent:new(bale), nil, nil, bale)
    end
end
