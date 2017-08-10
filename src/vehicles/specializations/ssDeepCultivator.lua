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

   self.validDeepCultivator = true

    local storeItem = StoreItemsUtil.storeItemsByXMLFilename[self.configFileName:lower()]
    local workingWidth = storeItem.specs.workingWidth
    local maxForce = self.powerConsumer.maxForce

    -- hard coded fix since it does not fit criteria of maxForce / workingWidth > 6
    if storeItem.name == "CULTIMER L 300" then
        self.validDeepCultivator = true
    
    -- subsoilers already act deep
    elseif self.typeName == "subsoiler" or maxForce / workingWidth < 6 then
        self.validDeepCultivator = false
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

    -- TOOD Need to set cultivatorDecompactionDelta for ssSC

    -- TODO(Jos) send event with new cultivation depth
end

function ssDeepCultivator:update(dt)
    if not g_currentMission:getIsServer() 
        or not g_seasons.soilCompaction.compactionEnabled 
        or not self.validDeepCultivator then
        return end

    if self:getIsActiveForInput(true) then
        local storeItem = StoreItemsUtil.storeItemsByXMLFilename[self.configFileName:lower()]
        local vehicleName = storeItem.brand .. " " .. storeItem.name

        -- Show text for changing cultivation depth
        local storeItemName = storeItem.name
        if string.len(storeItemName) > ssDeepCultivator.MAX_CHARS_TO_DISPLAY then
            storeItemName = ssUtil.trim(string.sub(storeItemName, 1, ssDeepCultivator.MAX_CHARS_TO_DISPLAY - 5)) .. "..."
        end

        local cultivationDepthText = g_i18n:getText("CULTIVATION_DEPTH_" .. tostring(self.ssCultivationDepth))
        -- need to set a new inputBinding
        g_currentMission:addHelpButtonText(string.format(g_i18n:getText("input_SEASONS_CULTIVATION_DEPTH"), cultivationDepthText), InputBinding.IMPLEMENT_EXTRA4, nil, GS_PRIO_HIGH)

        if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA4) then
            ssDeepCultivator:updateCultivationDepth(self)
        end
    end
end

function ssDeepCultivator:draw()
end
