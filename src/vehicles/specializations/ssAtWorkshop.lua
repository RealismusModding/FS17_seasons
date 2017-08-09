----------------------------------------------------------------------------------------------------
-- AT WORKSHOP SPECIALIZATION
----------------------------------------------------------------------------------------------------
-- Authors:  Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssAtWorkshop = {}

source(g_seasons.modDir .. "src/events/ssRepairVehicleEvent.lua")

ssAtWorkshop.RANGE = 4.0

function ssAtWorkshop:prerequisitesPresent(specializations)
    return true
end

function ssAtWorkshop:preLoad()
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
    local attributes = ""

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
    if self.isClient and g_currentMission.controlPlayer and g_currentMission.player ~= nil then
        local isPlayerInRange, player = getIsPlayerInRange(self, ssAtWorkshop.RANGE, g_currentMission.player)

        if isPlayerInRange then
            self.ssPlayerInRange = player
        else
            self.ssPlayerInRange = nil
        end
    end
end
