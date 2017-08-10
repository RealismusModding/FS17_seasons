----------------------------------------------------------------------------------------------------
-- AT WORKSHOP SPECIALIZATION
----------------------------------------------------------------------------------------------------
-- Purpose: Detect if a player is in walking range of a vehicle and vehicle is int he workshop
-- Authors: Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssAtWorkshop = {}

ssAtWorkshop.RANGE = 4.0

function ssAtWorkshop:prerequisitesPresent(specializations)
    return true
end

function ssAtWorkshop:preLoad()
    self.isPlayerInRange = ssAtWorkshop.isPlayerInRange
    self.isAtWorkshop = ssAtWorkshop.isAtWorkshop
    self.getWorkshop = ssAtWorkshop.getWorkshop
    self.canPlayerInteractInWorkshop = ssAtWorkshop.canPlayerInteractInWorkshop
end

function ssAtWorkshop:load(savegame)
end

function ssAtWorkshop:delete()
end

function ssAtWorkshop:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssAtWorkshop:keyEvent(unicode, sym, modifier, isDown)
end

function ssAtWorkshop:loadFromAttributesAndNodes(xmlFile, key)
    return true
end

function ssAtWorkshop:getSaveAttributesAndNodes(nodeIdent)
    return attributes, ""
end

function ssAtWorkshop:readStream(streamId, connection)
end

function ssAtWorkshop:writeStream(streamId, connection)
end

function ssAtWorkshop:draw()
end

local function isInDistance(self, player, maxDistance, refNode)
    local vx, _, vz = getWorldTranslation(player.rootNode)
    local sx, _, sz = getWorldTranslation(refNode)

    local dist = Utils.vector2Length(vx - sx, vz - sz)

    return dist <= maxDistance
end

-- Jos: Don't ask me why, but putting them inside Repairable breaks all, even with
-- callSpecializationsFunction...
local function getIsPlayerInRange(self, distance, player)
    if self.rootNode ~= 0 and SpecializationUtil.hasSpecialization(Motorized, self.specializations) then
        return isInDistance(self, player, distance, self.rootNode), player
    end

    return false, nil
end

function ssAtWorkshop:update(dt)
end

function ssAtWorkshop:updateTick(dt)
    -- Calculate if vehicle is in range for message about repairing
    if self.isClient and g_currentMission.player ~= nil then
        local isPlayerInRange, player = getIsPlayerInRange(self, ssAtWorkshop.RANGE, g_currentMission.player)

        if isPlayerInRange and g_currentMission.controlPlayer then
            self.ssPlayerInRange = player
        else
            self.ssPlayerInRange = nil
        end
    end
end

function ssAtWorkshop:isPlayerInRange(player)
    if player == nil then
        player = g_currentMission.player
    end

    return self.ssPlayerInRange == player
end

function ssAtWorkshop:isAtWorkshop()
    return self.ssInRangeOfWorkshop ~= nil
end

function ssAtWorkshop:getWorkshop()
    return self.ssInRangeOfWorkshop
end

function ssAtWorkshop:canPlayerInteractInWorkshop(player)
    return self:isAtWorkshop() and self:isPlayerInRange(player)
end

-- Tell a vehicle when it is in the area of a workshop. This information is
-- then used in ssRepairable to show or hide the repair option
function ssAtWorkshop:sellAreaTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
    if otherShapeId ~= nil and (onEnter or onLeave) then
        if onEnter then
            local vehicle = g_currentMission.nodeToVehicle[otherShapeId]

            if vehicle ~= nil then
                vehicle.ssInRangeOfWorkshop = self
            end
        elseif onLeave then
            local vehicle = g_currentMission.nodeToVehicle[otherShapeId]

            if vehicle ~= nil then
                vehicle.ssInRangeOfWorkshop = nil
            end
        end
    end
end

VehicleSellingPoint.sellAreaTriggerCallback = Utils.appendedFunction(VehicleSellingPoint.sellAreaTriggerCallback, ssAtWorkshop.sellAreaTriggerCallback)
