---------------------------------------------------------------------------------------------------
-- ANIMALS EVENT
---------------------------------------------------------------------------------------------------
-- Purpose:  Event sent to update client on new animals data
-- Authors:  Rahkiin
---------------------------------------------------------------------------------------------------

ssAnimalsDataEvent = {}
ssAnimalsDataEvent_mt = Class(ssAnimalsDataEvent, Event)
InitEventClass(ssAnimalsDataEvent, "ssAnimalsDataEvent")

function ssAnimalsDataEvent:emptyNew()
    local self = Event:new(ssAnimalsDataEvent_mt)
    self.className = "ssAnimalsDataEvent"
    return self
end

function ssAnimalsDataEvent:new()
    local self = ssAnimalsDataEvent:emptyNew()

    return self
end

function ssAnimalsDataEvent:writeStream(streamId, connection)
    for typ, husb in pairs(g_currentMission.husbandries) do
        local desc = husb.animalDesc

        streamWriteFloat32(streamId, desc.birthRatePerDay)
        streamWriteFloat32(streamId, desc.foodPerDay)
        streamWriteFloat32(streamId, desc.liquidManurePerDay)
        streamWriteFloat32(streamId, desc.manurePerDay)
        streamWriteFloat32(streamId, desc.milkPerDay)
        streamWriteFloat32(streamId, desc.palletFillLevelPerDay)
        streamWriteFloat32(streamId, desc.strawPerDay)
        streamWriteFloat32(streamId, desc.waterPerDay)

        streamWriteInt16(streamId, husb.totalNumAnimals)
    end
end

function ssAnimalsDataEvent:readStream(streamId, connection)
    for typ, husb in pairs(g_currentMission.husbandries) do
        local desc = husb.animalDesc

        desc.birthRatePerDay = streamReadFloat32(streamId)
        desc.foodPerDay = streamReadFloat32(streamId)
        desc.liquidManurePerDay = streamReadFloat32(streamId)
        desc.manurePerDay = streamReadFloat32(streamId)
        desc.milkPerDay = streamReadFloat32(streamId)
        desc.palletFillLevelPerDay = streamReadFloat32(streamId)
        desc.strawPerDay = streamReadFloat32(streamId)
        desc.waterPerDay = streamReadFloat32(streamId)

        husb.totalNumAnimals = streamReadInt16(streamId)
    end

    self:run(connection)
end

function ssAnimalsDataEvent:run(connection)
end
