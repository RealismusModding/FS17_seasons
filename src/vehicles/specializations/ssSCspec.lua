----------------------------------------------------------------------------------------------------
-- SC SPECIALIZATION
----------------------------------------------------------------------------------------------------
-- Author:  Rahkiin, reallogger
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssSCspec = {}

function ssSCspec:prerequisitesPresent(specializations)
    return true
end

function ssSCspec:preLoad(savegame)
    self.applySC = ssSCspec.applySC
    self.getCLayers = ssSCspec.getCLayers
    self.getTireMaxLoad = ssSCspec.getTireMaxLoad
end

function ssSCspec:load(savegame)
end

function ssSCspec:delete()
end

function ssSCspec:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssSCspec:keyEvent(unicode, sym, modifier, isDown)
end

function ssSCspec:applySC()
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
            local oldPressure = Utils.getNoNil(wheel.groundPressure,10)
            if wheel.load == nil then wheel.load = 0 end

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
            wheel.groundPressure = oldPressure * 999 / 1000 +  wheel.load / wheel.contactArea / 1000
            if wheel.contactArea == 0 then
                wheel.groundPressure = oldPressure
            end

            -- soil saturation index 0.2
            -- c index Cp 0.7
            -- reference pressure 100 kPa
            -- reference saturation Sk 50%
            local soilBulkDensityRef = 0.2 * (soilWater - 0.5) + 0.7 * math.log10(wheel.groundPressure / 100)

            --below only for debug print. TODO: remove when done
            wheel.soilBulkDensity = soilBulkDensityRef

            local wheelRot = getWheelShapeAxleSpeed(wheel.node, wheel.wheelShape)
            local wheelRotDir

            if wheelRot ~= 0 then
                wheelRotDir = wheelRot / math.abs(wheelRot)
            else
                wheelRotDir = 1
            end

            local underTireCLayers = 0
            local fwdTireCLayers = 0
            local wantedC = 3

            -- TODO: 2 lines below can be local and no need to store CLayers in wheel
            local x0, z0, x1, z1, x2, z2, fwdLayers = self:getCLayers(wheel, width, length, radius, radius * wheelRotDir * -1, 2 * radius * wheelRotDir)
            local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, x0, z0, x1, z1, x2, z2)
            ssDebug:drawDensityParallelogram(x, z, widthX, widthZ, heightX, heightZ, 0.25, 255, 255, 0)

            local x0, z0, x1, z1, x2, z2, underLayers = ssSCspec:getCLayers(wheel, width, length, radius, length, length)
            local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, x0, z0, x1, z1, x2, z2)
            ssDebug:drawDensityParallelogram(x, z, widthX, widthZ, heightX, heightZ, 0.25, 255, 0, 0)

            wheel.underTireCLayers = mathRound(underLayers,0)
            wheel.fwdTireCLayers = mathRound(fwdLayers,0)

            if wheel.underTireCLayers ==  3 and soilBulkDensityRef > -0.15 then
                wantedC = 2

            elseif wheel.underTireCLayers == 2 and wheel.fwdTireCLayers == 2
                and soilBulkDensityRef > 0.0 and soilBulkDensityRef <= 0.15 then
                wantedC = 1

            elseif wheel.underTireCLayers == 1 and wheel.fwdTireCLayers == 1 and soilBulkDensityRef > 0.15 then
                wantedC = 0
            end

            if wantedC ~= 3 then
                local _, _, _ = setDensityParallelogram(g_currentMission.terrainDetailId, x, z, widthX, widthZ, heightX, heightZ, g_currentMission.ploughCounterFirstChannel, g_currentMission.ploughCounterNumChannels, wantedC)
            end

            -- for debug
            --penetrationResistance = 0

            if wheel.groundPressure > penetrationResistance and self:getLastSpeed() > 0 and self.isEntered then

                local dx,_,dz = localDirectionToWorld(wheel.node, 0, 0, 1)
                local angle = Utils.convertToDensityMapAngle(Utils.getYRotationFromDirection(dx, dz), g_currentMission.terrainDetailAngleMaxValue)

                local x0, z0, x1, z1, x2, z2, underLayers = ssSCspec:getCLayers(wheel, math.max(0.1,width-0.15), length, radius, length, length)
                local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, x0, z0, x1, z1, x2, z2)

                -- TODO: not working
                setDensityMaskedParallelogram(g_currentMission.terrainDetailId, x, z, widthX, widthZ, heightX, heightZ,
                    g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels,
                    g_currentMission.terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, g_currentMission.ploughValue)
                setDensityMaskedParallelogram(g_currentMission.terrainDetailId, x, z, widthX, widthZ, heightX, heightZ,
                    g_currentMission.terrainDetailAngleFirstChannel, g_currentMission.terrainDetailAngleNumChannels,
                    g_currentMission.terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, angle)

            end
        end
    end
end

function ssSCspec:getTireMaxLoad(wheel, inflationPressure)
    local tireLoadIndex = 981 * wheel.ssMaxDeformation + 73
    local inflationFac = 0.56 + 0.002 * inflationPressure

    -- in kN
    return 44 * math.exp(0.0288 * tireLoadIndex) * inflationFac / 100
end

function ssSCspec:getCLayers(wheel, width, length, radius, delta0, delta2)
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
    local CLayers = density/area

    return x0, z0, x1, z1, x2, z2, CLayers
end

function ssSCspec:update(dt)
    if not g_currentMission:getIsServer() 
        or not  g_seasons.soilCompaction.compactionEnabled then
        return 
    end

    if self.lastSpeedReal ~= 0 and not ssWeatherManager:isGroundFrozen() then
        self:applySC()
    end

end

function ssSCspec:draw()
end
