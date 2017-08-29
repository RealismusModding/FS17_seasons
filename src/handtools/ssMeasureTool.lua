ssMeasureTool = {}
local ssMeasureTool_mt = Class(ssMeasureTool, HandTool)

-- InitStaticObjectClass(ssMeasureTool, "ssMeasureTool", ObjectIds.OBJECT_CHAINSAW)

ssMeasureTool.MEASURE_TIME = 1500 -- ms
ssMeasureTool.MEASURE_TIME_VAR = 300
ssMeasureTool.MEASURE_PULSE = 400
ssMeasureTool.MEASURE_TIMEOUT = 1000 --3000
ssMeasureTool.MEASURE_DISTANCE = 10

ssMeasureTool.BLINKING_MESSAGE_DURATION = 2000

function ssMeasureTool:new(isServer, isClient, customMt)
    local mt = customMt
    if mt == nil then
        mt = ssMeasureTool_mt
    end

    local self = HandTool:new(isServer, isClient, mt)
    return self
end

function ssMeasureTool:load(xmlFilename, player)
    if not ssMeasureTool:superClass().load(self, xmlFilename, player) then
        return false
    end

    local xmlFile = loadXMLFile("TempXML", xmlFilename)

    self.objectNode = getChildAt(self.rootNode, 0)
    self.pricePerMilliSecond = Utils.getNoNil(getXMLFloat(xmlFile, "handTool.measureTool.pricePerSecond"), 50) / 1000

    if self.isClient then
        -- self.handNode = Utils.getNoNil(Utils.indexToObject(self.rootNode, getXMLString(xmlFile, "handTool.chainsaw.handNode#index")), self.rootNode)
        -- self.handNodeRotation = Utils.getRadiansFromString(Utils.getNoNil(getXMLString(xmlFile, "handTool.chainsaw.handNode#rotation"), "0 0 0"), 3)
    end

    self.currentHandNode = nil

    delete(xmlFile)

    return true
end

function ssMeasureTool:delete()
    ssMeasureTool:superClass().delete(self)
end

function ssMeasureTool:update(dt, allowInput)
    ssMeasureTool:superClass().update(self, dt, allowInput)

    if self.isServer then
        local price = self.pricePerMilliSecond * (dt / 1000)

        g_currentMission.missionStats:updateStats("expenses", price)
        g_currentMission:addSharedMoney(-price, "vehicleRunningCost")
    end

    if allowInput then
        if InputBinding.isPressed(InputBinding.ACTIVATE_HANDTOOL) and self.measuringTimeoutStart == nil then
            if self.measuringStart == nil then
                self.measuringStart = g_currentMission.time
                self.measureDuration = math.random(ssMeasureTool.MEASURE_TIME - ssMeasureTool.MEASURE_TIME_VAR, ssMeasureTool.MEASURE_TIME + ssMeasureTool.MEASURE_TIME_VAR)
            end
        else
            self.measuringStart = nil
        end

        -- Timers for scanning and timeout
        if self.measuringStart ~= nil and g_currentMission.time - self.measuringStart >= self.measureDuration then
            self.measuringStart = nil
            self.measuringTimeoutStart = g_currentMission.time

            self:executeMeasure()
        elseif self.measuringTimeoutStart ~= nil and g_currentMission.time - self.measuringTimeoutStart >= ssMeasureTool.MEASURE_TIMEOUT then
            self.measuringTimeoutStart = nil
        end
    end
end

function ssMeasureTool:updateTick(dt, allowInput)
    ssMeasureTool:superClass().updateTick(self, dt, allowInput)
end

function ssMeasureTool:draw()
    ssMeasureTool:superClass().draw(self)

    if self.player:getIsInputAllowed() then
        g_currentMission:addHelpButtonText(g_i18n:getText("input_ACTIVATE_HANDTOOL"), InputBinding.ACTIVATE_HANDTOOL)

        -- Draw pointer, which is also a measure indicator
        local scale = 0.3
        if self.measuringStart ~= nil then
            local timeLapsed = g_currentMission.time - self.measuringStart
            local pulse = math.abs(math.sin(timeLapsed / ssMeasureTool.MEASURE_PULSE * math.pi))

            scale = pulse * 0.6 + 0.1
        end

        self.player.pickedUpObjectOverlay:setDimension(self.player.pickedUpObjectWidth * scale, self.player.pickedUpObjectHeight * scale)
        self.player.pickedUpObjectOverlay:setUVs(self.player.pickedUpObjectAimingUVs)
        self.player.pickedUpObjectOverlay:render()
    end

    if self.blinkingMessage then
        g_currentMission:showBlinkingWarning(self.blinkingMessage)

        if self.blinkingMessageUntil > g_currentMission.time then
            self.blinkingMessage = nil
        end
    end
end

function ssMeasureTool:setHandNode(handNode)
    ssMeasureTool:superClass().setHandNode(self, handNode)

    if self.currentHandNode ~= handNode then
        if g_currentMission.player ~= self.player then
            link(handNode, self.rootNode)
            self.currentHandNode = handNode

            local x,y,z = getWorldTranslation(self.handNode)
            x,y,z = worldToLocal(getParent(self.rootNode), x,y,z)

            local a,b,c = getTranslation(self.rootNode)

            setTranslation(self.rootNode, a - x, b - y, c - z)
        end
    end
end

function ssMeasureTool:onActivate(allowInput)
    ssMeasureTool:superClass().onActivate(self)
end

function ssMeasureTool:onDeactivate(allowInput)
    ssMeasureTool:superClass().onDeactivate(self)

    self.player.walkingIsLocked = false
end

function ssMeasureTool:executeMeasure()
    -- Raycast from the player
    local x, y, z = localToWorld(self.player.cameraNode, 0, 0, 0.5)
    local dx, dy, dz = localDirectionToWorld(self.player.cameraNode, 0, 0, -1)

    raycastClosest(x, y, z, dx, dy, dz, "raycastCallback", ssMeasureTool.MEASURE_DISTANCE + 1.0, self)
end

function ssMeasureTool:raycastCallback(hitObjectId, x, y, z, distance)
    log("callback", hitObjectId, x, y, z, distance)

    -- Too close or too far away
    if distance < 0.5 or distance > ssMeasureTool.MEASURE_DISTANCE then
        self:showFailed()

    -- We did only hit the terrain
    elseif hitObjectId == g_currentMission.terrainRootNode then
        self:showTerrainInfo(x, y, z)

    -- Some other object
    else
        local type = getRigidBodyType(hitObjectId)

        -- Skip vehicles
        if type == "Dynamic" and g_currentMission.nodeToVehicle[hitObjectId] ~= nil then
            self:showNoInfo()
        else -- Any object, either static or dynamic
            local object = g_currentMission:getNodeObject(hitObjectId)
            print_r(object)

            if object then
                if object:isa(Bale) then
                    self:showBaleInfo(object)
                elseif object:isa(FillablePallet) then
                    self:showFillablePallet(object)
                end
            else
                local tree = self:findTree(hitObjectId)

                if tree then
                    self:showPlantedTreeInfo(tree)
                elseif getSplitType(hitObjectId) ~= 0 then
                    self:showStaticTreeInfo({type = getSplitType(hitObjectId)})
                else
                    self:showNoInfo()
                end
            end
        end
    end

    return true
end

function ssMeasureTool:findTree(objectId)
    if getRigidBodyType(objectId) ~= "Static" then
        return nil
    end

    local treeId = getParent(getParent(objectId))

    for _, tree in pairs(g_currentMission.plantedTrees.growingTrees) do
        if tree.node == treeId then
            tree.growing = true

            return tree
        end
    end

    for _, tree in pairs(g_currentMission.plantedTrees.splitTrees) do
        if tree.node == treeId then
            tree.growing = false

            return tree
        end
    end

    return nil
end

function ssMeasureTool:showFailed()
    self.blinkingMessage = "Measurement failed"
    self.blinkingMessageUntil = g_currentMission.time + ssMeasureTool.BLINKING_MESSAGE_DURATION
end

function ssMeasureTool:showNoInfo()
    self.blinkingMessage = "Measurement failed: no info"
    self.blinkingMessageUntil = g_currentMission.time + ssMeasureTool.BLINKING_MESSAGE_DURATION
end

function ssMeasureTool:showBaleInfo(bale)
    log("Bale", bale)

    print_r(bale)
end

function ssMeasureTool:showTerrainInfo(x, y, z)
    log("Terrain", x, y, z)
end

function ssMeasureTool:showPlantedTreeInfo(tree)
    log("Planted Tree", tree)

    print_r(tree)
end

function ssMeasureTool:showStaticTreeInfo(tree)
    log("Static Tree", tree)

    print_r(tree)
end

function ssMeasureTool:showFillablePallet(pallet)
    log("FIllable pallet", pallet)

    print_r(pallet)
end

registerHandTool("ssMeasureTool", ssMeasureTool)
