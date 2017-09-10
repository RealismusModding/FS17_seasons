ssMeasureTool = {}
local ssMeasureTool_mt = Class(ssMeasureTool, HandTool)

-- InitStaticObjectClass(ssMeasureTool, "ssMeasureTool", ObjectIds.OBJECT_CHAINSAW)

ssMeasureTool.MEASURE_TIME = 1500 -- ms
ssMeasureTool.MEASURE_TIME_VAR = 300
ssMeasureTool.MEASURE_PULSE = 400
ssMeasureTool.MEASURE_TIMEOUT = 1000 --3000
ssMeasureTool.MEASURE_DISTANCE = 10

ssMeasureTool.BLINKING_MESSAGE_DURATION = 2000

ssMeasureTool.UVS_COMPACTION    = {   8,   8, 128, 128 }
ssMeasureTool.UVS_COMPASS       = { 144,   8, 128, 128 }
ssMeasureTool.UVS_CONTENTS      = { 280,   8, 128, 128 }
ssMeasureTool.UVS_CROP_HEIGHT   = { 416,   8, 128, 128 }
ssMeasureTool.UVS_TREE_DISTANCE = { 552,   8, 128, 128 }
ssMeasureTool.UVS_TREE_TYPE     = { 688,   8, 128, 128 }
ssMeasureTool.UVS_ELEVATION     = {   8, 144, 128, 128 }
ssMeasureTool.UVS_FERMENTATION  = { 144, 144, 128, 128 }
ssMeasureTool.UVS_FERTILIZATION = { 280, 144, 128, 128 }
ssMeasureTool.UVS_CROP_TYPE     = { 416, 144, 128, 128 }
ssMeasureTool.UVS_TREE_HEIGHT   = { 552, 144, 128, 128 }

ssMeasureTool.UVS_PLOUGHCOUNTER = { 552, 144, 128, 128 }

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

            self:executeMeasurement()
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

function ssMeasureTool:executeMeasurement()
    -- Raycast from the player
    local x, y, z = localToWorld(self.player.cameraNode, 0, 0, 0.5)
    local dx, dy, dz = localDirectionToWorld(self.player.cameraNode, 0, 0, -1)

    raycastClosest(x, y, z, dx, dy, dz, "raycastCallback", ssMeasureTool.MEASURE_DISTANCE, self)
end

-- Called by the raycast: handles finding the object that was scanned
function ssMeasureTool:raycastCallback(hitObjectId, x, y, z, distance)
    -- Too close or too far away
    if distance < 0.5 or distance > ssMeasureTool.MEASURE_DISTANCE or hitObjectId == 0 then
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
        elseif type == "NoRigidBody" then
            self:showFailed()
        else -- Any object, either static or dynamic
            local object = g_currentMission:getNodeObject(hitObjectId)

            if object then
                if object:isa(Bale) then
                    self:showBaleInfo(object)
                elseif object:isa(FillablePallet) then
                    self:showFillablePallet(object)
                elseif object:isa(TreePlaceable) then
                    local nameI18N = nil
                    local storeItem = StoreItemsUtil.storeItemsByXMLFilename[object.configFileName:lower()]
                    if storeItem then
                        nameI18N = storeItem.name
                    end

                    self:showStaticTreeInfo({
                        nameI18N = nameI18N
                    })
                end
            else
                local tree = self:findTree(hitObjectId)

                if tree then
                    self:showPlantedTreeInfo(tree)
                elseif getSplitType(hitObjectId) ~= 0 then
                    self:showStaticTreeInfo({treeType = getSplitType(hitObjectId)})
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
    local data = {}

    table.insert(data, {
        iconUVs = ssMeasureTool.UVS_CONTENTS,
        text = FillUtil.fillTypeIndexToDesc[bale.fillType].nameI18N .. " (" .. bale.fillLevel .. " l)"
    })

    if bale.wrappingState == 1 and bale.fermentingProcess ~= nil then
        local hours = g_seasons.environment.daysInSeason / 3 * 24 * bale.fermentingProcess
        table.insert(data, {
            iconUVs = ssMeasureTool.UVS_FERMENTATION,
            text = string.format("%.2f%% (%d hours to go)", bale.fermentingProcess * 100, hours)
        })
    end

    self:openDialog("Bale", data)
end

function ssMeasureTool:showTerrainInfo(x, y, z)
    -- Calculate area
    local areaSize = 1.0
    local halfArea = areaSize / 2.0

    local worldX, worldZ = x - halfArea, z - halfArea
    local worldWidthX, worldWidthZ = areaSize, 0
    local worldHeightX, worldHeightZ = 0, areaSize

    -- Read height
    local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, y, z)

    local a, b, c = getDensityParallelogram(g_currentMission.terrainDetailId, worldX,worldZ, worldWidthX,worldWidthZ, worldHeightX,worldHeightZ,  g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
    local terrainType = a / b

    -- Get spray level
    local a, b, c = getDensityParallelogram(g_currentMission.terrainDetailId, worldX,worldZ, worldWidthX,worldWidthZ, worldHeightX,worldHeightZ,  g_currentMission.sprayLevelFirstChannel, g_currentMission.sprayLevelNumChannels)
    local sprayLevel = a / b

    -- Get plough counter
    local a, b, c = getDensityParallelogram(g_currentMission.terrainDetailId, worldX,worldZ, worldWidthX,worldWidthZ, worldHeightX,worldHeightZ,  g_currentMission.ploughCounterFirstChannel, g_currentMission.ploughCounterNumChannels)
    local ploughCounter = a / b

    -- Get fruit and fruit height
    local crop = nil
    for index, fruit in pairs(g_currentMission.fruits) do
        local fruitDesc = FruitUtil.fruitIndexToDesc[index]
        local a, b, c = getDensityParallelogram(fruit.id, worldX,worldZ, worldWidthX,worldWidthZ, worldHeightX,worldHeightZ,  0, g_currentMission.numFruitDensityMapChannels)

        if a > 0 then
            fruit = {
                desc = fruitDesc,
                id = fruit.id,
                stage = a / b
            }
            break
        end
    end

    local data = {}

    table.insert(data, {
        iconUVs = ssMeasureTool.UVS_COMPASS,
        text = string.format("%.1fN %.1fE", x, z)
    })

    table.insert(data, {
        iconUVs = ssMeasureTool.UVS_ELEVATION,
        text = string.format("%.1f m", terrainHeight)
    })

    if crop then
        table.insert(data, {
            iconUVs = ssMeasureTool.UVS_CROP_TYPE,
            text = crop.desc.name
        })

        table.insert(data, {
            iconUVs = ssMeasureTool.UVS_CROP_HEIGHT,
            text = crop.stage
        })

        -- TODO: find fill for i18n
    end

    table.insert(data, {
        iconUVs = ssMeasureTool.UVS_FERTILIZATION,
        text = string.format("%.0f%%", sprayLevel / 3 * 100)
    })

    -- table.insert(data, {
    --     iconUVs = ssMeasureTool.UVS_PLOUGHCOUNTER,
    --     text = ploughCounter
    -- })

    self:openDialog("Terrain", data)
end

function ssMeasureTool:showPlantedTreeInfo(tree)
    local data = {}

    table.insert(data, {
        iconUVs = ssMeasureTool.UVS_TREE_TYPE,
        text = TreePlantUtil.treeTypeIndexToDesc[tree.treeType].nameI18N
    })

    table.insert(data, {
        iconUVs = ssMeasureTool.UVS_TREE_HEIGHT,
        text = string.format("%.0f%%", (tree.growing and tree.growthState or 1) * 100)
    })

    -- table.insert(data, {
    --     iconUVs = {552, 144, 128, 128},
    --     text = string.format("%.1f", tree.growthState)
    -- })

    table.insert(data, {
        iconUVs = ssMeasureTool.UVS_TREE_DISTANCE,
        text = string.format("%.1f m", tree.ssNearestDistance)
    })

    self:openDialog("Tree", data)
end

function ssMeasureTool:showStaticTreeInfo(tree)
    local data = {}
    local treeTypeDesc = TreePlantUtil.treeTypeIndexToDesc[tree.treeType]
    local typeName

    if treeTypeDesc then
        typeName = treeTypeDesc.nameI18N
    elseif tree.nameI18N then
        typeName = tree.nameI18N
    else
        typeName = "Unknown (", tree.treeType, ")"
    end

    table.insert(data, {
        iconUVs = ssMeasureTool.UVS_TREE_TYPE,
        text = typeName
    })

    table.insert(data, {
        iconUVs = ssMeasureTool.UVS_TREE_HEIGHT,
        text = "100%"
    })

    self:openDialog("Tree", data)
end

function ssMeasureTool:showFillablePallet(pallet)
    local data = {}

    table.insert(data, {
        iconUVs = ssMeasureTool.UVS_CONTENTS,
        text = string.format("%s (%d)", FillUtil.fillTypeIndexToDesc[pallet.fillType].nameI18N, pallet.fillLevel)
    })

    if pallet.fillType == FillUtil.FILLTYPE_TREESAPLINGS then
        table.insert(data, {
            iconUVs = ssMeasureTool.UVS_TREE_TYPE,
            text = TreePlantUtil.treeTypeIndexToDesc[pallet.treeType].nameI18N
        })
    end

    self:openDialog("Pallet", data)
end

function ssMeasureTool:openDialog(title, contents)
    local dialog = g_gui:showDialog("MeasureToolDialog")

    dialog.target:setTitle(title)
    dialog.target:setCallback(self.dialogClose, self, true)
    dialog.target:setData(contents)
end

function ssMeasureTool:dialogClose()
end

registerHandTool("ssMeasureTool", ssMeasureTool)

-- TODO:
-- translations
-- conversion meter - feet
