----------------------------------------------------------------------------------------------------
-- SNOW TRACKS SPECIALIZATION
----------------------------------------------------------------------------------------------------
-- Author:  reallogger, Wopster
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssSnowTracks = {}

ssSnowTracks.SNOW_RGBA = { 0.98, 0.98, 0.98, 1 }
ssSnowTracks.KEEP_SNOW_ON_WHEELS_THRESHOLD = 750 -- ms
ssSnowTracks.SNOW_FRICTION = GS_IS_CONSOLE_VERSION and 0.4 or 0.3

ssSnowTracks.FRICTION_TIRETYPE_SETTINGS = {
    ["chains"] = 1.0,
    ["crawler"] = 0.5,
    ["studded"] = 0.7
}

local PARAM_GREATER = "greater"
local PARAM_EQUAL = "equal"

function ssSnowTracks:prerequisitesPresent(specializations)
    return true
end

function ssSnowTracks:load(savegame)
    self.updateWheelTireFriction = Utils.appendedFunction(self.updateWheelTireFriction, ssSnowTracks.vehicleUpdateWheelTireFriction)
end

function ssSnowTracks:delete()
end

function ssSnowTracks:mouseEvent(...)
end

function ssSnowTracks:keyEvent(...)
end

local function applyWheelSnowTracks(self)
    local snowDepth = ssSnow.appliedSnowDepth
    local targetSnowDepth = math.min(0.48, snowDepth) -- Target snow depth in meters. Never higher than 0.48
    local snowLayers = math.modf(targetSnowDepth / ssSnow.LAYER_HEIGHT)

    -- partly from Crop destruction mod
    for _, wheel in pairs(self.wheels) do
        local newSnowDepth

        if wheel.hasGroundContact then
            local width = 0.5 * wheel.width
            local length = math.min(0.2, 0.35 * wheel.width)

            local radius = wheel.radius
            local wheelRot = getWheelShapeAxleSpeed(wheel.node, wheel.wheelShape)
            local wheelRotDir

            if wheelRot ~= 0 then
                wheelRotDir = wheelRot / math.abs(wheelRot)
            else
                wheelRotDir = 1
            end

            local _, _, _, _, _, _, underTireSnowLayers = ssSnowTracks:getSnowLayers(wheel, width, length, length)
            local x0, z0, x1, z1, x2, z2, fwdTireSnowLayers = ssSnowTracks:getSnowLayers(wheel, width, -0.6 * radius * wheelRotDir, 1.2 * radius * wheelRotDir)

            -- If the wheel is in snow, update its traction
            local oldInSnow = wheel.inSnow
            wheel.inSnow = isNumeric(underTireSnowLayers) and underTireSnowLayers >= 1

            if oldInSnow ~= wheel.inSnow then
                self:updateWheelTireFriction(wheel)
            end

            if wheel.inSnow then
                wheel.keepSnowTracksLimit = g_currentMission.time + ssSnowTracks.KEEP_SNOW_ON_WHEELS_THRESHOLD

                if self.isEntered and g_currentMission.surfaceNameToSurfaceSound ~= nil then
                    local sound = g_currentMission.surfaceNameToSurfaceSound["snow"]

                    if sound ~= nil then
                        sound.impactCount = sound.impactCount + 1
                    end
                end
            elseif oldInSnow and not wheel.inSnow then
                local circumference = math.pi * (2 * math.pi * radius)
                local maxTrackLength = circumference * (1 + g_currentMission.environment.groundWetness)
                local speedFactor = math.min(self:getLastSpeed(), 20) / 20

                maxTrackLength = maxTrackLength * (2 - speedFactor)
                wheel.keepSnowTracksLimit = g_currentMission.time + ssSnowTracks.KEEP_SNOW_ON_WHEELS_THRESHOLD
                wheel.dirtAmount = math.max(wheel.dirtAmount - self.lastMovedDistance / maxTrackLength, 0)
            end

            if wheel.inSnow or (wheel.keepSnowTracksLimit ~= nil and wheel.keepSnowTracksLimit < g_currentMission.time) then
                if wheel.contact == Vehicle.WHEEL_GROUND_CONTACT or wheel.contact == Vehicle.WHEEL_GROUND_HEIGHT_CONTACT then
                    wheel.contact = Vehicle.WHEEL_NO_CONTACT -- avoid ground contact for color switches
                end

                wheel.lastColor = { unpack(ssSnowTracks.SNOW_RGBA) }
            end

            local reduceSnow = snowLayers == fwdTireSnowLayers
            local fwdTireSnowDepth = fwdTireSnowLayers / ssSnow.LAYER_HEIGHT / 100 -- fwdTireSnowDepth in m

            if fwdTireSnowLayers > 1 and reduceSnow then
                local sinkage = 0.7 * targetSnowDepth
                local sinkageLayers = math.min(math.modf(sinkage / ssSnow.LAYER_HEIGHT), fwdTireSnowLayers)

                ssSnow:removeSnow(x0, z0, x1, z1, x2, z2, sinkageLayers)

                if fwdTireSnowDepth <= radius then
                    setLinearDamping(wheel.node, 0.35)
                elseif fwdTireSnowDepth > radius and fwdTireSnowDepth <= 2 * radius then
                    setLinearDamping(wheel.node, 0.55)
                elseif fwdTireSnowDepth > 2 * radius then
                    setLinearDamping(wheel.node, 0.95)
                end
            elseif fwdTireSnowDepth > 2 * radius then
                setLinearDamping(wheel.node, 0.95)
            else
                setLinearDamping(wheel.node, 0)
            end
        end
    end
end

local function resetWheelSnowTracks(self)
    for _, wheel in pairs(self.wheels) do
        if wheel.inSnow or (wheel.keepSnowTracksLimit ~= nil and wheel.keepSnowTracksLimit < g_currentMission.time) then
            if wheel.contact == Vehicle.WHEEL_GROUND_CONTACT or wheel.contact == Vehicle.WHEEL_GROUND_HEIGHT_CONTACT then
                wheel.contact = Vehicle.WHEEL_NO_CONTACT -- avoid ground contact for color switches
            end

            wheel.lastColor = { unpack(ssSnowTracks.SNOW_RGBA) }
        end

        if wheel.inSnow then
            wheel.inSnow = false

            self:updateWheelTireFriction(wheel)
            setLinearDamping(wheel.node, 0)
        end
    end
end

function ssSnowTracks:getSnowLayers(wheel, width, delta0, delta2)
    local x0, y0, z0
    local x1, y1, z1
    local x2, y2, z2

    if wheel.repr == wheel.driveNode then
        x0, y0, z0 = localToWorld(wheel.node, wheel.positionX + width, wheel.positionY, wheel.positionZ - delta0)
        x1, y1, z1 = localToWorld(wheel.node, wheel.positionX - width, wheel.positionY, wheel.positionZ - delta0)
        x2, y2, z2 = localToWorld(wheel.node, wheel.positionX + width, wheel.positionY, wheel.positionZ + delta2)
    else
        local x, _, z = localToLocal(wheel.driveNode, wheel.repr, 0, 0, 0)
        x0, y0, z0 = localToWorld(wheel.repr, x + width, 0, z - delta0)
        x1, y1, z1 = localToWorld(wheel.repr, x - width, 0, z - delta0)
        x2, y2, z2 = localToWorld(wheel.repr, x + width, 0, z + delta2)
    end

    local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, x0, z0, x1, z1, x2, z2)

    setDensityMaskParams(g_currentMission.terrainDetailHeightId, PARAM_EQUAL, TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_SNOW]["index"])
    setDensityCompareParams(g_currentMission.terrainDetailHeightId, PARAM_GREATER, 0)
    local density, area, _ = getDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 5, 6, g_currentMission.terrainDetailHeightId, 0, 5, 0)
    local snowLayers = density / area
    setDensityMaskParams(g_currentMission.terrainDetailHeightId, PARAM_GREATER, -1)
    setDensityCompareParams(g_currentMission.terrainDetailHeightId, PARAM_GREATER, -1)

    return x0, z0, x1, z1, x2, z2, snowLayers
end

function ssSnowTracks:update(dt)
    if not g_currentMission:getIsServer()
            or not g_seasons.vehicle.snowTracksEnabled
            or not g_seasons.snow.mode == g_seasons.snow.MODE_ONE_LAYER then
        return
    end

    local surfaceSound = g_currentMission.surfaceNameToSurfaceSound["snow"]

    if surfaceSound ~= nil then
        surfaceSound.impactCount = 0
    end

    if self.lastSpeedReal ~= 0 and ssSnow.appliedSnowDepth > ssSnow.LAYER_HEIGHT then
        applyWheelSnowTracks(self)
    elseif self.lastSpeedReal ~= 0 and ssSnow.appliedSnowDepth <= ssSnow.LAYER_HEIGHT then
        resetWheelSnowTracks(self)
    end

    if self.isEntered then
        local lastSpeed = self:getLastSpeed()
        ssEnvironment:playSurfaceSound(dt, surfaceSound, #self.wheels, lastSpeed, math.abs(lastSpeed) < 1)
    end
end

function ssSnowTracks:draw()
end

function ssSnowTracks:vehicleUpdateWheelTireFriction(wheel)
    local function setFriction(factor)
        setWheelShapeTireFriction(wheel.node, wheel.wheelShape, wheel.maxLongStiffness, wheel.maxLatStiffness,
            wheel.maxLatStiffnessLoad, wheel.frictionScale * wheel.tireGroundFrictionCoeff * factor)
    end

    if self.isServer and self.isAddedToPhysics then
        if wheel.inSnow then
            local friction = ssSnowTracks.FRICTION_TIRETYPE_SETTINGS[WheelsUtil.tireTypes[wheel.tireType].name]

            if friction ~= nil then
                setFriction(friction)
            else
                setFriction(ssSnowTracks.SNOW_FRICTION)
            end
        end
    end
end
