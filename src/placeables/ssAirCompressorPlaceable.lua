----------------------------------------------------------------------------------------------------
-- AIR COMPRESSOR
----------------------------------------------------------------------------------------------------
-- Purpose:
-- Authors:  Rahkiin
--
-- Note: bulk of the code is from the high pressure washer, which has similair features.
--
-- Copyright (c) Realismus Modding, 2018
----------------------------------------------------------------------------------------------------

ssAirCompressorPlaceable = {}

local ssAirCompressorPlaceable_mt = Class(ssAirCompressorPlaceable, Placeable)

InitObjectClass(ssAirCompressorPlaceable, "ssAirCompressorPlaceable")

function ssAirCompressorPlaceable:new(isServer, isClient, customMt)
    local mt = customMt
    if mt == nil then
        mt = ssAirCompressorPlaceable_mt
    end

    local self = Placeable:new(isServer, isClient, mt)
    registerObjectClassName(self, "ssAirCompressorPlaceable")

    self.messageShown = false

    return self
end

function ssAirCompressorPlaceable:load(xmlFilename, x,y,z, rx,ry,rz, initRandom)
    if not ssAirCompressorPlaceable:superClass().load(self, xmlFilename, x,y,z, rx,ry,rz, initRandom) then
        return false
    end

    local xmlFile = loadXMLFile("TempXML", xmlFilename)

    self.playerInRangeDistance = Utils.getNoNil(getXMLFloat(xmlFile, "placeable.airCompressor.playerInRangeDistance"), 3)
    self.actionRadius = Utils.getNoNil(getXMLFloat(xmlFile, "placeable.airCompressor.actionRadius#distance"), 15)
    self.airDistance = Utils.getNoNil(getXMLFloat(xmlFile, "placeable.airCompressor.airDistance"), 10)
    self.pricePerMilliSecond = Utils.getNoNil(getXMLFloat(xmlFile, "placeable.airCompressor.pricePerSecond"), 10) / 1000

    self.lanceNode = Utils.indexToObject(self.nodeId, getXMLString(xmlFile, "placeable.airCompressor.lance#index"))
    self.linkPosition = Utils.getVectorNFromString(Utils.getNoNil(getXMLString(xmlFile, "placeable.airCompressor.lance#position"), "0 0 0"), 3)
    self.linkRotation = Utils.getRadiansFromString(Utils.getNoNil(getXMLString(xmlFile, "placeable.airCompressor.lance#rotation"), "0 0 0"), 3)
    self.lanceNodeParent = getParent(self.lanceNode)
    self.lanceRaycastNode = Utils.indexToObject(self.nodeId, getXMLString(xmlFile, "placeable.airCompressor.lance#raycastNode"))


    delete(xmlFile)

    self.isPlayerInRange = false
    self.isTurnedOn = false
    self.activatable = ssAirCompressorPlaceableActivatable:new(self)
    self.lastInRangePosition = {0, 0, 0}
    self.isTurningOff = false
    self.turnOffTime = 0
    self.turnOffDuration = 500

    return true
end

function ssAirCompressorPlaceable:delete()
    self:setIsTurnedOn(false, nil, false)

    if self.isClient then
        -- Delete effects, samples
    end

    unregisterObjectClassName(self)
    g_currentMission:removeActivatableObject(self.activatable)
    ssAirCompressorPlaceable:superClass().delete(self)
end

function ssAirCompressorPlaceable:readStream(streamId, connection)
    ssAirCompressorPlaceable:superClass().readStream(self, streamId, connection)

    if connection:getIsServer() then
        local isTurnedOn = streamReadBool(streamId)
        if isTurnedOn then
            local player = readNetworkNodeObject(streamId)
            if player ~= nil then
                self:setIsTurnedOn(isTurnedOn, player, true)
            end
        end
    end
end

function ssAirCompressorPlaceable:writeStream(streamId, connection)
    ssAirCompressorPlaceable:superClass().writeStream(self, streamId, connection)

    if not connection:getIsServer() then
        streamWriteBool(streamId, self.isTurnedOn)
        if self.isTurnedOn then
            writeNetworkNodeObject(streamId, self.currentPlayer)
        end
    end
end

function ssAirCompressorPlaceable:activateHandtool(player)
    self:setIsTurnedOn(true, player, true)
end

function ssAirCompressorPlaceable:update(dt)
    ssAirCompressorPlaceable:superClass().update(self, dt)

    if self.currentPlayer ~= nil then
        local isPlayerInRange = self:getIsPlayerInRange(self.actionRadius, self.currentPlayer)

        if isPlayerInRange then
            self.lastInRangePosition = {getTranslation(self.currentPlayer.rootNode)}
        else
            -- Limit player movement
            local kx, _, kz = getWorldTranslation(self.nodeId)
            local px, py, pz = getWorldTranslation(self.currentPlayer.rootNode)
            local len = Utils.vector2Length(px - kx, pz - kz)

            local x,y,z = unpack(self.lastInRangePosition)
            x = kx + ((px - kx) / len) * (self.actionRadius - 0.00001 * dt)
            z = kz + ((pz - kz) / len) * (self.actionRadius - 0.00001 * dt)
            self.currentPlayer:moveToAbsoluteInternal(x, py, z)
            self.lastInRangePosition = {x, y, z}

            if not self.messageShown and self.currentPlayer == g_currentMission.player then
-- TODO: different text
                g_currentMission:showBlinkingWarning(g_i18n:getText("warning_hpwRangeRestriction"), 6000)
                self.messageShown = true
            end
        end
    end

    if self.isServer then
        if self.isTurnedOn and false then --and self.doWashing then
            self.foundVehicle = nil
-- self:cleanVehicle(self.currentPlayer.cameraNode, dt)

            if self.lanceRaycastNode ~= nil then
-- self:cleanVehicle(self.lanceRaycastNode, dt)
            end

            local price = self.pricePerSecond * (dt / 1000)
            g_currentMission.missionStats:updateStats("expenses", price)
            g_currentMission:addSharedMoney(-price, "vehicleRunningCost")
        end
    end

    -- if self.isTurningOff then
    --     if g_currentMission.time < self.turnOffTime then
    --         if self.sampleCompressor ~= nil then
    --             local pitch = Utils.lerp(self.compressorPitchMin, self.sampleCompressor.pitchOffset, Utils.clamp((self.turnOffTime - g_currentMission.time) / self.turnOffDuration, 0, 1))
    --             local volume = Utils.lerp(0, self.sampleCompressor.volume, Utils.clamp((self.turnOffTime - g_currentMission.time) / self.turnOffDuration, 0, 1))
    --             SoundUtil.setSamplePitch(self.sampleCompressor, pitch)
    --             SoundUtil.setSampleVolume(self.sampleCompressor, volume)
    --         end
    --     else
    --         self.isTurningOff = false
    --         if self.sampleCompressor ~= nil then
    --             SoundUtil.stop3DSample(self.sampleCompressor)
    --         end
    --     end
    -- end
end

-- TODO: rename
function ssAirCompressorPlaceable:cleanVehicle(node, dt)
    local x,y,z = getWorldTranslation(node)
    local dx, dy, dz = localDirectionToWorld(node, 0, 0, -1)
    local lastFoundVehicle = self.foundVehicle

    raycastAll(x, y, z, dx, dy, dz, "airRaycastCallback", self.airDistance, self, 32 + 64 + 128 + 256 + 4096 + 8194)

    if self.foundVehicle ~= nil and lastFoundVehicle ~= self.foundVehicle then
        -- self.foundVehicle:setDirtAmount(self.foundVehicle:getDirtAmount() - self.washMultiplier*dt/self.foundVehicle.washDuration)
        -- TODO: Do the actual tire air stuff, IF has ssTirePressure spec
    end
end

function ssAirCompressorPlaceable:updateTick(dt)
    ssAirCompressorPlaceable:superClass().updateTick(self, dt)

    local isPlayerInRange, player = self:getIsPlayerInRange(self.playerInRangeDistance)

    if isPlayerInRange then
        self.playerInRange = player
        self.isPlayerInRange = true
        g_currentMission:addActivatableObject(self.activatable)
    else
        self.playerInRange = nil
        self.isPlayerInRange = false
        g_currentMission:removeActivatableObject(self.activatable)
    end
end

function ssAirCompressorPlaceable:setIsWashing(doWashing, force, noEventSend)
--     HPWPlaceableStateEvent.sendEvent(self, doWashing, noEventSend)
--     if self.doWashing ~= doWashing then
--         if self.isClient then
--             if self.washerParticleSystems ~= nil then
--                 for _,ps in pairs(self.washerParticleSystems) do
--                     ParticleUtil.setEmittingState(ps, doWashing and self:getIsActiveForInput())
--                 end
--             end

--             if doWashing then
--                 EffectManager:setFillType(self.waterEffects, FillUtil.FILLTYPE_WATER)
--                 EffectManager:startEffects(self.waterEffects)
--                 if self.sampleWashing ~= nil and self.currentPlayer == g_currentMission.player  then
--                     if self:getIsActiveForSound() then
--                         SoundUtil.playSample(self.sampleWashing, 0, 0, 1)
--                     end
--                 end
--             else
--                 if force then
--                     EffectManager:resetEffects(self.waterEffects)
--                 else
--                     EffectManager:stopEffects(self.waterEffects)
--                 end
--                 if self.sampleWashing ~= nil then
--                     SoundUtil.stopSample(self.sampleWashing, true)
--                 end
--             end
--         end
--         self.doWashing = doWashing
--     end
end

function ssAirCompressorPlaceable:setIsTurnedOn(isTurnedOn, player, noEventSend)
    HPWPlaceableTurnOnEvent.sendEvent(self, isTurnedOn, player, noEventSend)

    if self.isTurnedOn ~= isTurnedOn then
        if isTurnedOn then
            self.isTurnedOn = isTurnedOn
            self.currentPlayer = player

            -- player stuff
            local tool = {}
            tool.node = self.lanceNode
            link(player.toolsRootNode, tool.node)
            setVisibility(tool.node, false)
            setTranslation(tool.node, unpack(self.linkPosition))
            setRotation(tool.node, unpack(self.linkRotation))
            tool.update = ssAirCompressorPlaceable.updateLance
            tool.updateTick = ssAirCompressorPlaceable.updateTickLance
            tool.delete = ssAirCompressorPlaceable.deleteLance
            tool.draw = ssAirCompressorPlaceable.drawLance
            tool.onActivate = ssAirCompressorPlaceable.activateLance
            tool.onDeactivate = ssAirCompressorPlaceable.deactivateLance
            tool.targets = self.targets
            tool.owner = self
            tool.static = false
            self.tool = tool
            self.currentPlayer:setTool(tool)
            self.currentPlayer.hasHPWLance = true

            if self.isClient then
                -- if self.sampleSwitch ~= nil and self:getIsActiveForSound() then
                --     SoundUtil.playSample(self.sampleSwitch, 1, 0, nil)
                -- end
                -- if self.sampleCompressor ~= nil then
                --     SoundUtil.setSamplePitch(self.sampleCompressor, self.sampleCompressor.pitchOffset)
                --     SoundUtil.setSampleVolume(self.sampleCompressor, self.sampleCompressor.volume)
                --     SoundUtil.play3DSample(self.sampleCompressor)
                -- end
                if self.isTurningOff then
                    self.isTurningOff = false
                end
                setVisibility(self.lanceNode, g_currentMission.player == player)
            end
        else
            self:onDeactivate()
        end
        if self.exhaustNode ~= nil then
            setVisibility(self.exhaustNode, isTurnedOn)
        end
    end
end

function ssAirCompressorPlaceable:onDeactivate()
    if self.isClient then
        if self.sampleSwitch ~= nil and self:getIsActiveForSound() then
            -- SoundUtil.playSample(self.sampleSwitch, 1, 0, nil)
        end
    end

    self.isTurnedOn = false
    setVisibility(self.lanceNode, true)
    self:setIsWashing(false, true, true)

    -- Remove tool from player
    if self.currentPlayer ~= nil then
        self.currentPlayer:setToolById(0, true)
        self.currentPlayer.hasHPWLance = false
    end

    if self.isClient then
        if self.sampleWashing ~= nil then
            -- SoundUtil.stopSample(self.sampleWashing, true)
        end

        self.isTurningOff = true
        self.turnOffTime = g_currentMission.time + self.turnOffDuration

        -- Reset lance node
        link(self.lanceNodeParent, self.lanceNode)
        setTranslation(self.lanceNode, 0,0,0)
        setRotation(self.lanceNode, 0,0,0)
    end

    self.currentPlayer = nil
end

function ssAirCompressorPlaceable:getIsActiveForInput()
    if self.isTurnedOn and self.currentPlayer == g_currentMission.player and not g_gui:getIsGuiVisible() then
        return true
    end
    return false
end

function ssAirCompressorPlaceable:getIsActiveForSound()
    return self:getIsActiveForInput()
end

function ssAirCompressorPlaceable:canBeSold()
    local warning = g_i18n:getText("shop_messageReturnVehicleInUse")

    if self.currentPlayer ~= nil then
        return false, warning
    end

    return true, nil
end

-- Simple raycast to find the vehicle pointed at by the player
function ssAirCompressorPlaceable:washRaycastCallback(hitActorId, x, y, z, distance, nx, ny, nz, subShapeIndex, hitShapeId)
    local vehicle = g_currentMission.nodeToVehicle[hitActorId]

    if hitActorId ~= hitShapeId then
        -- object is a compoundChild. Try to find the compound
        local parentId = hitShapeId
        while parentId ~= 0 do
            if g_currentMission.nodeToVehicle[parentId] ~= nil then
                -- found valid compound
                vehicle = g_currentMission.nodeToVehicle[parentId]
                break
            end
            parentId = getParent(parentId)
        end
    end

    if vehicle ~= nil and vehicle.getInflationPressure ~= nil and vehicle.setInflationPressure ~= nil then
        self.foundCoords = {x, y, z}
        self.foundVehicle = vehicle

        return false
    end

    return true
end

registerPlaceableType("ssAirCompressor", ssAirCompressorPlaceable)

----------------------
-- Lance player tool
----------------------

function ssAirCompressorPlaceable.activateLance(tool)
    setVisibility(tool.node, true)
end

function ssAirCompressorPlaceable.deactivateLance(tool)
    tool.owner:setIsTurnedOn(false, nil)
end

function ssAirCompressorPlaceable.deleteLance(tool)
    tool.owner:setIsTurnedOn(false, nil)
end

function ssAirCompressorPlaceable.drawLance(tool)
    if tool.owner.currentPlayer == g_currentMission.player then
        g_currentMission:addHelpButtonText(g_i18n:getText("input_ACTIVATE_HANDTOOL"), InputBinding.ACTIVATE_HANDTOOL)
-- TODO: add second activation: add air, remove add
    end
end

function ssAirCompressorPlaceable.updateLance(tool, dt, allowInput)
    if allowInput then
        tool.owner:setIsWashing(InputBinding.isPressed(InputBinding.ACTIVATE_HANDTOOL), false, false)
    end
end

function ssAirCompressorPlaceable.updateTickLance(tool, dt, allowInput)
end

----------------------
-- Activatable object
----------------------

ssAirCompressorPlaceableActivatable = {}
local ssAirCompressorPlaceableActivatable_mt = Class(ssAirCompressorPlaceableActivatable)

function ssAirCompressorPlaceableActivatable:new(airCompressor)
    local self = {}
    setmetatable(self, ssAirCompressorPlaceableActivatable_mt)

    self.airCompressor = airCompressor
    self.activateText = "unknown"

    return self
end

function ssAirCompressorPlaceableActivatable:getIsActivatable()
    if not self.airCompressor.isPlayerInRange then
        return false
    end

    if self.airCompressor.playerInRange ~= g_currentMission.player then
        return false
    end

    if not self.airCompressor.playerInRange.isControlled then
        return false
    end

    if self.airCompressor.isTurnedOn and self.airCompressor.currentPlayer ~= g_currentMission.player then
        return false
    end

    if not self.airCompressor.isTurnedOn and g_currentMission.player.hasHPWLance == true then
        return false
    end

    if self.airCompressor.isDeleted then
        return false
    end

    self:updateActivateText()
    return true
end

function ssAirCompressorPlaceableActivatable:onActivateObject()
    self.airCompressor:setIsTurnedOn(not self.airCompressor.isTurnedOn, g_currentMission.player)
    self:updateActivateText()
    g_currentMission:addActivatableObject(self)
end

function ssAirCompressorPlaceableActivatable:drawActivate()
end

function ssAirCompressorPlaceableActivatable:updateActivateText()
    if self.airCompressor.isTurnedOn then
        self.activateText = string.format(g_i18n:getText("action_turnOffOBJECT"), g_i18n:getText("typeDesc_highPressureWasher"))
    else
        self.activateText = string.format(g_i18n:getText("action_turnOnOBJECT"), g_i18n:getText("typeDesc_highPressureWasher"))
    end
end
