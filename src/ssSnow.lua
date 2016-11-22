---------------------------------------------------------------------------------------------------------
-- SCRIPT TO ADD PHYSICAL SNOW LAYERS
---------------------------------------------------------------------------------------------------------
-- Purpose:  to create plowable snow on the ground
-- Authors:  mrbear
--

ssSnow = {};

function ssSnow.preSetup()
end

function ssSnow.setup()
    addModEventListener(ssSnow)
end

function ssSnow:loadMap(name)
    -- Register Snow as a fill and Tip type
    FillUtil.registerFillType("snow",  g_i18n:getText("fillType_snow"), FillUtil.FILLTYPE_CATEGORY_BULK, 0,  false,  "dataS2/menu/hud/fillTypes/hud_fill_straw.png", "dataS2/menu/hud/fillTypes/hud_fill_straw_sml.png", 0.0002* 0.5, math.rad(50));
    TipUtil.registerDensityMapHeightType(FillUtil.FILLTYPE_SNOW, math.rad(35), 0.8, 0.10, 0.10, 1.20, 3, true, ssSeasonsMod.modDir .. "resources/snow_diffuse.dds", ssSeasonsMod.modDir .. "resources/snow_normal.dds", ssSeasonsMod.modDir .. "resources/snowDistance_diffuse.dds");

    -- General initalization
    g_currentMission.environment:addHourChangeListener(self);
    if g_currentMission.missionInfo.timeScale > 120 then
        self.mapSegments = 1; -- Not enought time to do it section by section since it might be called every two hour as worst case.
    else
        self.mapSegments = 16; -- Must be evenly dividable with mapsize.
    end

    self.doAddSnow = false; -- Should we currently be running a loop to add Snow on the map.
    self.currentX = 0; -- The row that we are currently updating
    self.currentZ = 0; -- The column that we are currently updating
    self.addedSnowForCurrentSnowfall = false; -- Have we already added snow for the current snowfall?

end

function ssSnow:deleteMap()
end

function ssSnow:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssSnow:keyEvent(unicode, sym, modifier, isDown)
end

function ssSnow:update(dt)
    if self.doAddSnow == true then

        print("Updating snow for: " .. self.currentX .. ", " .. self.currentZ );

        local startWorldX =  self.currentX * g_currentMission.terrainSize / self.mapSegments - g_currentMission.terrainSize / 2;
        local startWorldZ =  self.currentZ * g_currentMission.terrainSize / self.mapSegments - g_currentMission.terrainSize / 2;
        local widthWorldX = startWorldX + g_currentMission.terrainSize / self.mapSegments - 0.1; -- -0.1 to avoid overlap.
        local widthWorldZ = startWorldZ;
        local heightWorldX = startWorldX;
        local heightWorldZ = startWorldZ + g_currentMission.terrainSize / self.mapSegments - 0.1; -- -0.1 to avoid overlap.

        print("- " .. startWorldX .. ", " .. startWorldZ .. ", " .. widthWorldX .. ", " .. widthWorldZ .. ", " .. heightWorldX .. ", " .. heightWorldZ );

        ssSnow:addSnow(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ);

        if self.currentZ < self.mapSegments - 1 then -- Starting with column 0 So index of last column is one less then the number of columns.
            -- Next column
            self.currentZ = self.currentZ + 1;
        elseif  self.currentX < self.mapSegments - 1 then -- Starting with row 0
            -- Next row
            self.currentX = self.currentX + 1;
            self.currentZ = 0;
        else
            -- Done with the loop, set up for the next one.
            self.currentX = 0;
            self.currentZ = 0;
            self.doAddSnow = false;
        end
    end
end

function ssSnow:draw()
end

function ssSnow:hourChanged()
    if g_currentMission.environment.currentRain ~= nil then
        -- ChangeMe Change to Environment.RAINTYPE_HAIL when we get weathercontrol working. Rain is easier to provoke for testing.
        if self.addedSnowForCurrentSnowfall == false and g_currentMission.environment.currentRain.rainTypeId == Environment.RAINTYPE_RAIN then
            self.addedSnowForCurrentSnowfall = true;
            self.doAddSnow = true;
        end
    else
        self.addedSnowForCurrentSnowfall = false;
    end
end

function ssSnow:addSnow(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    if g_currentMission.terrainDetailHeightId ~= nil then
        extraMaskid = g_currentMission.terrainDetailId; -- g_currentMission.terrainDetailId
        extraMaskFirstChannel = 0;
        extraMaskNumchannels = 1;

        -- Set snow type where we have no other heaps or painted areas on the map.
        local x,z, widthX,widthZ, heightX,heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ);
        setDensityMaskParams(extraMaskid,"equals",0);
        setDensityCompareParams(g_currentMission.terrainDetailHeightId, "equals",0);
        setDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 0, 5, extraMaskid, extraMaskFirstChannel, extraMaskNumchannels, 21);
        setDensityMaskParams(g_currentMission.terrainDetailHeightId, "greater", -1);
        setDensityCompareParams(g_currentMission.terrainDetailHeightId, "greater", -1);

        -- Add snow where type is snow.
        setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", 21);
        addDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 5, 6, g_currentMission.terrainDetailHeightId, 0, 5, 1);
        setDensityMaskParams(g_currentMission.terrainDetailHeightId, "greater", -1);
    end
end
