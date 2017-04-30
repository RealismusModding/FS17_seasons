----------------------------------------------------------------------------------------------------
-- VARIABLE TREE PLANTER SPECIALIZATION
----------------------------------------------------------------------------------------------------
-- Applied to every tree planter in order to vary the distance between planted trees
-- Authors: reallogger
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssVariableTreePlanter = {}

ssVariableTreePlanter.plantingDistances = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}

source(g_seasons.modDir .. "src/events/ssVariableTreePlanterEvent.lua")

function ssVariableTreePlanter:prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(TreePlanter, specializations)
end

function ssVariableTreePlanter:load(savegame)
    self.treePlanterMinDistance = 10

    if savegame ~= nil then
        self.treePlanterMinDistance = ssXMLUtil.getInt(savegame.xmlFile, savegame.key .. "#ssPlantingDistance", self.treePlanterMinDistance)
    end
end

function ssVariableTreePlanter:delete()
end

function ssVariableTreePlanter:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssVariableTreePlanter:keyEvent(unicode, sym, modifier, isDown)
end

function ssVariableTreePlanter:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
    return true
end

function ssVariableTreePlanter:getSaveAttributesAndNodes(nodeIdent)
    local attributes = ""

    if self.treePlanterMinDistance ~= nil then
        attributes = attributes .. 'ssPlantingDistance="' .. self.treePlanterMinDistance ..  '" '
    end

    return attributes, ""
end

function ssVariableTreePlanter:readStream(streamId, connection)
    self.treePlanterMinDistance = streamReadFloat32(streamId)
end

function ssVariableTreePlanter:writeStream(streamId, connection)
    streamWriteFloat32(streamId, self.treePlanterMinDistance)
end

function ssVariableTreePlanter:draw()
    g_currentMission:addHelpButtonText(string.format(g_i18n:getText("input_SEASONS_PLANTING_DISTANCE"), self.treePlanterMinDistance), InputBinding.IMPLEMENT_EXTRA2, nil, GS_PRIO_HIGH)
end

function ssVariableTreePlanter:updateTick(dt)
end

function ssVariableTreePlanter:update(dt)
    if self:getIsActive() and self:getIsActiveForInput() then
        if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA2) then
            local currentDistance = self.treePlanterMinDistance
            local newDistance = 0
            local n = table.getn(ssVariableTreePlanter.plantingDistances)

            for i, dist in pairs(ssVariableTreePlanter.plantingDistances) do
                if dist == currentDistance and i ~= n then
                    newDistance = ssVariableTreePlanter.plantingDistances[i + 1]
                elseif dist == currentDistance and i == n then
                    newDistance = ssVariableTreePlanter.plantingDistances[1]
                end
            end

            self.treePlanterMinDistance = newDistance

            g_client:getServerConnection():sendEvent(ssVariableTreePlanterEvent:new(self, newDistance))
        end
    end
end
