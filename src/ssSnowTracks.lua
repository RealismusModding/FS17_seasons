---------------------------------------------------------------------------------------------------------
-- SNOW TRACKS SPECIALIZATION
---------------------------------------------------------------------------------------------------------
-- Author:  reallogger
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

local function applyTracks(self, dt)
    local snowDepth = ssSnow.appliedSnowDepth
    local targetSnowDepth = math.min(0.48, snowDepth) -- Target snow depth in meters. Never higher than 0.48
    local snowLayers = math.modf(targetSnowDepth / ssSnow.LAYER_HEIGHT)

    -- partly from Crop destruction mod
    for _, wheel in pairs(self.wheels) do

        local newSnowDepth

        if wheel.hasGroundContact then

            local x0,y0,z0
            local x1,y1,z1
            local x2,y2,z2

            local width = 0.5 * wheel.width;
            local length = math.min(0.2, 0.35 * wheel.width);
            local radius = wheel.radius
            local underTireSnowLayers = 0

            local sinkage = 0.7 * targetSnowDepth

            local wheelRot = getWheelShapeAxleSpeed(wheel.node,wheel.wheelShape)
            local wheelRotDir

            if wheelRot ~= 0 then
                wheelRotDir = wheelRot / math.abs(wheelRot)
            else
                wheelRotDir = 1
            end

            local underTireSnowLayers = 0
            local fwdTireSnowLayers = 0
            x0,z0, x1,z1, x2,z2,underTireSnowLayers = ssSnowTracks:getSnowLayers(wheel,width,length,radius,length,length)

            x0,z0, x1,z1, x2,z2,fwdTireSnowLayers = ssSnowTracks:getSnowLayers(wheel,width,length,radius,-0.6 * radius * wheelRotDir,1.2 * radius * wheelRotDir)
            local fwdTireSnowDepth = fwdTireSnowLayers / ssSnow.LAYER_HEIGHT / 100  --fwdTireSnowDepth in m

            if underTireSnowLayers >= 1 then
                wheel.inSnow = true
            end

            local reduceSnow = false 
            if snowLayers == fwdTireSnowLayers then --and (snowLayers + 3) > fwdTireSnowLayers and wheel.inSnow then
                reduceSnow = true
            end

            if (targetSnowDepth - sinkage) > ssSnow.LAYER_HEIGHT and reduceSnow then
                --local x,_,_ = getWheelShapeContactPoint(wheel.node, wheel.wheelShape)
                --local distanceLayers = math.max(math.modf(x* ssSnow.LAYER_HEIGHT,2))
                --print(distanceLayers)
                
                --if distanceLayers > underTireSnowLayers then
                sinkageLayers = math.min(math.modf(sinkage / ssSnow.LAYER_HEIGHT),fwdTireSnowLayers)
                ssSnow:removeSnow(x0,z0, x1,z1, x2,z2, sinkageLayers)
                --end

                

                if fwdTireSnowDepth <= radius then
		    	    setLinearDamping(wheel.node,0.3)

                elseif fwdTireSnowDepth > radius and fwdTireSnowDepth <= 2 * radius then
	    		    setLinearDamping(wheel.node,0.5)

                elseif fwdTireSnowDepth > 2 * radius then
	    		    setLinearDamping(wheel.node,0.95)
                    
                end

                --log('sizeWidth = ',sizeWidth, ' | sinkage = ', sinkage,' | radius = ',radius,' | arcLength = ',arcLength,' | snowForce = ',snowForce)

            elseif fwdTireSnowDepth > 2 * radius then
                setLinearDamping(wheel.node,0.95)

            else
                setLinearDamping(wheel.node,0.2)
            
            end
            
            --if self.lastSpeedReal*60*60 < 4 and wheel.rotSpeed > 1 and wheel.driveMode == 1 then 
            --    local underTireSnowLayers = 0
            --    local behindTireSnowLayers = 0
                
            --    x0,z0, x1,z1, x2,z2,underTireSnowLayers = ssSnowTracks:getSnowLayers(wheel,width,length,radius,length,length)
            --    newSnowDepth = math.max(underTireSnowLayers - 1,0)
            --    ssSnow:removeSnow(x0,z0, x1,z1, x2,z2, newSnowDepth)

            --    x0,z0, x1,z1, x2,z2,behindTireSnowLayers = ssSnowTracks:getSnowLayers(wheel,width*2,length,radius,0.6 * radius * wheelRotDir,-1.2 * radius * wheelRotDir)
            --    newSnowDepth = math.min(behindTireSnowLayers + 10 ,0)    
            --    ssSnow:addSnow(x0,z0, x1,z1, x2,z2, newSnowDepth)

            --end

        end
    end
end

function ssSnowTracks:getSnowLayers(wheel,width,length,radius,delta0,delta2)

    local x0,y0,z0
    local x1,y1,z1
    local x2,y2,z2

    if wheel.repr == wheel.driveNode then
        x0,y0,z0 = localToWorld(wheel.node, wheel.positionX + width, wheel.positionY, wheel.positionZ - delta0)
        x1,y1,z1 = localToWorld(wheel.node, wheel.positionX - width, wheel.positionY, wheel.positionZ - delta0)
        x2,y2,z2 = localToWorld(wheel.node, wheel.positionX + width, wheel.positionY, wheel.positionZ + delta2)
    else
        local x,_,z = localToLocal(wheel.driveNode, wheel.repr, 0,0,0)
        x0,y0,z0 = localToWorld(wheel.repr, x + width, 0, z - delta0)
        x1,y1,z1 = localToWorld(wheel.repr, x - width, 0, z - delta0)
        x2,y2,z2 = localToWorld(wheel.repr, x + width, 0, z + delta2)
    end

    local x,z, widthX,widthZ, heightX,heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, x0,z0, x1,z1, x2,z2)

    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_SNOW]["index"])
    setDensityCompareParams(g_currentMission.terrainDetailHeightId, "greater", 0)
    local density, area, _ = getDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 5, 6, g_currentMission.terrainDetailHeightId, 0, 5, 0)
    local snowLayers = density / area
    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "greater", -1)

    return x0,z0, x1,z1, x2,z2,snowLayers

end

function ssSnowTracks:update(dt)
    if not g_currentMission:getIsServer() then return end
    -- if not ssVehicle.snowTracksEnabled then return end

    if self.lastSpeedReal ~= 0 and ssSnow.appliedSnowDepth > ssSnow.LAYER_HEIGHT then
        applyTracks(self, dt)
    elseif self.lastSpeedReal ~= 0 and ssSnow.appliedSnowDepth == ssSnow.LAYER_HEIGHT then
        for _, wheel in pairs(self.wheels) do
           wheel.inSnow = false
           setLinearDamping(wheel.node, 0)
        end
    else 
        for _, wheel in pairs(self.wheels) do
            wheel.inSnow = false
            setLinearDamping(wheel.node, 0)
        end
    end
end

function ssSnowTracks:updateTick(dt)
end

function ssSnowTracks:draw()
end

