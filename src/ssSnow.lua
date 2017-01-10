---------------------------------------------------------------------------------------------------------
-- SCRIPT TO ADD PHYSICAL SNOW LAYERS
---------------------------------------------------------------------------------------------------------
-- Purpose:  to create plowable snow on the ground
-- Authors:  mrbear
--

ssSnow = {}
ssSnow.LAYER_HEIGHT = 0.06
ssSnow.MAX_HEIGHT = 0.48
ssSnow.SNOW_MASK_NAME = "SeasonsSnowMask"
ssSnow.SNOW_MASK_FIRST_CHANNEL = 0
ssSnow.SNOW_MASK_NUM_CHANNELS = 1

function ssSnow:load(savegame, key)
    self.appliedSnowDepth = ssStorage.getXMLInt(savegame, key .. ".weather.appliedSnowDepth", 0) * self.LAYER_HEIGHT

    -- Automatic snow using the weather. Can be disabled for debugging
    self.autoSnow = true
end

function ssSnow:save(savegame, key)
    ssStorage.setXMLInt(savegame, key .. ".weather.appliedSnowDepth", self.appliedSnowDepth / self.LAYER_HEIGHT)
end

function ssSnow:loadMap(name)
    -- Register Snow as a fill and Tip type
    FillUtil.registerFillType("snow",  g_i18n:getText("fillType_snow"), FillUtil.FILLTYPE_CATEGORY_BULK, 0,  false,  "dataS2/menu/hud/fillTypes/hud_fill_straw.png", "dataS2/menu/hud/fillTypes/hud_fill_straw_sml.png", 0.0002* 0.5, math.rad(50))
    TipUtil.registerDensityMapHeightType(FillUtil.FILLTYPE_SNOW, math.rad(35), 0.8, 0.10, 0.10, 1.20, 3, true, ssSeasonsMod.modDir .. "resources/environment/snow_diffuse.dds", ssSeasonsMod.modDir .. "resources/environment/snow_normal.dds", ssSeasonsMod.modDir .. "resources/environment/snowDistance_diffuse.dds")

    if g_currentMission:getIsServer() then
        g_currentMission.environment:addHourChangeListener(self)

        self.snowLayersDelta = 0 -- Number of snow layers to add or remove.

        if self.snowMaskId ~= nil then
            setVisibility(self.snowMaskId, false)
        end

        ssDensityMapScanner:registerCallback("ssSnowAddSnow", self, self.addSnow)
        ssDensityMapScanner:registerCallback("ssSnowRemoveSnow", self, self.removeSnow)
    end
end

function ssSnow:deleteMap()
end

function ssSnow:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssSnow:keyEvent(unicode, sym, modifier, isDown)
end

function ssSnow:draw()
end

function ssSnow:applySnow(targetSnowDepth)
    targetSnowDepth = math.min(self.MAX_HEIGHT, targetSnowDepth) -- Target snow depth in meters. Never higher than 0.4

    -- Limit snow height to 1 layer on non-snow masked maps
    if self.snowMaskId == nil and self.autoSnow then -- only do with autosnow: is debug mode
        targetSnowDepth = math.min(ssSnow.LAYER_HEIGHT, targetSnowDepth)
    end

    -- print("-- Target Snowdept: " .. targetSnowDepth .. " Applied Snowdepth: " .. self.appliedSnowDepth)

    if self.appliedSnowDepth < 0 and targetSnowDepth > 0 then
        self.appliedSnowDepth = 0
    end

    -- Disable snow updates when unnecessary.
    if targetSnowDepth < -4 and self.updateSnow == true then
        self.snowLayersDelta = 100
        ssDensityMapScanner:queuJob("ssSnowRemoveSnow", self.snowLayersDelta)
        self.updateSnow = false
    elseif targetSnowDepth > 0 then
        self.updateSnow = true
    end

    if targetSnowDepth - self.appliedSnowDepth >= ssSnow.LAYER_HEIGHT and self.updateSnow == true then
        self.snowLayersDelta = math.modf((targetSnowDepth - self.appliedSnowDepth) / ssSnow.LAYER_HEIGHT)
        if targetSnowDepth > 0 then
            log("Snow, Adding: " .. self.snowLayersDelta .. " layers of Snow. Total depth: " .. self.appliedSnowDepth .. " m Requested: " .. targetSnowDepth .. " m" )
            ssDensityMapScanner:queuJob("ssSnowAddSnow", self.snowLayersDelta)
        end
        self.appliedSnowDepth = self.appliedSnowDepth + self.snowLayersDelta * ssSnow.LAYER_HEIGHT
    elseif self.appliedSnowDepth - targetSnowDepth >= ssSnow.LAYER_HEIGHT and self.updateSnow == true then
        self.snowLayersDelta = math.modf((self.appliedSnowDepth - targetSnowDepth) / ssSnow.LAYER_HEIGHT)
        self.appliedSnowDepth = self.appliedSnowDepth - self.snowLayersDelta * ssSnow.LAYER_HEIGHT
        log("Snow, Removing: " .. self.snowLayersDelta .. " layers of Snow. Total depth: " .. self.appliedSnowDepth .. " m Requested: " .. targetSnowDepth .. " m" )
        ssDensityMapScanner:queuJob("ssSnowRemoveSnow", self.snowLayersDelta)
    end
end

function ssSnow:hourChanged()
    if not self.autoSnow then return end

    local targetFromweatherSystem = ssWeatherManager:getSnowHeight() -- Fetch from weathersystem.

    self:applySnow(targetFromweatherSystem)
end

-- Must be defined before being registered with ssDensityMapScanner.
function ssSnow:addSnow(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, layers)
    layers = tonumber(layers)
    local x,z, widthX,widthZ, heightX,heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

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
    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_SNOW]["index"])
    addDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 5, 6, g_currentMission.terrainDetailHeightId, 0, 5, layers)
    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "greater", -1)
end

-- Must be defined before being registered with ssDensityMapScanner.
function ssSnow:removeSnow(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, layers)
    layers = tonumber(layers)
    local x,z, widthX,widthZ, heightX,heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

    -- Remove snow where type is snow.
    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_SNOW]["index"])
    setDensityCompareParams(g_currentMission.terrainDetailHeightId, "greater", 0)
    addDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 5, 6, g_currentMission.terrainDetailHeightId, 0, 5, -layers)
    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "greater", -1)

    -- Remove snow type where we have no snow.
    setDensityMaskParams(g_currentMission.terrainDetailHeightId,"equals",0)
    setDensityCompareParams(g_currentMission.terrainDetailHeightId, "equals",TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_SNOW]["index"])
    setDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 0, 5, g_currentMission.terrainDetailHeightId, 5, 6, 0)
    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "greater", -1)
    setDensityCompareParams(g_currentMission.terrainDetailHeightId, "greater", -1)
end

function ssSnow:update(dt)
    if not self.loadedSnowMask then
        self.loadedSnowMask = true

        self.snowMaskId = getChild(g_currentMission.terrainRootNode, ssSnow.SNOW_MASK_NAME)
        if self.snowMaskId == 0 then
            self.snowMaskId = nil
        end
    end
end

function ssSnow:updatePlacableOnCreation()
    if self.snowMaskId == nil then return end

    local numAreas = table.getn(self.clearAreas)
    for i=1, numAreas do
        local x,_,z = getWorldTranslation(self.clearAreas[i].start)
        local x1,_,z1 = getWorldTranslation(self.clearAreas[i].width)
        local x2,_,z2 = getWorldTranslation(self.clearAreas[i].height)
        local startX,startZ, widthX,widthZ, heightX,heightZ = Utils.getXZWidthAndHeight(self.snowMaskId, x, z, x1, z1, x2, z2)
        -- Remove area from snowMask
        setDensityParallelogram(self.snowMaskId, startX,startZ, widthX,widthZ, heightX,heightZ, 0, 1, 1)
    end
end

Placeable.finalizePlacement = Utils.appendedFunction(Placeable.finalizePlacement, ssSnow.updatePlacableOnCreation)

function ssSnow:updatePlacablenOnDelete()
    if self.snowMaskId == nil then return end

    local numAreas = table.getn(self.clearAreas)
    for i=1, numAreas do
        local x,_,z = getWorldTranslation(self.clearAreas[i].start)
        local x1,_,z1 = getWorldTranslation(self.clearAreas[i].width)
        local x2,_,z2 = getWorldTranslation(self.clearAreas[i].height)
        local startX,startZ, widthX,widthZ, heightX,heightZ = Utils.getXZWidthAndHeight(self.snowMaskId, x, z, x1, z1, x2, z2)
        -- Add area to snowMask
        setDensityParallelogram(self.snowMaskId, startX,startZ, widthX,widthZ, heightX,heightZ, 0, 1, 0)
    end
end

Placeable.onSell = Utils.appendedFunction(Placeable.onSell, ssSnow.updatePlacablenOnDelete)
