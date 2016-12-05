---------------------------------------------------------------------------------------------------------
-- SCRIPT TO ADD PHYSICAL SNOW LAYERS
---------------------------------------------------------------------------------------------------------
-- Purpose:  to create plowable snow on the ground
-- Authors:  mrbear
--

ssSnow = {}
ssSnow.LAYER_HEIGHT = 0.06
ssSnow.SNOW_MASK_NAME="SeasonSnowMask"
ssSnow.SNOW_MASK_FIRST_CHANNEL = 0
ssSnow.SNOW_MASK_NUM_CHANNELS = 1

function ssSnow:load(savegame, key)
    self.appliedSnowDepth = ssStorage.getXMLInt(savegame, key .. ".weather.appliedSnowDepth", 0) * self.LAYER_HEIGHT
end

function ssSnow:save(savegame, key)
    ssStorage.setXMLInt(savegame, key .. ".weather.appliedSnowDepth", self.appliedSnowDepth / self.LAYER_HEIGHT)
end


function ssSnow:loadMap(name)
    -- Register Snow as a fill and Tip type
    FillUtil.registerFillType("snow",  g_i18n:getText("fillType_snow"), FillUtil.FILLTYPE_CATEGORY_BULK, 0,  false,  "dataS2/menu/hud/fillTypes/hud_fill_straw.png", "dataS2/menu/hud/fillTypes/hud_fill_straw_sml.png", 0.0002* 0.5, math.rad(50))
    TipUtil.registerDensityMapHeightType(FillUtil.FILLTYPE_SNOW, math.rad(35), 0.8, 0.10, 0.10, 1.20, 3, true, ssSeasonsMod.modDir .. "resources/snow_diffuse.dds", ssSeasonsMod.modDir .. "resources/snow_normal.dds", ssSeasonsMod.modDir .. "resources/snowDistance_diffuse.dds")

    if g_currentMission:getIsClient() then
        g_currentMission.environment:addHourChangeListener(self)

        self.doAddSnow = false -- Should we currently be running a loop to add Snow on the map.
        self.doRemoveSnow = false
        self.snowLayersDelta = 0 -- Number of snow layers to add or remove.
        self.updateSnow = true

        self.currentX = 0 -- The row that we are currently updating
        self.currentZ = 0 -- The column that we are currently updating
        self.addedSnowForCurrentSnowfall = false -- Have we already added snow for the current snowfall?
    end
end


function ssSnow:updatePlacableOnCreation()
    local snowMaskId = getChild(g_currentMission.terrainRootNode, "SeasonSnowMask") -- 0 if no snow mask
    if snowMaskId == 0 then
        return
    end
    local numAreas = table.getn(self.clearAreas)
    for i=1, numAreas do
        local x,_,z = getWorldTranslation(self.clearAreas[i].start)
        local x1,_,z1 = getWorldTranslation(self.clearAreas[i].width)
        local x2,_,z2 = getWorldTranslation(self.clearAreas[i].height)
        local startX,startZ, widthX,widthZ, heightX,heightZ = Utils.getXZWidthAndHeight(snowMaskId, x, z, x1, z1, x2, z2)
        -- Remove area from snowMask
        setDensityParallelogram(snowMaskId, startX,startZ, widthX,widthZ, heightX,heightZ, 0, 1, 1)
    end
end
Placeable.finalizePlacement = Utils.appendedFunction(Placeable.finalizePlacement, ssSnow.updatePlacableOnCreation)

function ssSnow:updatePlacablenOnDelete()
    local snowMaskId = getChild(g_currentMission.terrainRootNode, "SeasonSnowMask") -- 0 if no snow mask
    if snowMaskId == 0 then
        return
    end
    local numAreas = table.getn(self.clearAreas)
    for i=1, numAreas do
        local x,_,z = getWorldTranslation(self.clearAreas[i].start)
        local x1,_,z1 = getWorldTranslation(self.clearAreas[i].width)
        local x2,_,z2 = getWorldTranslation(self.clearAreas[i].height)
        local startX,startZ, widthX,widthZ, heightX,heightZ = Utils.getXZWidthAndHeight(snowMaskId, x, z, x1, z1, x2, z2)
        -- Add area to snowMask
        setDensityParallelogram(snowMaskId, startX,startZ, widthX,widthZ, heightX,heightZ, 0, 1, 0)
    end
end
Placeable.deleteFinal = Utils.prependedFunction(Placeable.deleteFinal, ssSnow.updatePlacablenOnDelete);

function ssSnow:deleteMap()
end

function ssSnow:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssSnow:keyEvent(unicode, sym, modifier, isDown)
end

function ssSnow:draw()
end

function ssSnow:hourChanged()

    local targetFromweatherSystem = ssWeatherManager:getSnowHeight() -- Fetch from weatersystem.
    local targetSnowDepth = math.min(0.48, targetFromweatherSystem) -- Target snow depth in meters. Never higher than 0.4

    -- print("-- Target Snowdept: " .. targetSnowDepth .. " Applied Snowdepth: " .. self.appliedSnowDepth);

    if self.appliedSnowDepth < 0 and targetSnowDepth > 0 then
        self.appliedSnowDepth = 0
    end

    -- Disable snow updates when unnecessary.
    if targetSnowDepth < -4 and self.updateSnow == true then
        -- print("--- Disabling snow updates ---")
        self.snowLayersDelta=100
        self.doRemoveSnow = true
        self.updateSnow=false
    elseif targetSnowDepth > 0 then
        -- print("--- Enabling snow updates ---")
        self.updateSnow=true
    end


    if targetSnowDepth - self.appliedSnowDepth >= ssSnow.LAYER_HEIGHT and self.updateSnow == true then
        self.snowLayersDelta = math.modf((targetSnowDepth - self.appliedSnowDepth) / ssSnow.LAYER_HEIGHT)
        if targetSnowDepth > 0 then
            self.doAddSnow = true
            print("Adding: " .. self.snowLayersDelta .. " layers of Snow. Total depth: " .. self.appliedSnowDepth .. " m Requested: " .. targetSnowDepth .. " m" )
        end
        self.appliedSnowDepth = self.appliedSnowDepth + self.snowLayersDelta * ssSnow.LAYER_HEIGHT
    elseif self.appliedSnowDepth - targetSnowDepth >= ssSnow.LAYER_HEIGHT and self.updateSnow == true then
        self.snowLayersDelta = math.modf((self.appliedSnowDepth - targetSnowDepth) / ssSnow.LAYER_HEIGHT)
        self.appliedSnowDepth = self.appliedSnowDepth - self.snowLayersDelta * ssSnow.LAYER_HEIGHT
        self.doRemoveSnow = true
        print("Removing: " .. self.snowLayersDelta .. " layers of Snow. Total depth: " .. self.appliedSnowDepth .. " m Requested: " .. targetSnowDepth .. " m" )
    end

end

-- Must be defined before call to ssSeasonsUtil:ssIterateOverTerrain where it's used as an argument.
local function addSnow(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, layers)
    local snowMaskId = getChild(g_currentMission.terrainRootNode, ssSnow.SNOW_MASK_NAME) -- 0 if no snow mask, should realy be done externally before first update() and stored.
    local x,z, widthX,widthZ, heightX,heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

    if snowMaskId ~= 0 then
        -- Set snow type where we have no other heaps or masked areas on the map.
        setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", 0)
        setDensityCompareParams(g_currentMission.terrainDetailHeightId, "equals", 0)
        setDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 0, 5, snowMaskId, ssSnow.SNOW_MASK_FIRST_CHANNEL, ssSnow.SNOW_MASK_NUM_CHANNELS, TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_SNOW]["index"])
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

local function removeSnow(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, layers)

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
    -- This should be done ones at startup. Just before the first update when everything is loaded.
    local snowMaskId = getChild(g_currentMission.terrainRootNode, ssSnow.SNOW_MASK_NAME) -- 0 if no snow mask, should realy be done externally before first update() and stored.
    if snowMaskId ~= 0 then
        setVisibility(snowMaskId, false)
    end
    
    if g_currentMission:getIsClient() then
        if self.doAddSnow == true then
            self.currentX, self.currentZ, self.doAddSnow = ssSeasonsUtil:ssIterateOverTerrain(self.currentX, self.currentZ, addSnow, self.snowLayersDelta)
        elseif self.doRemoveSnow == true then
            self.currentX, self.currentZ, self.doRemoveSnow = ssSeasonsUtil:ssIterateOverTerrain(self.currentX, self.currentZ, removeSnow, self.snowLayersDelta)
        end
    end
end
