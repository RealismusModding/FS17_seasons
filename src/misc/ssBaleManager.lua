----------------------------------------------------------------------------------------------------
-- BALE MANAGER SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  To reduce fillLevel of bales
-- Authors:  reallogger
-- Credits:  baron for fermenting bales
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssBaleManager = {}

source(g_seasons.modDir .. "src/events/ssBaleFermentEvent.lua")

function ssBaleManager:preLoad()
    Bale.loadFromAttributesAndNodes = Utils.overwrittenFunction(Bale.loadFromAttributesAndNodes, ssBaleManager.baleLoadFromAttributesAndNodes)
    Bale.getSaveAttributesAndNodes = Utils.overwrittenFunction(Bale.getSaveAttributesAndNodes, ssBaleManager.baleGetSaveAttributesAndNodes)
    Bale.updateTick = Utils.appendedFunction(Bale.updateTick, ssBaleManager.baleUpdateTick)
    BaleWrapper.doStateChange = Utils.appendedFunction(BaleWrapper.doStateChange, ssBaleManager.baleWrapperDoStateChange)
    Bale.readStream = Utils.appendedFunction(Bale.readStream, ssBaleManager.baleReadStream)
    Bale.writeStream = Utils.appendedFunction(Bale.writeStream, ssBaleManager.baleWriteStream)
end

function ssBaleManager:loadMap(name)
    g_currentMission.environment:addHourChangeListener(self)
    g_currentMission.environment:addDayChangeListener(self)
    g_seasons.environment:addSeasonLengthChangeListener(self)

    if g_currentMission:getIsServer() then
        self:setFermentationTime()
    end
end

function ssBaleManager:reduceFillLevel()
    for index, object in pairs(g_currentMission.itemsToSave) do
        -- only check bales
        if object.item:isa(Bale) then
            local bale = object.item

            -- wrapped bales are not affected
            if bale.wrappingState ~= 1 then

                -- with a snowmask only reduce hay and hay bales outside and grass bales inside/outside
                if ssSnow.snowMaskId ~= nil then
                    local dim = {}

                    if bale.baleDiameter ~= nil then
                        dim.width = bale.baleWidth
                        dim.length = bale.baleDiameter
                    else
                        dim.width = bale.baleWidth
                        dim.length = bale.baleLength
                    end

                    local x0 = bale.sendPosX + dim.width
                    local x1 = bale.sendPosX - dim.width
                    local x2 = bale.sendPosX + dim.width
                    local z0 = bale.sendPosZ - dim.length
                    local z1 = bale.sendPosZ - dim.length
                    local z2 = bale.sendPosZ + dim.length

                    local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, x0, z0, x1, z1, x2, z2)

                    local density, _, _ = getDensityMaskedParallelogram(ssSnow.snowMaskId, x, z, widthX, widthZ, heightX, heightZ, 0, 5, ssSnow.snowMaskId, ssSnow.SNOW_MASK_FIRST_CHANNEL, ssSnow.SNOW_MASK_NUM_CHANNELS)

                    -- check if the bale is outside and there has been rain during the day
                    if density == 0 and g_currentMission.environment.timeSinceLastRain < 60 then

                        if bale.fillType == FillUtil.getFillTypesByNames("straw")[1] or bale.fillType == FillUtil.getFillTypesByNames("dryGrass")[1] then
                            local origFillLevel = bale.fillLevel
                            local reductionFactor = self:calculateBaleReduction(bale)
                            bale.fillLevel = origFillLevel * reductionFactor
                        end
                    end

                    if bale.fillType == FillUtil.getFillTypesByNames("grass_windrow")[1] then
                        local origFillLevel = bale.fillLevel
                        local reductionFactor = self:calculateBaleReduction(bale)
                        bale.fillLevel = origFillLevel * reductionFactor
                    end

                -- without a snowmask reduce only unwrapped grass bales
                elseif bale.fillType == FillUtil.getFillTypesByNames("grass_windrow")[1] then
                    local origFillLevel = bale.fillLevel
                    local reductionFactor = self:calculateBaleReduction(bale)
                    bale.fillLevel = origFillLevel * reductionFactor
                end

            end
        end
    end
end

function ssBaleManager:hourChanged()
    if g_currentMission:getIsServer() then
        self:reduceFillLevel()
    end
end

function ssBaleManager:dayChanged()
    if g_currentMission:getIsServer() then
        self:incrementBaleAge()
        self:removeBale()
    end
end

function ssBaleManager:seasonLengthChanged()
    if g_currentMission:getIsServer() then
        self:setFermentationTime()
    end
end

function ssBaleManager:removeBale()
    for index, object in pairs(g_currentMission.itemsToSave) do
        if object.item:isa(Bale) then
            local bale = object.item

            if bale.fillType == FillUtil.getFillTypesByNames("straw")[1] or bale.fillType == FillUtil.getFillTypesByNames("dryGrass")[1] then
                local volume = math.huge

                -- when fillLevel is less than volume (i.e. uncompressed) the bale will be deleted
                if bale.baleDiameter ~= nil then
                    volume = math.pi * (bale.baleDiameter / 2 ) ^ 2 * bale.baleWidth * 1000
                else
                    volume = bale.baleWidth * bale.baleLength * bale.baleHeight * 1000
                end

                if bale.fillLevel < volume then
                    self:delete(bale)
                end

            -- when grass bale is more than 2 days old it will be deleted
            elseif bale.fillType == FillUtil.getFillTypesByNames("grass_windrow")[1] and bale.wrappingState ~= 1 then
                if bale.age > 2 then
                    self:delete(bale)
                end
            end
        end
    end
end

function ssBaleManager:delete(singleBale)
    -- from https://gdn.giants-software.com/documentation_scripting.php?version=script&category=65&class=2511#delete34583
    if singleBale.i3dFilename ~= nil then
        Utils.releaseSharedI3DFile(singleBale.i3dFilename, nil, true)
    end

    g_currentMission:removeLimitedObject(FSBaseMission.LIMITED_OBJECT_TYPE_BALE, singleBale)
    unregisterObjectClassName(singleBale)
    g_currentMission:removeItemToSave(singleBale)
    Bale:superClass().delete(singleBale)
end

function ssBaleManager:incrementBaleAge()
    for index, object in pairs(g_currentMission.itemsToSave) do
        if object.item:isa(Bale) then
            local bale = object.item

            if bale.age ~= nil then
                bale.age = bale.age + 1
            else
                bale.age = 0
            end
        end
    end
end

function ssBaleManager:calculateBaleReduction(singleBale)
    local reductionFactor = 1
    local daysInSeason = g_seasons.environment.daysInSeason

    if singleBale.fillType == FillUtil.getFillTypesByNames("straw")[1] or singleBale.fillType == FillUtil.getFillTypesByNames("dryGrass")[1] then
        reductionFactor = 0.99

    elseif singleBale.fillType == FillUtil.getFillTypesByNames("grass_windrow")[1] then
        if singleBale.age == nil then
            singleBale.age = 0
        end

        local dayReductionFactor = 1 - ( (2.4 * singleBale.age / daysInSeason + 1.2 ) ^ 5.75) / 100
        reductionFactor = 1 - (1 - dayReductionFactor) / 24
    end

    return reductionFactor
end

function ssBaleManager:setFermentationTime()
    -- fermentation time set to the equivalent of 4 weeks
    self.fermentationTime = 3600 * 24 * g_seasons.environment.daysInSeason / 3
end

--------------------------------------------------------
-- Bale(Wrapper) overwrite functions for fermentation
--------------------------------------------------------

-- from fatov - balewrapper determines what bales to ferment
function ssBaleManager:baleWrapperDoStateChange(id, nearestBaleServerId)

    if self.isServer then
        if id == BaleWrapper.CHANGE_WRAPPER_BALE_DROPPED and self.lastDroppedBale ~= nil then
            local bale = self.lastDroppedBale

           if bale.fillType == FillUtil.FILLTYPE_SILAGE and bale.wrappingState >= 1 then
                --initiate fermenting process
                bale.fillType = FillUtil.FILLTYPE_GRASS_WINDROW
                bale.fermentingProcess = 0

                ssBaleFermentEvent:sendEvent(bale)
            end
        end
    end
end

-- from fatov - ferment bales
function ssBaleManager:baleUpdateTick(dt)
    if self.isServer then
        if self.fermentingProcess ~= nil then
            self.fermentingProcess = self.fermentingProcess + ((dt * 0.001 * g_currentMission.missionInfo.timeScale) / ssBaleManager.fermentationTime)

            if self.fermentingProcess >= 1 then
                --finish fermenting process
                self.fillType = FillUtil.FILLTYPE_SILAGE
                self.fermentingProcess = nil

                ssBaleFermentEvent:sendEvent(self)
            end
        end
    end
end

function ssBaleManager:baleLoadFromAttributesAndNodes(superFunc, xmlFile, key, resetVehicles)
    local state = superFunc(self, xmlFile, key, resetVehicles)

    self.age = Utils.getNoNil(getXMLInt(xmlFile, key .. "#age"), 0)
    self.fermentingProcess = getXMLFloat(xmlFile, key .. "#fermentingProcess")

    if self.fermentingProcess ~= nil then
        self.fillType = FillUtil.FILLTYPE_GRASS_WINDROW
    end

    return state
end

function ssBaleManager:baleGetSaveAttributesAndNodes(superFunc, nodeIdent)
    local attributes, nodes = superFunc(self, nodeIdent)

    if attributes ~= nil and self.age ~= nil then
        attributes = attributes .. ' age="' .. self.age .. '"'
    end

    if attributes ~= nil and self.fermentingProcess ~= nil then
        attributes = attributes .. ' fermentingProcess="' .. self.fermentingProcess .. '"'
    end

    return attributes, nodes
end

function ssBaleManager:baleWriteStream(streamId, connection)
    local isFermenting = self.fermentingProcess ~= nil

    streamWriteBool(streamId, isFermenting)
end

function ssBaleManager:baleReadStream(streamId, connection)
    if streamReadBool(streamId, connection) then
        self.fillType = FillUtil.FILLTYPE_GRASS_WINDROW
    end
end
