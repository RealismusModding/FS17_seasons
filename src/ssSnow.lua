---------------------------------------------------------------------------------------------------------
-- SCRIPT TO ADD PHYSICAL SNOW LAYERS
---------------------------------------------------------------------------------------------------------
-- Purpose:  to create plowable snow on the ground
-- Authors:  mrbear
--

ssSnow = {}
ssSnow.LAYER_HEIGHT = 0.06

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

    -- General initalization
    g_currentMission.environment:addHourChangeListener(self)
    -- ssSeasonsMod:addSeasonChangeListener(self)

    self.doAddSnow = false -- Should we currently be running a loop to add Snow on the map.
    self.doRemoveSnow = false
    self.snowLayersDelta = 0 -- Number of snow layers to add or remove.
    self.updateSnow = true

    self.currentX = 0 -- The row that we are currently updating
    self.currentZ = 0 -- The column that we are currently updating
    self.addedSnowForCurrentSnowfall = false -- Have we already added snow for the current snowfall?

    --[[
    self.testValue = 1
    self.testValues={}
    self.testValues[1]=0
    self.testValues[2]=0.12
    self.testValues[3]=0.06
    self.testValues[4]=-0.18
    self.testValues[5]=-0.06
    self.testValues[6]=-0.12
    self.testValues[7]=-0.12
    self.testValues[8]=-0.12
    self.testValues[9]=-0.12
    self.testValues[10]=-20
]]--
    end

function ssSnow:deleteMap()
end

function ssSnow:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssSnow:keyEvent(unicode, sym, modifier, isDown)
end

function ssSnow:draw()
end

function ssSnow:seasonChanged()
    log("Season changed into "..ssSeasonsUtil:seasonName())
end

function ssSnow:hourChanged()
    --[[
    -- Inject snow data.
    if self.testValue == 10 then
        self.testValue=1
    else
        self.testValue=self.testValue+1
    end
    local targetSnowDepth = self.testValues[self.testValue]
    ]]--

    local targetFromweatherSystem = ssWeatherManager:getSnowHeight() -- Fetch from weatersystem.
    local targetSnowDepth = math.min(0.48, targetFromweatherSystem) -- Target snow depth in meters. Never higher than 0.4

    -- print("-- Target Snowdept: " .. targetSnowDepth .. " Applied Snowdepth: " .. self.appliedSnowDepth);

    if self.appliedSnowDepth < 0 and targetSnowDepth > 0 then
        self.appliedSnowDepth = 0
    end

    -- Disable snow updates when unnecessary.
    if targetSnowDepth < -8 and self.updateSnow == true then
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
    if g_currentMission.terrainDetailHeightId ~= nil then
        local x,z, widthX,widthZ, heightX,heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

        extraMaskid = g_currentMission.terrainDetailId
        extraMaskFirstChannel = 0
        extraMaskNumchannels = 1

        -- Set snow type where we have no other heaps or painted areas on the map.
        setDensityMaskParams(extraMaskid, "greater", -1) -- noop until we use mask layers
        setDensityCompareParams(g_currentMission.terrainDetailHeightId, "equals", 0)
        setDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 0, 5, extraMaskid, extraMaskFirstChannel, extraMaskNumchannels, TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_SNOW]["index"])
        setDensityMaskParams(g_currentMission.terrainDetailHeightId, "greater", -1)
        setDensityCompareParams(g_currentMission.terrainDetailHeightId, "greater", -1)

        -- Add snow where type is snow.
        setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_SNOW]["index"])
        addDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 5, 6, g_currentMission.terrainDetailHeightId, 0, 5, layers)
        setDensityMaskParams(g_currentMission.terrainDetailHeightId, "greater", -1)
    end
end

local function removeSnow(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, layers)
    if g_currentMission.terrainDetailHeightId ~= nil then
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
end

function ssSnow:update(dt)
    if self.doAddSnow == true then
        self.currentX, self.currentZ, self.doAddSnow = ssSeasonsUtil:ssIterateOverTerrain(self.currentX, self.currentZ, addSnow, self.snowLayersDelta)
    elseif self.doRemoveSnow == true then
        self.currentX, self.currentZ, self.doRemoveSnow = ssSeasonsUtil:ssIterateOverTerrain(self.currentX, self.currentZ, removeSnow, self.snowLayersDelta)
    end
end
