---------------------------------------------------------------------------------------------------------
-- SWATH MANAGER SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  To reduce swaths
-- Authors:  reallogger
-- (very much based on ssSnow so thank you mrbear)
--

ssSwathManager = {}

function ssSwathManager:load(savegame, key)
end

function ssSwathManager:save(savegame, key)
end

function ssSwathManager:loadMap(name)
    g_seasons.environment:addGrowthStageChangeListener(self)
    g_currentMission.environment:addDayChangeListener(self)

    if g_currentMission:getIsServer() == true then
        ssDensityMapScanner:registerCallback("ssSwathManagerReduceSwaths", self, self.reduceSwaths)
    end
end

function ssSwathManager:reduceSwaths(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, layers)
    layers = tonumber(layers)
    local x,z, widthX,widthZ, heightX,heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

    -- Remove grass swaths
    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_GRASS_WINDROW]["index"])
    setDensityCompareParams(g_currentMission.terrainDetailHeightId, "greater", 0)
    addDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 5, 6, g_currentMission.terrainDetailHeightId, 0, 5, -layers)
    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "greater", -1)
    setDensityCompareParams(g_currentMission.terrainDetailHeightId, "greater", -1)

    if ssSnow.snowMaskId ~= nil then
        -- FIXME: The snow mask does not work so at present swaths that are both inside and outside are reduced

        -- Remove straw swaths that are outside (the mask)
        setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", 0)
        setDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 0, 5, self.snowMaskId, ssSnow.SNOW_MASK_FIRST_CHANNEL, ssSnow.SNOW_MASK_NUM_CHANNELS, TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_STRAW]["index"])
        setDensityMaskParams(g_currentMission.terrainDetailHeightId, "greater", -1)
            
        setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_STRAW]["index"])
        addDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 5, 6, g_currentMission.terrainDetailHeightId, 0, 5, -layers)
        setDensityMaskParams(g_currentMission.terrainDetailHeightId, "greater", -1)

        -- Remove hay swaths that are outside (the mask)
        setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", 0)
        setDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 0, 5, self.snowMaskId, ssSnow.SNOW_MASK_FIRST_CHANNEL, ssSnow.SNOW_MASK_NUM_CHANNELS, TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_DRYGRASS_WINDROW]["index"])
        setDensityMaskParams(g_currentMission.terrainDetailHeightId, "greater", -1)
            
        setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_DRYGRASS_WINDROW]["index"])
        addDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 5, 6, g_currentMission.terrainDetailHeightId, 0, 5, -layers)
        setDensityMaskParams(g_currentMission.terrainDetailHeightId, "greater", -1)


    else
        -- if no mask then reduce straw and dryGrass (hay)
        setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_STRAW]["index"])
        setDensityCompareParams(g_currentMission.terrainDetailHeightId, "greater", 0)
        addDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 5, 6, g_currentMission.terrainDetailHeightId, 0, 5, -layers)
        setDensityMaskParams(g_currentMission.terrainDetailHeightId, "greater", -1)
        setDensityCompareParams(g_currentMission.terrainDetailHeightId, "greater", -1) 

        setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_DRYGRASS_WINDROW]["index"])
        setDensityCompareParams(g_currentMission.terrainDetailHeightId, "greater", 0)
        addDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 5, 6, g_currentMission.terrainDetailHeightId, 0, 5, -layers)
        setDensityMaskParams(g_currentMission.terrainDetailHeightId, "greater", -1)
        setDensityCompareParams(g_currentMission.terrainDetailHeightId, "greater", -1) 

    end
end

function ssSwathManager:dayChanged()
    if g_currentMission:getIsServer() then
        ssDensityMapScanner:queueJob("ssSwathManagerReduceSwaths", 1)
    end
end

function ssSwathManager:growthStageChanged()
    if g_currentMission:getIsServer() then
        -- removing all swaths at beginning of winter
        if g_seasons.environment:growthTransitionAtDay() == 10 then
            ssDensityMapScanner:queueJob("ssSwathManagerReduceSwaths", 64)
        end
    end
end

