ssMeasureTool = {}
local ssMeasureTool_mt = Class(ssMeasureTool, HandTool)

InitObjectClass(ssMeasureTool, "ssMeasureTool")

ssMeasureTool.MEASURE_TIME = 1700 -- ms
ssMeasureTool.MEASURE_TIME_VAR = 600
ssMeasureTool.MEASURE_TIMEOUT = 2000
ssMeasureTool.MEASURE_PULSE = 483
ssMeasureTool.BREATH_TIME = 4400

ssMeasureTool.MEASURE_DISTANCE = 5 -- meters

ssMeasureTool.BLINKING_MESSAGE_DURATION = ssMeasureTool.MEASURE_TIMEOUT

ssMeasureTool.UVS_COMPACTION    = {   8,   8, 128, 128 }
ssMeasureTool.UVS_COMPASS       = { 144,   8, 128, 128 }
ssMeasureTool.UVS_CONTENTS      = { 280,   8, 128, 128 }
ssMeasureTool.UVS_CROP_HEIGHT   = { 416,   8, 128, 128 }
ssMeasureTool.UVS_TREE_DISTANCE = { 552,   8, 128, 128 }
ssMeasureTool.UVS_TREE_TYPE     = { 688,   8, 128, 128 }
ssMeasureTool.UVS_CROP_MOISTURE = { 824,   8, 128, 128 }
ssMeasureTool.UVS_ELEVATION     = {   8, 144, 128, 128 }
ssMeasureTool.UVS_FERMENTATION  = { 144, 144, 128, 128 }
ssMeasureTool.UVS_FERTILIZATION = { 280, 144, 128, 128 }
ssMeasureTool.UVS_CROP_TYPE     = { 416, 144, 128, 128 }
ssMeasureTool.UVS_TREE_HEIGHT   = { 552, 144, 128, 128 }
ssMeasureTool.UVS_MOISTURE      = { 688, 144, 128, 128 }
ssMeasureTool.UVS_SOIL_MOISTURE = { 824, 144, 128, 128 }

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

    local xmlFile = loadXMLFile("handtool", xmlFilename)

    self.objectNode = getChildAt(self.rootNode, 0)

    self.pricePerMilliSecond = Utils.getNoNil(getXMLFloat(xmlFile, "handTool.measureTool.pricePerSecond"), 50) / 1000
    self.moveCounter = 0

    if self.isClient then
        local uiScale = g_gameSettings:getValue("uiScale")

        self.selectionOverlayWidth, self.selectionOverlayHeight = getNormalizedScreenValues(46 * uiScale, 40 * uiScale)
        self.selectionOverlay = Overlay:new("selectionOverlay", g_baseUIFilename, 0.5, 0.5, self.selectionOverlayWidth, self.selectionOverlayHeight)
        self.selectionOverlay:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_CENTER)
        self.selectionOverlay:setDimension(0.3 * self.selectionOverlayWidth, 0.3 * self.selectionOverlayHeight)
        self.selectionOverlay:setUVs(getNormalizedUVs({870, 280, 69, 60}))
        self.selectionOverlay:setColor(1, 1, 1, 0.3)

        self.sampleMeasure = SoundUtil.loadSample(xmlFile, {}, "handTool.measureTool.measureSound", nil, self.baseDirectory)

        SoundUtil.setSampleVolume(self.sampleMeasure, 0.1)
    end

    if g_currentMission.player ~= player then
        setVisibility(self.rootNode, false)
    end

    delete(xmlFile)

    return true
end

function ssMeasureTool:delete()
    ssMeasureTool:superClass().delete(self)

    if self.isClient then
        self.selectionOverlay:delete()

        SoundUtil.deleteSample(self.sampleMeasure)
    end
end

function ssMeasureTool:update(dt, allowInput)
    ssMeasureTool:superClass().update(self, dt, allowInput)

    if self.isServer then
        local price = self.pricePerMilliSecond * (dt / 1000)

        g_currentMission.missionStats:updateStats("expenses", price)
        g_currentMission:addSharedMoney(-price, "vehicleRunningCost")
    end

    self.moveCounter = (self.moveCounter + dt) % ssMeasureTool.BREATH_TIME
    local pulse = math.sin(self.moveCounter / ssMeasureTool.BREATH_TIME * math.pi)
    setTranslation(self.rootNode, self.position[1], self.position[2] + pulse * 0.003 - 0.0015, self.position[3])
    setRotation(self.rootNode, self.rotation[1] - pulse * math.rad(4) + math.rad(2), self.rotation[2], self.rotation[3])

    if allowInput then
        if InputBinding.isPressed(InputBinding.ACTIVATE_HANDTOOL) and self.measuringTimeoutStart == nil then
            if self.measuringStart == nil then
                self.measuringStart = g_currentMission.time
                self.measureDuration = math.random(ssMeasureTool.MEASURE_TIME - ssMeasureTool.MEASURE_TIME_VAR, ssMeasureTool.MEASURE_TIME + ssMeasureTool.MEASURE_TIME_VAR)

                self.measureDuration = self.measureDuration - self.measureDuration % ssMeasureTool.MEASURE_PULSE
            end

            if not SoundUtil.isSamplePlaying(self.sampleMeasure, 0) then
                SoundUtil.playSample(self.sampleMeasure, 0, 0, nil)
            end
        else
            self.measuringStart = nil

            SoundUtil.stopSample(self.sampleMeasure)
        end

        -- Timers for scanning and timeout
        if self.measuringStart ~= nil and g_currentMission.time - self.measuringStart >= self.measureDuration then
            self.measuringStart = nil
            self.measuringTimeoutStart = g_currentMission.time

            SoundUtil.stopSample(self.sampleMeasure)

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
        elseif self.measuringTimeoutStart ~= nil then
            self.selectionOverlay:setColor(0.6514, 0.0399, 0.0399, 0.3)
        else
            self.selectionOverlay:setColor(1, 1, 1, 0.3)
        end

        self.selectionOverlay:setDimension(self.selectionOverlayWidth * scale, self.selectionOverlayHeight * scale)
    else
        self.selectionOverlay:setDimension(self.selectionOverlayWidth * 0.3, self.selectionOverlayHeight * 0.3)
    end

    if self.blinkingMessage then
        g_currentMission:showBlinkingWarning(self.blinkingMessage)

        if self.blinkingMessageUntil > g_currentMission.time then
            self.blinkingMessage = nil
        end
    else
        self.selectionOverlay:render()
    end
end

function ssMeasureTool:onActivate(allowInput)
    ssMeasureTool:superClass().onActivate(self)

    setVisibility(self.rootNode, g_currentMission.player == self.player)
end

function ssMeasureTool:onDeactivate(allowInput)
    ssMeasureTool:superClass().onDeactivate(self)

    self.player.walkingIsLocked = false
end

function ssMeasureTool:executeMeasurement()
    -- Raycast from the player
    local x, y, z = localToWorld(self.player.cameraNode, 0, 0, 0.5)
    local dx, dy, dz = localDirectionToWorld(self.player.cameraNode, 0, 0, -1)

    raycastClosest(x, y, z, dx, dy, dz, "raycastCallback", ssMeasureTool.MEASURE_DISTANCE, self, 32+64+128+256+4096)
end

-- Called by the raycast: handles finding the object that was scanned
function ssMeasureTool:raycastCallback(hitObjectId, x, y, z, distance)
    -- Too close or too far away
    if hitObjectId == 0 then
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
                    local nameI18N
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
    self.blinkingMessage = ssLang.getText("measuretool_failed")
    self.blinkingMessageUntil = g_currentMission.time + ssMeasureTool.BLINKING_MESSAGE_DURATION
end

function ssMeasureTool:showNoInfo()
    self.blinkingMessage = ssLang.getText("measuretool_no_info")
    self.blinkingMessageUntil = g_currentMission.time + ssMeasureTool.BLINKING_MESSAGE_DURATION
end

function ssMeasureTool:showBaleInfo(bale)
    local data = {}

    table.insert(data, {
        iconUVs = ssMeasureTool.UVS_CONTENTS,
        text = string.format("%s (%.0f %s)", FillUtil.fillTypeIndexToDesc[bale.fillType].nameI18N, bale.fillLevel, ssLang.getText("unit_literShort"))
    })

    if bale.wrappingState == 1 and bale.fermentingProcess ~= nil then
        local hours = g_seasons.environment.daysInSeason / 3 * 24 * (1 - bale.fermentingProcess)

        local text = ""
        if bale.fillType ~= FillUtil.FILLTYPE_DRYGRASS_WINDROW then
            if hours <= 1 then
                text = ssLang.getText("measuretool_fermentation_time_low")
            else
                text = string.format(ssLang.getText("measuretool_fermentation_time"), math.ceil(hours))
            end
            text = "(" .. text .. ")"
        end

        table.insert(data, {
            iconUVs = ssMeasureTool.UVS_FERMENTATION,
            text = string.format("%.2f%% %s", bale.fermentingProcess * 100, text)
        })
    end

    self:openDialog(data)
end

function ssMeasureTool:showTerrainInfo(x, y, z)
    -- Calculate area
    local areaSize = 1.0
    local halfArea = areaSize / 2.0

    local worldX, worldZ = x - halfArea, z - halfArea
    local worldWidthX, worldWidthZ = areaSize, 0
    local worldHeightX, worldHeightZ = 0, areaSize

    -- Read height
    local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, y, z) - g_currentMission.waterY

    local a, b, c = getDensityParallelogram(g_currentMission.terrainDetailId, worldX,worldZ, worldWidthX,worldWidthZ, worldHeightX,worldHeightZ,  g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
    local terrainType = a / b

    -- Get spray level
    local a, b, c = getDensityParallelogram(g_currentMission.terrainDetailId, worldX,worldZ, worldWidthX,worldWidthZ, worldHeightX,worldHeightZ,  g_currentMission.sprayLevelFirstChannel, g_currentMission.sprayLevelNumChannels)
    local sprayLevel = a / b

    -- Get plough counter
    local a, b, c = getDensityParallelogram(g_currentMission.terrainDetailId, worldX,worldZ, worldWidthX,worldWidthZ, worldHeightX,worldHeightZ,  g_currentMission.ploughCounterFirstChannel, g_currentMission.ploughCounterNumChannels)
    local ploughCounter = a / b

    -- Get fruit and fruit height
    local crop
    for index, fruit in pairs(g_currentMission.fruits) do
        local fruitDesc = FruitUtil.fruitIndexToDesc[index]
        local a, b, c = getDensityParallelogram(fruit.id, worldX,worldZ, worldWidthX,worldWidthZ, worldHeightX,worldHeightZ,  0, g_currentMission.numFruitDensityMapChannels)

        if a > 0 then
            crop = {
                desc = fruitDesc,
                id = fruit.id,
                stage = a / b
            }
            break
        end
    end

    local data = {}


    local worldSize = g_currentMission.terrainSize
    local normalizedPlayerPosX = Utils.clamp((x + worldSize * 0.5) / worldSize, 0, 1)
    local normalizedPlayerPosZ = Utils.clamp((z + worldSize * 0.5) / worldSize, 0, 1)

    local posX = normalizedPlayerPosX * worldSize
    local posZ = normalizedPlayerPosZ * worldSize

    table.insert(data, {
        iconUVs = ssMeasureTool.UVS_COMPASS,
        text = string.format("%.2f, %.2f", posX, posZ)
    })

    table.insert(data, {
        iconUVs = ssMeasureTool.UVS_ELEVATION,
        text = ssLang.formatLength(terrainHeight)
    })

    if crop then
        local fillType = FruitUtil.fruitTypeToFillType[crop.desc.index]
        local length = 0
        local densityState = crop.stage - 1
        local numStates = FruitUtil.fruitTypeGrowths[crop.desc.name].numGrowthStates - 1
        if densityState <= numStates then
            length = Utils.clamp(densityState / numStates, 0, 1)
        end

        table.insert(data, {
            iconUVs = ssMeasureTool.UVS_CROP_TYPE,
            text = FillUtil.fillTypeIndexToDesc[fillType].nameI18N
        })

        table.insert(data, {
            iconUVs = ssMeasureTool.UVS_CROP_HEIGHT,
            text = string.format("%.0f%%", length * 100)
        })

        local moisture = math.max(math.min(g_seasons.weather.cropMoistureContent, 100), 0)
        table.insert(data, {
            iconUVs = ssMeasureTool.UVS_CROP_MOISTURE,
            text = string.format("%.0f%%", moisture)
        })
    end

    table.insert(data, {
        iconUVs = ssMeasureTool.UVS_FERTILIZATION,
        text = string.format("%.0f%%", sprayLevel / 3 * 100)
    })

    -- table.insert(data, {
    --     iconUVs = ssMeasureTool.UVS_PLOUGHCOUNTER,
    --     text = ploughCounter
    -- })

    local moisture = math.max(math.min(g_currentMission.environment.groundWetness, 1), 0)
    table.insert(data, {
        iconUVs = ssMeasureTool.UVS_MOISTURE,
        text = string.format("%.0f%%", moisture * 100)
    })

    self:openDialog(data)
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

    table.insert(data, {
        iconUVs = ssMeasureTool.UVS_TREE_DISTANCE,
        text = ssLang.formatLength(tree.ssNearestDistance),
        hasIssue = g_seasons.treeManager:isTreeGrowthLimited(tree)
    })

    self:openDialog(data)
end

function ssMeasureTool:showStaticTreeInfo(tree)
    local data = {}
    local treeTypeDesc = TreePlantUtil.treeTypeIndexToDesc[tree.treeType]
    local typeName

    if treeTypeDesc then
        typeName = treeTypeDesc.nameI18N
    elseif tree.nameI18N then
        typeName = tree.nameI18N
    end

    if typeName then
        table.insert(data, {
            iconUVs = ssMeasureTool.UVS_TREE_TYPE,
            text = typeName
        })
    end

    table.insert(data, {
        iconUVs = ssMeasureTool.UVS_TREE_HEIGHT,
        text = "100%"
    })

    self:openDialog(data)
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

    self:openDialog(data)
end

function ssMeasureTool:openDialog(contents)
    local dialog = g_gui:showDialog("MeasureToolDialog")

    dialog.target:setTitle(ssLang.getText("measuretool_title"))
    dialog.target:setCallback(self.dialogClose, self, true)
    dialog.target:setData(contents)
end

function ssMeasureTool:dialogClose()
end

registerHandTool("ssMeasureTool", ssMeasureTool)
