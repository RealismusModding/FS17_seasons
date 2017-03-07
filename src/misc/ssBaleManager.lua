---------------------------------------------------------------------------------------------------------
-- BALE MANAGER SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  To reduce fillLevel of bales
-- Authors:  reallogger
--

ssBaleManager = {}

function ssBaleManager:loadMap(name)
    g_currentMission.environment:addHourChangeListener(self)
    g_currentMission.environment:addDayChangeListener(self)

    Bale.loadFromAttributesAndNodes = Utils.overwrittenFunction(Bale.loadFromAttributesAndNodes, ssBaleManager.loadFromAttributesAndNodes)
    Bale.getSaveAttributesAndNodes = Utils.overwrittenFunction(Bale.getSaveAttributesAndNodes, ssBaleManager.getSaveAttributesAndNodes)
end

function ssBaleManager:reduceFillLevel()
    for index,object in pairs(g_currentMission.itemsToSave) do
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

                    local x,z, widthX,widthZ, heightX,heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, x0,z0, x1,z1, x2,z2)

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

                -- without a snowmask reduce all unwrapped bales
                else
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

function ssBaleManager:removeBale()
    for index,object in pairs(g_currentMission.itemsToSave) do
        if object.item:isa(Bale) then
            local bale = object.item

            if bale.fillType == FillUtil.getFillTypesByNames("straw")[1] or bale.fillType == FillUtil.getFillTypesByNames("dryGrass")[1] then
                local volume = math.huge

                -- when fillLevel is less than volume (i.e. uncompressed) the bale will be deleted
                if bale.baleDiameter ~= nil then
                    volume = math.pi*(bale.baleDiameter / 2 )^2 * bale.baleWidth * 1000
                else
                    volume = bale.baleWidth * bale.baleLength * bale.baleHeight * 1000
                end

                if bale.fillLevel < volume then
                    self:delete(bale)
                end

            -- when grass bale is more than 2 days old it will be deleted
            elseif bale.fillType == FillUtil.getFillTypesByNames("grass_windrow")[1] then
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
    for index,object in pairs(g_currentMission.itemsToSave) do

        if object.item:isa(Bale) then
            local bale = object.item

            if bale.age ~= nil then
                local yesterdayAge = bale.age
                bale.age = yesterdayAge + 1
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

        local dayReductionFactor = 1 - ( ( 2.4 * singleBale.age / daysInSeason + 1.2 )^5.75) / 100
        reductionFactor = 1 - ( 1 - dayReductionFactor)/24

    end

    return reductionFactor
end

function ssBaleManager:loadFromAttributesAndNodes(oldFunc, xmlFile, key, resetVehicles)
    local state = oldFunc(self, xmlFile, key, resetVehicles)

    if state then
        local ageLoad = getXMLString(xmlFile, key .. "#age")

        if age ~= nil then
            self.age = ageLoad
        end
    end

    return state
end

function ssBaleManager:getSaveAttributesAndNodes(oldFunc, nodeIdent)
    local attributes, nodes = oldFunc(self, nodeIdent)

    if attributes ~= nil and self.age ~= nil then
        attributes = attributes .. ' age="' .. self.age .. '"'
    end

    return attributes, nodes
end
