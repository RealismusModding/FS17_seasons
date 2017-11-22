----------------------------------------------------------------------------------------------------
-- REPAIRABLE SPECIALIZATION
----------------------------------------------------------------------------------------------------
-- Authors:  Rahkiin, reallogger, Rival
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssRepairable = {}

function ssRepairable:prerequisitesPresent(specializations)
    return true
end

function ssRepairable:load(savegame)
    self.ssLastRepairDay = g_currentMission.environment.currentDay
    self.ssLastRepairOperatingTime = self.operatingTime
    self.ssCumulativeDirt = 0

    if savegame ~= nil then
        self.ssLastRepairDay = ssXMLUtil.getFloat(savegame.xmlFile, savegame.key .. "#ssLastRepairDay", self.ssLastRepairDay)
        self.ssLastRepairOperatingTime = ssXMLUtil.getFloat(savegame.xmlFile, savegame.key .. "#ssYesterdayOperatingTime", self.ssLastRepairOperatingTime)
        self.ssCumulativeDirt = ssXMLUtil.getFloat(savegame.xmlFile, savegame.key .. "#ssCumulativeDirt", self.ssCumulativeDirt)
    end
end

function ssRepairable:delete()
end

function ssRepairable:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssRepairable:keyEvent(unicode, sym, modifier, isDown)
end

function ssRepairable:loadFromAttributesAndNodes(xmlFile, key)
    return true
end

function ssRepairable:getSaveAttributesAndNodes(nodeIdent)
    local attributes = ""

    if self.ssLastRepairDay ~= nil then
        attributes = attributes .. "ssLastRepairDay=\"" .. self.ssLastRepairDay ..  "\" "
        attributes = attributes .. "ssYesterdayOperatingTime=\"" .. self.ssLastRepairOperatingTime ..  "\" "
        attributes = attributes .. "ssCumulativeDirt=\"" .. self.ssCumulativeDirt ..  "\" "
    end

    return attributes, ""
end

function ssRepairable:readStream(streamId, connection)
    self.ssLastRepairDay = streamReadFloat32(streamId)
    self.ssLastRepairOperatingTime = streamReadFloat32(streamId)
    self.ssCumulativeDirt = streamReadFloat32(streamId)
end

function ssRepairable:writeStream(streamId, connection)
    streamWriteFloat32(streamId, self.ssLastRepairDay)
    streamWriteFloat32(streamId, self.ssLastRepairOperatingTime)
    streamWriteFloat32(streamId, self.ssCumulativeDirt)
end

function ssRepairable:draw()
end

function ssRepairable:updateTick(dt)
    -- Calculate cumulative dirt
    if self.getDirtAmount ~= nil then
        local factor = self:getIsOperating() and 1 or 0.1

        self.ssCumulativeDirt = self.ssCumulativeDirt + self:getDirtAmount() * dt * factor
    end
end

function ssRepairable:update(dt)
    -- stupid fix for setting ssLastRepairOperatingTime to operatingTime for a new savegame
    if self.ssLastRepairOperatingTime == 0 then
        self.ssLastRepairOperatingTime = self.operatingTime
    end
end
