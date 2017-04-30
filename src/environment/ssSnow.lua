----------------------------------------------------------------------------------------------------
-- SCRIPT TO ADD PHYSICAL SNOW LAYERS
----------------------------------------------------------------------------------------------------
-- Purpose:  to create plowable snow on the ground
-- Authors:  mrbear, reallogger (only removing snow under objects)
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssSnow = {}
g_seasons.snow = ssSnow

ssSnow.LAYER_HEIGHT = 0.06
ssSnow.MAX_HEIGHT = 0.48
ssSnow.SNOW_MASK_FIRST_CHANNEL = 0
ssSnow.SNOW_MASK_NUM_CHANNELS = 1

ssSnow.MODE_OFF = 1
ssSnow.MODE_ONE_LAYER = 2
ssSnow.MODE_ON = 3

function ssSnow:preLoad()
    Placeable.finalizePlacement = Utils.appendedFunction(Placeable.finalizePlacement, ssSnow.placeableFinalizePlacement)
    Placeable.onSell = Utils.appendedFunction(Placeable.onSell, ssSnow.placeableOnSell)
end

function ssSnow:load(savegame, key)
    self.appliedSnowDepth = ssXMLUtil.getInt(savegame, key .. ".weather.appliedSnowDepth", 0) * self.LAYER_HEIGHT
    self.updateSnow = ssXMLUtil.getBool(savegame, key .. ".weather.updateSnow", false)

    local saveMode = ssXMLUtil.getInt(savegame, key .. ".weather.snowMode", nil)
    if saveMode == nil then
        self.mode = ssSnow.MODE_ON
    else
        self.mode = saveMode
        self.modeIsFromSave = true
    end

    -- Automatic snow using the weather. Can be disabled for debugging
    self.autoSnow = true
end

function ssSnow:save(savegame, key)
    ssXMLUtil.setInt(savegame, key .. ".weather.appliedSnowDepth", self.appliedSnowDepth / self.LAYER_HEIGHT)
    ssXMLUtil.setBool(savegame, key .. ".weather.updateSnow", self.updateSnow)
    ssXMLUtil.setInt(savegame, key .. ".weather.snowMode", self.mode)
end

function ssSnow:loadMap(name)
    -- Register Snow as a fill and Tip type
    local t = FillUtil.registerFillType("snow", g_i18n:getText("fillType_snow"), FillUtil.FILLTYPE_CATEGORY_BULK, 0, false, g_seasons.modDir .. "resources/huds/hud_fill_snow.png", g_seasons.modDir .. "resources/huds/hud_fill_snow_sml.png", 0.00016, math.rad(50))
    TipUtil.registerDensityMapHeightType(FillUtil.FILLTYPE_SNOW, math.rad(35), 0.8, 0.10, 0.10, 1.20, 3, true, g_seasons.modDir .. "resources/environment/snow_diffuse.dds", g_seasons.modDir .. "resources/environment/snow_normal.dds", g_seasons.modDir .. "resources/environment/snowDistance_diffuse.dds")
    loadI3DFile(g_seasons.modDir .. "resources/environment/snow_materialHolder.i3d") -- Snow fillplanes and effects.

    -- Load overlay icon, properly
    local uiScale = g_gameSettings:getValue("uiScale")
    local levelIconWidth, levelIconHeight = getNormalizedScreenValues(20 * uiScale, 20 * uiScale)
    g_currentMission:addFillTypeOverlay(t, FillUtil.fillTypeIndexToDesc[t].hudOverlayFilename, levelIconWidth, levelIconHeight)

    if g_currentMission:getIsServer() then
        g_currentMission.environment:addHourChangeListener(self)

        self.snowLayersDelta = 0 -- Number of snow layers to add or remove.

        ssDensityMapScanner:registerCallback("ssSnowAddSnow", self, self.addSnow, self.removeSnowUnderObjects)
        ssDensityMapScanner:registerCallback("ssSnowRemoveSnow", self, self.removeSnow)

        addConsoleCommand("ssAddSnow", "Adds one layer of snow", "consoleCommandAddSnow", self)
        addConsoleCommand("ssRemoveSnow", "Removes one layer of snow", "consoleCommandRemoveSnow", self)
        addConsoleCommand("ssResetSnow", "Removes all snow", "consoleCommandResetSnow", self)
    end

end

function ssSnow:readStream(streamId, connection)
    -- Applied snow depth is not needed
    self.mode = streamReadInt8(streamId)
end

function ssSnow:writeStream(streamId, connection)
    streamWriteInt8(streamId, self.mode)
end

function ssSnow:setMode(mode)
    if mode == self.mode then return end
    if mode < 1 or mode > 3 then return end

    self.mode = mode

    if g_currentMission:getIsServer() then
        if self.mode == self.MODE_OFF then
            self:applySnow(0)
        elseif self.mode == self.MODE_ONE_LAYER and self.appliedSnowDepth > self.LAYER_HEIGHT then
            self:applySnow(self.LAYER_HEIGHT)
        end
    end
end

function ssSnow:applySnow(targetSnowDepth)
    if not g_currentMission:getIsServer() then return end

    local oldSnowDepth = self.appliedSnowDepth

    if self.mode == self.MODE_ONE_LAYER then
        targetSnowDepth = math.min(self.LAYER_HEIGHT, targetSnowDepth)
    elseif self.mode == self.MODE_OFF then
        targetSnowDepth = 0
    else
        -- Target snow depth in meters. Never higher than 0.48
        targetSnowDepth = math.min(self.MAX_HEIGHT, targetSnowDepth)
    end

    if self.appliedSnowDepth < 0 and targetSnowDepth > 0 then
        self.appliedSnowDepth = 0
    end

    -- Disable snow updates when unnecessary.
    if targetSnowDepth < -4 and self.updateSnow == true then
        self.snowLayersDelta = 100
        ssDensityMapScanner:queueJob("ssSnowRemoveSnow", self.snowLayersDelta)
        self.updateSnow = false
        self.appliedSnowDepth = 0
    elseif targetSnowDepth > 0 then
        self.updateSnow = true
    end

    if self.updateSnow then
        if targetSnowDepth - self.appliedSnowDepth >= ssSnow.LAYER_HEIGHT then
            self.snowLayersDelta = math.modf((targetSnowDepth - self.appliedSnowDepth) / ssSnow.LAYER_HEIGHT)

            if targetSnowDepth > 0 then
                -- log("Snow, Adding: " .. self.snowLayersDelta .. " layers of Snow. Total depth: " .. self.appliedSnowDepth .. " m Requested: " .. targetSnowDepth .. " m" )
                ssDensityMapScanner:queueJob("ssSnowAddSnow", self.snowLayersDelta)
            end

            self.appliedSnowDepth = self.appliedSnowDepth + self.snowLayersDelta * ssSnow.LAYER_HEIGHT
        elseif self.appliedSnowDepth - targetSnowDepth >= ssSnow.LAYER_HEIGHT then
            self.snowLayersDelta = math.modf((self.appliedSnowDepth - targetSnowDepth) / ssSnow.LAYER_HEIGHT)
            self.appliedSnowDepth = self.appliedSnowDepth - self.snowLayersDelta * ssSnow.LAYER_HEIGHT

            -- log("Snow, Removing: " .. self.snowLayersDelta .. " layers of Snow. Total depth: " .. self.appliedSnowDepth .. " m Requested: " .. targetSnowDepth .. " m" )

            ssDensityMapScanner:queueJob("ssSnowRemoveSnow", self.snowLayersDelta)
        end
    end
end

function ssSnow:hourChanged()
    if not self.autoSnow or self.mode == ssSnow.MODE_OFF then return end

    local targetFromweatherSystem = ssWeatherManager:getSnowHeight() -- Fetch from weathersystem.

    self:applySnow(targetFromweatherSystem)
end

-- Must be defined before being registered with ssDensityMapScanner.
function ssSnow:addSnow(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, layers)
    layers = tonumber(layers)

    -- Fix for broken vanilla game: when swath is very near the south border, the game crashes
    heightWorldZ = math.min(heightWorldZ, (g_currentMission.terrainSize / 2.0) - 18.0)

    local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

    if self.snowMaskId ~= nil then
        -- Set snow type where we have no other heaps or masked areas on the map.
        setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", 0)
        setDensityCompareParams(g_currentMission.terrainDetailHeightId, "equals", 0)
        setDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 0, 5, self.snowMaskId, ssSnow.SNOW_MASK_FIRST_CHANNEL, ssSnow.SNOW_MASK_NUM_CHANNELS, TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_SNOW]["index"])
        setDensityMaskParams(g_currentMission.terrainDetailHeightId, "greater", -1)
        setDensityCompareParams(g_currentMission.terrainDetailHeightId, "greater", -1)
    else
        -- No snowmask provided by maps, so only mask for heaps
        setDensityCompareParams(g_currentMission.terrainDetailHeightId, "equals", 0)
        setDensityParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 0, 5, TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_SNOW]["index"])
        setDensityCompareParams(g_currentMission.terrainDetailHeightId, "greater", -1)
    end
    -- Add snow where type is snow.
    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_SNOW].index)
    addDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 5, 6, g_currentMission.terrainDetailHeightId, 0, 5, layers)
    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "greater", -1)
end

-- Must be defined before being registered with ssDensityMapScanner.
function ssSnow:removeSnow(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, layers)
    layers = tonumber(layers)
    local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

    -- Remove snow where type is snow.
    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_SNOW].index)
    setDensityCompareParams(g_currentMission.terrainDetailHeightId, "greater", 0)
    addDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 5, 6, g_currentMission.terrainDetailHeightId, 0, 5, -layers)

    -- Remove snow type where we have no snow.
    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", 0)
    setDensityCompareParams(g_currentMission.terrainDetailHeightId, "equals", TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_SNOW].index)
    setDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 0, 5, g_currentMission.terrainDetailHeightId, 5, 6, 0)

    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "greater", -1)
    setDensityCompareParams(g_currentMission.terrainDetailHeightId, "greater", -1)
end

function ssSnow:update(dt)
    if not self.loadedSnowMask then
        self.loadedSnowMask = true

        self.snowMaskId = ssUtil.getSnowMaskId()

        if self.snowMaskId ~= nil then
            setVisibility(self.snowMaskId, false)
        end

        -- When no mask is available, limit to one layer
        if self.snowMaskId == nil and not self.modeIsFromSave then
            self.mode = self.MODE_ONE_LAYER
        end
    end
end

--
-- Placeables auto-mask
--

function ssSnow:placeableFinalizePlacement()
    g_seasons.snow:setPlacableAreaInSnowMask(self, 1)
end

function ssSnow:placeableOnSell()
    g_seasons.snow:setPlacableAreaInSnowMask(self, 0)
end

function ssSnow:setPlacableAreaInSnowMask(placeable, value)
    if self.snowMaskId == nil then return end

    local numAreas = table.getn(placeable.clearAreas)

    for i = 1, numAreas do
        local x, _, z = getWorldTranslation(placeable.clearAreas[i].start)
        local x1, _, z1 = getWorldTranslation(placeable.clearAreas[i].width)
        local x2, _, z2 = getWorldTranslation(placeable.clearAreas[i].height)

        local startX, startZ, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(self.snowMaskId, x, z, x1, z1, x2, z2)

        setDensityParallelogram(self.snowMaskId, startX, startZ, widthX, widthZ, heightX, heightZ, 0, 1, value)
    end
end

--
-- No snow under objects
--

function ssSnow:removeSnowUnderObjects()
    local dim = {}

    for _, object in pairs(g_currentMission.itemsToSave) do
        dim.width = 0
        dim.length = 0

        if object.className == "Bale" then
            if object.item.baleDiameter ~= nil then
                dim.width = object.item.baleWidth
                dim.length = object.item.baleDiameter

                -- change dimension if bale is lying down
                if object.item.sendRotX > 1.5 then
                    dim.width = object.item.baleDiameter
                end
            elseif object.item.baleLength ~= nil then
                dim.width = object.item.baleWidth
                dim.length = object.item.baleLength
            end

            self:removeSnowLayer(object.item, dim)

        elseif object.className == "FillablePallet" then
            dim.width = 1
            dim.length = 1

            self:removeSnowLayer(object.item, dim)
        end
    end

    for _, singleVehicle in pairs(g_currentMission.vehicles) do
        if singleVehicle.wheels ~= nil then
            for _, wheel in pairs(singleVehicle.wheels) do

                local width = 0.5 * wheel.width;
                local length = math.min(0.2, 0.35 * wheel.width);
                local radius = wheel.radius

                local x0, z0, x1, z1, x2, z2 = self:getWheelCoord(wheel, width, length)

                self:removeSnow(x0, z0, x1, z1, x2, z2, 1)
            end
        end
    end
end

function ssSnow:removeSnowLayer(objectInSnow, dim)
    local scale = 0.65

    local x0 = objectInSnow.sendPosX + dim.width * scale
    local x1 = objectInSnow.sendPosX - dim.width * scale
    local x2 = objectInSnow.sendPosX + dim.width * scale
    local z0 = objectInSnow.sendPosZ - dim.length * scale
    local z1 = objectInSnow.sendPosZ - dim.length * scale
    local z2 = objectInSnow.sendPosZ + dim.length * scale

    local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, x0, z0, x1, z1, x2, z2)

    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_SNOW]["index"])
    setDensityCompareParams(g_currentMission.terrainDetailHeightId, "greater", 0)

    local density, area, _ = getDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 5, 6, g_currentMission.terrainDetailHeightId, 0, 5, 0)
    local snowLayers = density / area

    setDensityCompareParams(g_currentMission.terrainDetailHeightId, "greater", -1)
    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "greater", -1)

    if snowLayers > 1 then
        self:removeSnow(x0, z0, x1, z1, x2, z2, 1)
    end
end

function ssSnow:getWheelCoord(wheel, width, length)
    local x0, y0, z0
    local x1, y1, z1
    local x2, y2, z2

    if wheel.repr == wheel.driveNode then
        x0, y0, z0 = localToWorld(wheel.node, wheel.positionX + width, wheel.positionY, wheel.positionZ - length)
        x1, y1, z1 = localToWorld(wheel.node, wheel.positionX - width, wheel.positionY, wheel.positionZ - length)
        x2, y2, z2 = localToWorld(wheel.node, wheel.positionX + width, wheel.positionY, wheel.positionZ + length)
    else
        local x, _, z = localToLocal(wheel.driveNode, wheel.repr, 0, 0, 0)
        x0, y0, z0 = localToWorld(wheel.repr, x + width, 0, z - length)
        x1, y1, z1 = localToWorld(wheel.repr, x - width, 0, z - length)
        x2, y2, z2 = localToWorld(wheel.repr, x + width, 0, z + length)
    end

    return x0, z0, x1, z1, x2, z2
end

--
-- Commands
--

function ssSnow:consoleCommandAddSnow()
    self:applySnow(self.appliedSnowDepth + ssSnow.LAYER_HEIGHT)
end

function ssSnow:consoleCommandRemoveSnow()
    self:applySnow(self.appliedSnowDepth - ssSnow.LAYER_HEIGHT)
end

function ssSnow:consoleCommandResetSnow()
    self:applySnow(0)
end
