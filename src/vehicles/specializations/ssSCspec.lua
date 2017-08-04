----------------------------------------------------------------------------------------------------
-- SC SPECIALIZATION
----------------------------------------------------------------------------------------------------
-- Author:  reallogger
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssSCspec = {}

function ssSCspec:prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Washable, specializations)
end

function ssSCspec:load(savegame)
end

function ssSCspec:delete()
end

function ssSCspec:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssSCspec:keyEvent(unicode, sym, modifier, isDown)
end

local function applySC(self)

    local soilWater = g_currentMission.environment.groundWetness

    for _, wheel in pairs(self.wheels) do

        if wheel.hasGroundContact and not wheel.mrNotAWheel then
            local x0, y0, z0
            local x1, y1, z1
            local x2, y2, z2

            local width = wheel.width;
            local length = math.max(0.1, 0.35 * wheel.radius);
            local contactArea = length * width

            -- TODO: No need to store groundPressure, but for display
            wheel.load = getWheelShapeContactForce(wheel.node, wheel.wheelShape)
            local oldPressure = wheel.groundPressure
            if oldPressure == nil then oldPressure = 10 end
            if wheel.load == nil then wheel.load = 0 end

            wheel.groundPressure = mathRound(oldPressure * 999 / 1000 +  wheel.load / contactArea / 1000, 2)

            -- soil saturation index 0.2
            -- c index Cp 0.7
            -- reference pressure 100 kPa
            -- reference saturation Sk 50%
            soilBulkDensityRef = 0.2 * (soilWater - 0.5) + 0.7 * math.log10(wheel.groundPressure / 100)
            wheel.soilBulkDensity = mathRound(soilBulkDensityRef, 2)

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
            --_, _, _, _, _, _, fwdLayers = ssSCspec:getCLayers(wheel, width, length, wheel.radius, wheel.radius * wheelRotDir, 2 * wheel.radius * wheelRotDir)
            x0, z0, x1, z1, x2, z2, fwdLayers = ssSCspec:getCLayers(wheel, width, length, wheel.radius, wheel.radius * wheelRotDir * -1, 2 * wheel.radius * wheelRotDir)
            local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, x0, z0, x1, z1, x2, z2)
            ssDebug:drawDensityParallelogram(x, z, widthX, widthZ, heightX, heightZ, 0.25, 255, 255, 0)

            x0, z0, x1, z1, x2, z2, underLayers = ssSCspec:getCLayers(wheel, width, length, wheel.radius, length, length)
            local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, x0, z0, x1, z1, x2, z2)
            ssDebug:drawDensityParallelogram(x, z, widthX, widthZ, heightX, heightZ, 0.25, 255, 0, 0)

            wheel.underTireCLayers = mathRound(underLayers,0)
            wheel.fwdTireCLayers = mathRound(fwdLayers,0)

            -- TODO: comments to be added
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

        end
    end
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
    
    if not g_currentMission:getIsServer() then 
        return 
    end
    --    or not g_seasons.vehicle.ssSCEnabled -- TODO: Make toggle

    if self.lastSpeedReal ~= 0 and not ssWeatherManager:isGroundFrozen() then
        applySC(self)
    end
end

function ssSCspec:updateTick(dt)
end

function ssSCspec:draw()
end
