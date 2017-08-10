----------------------------------------------------------------------------------------------------
-- DEEP CULTIVATOR SPECIALIZATION
----------------------------------------------------------------------------------------------------
-- Authors:  baron, Rahkiin, reallogger
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssDeepCultivator = {}

ssDeepCultivator.MAX_CHARS_TO_DISPLAY = 20

ssDeepCultivator.DEPTH_SHALLOW = 1
ssDeepCultivator.DEPTH_DEEP = 2
ssDeepCultivator.DEPTH_MAX = ssDeepCultivator.DEPTH_DEEP

function ssDeepCultivator:prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Cultivator, specializations)
end

function ssDeepCultivator:preLoad()
    self.updateCultivationDepth = ssDeepCultivator.updateCultivationDepth
end

function ssDeepCultivator:load(savegame)
    self.ssCultivationDepth = ssDeepCultivator.DEPTH_DEEP

    if savegame ~= nil then
        self.ssCultivationDepth = ssXMLUtil.getInt(savegame.xmlFile, savegame.key .. "#ssCultivationDepth", self.ssCultivationDepth)
    end
end

function ssDeepCultivator:delete()
end

function ssDeepCultivator:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssDeepCultivator:keyEvent(unicode, sym, modifier, isDown)
end

function ssDeepCultivator:loadFromAttributesAndNodes(xmlFile, key)
    return true
end

function ssDeepCultivator:getSaveAttributesAndNodes(nodeIdent)
    local attributes = ""

    attributes = attributes .. "ssCultivationDepth=\"" .. self.ssCultivationDepth ..  "\" "

    return attributes, ""
end

function ssDeepCultivator:readStream(streamId, connection)
end

function ssDeepCultivator:writeStream(streamId, connection)
end

function ssDeepCultivator:updateCultivationDepth(self)
    self.ssCultivationDepth = self.ssCultivationDepth + 1
    if self.ssCultivationDepth > ssDeepCultivator.DEPTH_MAX then
        self.ssCultivationDepth = ssDeepCultivator.DEPTH_SHALLOW
    end

    -- TODO(Jos) send event with new cultivation depth
end

function ssDeepCultivator:update(dt)
    if not g_currentMission:getIsServer() 
        or not g_seasons.soilCompaction.compactionEnabled then
        return 
    end

end

function ssDeepCultivator:draw()
end
