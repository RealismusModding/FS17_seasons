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

ssBaleManager.MASK_RECT_WIDTH = 2 --2x2m

source(g_seasons.modDir .. "src/events/ssBaleFermentEvent.lua")
source(g_seasons.modDir .. "src/events/ssBaleRotEvent.lua")

function ssBaleManager:preLoad()
    g_seasons.baleManager = self

    ssUtil.overwrittenFunction(Bale, "loadFromAttributesAndNodes", ssBaleManager.baleLoadFromAttributesAndNodes)
    ssUtil.overwrittenFunction(Bale, "getSaveAttributesAndNodes", ssBaleManager.baleGetSaveAttributesAndNodes)
    ssUtil.appendedFunction(Bale, "updateTick", ssBaleManager.baleUpdateTick)
    ssUtil.appendedFunction(Bale, "readStream", ssBaleManager.baleReadStream)
    ssUtil.appendedFunction(Bale, "writeStream", ssBaleManager.baleWriteStream)
    Bale.setFillType = ssBaleManager.baleSetFillType
    ssUtil.appendedFunction(BaleWrapper, "load", ssBaleManager.baleWrapperLoad)
    ssUtil.overwrittenFunction(BaleWrapper, "getSaveAttributesAndNodes", ssBaleManager.baleWrapperGetSaveAttributesAndNodes)
    ssUtil.appendedFunction(BaleWrapper, "doStateChange", ssBaleManager.baleWrapperDoStateChange)
    ssUtil.prependedFunction(BaleWrapper, "pickupWrapperBale", ssBaleManager.baleWrapperPickupWrapperBale)
end

function ssBaleManager:loadMap(name)
    g_currentMission.environment:addHourChangeListener(self)
    g_currentMission.environment:addDayChangeListener(self)
    g_seasons.environment:addSeasonLengthChangeListener(self)

    if g_currentMission:getIsServer() then
        self:setFermentationTime()
    end
end

function ssBaleManager:deleteMap()
    g_currentMission.environment:removeHourChangeListener(self)
    g_currentMission.environment:removeDayChangeListener(self)
    g_seasons.environment:removeSeasonLengthChangeListener(self)

    Bale.setFillType = nil
end

function ssBaleManager:reduceFillLevel()
    for _, object in pairs(g_currentMission.itemsToSave) do
        -- only check bales
        if object.item:isa(Bale) then
            local bale = object.item

            -- wrapped bales are not affected
            if bale.wrappingState ~= 1 then
                local isGrassBale = bale:getFillType() == FillUtil.FILLTYPE_GRASS_WINDROW

                -- with a snowmask only reduce hay and hay bales outside and grass bales inside/outside
                -- if there has been rain during the day
                if ssSnow.snowMaskId ~= nil and not isGrassBale and g_currentMission.environment.timeSinceLastRain < 60 then
                    local x0 = bale.sendPosX - (ssBaleManager.MASK_RECT_WIDTH / 2)
                    local z0 = bale.sendPosZ - (ssBaleManager.MASK_RECT_WIDTH / 2)
                    local x1 = x0 + ssBaleManager.MASK_RECT_WIDTH
                    local z1 = z0
                    local x2 = x0
                    local z2 = z0 + ssBaleManager.MASK_RECT_WIDTH

                    local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, x0, z0, x1, z1, x2, z2)

                    local density, _, _ = getDensityParallelogram(ssSnow.snowMaskId, x, z, widthX, widthZ, heightX, heightZ, ssSnow.SNOW_MASK_FIRST_CHANNEL, ssSnow.SNOW_MASK_NUM_CHANNELS)

                    -- check if the bale is outside
                    if density == 0 then
                        if bale:getFillType() == FillUtil.FILLTYPE_STRAW or bale:getFillType() == FillUtil.FILLTYPE_DRYGRASS_WINDROW then
                            bale:setFillLevel(bale:getFillLevel() * self:calculateBaleReduction(bale))
                            ssBaleRotEvent:sendEvent(bale)
                        end
                    end

                -- with or without a snowmask reduce only unwrapped grass bales
                elseif isGrassBale then
                    bale:setFillLevel(bale:getFillLevel() * self:calculateBaleReduction(bale))
                    ssBaleRotEvent:sendEvent(bale)
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
    for _, object in pairs(g_currentMission.itemsToSave) do
        if object.item:isa(Bale) then
            local bale = object.item

            if bale:getFillType() == FillUtil.FILLTYPE_STRAW or bale:getFillType() == FillUtil.FILLTYPE_DRYGRASS_WINDROW then
                local volume = math.huge

                -- when fillLevel is less than volume (i.e. uncompressed) the bale will be deleted
                if bale.baleDiameter ~= nil then
                    volume = math.pi * (bale.baleDiameter / 2 ) ^ 2 * bale.baleWidth * 1000
                else
                    volume = bale.baleWidth * bale.baleLength * bale.baleHeight * 1000
                end

                if bale:getFillLevel() < volume then
                    self:delete(bale)
                end

            -- when grass bale is more than 2 days old it will be deleted
            elseif bale:getFillType() == FillUtil.FILLTYPE_GRASS_WINDROW and bale.wrappingState ~= 1 then
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
    for _, object in pairs(g_currentMission.itemsToSave) do
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

    if singleBale:getFillType() == FillUtil.FILLTYPE_STRAW or singleBale:getFillType() == FillUtil.FILLTYPE_DRYGRASS_WINDROW then
        reductionFactor = math.min(0.965 + math.sqrt(daysInSeason / 30000), 0.99)

    elseif singleBale:getFillType() == FillUtil.FILLTYPE_GRASS_WINDROW then
        if singleBale.age == nil then
            singleBale.age = 0
        end

        local dayReductionFactor = 1 - ( (2.4 * singleBale.age / daysInSeason + 1.2 ) ^ 5.75) / 100
        reductionFactor = math.max(1 - (1 - dayReductionFactor) / 24, 0.975)
    end

    return reductionFactor
end

function ssBaleManager:setFermentationTime()
    -- fermentation time set to the equivalent of 4 weeks
    self.fermentationTime = 3600 * 24 * g_seasons.environment.daysInSeason / 3
end

function ssBaleManager.isBaleFermenting(bale)
    return bale.fermentingProcess ~= nil and bale:getFillType() ~= FillUtil.FILLTYPE_DRYGRASS_WINDROW and bale:getFillType() ~= FillUtil.FILLTYPE_STRAW
end

--------------------------------------------------------
-- Overwritten bale functions for fermentation
--------------------------------------------------------

-- from fatov - ferment bales
function ssBaleManager:baleUpdateTick(dt)
    if self.isServer then
        if ssBaleManager.isBaleFermenting(self) then
            self.fermentingProcess = self.fermentingProcess + ((dt * 0.001 * g_currentMission.missionInfo.timeScale) / ssBaleManager.fermentationTime)

            if self.fermentingProcess >= 1 then
                --finish fermenting process
                self:setFillType(FillUtil.FILLTYPE_SILAGE)
                self.fermentingProcess = nil

                ssBaleFermentEvent:sendEvent(self)
            end
        end
    end
end

-- Bale.setFillType()
function ssBaleManager:baleSetFillType(fillType)
    self.fillType = fillType
    self:setFillLevel(self:getFillLevel()) -- to trigger mass update
end

--------------------------------------------------------
-- Overwritten BaleWrapper functions for fermentation
--------------------------------------------------------

-- append baleWrapper.doStateChange to initiate fermentation
function ssBaleManager:baleWrapperDoStateChange(id, nearestBaleServerId)
    if self.isServer then
        if id == BaleWrapper.CHANGE_WRAPPER_BALE_DROPPED and self.lastDroppedBale ~= nil then
            local bale = self.lastDroppedBale

           if bale:getFillType() == FillUtil.FILLTYPE_SILAGE and bale.wrappingState >= 1 then
                --initiate fermenting process
                bale:setFillType(Utils.getNoNil(self.baleFillTypeSource, FillUtil.FILLTYPE_GRASS_WINDROW))
                bale.fermentingProcess = 0

                ssBaleFermentEvent:sendEvent(bale)
            end

            self.baleFillTypeSource = nil
        end
    end
end

-- prepended baleWrapper.pickupWrapperBale, to store fillTypeSource
function ssBaleManager:baleWrapperPickupWrapperBale(bale, baleType)
    self.baleFillTypeSource = bale:getFillType()
end


--------------------------------------------------------
-- Network sync bales
--------------------------------------------------------

function ssBaleManager:baleWriteStream(streamId, connection)
    streamWriteUIntN(streamId, self:getFillType(), FillUtil.sendNumBits)
end

function ssBaleManager:baleReadStream(streamId, connection)
    self.fillType = streamReadUIntN(streamId, FillUtil.sendNumBits)
end

--------------------------------------------------------
-- Saving and loading
--------------------------------------------------------

-- Store baleFillTypeSource for bale wrappers
function ssBaleManager:baleWrapperLoad(savegame)
    if savegame ~= nil and not savegame.resetVehicles then
        local baleFillTypeSourceName = getXMLString(savegame.xmlFile, savegame.key .. "#baleFillTypeSource")

        if baleFillTypeSourceName ~= nil then
            self.baleFillTypeSource = FillUtil.getFillTypesByNames(baleFillTypeSourceName)[1]
        end
    end
end

function ssBaleManager:baleWrapperGetSaveAttributesAndNodes(superFunc, nodeIdent)
    local attributes, nodes = superFunc(self, nodeIdent)

    if attributes ~= nil and self.baleFillTypeSource ~= nil then
        attributes = attributes .. ' baleFillTypeSource="' .. Utils.getNoNil(FillUtil.fillTypeIntToName[self.baleFillTypeSource], "grass_windrow") .. '"'
    end

    return attributes, nodes
end

-- Store bale parameters
function ssBaleManager:baleLoadFromAttributesAndNodes(superFunc, xmlFile, key, resetVehicles)
    local state = superFunc(self, xmlFile, key, resetVehicles)

    self.age = Utils.getNoNil(getXMLInt(xmlFile, key .. "#age"), 0)
    self.fermentingProcess = getXMLFloat(xmlFile, key .. "#fermentingProcess")
    local fermentingFillTypeName = Utils.getNoNil(getXMLString(xmlFile, key .. "#fermentingFillType"), "grass_windrow")

    if self.fermentingProcess ~= nil then
        self:setFillType(FillUtil.getFillTypesByNames(fermentingFillTypeName)[1])
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
        attributes = attributes .. ' fermentingFillType="' .. Utils.getNoNil(FillUtil.fillTypeIntToName[self:getFillType()], "grass_windrow") .. '"'
    end

    return attributes, nodes
end
