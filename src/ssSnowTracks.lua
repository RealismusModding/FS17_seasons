---------------------------------------------------------------------------------------------------------
-- SNOW TRACKS SPECIALIZATION
---------------------------------------------------------------------------------------------------------
-- Authors:  reallogger
--

ssSnowTracks = {}

function ssSnowTracks:prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Washable, specializations)
end

function ssSnowTracks:load(savegame)
end

function ssSnowTracks:delete()
end

function ssSnowTracks:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssSnowTracks:keyEvent(unicode, sym, modifier, isDown)
end

local function tracks(self,dt)
    local snowDepth = ssWeatherManager:getSnowHeight()
    local targetSnowDepth = math.min(0.48, snowDepth) -- Target snow depth in meters. Never higher than 0.4
    local snowLayers = math.modf(targetSnowDepth/ ssSnow.LAYER_HEIGHT)

    self.inSnow = true

    -- partly from Crop destruction mod
    for _, wheel in pairs(self.wheels) do

        local width = 0.5 * wheel.width;
        local length = math.min(0.2, 0.35 * wheel.width);
        local radius = wheel.radius

        local x0,y0,z0;
        local x1,y1,z1;
        local x2,y2,z2;

        --local contactPressure = wheel.deltaY / (width * radius / 4)*30 -- as an estimate
        local sinkage = 0.7 * targetSnowDepth

        wheel.tireGroundFrictionCoeff = 0.1
        
        local wheelRot = getWheelShapeAxleSpeed(wheel.node,wheel.wheelShape)
        local wheelRotDir

        if wheelRot ~= 0 then
            wheelRotDir = wheelRot/math.abs(wheelRot)
        else
            wheelRotDir = 1
        end

        if wheel.repr == wheel.driveNode then
            x0,y0,z0 = localToWorld(wheel.node, wheel.positionX + width, wheel.positionY, wheel.positionZ + 0.6 * radius * wheelRotDir);
            x1,y1,z1 = localToWorld(wheel.node, wheel.positionX - width, wheel.positionY, wheel.positionZ + 0.6 * radius * wheelRotDir);
            x2,y2,z2 = localToWorld(wheel.node, wheel.positionX + width, wheel.positionY, wheel.positionZ + 1.2 * radius * wheelRotDir);
        else
            local x,_,z = localToLocal(wheel.driveNode, wheel.repr, 0,0,0);
            x0,y0,z0 = localToWorld(wheel.repr, x + width, 0, z + 0.6 * radius * wheelRotDir);
            x1,y1,z1 = localToWorld(wheel.repr, x - width, 0, z + 0.6 * radius * wheelRotDir);
            x2,y2,z2 = localToWorld(wheel.repr, x + width, 0, z + 1.2 * radius * wheelRotDir);
        end

        local x,z, widthX,widthZ, heightX,heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, x0,z0, x1,z1, x2,z2)


        setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_SNOW]["index"])
        setDensityCompareParams(g_currentMission.terrainDetailHeightId, "greater", 0)
        local density, area, _ = getDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 5, 6, g_currentMission.terrainDetailHeightId, 0, 5, 0)
        local underTireSnowLayers = density / area
        setDensityMaskParams(g_currentMission.terrainDetailHeightId, "greater", -1)
        --log(underTireSnowLayers)        
        local underTireSnowDepth = underTireSnowLayers / ssSnow.LAYER_HEIGHT

        if (targetSnowDepth - sinkage) > ssSnow.LAYER_HEIGHT and snowLayers == underTireSnowLayers then
            newSnowDepth = math.modf(sinkage / ssSnow.LAYER_HEIGHT)
            ssSnow:removeSnow(x0,z0, x1,z1, x2,z2, newSnowDepth)

            local arcLength = sinkage
            local snowForce
		    
            if underTireSnowDepth <= radius then
			    local alpha = math.asin(sinkage / radius)
                log('alpha1 = ', alpha)
			    arcLength = alpha * radius
                snowForce = 15 * (200 * arcLength * wheel.width)^1.3

            elseif underTireSnowDepth > radius and underTireSnowDepth <= 2 * radius then
			    local alpha = math.sin((radius - sinkage) / radius)
                log('alpha2 = ', alpha)
			    arcLength = alpha * radius + math.pi/2
                snowForce = 15 * (200 * arcLength * wheel.width)^1.3 + 10000 * (sinkage - radius)
                
            elseif underTireSnowDepth > 2 * radius then
			    arcLength = math.pi * radius
                log('alpha3 = ')
                snowForce = 15 * (200 * arcLength * wheel.width)^1.3 + 15000 * (sinkage - radius)
            end

            --log('sizeWidth = ',sizeWidth, ' | sinkage = ', sinkage,' | radius = ',radius,' | arcLength = ',arcLength,' | snowForce = ',snowForce)
            --setLinearDamping(wheel.node,snowForce/7.5)
        elseif underTireSnowLayers == 0 then
            --setLinearDamping(wheel.node,snowForce/7.5)
        end

     end
end

function ssSnowTracks:update(dt)
    local snowDepth = ssWeatherManager:getSnowHeight()

    if self.lastSpeedReal ~= 0 and snowDepth > ssSnow.LAYER_HEIGHT then
        tracks(self,dt)
    else
        for _, wheel in pairs(self.wheels) do
            setLinearDamping(wheel.node,0)
        end
    end
end

function ssSnowTracks:updateTick(dt)
end

function ssSnowTracks:draw()
end

