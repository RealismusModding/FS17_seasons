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

    self.ssOrigMaxForce = self.powerConsumer.maxForce
    self.ssDeepCultivatorMod = getXMLBool(self.xmlFile, "vehicle.ssCultivation#deep")
    self.ssSubsoilerMod = getXMLBool(self.xmlFile, "vehicle.ssCultivation#subsoiler")

    local isValid, depth = ssDeepCultivator.isStoreItemDeepCultivator(StoreItemsUtil.storeItemsByXMLFilename[self.configFileName:lower()])
    self.ssValidDeepCultivator = isValid
    if depth ~= nil then
        self.ssCultivationDepth = depth
    end

    if self.ssCultivationDepth == ssDeepCultivator.DEPTH_SHALLOW then
        self.powerConsumer.maxForce = self.ssOrigMaxForce * ssDeepCultivator.SHALLOW_FORCE_FACTOR
    end

    if savegame ~= nil then
        self.ssCultivationDepth = ssXMLUtil.getInt(savegame.xmlFile, savegame.key .. "#ssCultivationDepth", self.ssCultivationDepth)
    end
end

function ssDeepCultivator.isStoreItemDeepCultivator(storeItem)
    local xmlFile = loadXMLFile("TempConfig", storeItem.xmlFilename)
    if not xmlFile then return false end

    local typeName = getXMLString(xmlFile, "vehicle#type")
    local deepCultivatorMod = Utils.getNoNil(getXMLBool(xmlFile, "vehicle.ssCultivation#deep"), false)
    local subsoilerMod = Utils.getNoNil(getXMLBool(xmlFile, "vehicle.ssCultivation#subsoiler"), false)
    local workingWidth = storeItem.specs.workingWidth
    local maxForce = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.powerConsumer#maxForce"), 0)

    delete(xmlFile)

    if deepCultivatorMod and subsoilerMod then
        logInfo("ssDeepCultivator:", storeItem.name .. " cannot be both a subsoiler and a deep cultivator. Subsoiler applied.")
        return false
    end

    if storeItem.name == "CULTIMER L 300" -- Fails to listen to the algo
        or deepCultivatorMod -- special designation
        or maxForce / workingWidth > 6 then -- a lot of force on a small area: assume deep
        return true
    end

    -- Subsoilers act always deep (as a plough)
    if typeName == "subsoiler" -- Platinum DLC
        or subsoilerMod then
        return false, 3
    end

    return false
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

        -- checking what crop is cultivated and what stage it is
        local crop = nil
        for index, fruit in pairs(g_currentMission.fruits) do
            local fruitDesc = FruitUtil.fruitIndexToDesc[index]
            local a, b, _ = getDensityParallelogram(fruit.id, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ,  0, g_currentMission.numFruitDensityMapChannels)

            if a ~= nil then
                if a > 0 then
                    crop = {
                        desc = fruitDesc,
                        stage = a / b
                    }
                    break
                end
            end
        end

        -- increasing cultivation depth if cultivating radish that is ready
        if crop ~= nil then
            if crop.desc.index == FruitUtil.FRUITTYPE_OILSEEDRADISH and crop.stage == crop.desc.maxHarvestingGrowthState then
                depth = math.min(depth + 1, 3)
            end
        end

        -- Add depth parameter
        return oldAreaUpdater(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, forced, commonForced, angle, depth)
    end

    local sumArea = superFunc(self, ...)

    Utils.updateCultivatorArea = oldAreaUpdater

    return sumArea
end

function ssDeepCultivator:draw()
end
