----------------------------------------------------------------------------------------------------
-- SOIL COMPACTION SPECIALIZATION
----------------------------------------------------------------------------------------------------
-- Author:  Rahkiin, reallogger
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssSoilCompaction = {}

ssSoilCompaction.MAX_CHARS_TO_DISPLAY = 20
ssSoilCompaction.LIGHT_COMPACTION = -0.15
ssSoilCompaction.MEDIUM_COMPACTION = 0.05
ssSoilCompaction.HEAVY_COMPACTION = 0.2

function ssSoilCompaction:prerequisitesPresent(specializations)
    return true
end

function ssSoilCompaction:preLoad(savegame)
end

function ssSoilCompaction:load(savegame)
    self.applySoilCompaction = ssSoilCompaction.applySoilCompaction
    self.getCompactionLayers = ssSoilCompaction.getCompactionLayers
    self.getTireMaxLoad = ssSoilCompaction.getTireMaxLoad
end

function ssSoilCompaction:delete()
end

function ssSoilCompaction:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssSoilCompaction:keyEvent(unicode, sym, modifier, isDown)
end

function ssSoilCompaction:applySoilCompaction()
    local soilWater = g_currentMission.environment.groundWetness

    for _, wheel in pairs(self.wheels) do
        if wheel.hasGroundContact and not wheel.mrNotAWheel and wheel.isSynchronized then
            local x0, y0, z0
            local x1, y1, z1
            local x2, y2, z2

            local width = wheel.width
            local radius = wheel.radius
            local length = math.max(0.1, 0.35 * radius)
            --local contactArea = length * width
            local penetrationResistance = 4e5 / (20 + (g_currentMission.environment.groundWetness * 100 + 5)^2)

            wheel.load = getWheelShapeContactForce(wheel.node, wheel.wheelShape)
            local oldPressure = Utils.getNoNil(wheel.groundPressure,15)
            if wheel.load == nil then wheel.load = wheel.restLoad end

            local inflationPressure = 180
            if self.getInflationPressure then
                inflationPressure = self:getInflationPressure()
            end

            if wheel.ssMaxLoad == nil then
                wheel.ssMaxDeformation = Utils.getNoNil(wheel.maxDeformation,0)
                wheel.ssMaxLoad = self:getTireMaxLoad(wheel, inflationPressure)
            end

            wheel.contactArea = 0.38 * wheel.load^0.7 * math.sqrt(width / (radius * 2)) / inflationPressure^0.45

            local tireTypeCrawler = WheelsUtil.getTireType("crawler")
            if wheel.tireType == tireTypeCrawler then
                length = radius
                wheel.contactArea = length * width
            end

            -- TODO: No need to store groundPressure, but for display
            wheel.groundPressure = oldPressure * 99 / 100 +  wheel.load / wheel.contactArea / 100
            if wheel.contactArea == 0 then
                wheel.groundPressure = oldPressure
            end

            -- soil saturation index 0.2
            -- c index Cp 0.7
            -- reference pressure 100 kPa
            -- reference saturation Sk 50%
            local soilBulkDensityRef = 0.2 * (soilWater - 0.5) + 0.7 * math.log10(wheel.groundPressure / 100)

            wheel.possibleCompaction = 3
            if soilBulkDensityRef > ssSoilCompaction.LIGHT_COMPACTION and soilBulkDensityRef <= ssSoilCompaction.MEDIUM_COMPACTION then
                wheel.possibleCompaction = 2

            elseif soilBulkDensityRef > ssSoilCompaction.MEDIUM_COMPACTION and soilBulkDensityRef <= ssSoilCompaction.HEAVY_COMPACTION then
                wheel.possibleCompaction = 1

            elseif soilBulkDensityRef > ssSoilCompaction.HEAVY_COMPACTION then
                wheel.possibleCompaction = 0
            end
            --below only for debug print. TODO: remove when done
            wheel.soilBulkDensity = soilBulkDensityRef

            local wheelRot = getWheelShapeAxleSpeed(wheel.node, wheel.wheelShape)
            local wheelRotDir

            if wheelRot ~= 0 then
                wheelRotDir = wheelRot / math.abs(wheelRot)
            else
                wheelRotDir = 1
            end

            local underTireCompaction = 0
            local fwdTireCompaction = 0
            local wantedC = 3

            -- TODO: 2 lines below can be local and no need to store CLayers in wheel
            local x0, z0, x1, z1, x2, z2, fwdLayers = self:getCompactionLayers(wheel, width, length, radius, radius * wheelRotDir * -1, 2 * radius * wheelRotDir)
            local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, x0, z0, x1, z1, x2, z2)

            -- debug print
            --ssDebug:drawDensityParallelogram(x, z, widthX, widthZ, heightX, heightZ, 0.25, 255, 255, 0)

            local x0, z0, x1, z1, x2, z2, underLayers = self:getCompactionLayers(wheel, width, length, radius, length, length)
            local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, x0, z0, x1, z1, x2, z2)

            -- debug print
            --ssDebug:drawDensityParallelogram(x, z, widthX, widthZ, heightX, heightZ, 0.25, 255, 0, 0)

            wheel.underTireCompaction = mathRound(underLayers,0)
            wheel.fwdTireCompaction = mathRound(fwdLayers,0)

            if wheel.underTireCompaction ==  3 and soilBulkDensityRef > ssSoilCompaction.LIGHT_COMPACTION then
                wantedC = 2

            elseif wheel.underTireCompaction == 2 and wheel.fwdTireCompaction == 2
                and soilBulkDensityRef > ssSoilCompaction.MEDIUM_COMPACTION and soilBulkDensityRef <= ssSoilCompaction.HEAVY_COMPACTION then
                wantedC = 1

            elseif wheel.underTireCompaction == 1 and wheel.fwdTireCompaction == 1 and soilBulkDensityRef > ssSoilCompaction.HEAVY_COMPACTION then
                wantedC = 0
            end

            if wantedC ~= 3 then
                setDensityParallelogram(g_currentMission.terrainDetailId, x, z, widthX, widthZ, heightX, heightZ, g_currentMission.ploughCounterFirstChannel, g_currentMission.ploughCounterNumChannels, wantedC)
            end

            -- for debug
            -- penetrationResistance = 0

            if wheel.groundPressure > penetrationResistance and self:getLastSpeed() > 0 and self.isEntered then
                local dx, _ ,dz = localDirectionToWorld(self.rootNode, 0, 0, 1)
                local angle = Utils.convertToDensityMapAngle(Utils.getYRotationFromDirection(dx, dz), g_currentMission.terrainDetailAngleMaxValue)

                local x0, z0, x1, z1, x2, z2, underLayers = self:getCompactionLayers(wheel, math.max(0.1, width - 0.15), length, radius, length, length)
                local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, x0, z0, x1, z1, x2, z2)

                local cm = g_currentMission
                setDensityMaskedParallelogram(cm.terrainDetailId, x, z, widthX, widthZ, heightX, heightZ, cm.terrainDetailTypeFirstChannel, cm.terrainDetailTypeNumChannels, cm.terrainDetailId, cm.terrainDetailTypeFirstChannel, cm.terrainDetailTypeNumChannels, cm.ploughValue)
                setDensityMaskedParallelogram(cm.terrainDetailId, x, z, widthX, widthZ, heightX, heightZ, cm.terrainDetailAngleFirstChannel, cm.terrainDetailAngleNumChannels, cm.terrainDetailId, cm.terrainDetailTypeFirstChannel, cm.terrainDetailTypeNumChannels, angle)
            end
        end
    end
end

function ssSoilCompaction:getTireMaxLoad(wheel, inflationPressure)
    local tireLoadIndex = 981 * wheel.ssMaxDeformation + 73
    local inflationFac = 0.56 + 0.002 * inflationPressure

    -- in kN
    return 44 * math.exp(0.0288 * tireLoadIndex) * inflationFac / 100
end

function ssSoilCompaction:getCompactionLayers(wheel, width, length, radius, delta0, delta2)
    local x0, y0, z0
    local x1, y1, z1
    local x2, y2, z2

    if wheel.repr == wheel.driveNode then
        x0, y0, z0 = localToWorld(wheel.node, wheel.positionX + width / 2, wheel.positionY, wheel.positionZ - delta0)
        x1, y1, z1 = localToWorld(wheel.node, wheel.positionX - width / 2, wheel.positionY, wheel.positionZ - delta0)
        x2, y2, z2 = localToWorld(wheel.node, wheel.positionX + width / 2, wheel.positionY, wheel.positionZ + delta2)
    else
        local x, _, z = localToLocal(wheel.driveNode, wheel.repr, 0, 0, 0)
        x0, y0, z0 = localToWorld(wheel.repr, x + width / 2, 0, z - delta0)
        x1, y1, z1 = localToWorld(wheel.repr, x - width / 2, 0, z - delta0)
        x2, y2, z2 = localToWorld(wheel.repr, x + width / 2, 0, z + delta2)
    end

    local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailId, x0, z0, x1, z1, x2, z2)

    local density, area, _ = getDensityParallelogram(g_currentMission.terrainDetailId, x, z, widthX, widthZ, heightX, heightZ, g_currentMission.ploughCounterFirstChannel, g_currentMission.ploughCounterNumChannels)
    local compactionLayers = density/area

    return x0, z0, x1, z1, x2, z2, compactionLayers
end

function ssSoilCompaction:update(dt)
    if not g_seasons.soilCompaction.enabled then return end

    if self.lastSpeedReal ~= 0
        and g_currentMission:getIsServer()
        and not ssWeatherManager:isGroundFrozen()
        and not SpecializationUtil.hasSpecialization(Cultivator, self.specializations) then
        self:applySoilCompaction()
    end

    -- text in menu will not be correct before the tractor has driven a few seconds
    -- TODO: only works for tractors you have been sitting in at the moment
    if self:isPlayerInRange() then
        local worstCompaction = 4
        for _, wheel in pairs(self.wheels) do
            -- fallback to 'no compaction'
            worstCompaction = math.min(worstCompaction,Utils.getNoNil(wheel.possibleCompaction, 4))
        end

        if worstCompaction < 4 then
            local storeItem = StoreItemsUtil.storeItemsByXMLFilename[self.configFileName:lower()]
            local storeItemName = storeItem.name
            if string.len(storeItemName) > ssSoilCompaction.MAX_CHARS_TO_DISPLAY then
                storeItemName = ssUtil.trim(string.sub(storeItemName, 1, ssSoilCompaction.MAX_CHARS_TO_DISPLAY - 5)) .. "..."
            end

            local compactionText = string.format(g_i18n:getText("COMPACTION_" .. tostring(worstCompaction)), storeItemName)
            g_currentMission:addExtraPrintText(compactionText)
        end
    end
end

function ssSoilCompaction:draw()
end
