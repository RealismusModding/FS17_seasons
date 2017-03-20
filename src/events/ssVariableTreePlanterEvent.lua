---------------------------------------------------------------------------------------------------
-- VARIABLE TREE PLANTER EVENT
---------------------------------------------------------------------------------------------------
-- Purpose:  Event sent when state of the planter changes
-- Authors:  Rahkiin
---------------------------------------------------------------------------------------------------

ssVariableTreePlanterEvent = {}
ssVariableTreePlanterEvent_mt = Class(ssVariableTreePlanterEvent, Event)
InitEventClass(ssVariableTreePlanterEvent, "ssVariableTreePlanterEvent")

function ssVariableTreePlanterEvent:emptyNew()
    local self = Event:new(ssVariableTreePlanterEvent_mt)
    self.className = "ssVariableTreePlanterEvent"
    return self
end

function ssVariableTreePlanterEvent:new(vehicle, distance)
    local self = ssVariableTreePlanterEvent:emptyNew()

    self.vehicle = vehicle
    self.distance = distance

    return self
end

function ssVariableTreePlanterEvent:writeStream(streamId, connection)
    writeNetworkNodeObject(streamId, self.vehicle)
    streamWriteInt8(streamId, self.distance)
end

function ssVariableTreePlanterEvent:readStream(streamId, connection)
    self.vehicle = readNetworkNodeObject(streamId)
    self.distance = streamReadInt8(streamId)

    self:run(connection)
end

function ssVariableTreePlanterEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.vehicle)
    end

    if self.vehicle ~= nil then
        self.vehicle.treePlanterMinDistance = self.distance
    end
end
