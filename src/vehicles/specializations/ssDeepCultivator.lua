----------------------------------------------------------------------------------------------------
-- DEEP CULTIVATOR SPECIALIZATION
----------------------------------------------------------------------------------------------------
-- Authors:  baron, Rahkiin, reallogger
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssDeepCultivator = {}

ssDeepCultivator.SHALLOW_FORCE_FACTOR = 0.7

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
    self.updateCultivationDepth = ssDeepCultivator.updateCultivationDepth
    self.processCultivatorAreas = Utils.overwrittenFunction(self.processCultivatorAreas, ssDeepCultivator.processCultivatorAreas);

    self.ssCultivationDepth = ssDeepCultivator.DEPTH_SHALLOW

    if savegame ~= nil then
        self.ssCultivationDepth = ssXMLUtil.getInt(savegame.xmlFile, savegame.key .. "#ssCultivationDepth", self.ssCultivationDepth)
    end

    self.ssValidDeepCultivator = false

    local storeItem = StoreItemsUtil.storeItemsByXMLFilename[self.configFileName:lower()]
    local workingWidth = storeItem.specs.workingWidth
    local maxForce = self.powerConsumer.maxForce
    self.ssOrigMaxForce = maxForce

    self.ssDeepCultivatorMod = getXMLBool(self.xmlFile, "vehicle.ssCultivation#deep")
    self.ssSubsoilerMod = getXMLBool(self.xmlFile, "vehicle.ssCultivation#subsoiler")

    if self.ssDeepCultivatorMod and self.ssSubsoilerMod then
        logInfo("ssDeepCultivator:", storeItem.name .. " cannot be both a subsoiler and a deep cultivator. Subsoiler applied.")
        self.ssDeepCultivatorMod = false
    end

    -- hard coded fix since it does not fit criteria of maxForce / workingWidth > 6
    if storeItem.name == "CULTIMER L 300"
        or self.ssDeepCultivatorMod or maxForce / workingWidth > 6 then
        self.ssValidDeepCultivator = true
    end

    -- subsoilers already act deep
    if self.typeName == "subsoiler" or self.ssSubsoilerMod then
        self.ssValidDeepCultivator = false
        self.ssCultivationDepth = 3
    end

    if self.ssCultivationDepth == ssDeepCultivator.DEPTH_SHALLOW then
        self.powerConsumer.maxForce = self.ssOrigMaxForce * ssDeepCultivator.SHALLOW_FORCE_FACTOR
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

function ssDeepCultivator:updateCultivationDepth()
    self.ssCultivationDepth = self.ssCultivationDepth + 1
    self.powerConsumer.maxForce = self.ssOrigMaxForce

    if self.ssCultivationDepth > ssDeepCultivator.DEPTH_MAX then
        self.ssCultivationDepth = ssDeepCultivator.DEPTH_SHALLOW
        self.powerConsumer.maxForce = self.ssOrigMaxForce * ssDeepCultivator.SHALLOW_FORCE_FACTOR
    end

    -- TODO(Jos) send event with new cultivation depth
end

function ssDeepCultivator:update(dt)
    if not g_currentMission:getIsServer()
        or not g_seasons.soilCompaction.enabled
        or not self.ssValidDeepCultivator then
        return end

    if self:getIsActiveForInput(true) then
        local cultivationDepthText = g_i18n:getText("CULTIVATION_DEPTH_" .. tostring(self.ssCultivationDepth))
        -- need to set a new inputBinding
        g_currentMission:addHelpButtonText(string.format(g_i18n:getText("input_SEASONS_CULTIVATION_DEPTH"), cultivationDepthText), InputBinding.IMPLEMENT_EXTRA4, nil, GS_PRIO_HIGH)

        if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA4) then
            self:updateCultivationDepth()
        end
    end
end

function ssDeepCultivator:processCultivatorAreas(superFunc, ...)
    local depth = ssDeepCultivator.DEPTH_SHALLOW

    -- When SC is disabled we should not apply a deeper depth even though it is configured as such
    if g_seasons.soilCompaction.enabled then
        depth = self.ssCultivationDepth
    end

    local oldAreaUpdater = Utils.updateCultivatorArea
    Utils.updateCultivatorArea = function (startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, forced, commonForced, angle)
        -- Add depth parameter
        return oldAreaUpdater(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, forced, commonForced, angle, depth)
    end

    local sumArea = superFunc(self, ...)

    Utils.updateCultivatorArea = oldAreaUpdater

    return sumArea
end

function ssDeepCultivator:draw()
end
