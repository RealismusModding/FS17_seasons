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
    g_currentMission.environment:addHourChangeListener(self)

end

function ssSwathManager:reduceGrass(layers) 
    layers = tonumber(layers)

    local startWorldX = 0
    local startWorldZ = 0
    local widthWorldX = g_currentMission.terrainSize
    local widthWorldZ = 0
    local heightWorldX = 0
    local heightWorldZ = g_currentMission.terrainSize

    local x,z, widthX,widthZ, heightX,heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

    -- Reduce grass swaths
    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_GRASS_WINDROW]["index"])
    setDensityCompareParams(g_currentMission.terrainDetailHeightId, "greater", 0)
    addDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 5, 6, g_currentMission.terrainDetailHeightId, 0, 5, -layers)
    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "greater", -1)
    setDensityCompareParams(g_currentMission.terrainDetailHeightId, "greater", -1)

end

function ssSwathManager:reduceStrawHay(layers)
    layers = tonumber(layers)

    local startWorldX = 0
    local startWorldZ = 0
    local widthWorldX = g_currentMission.terrainSize
    local widthWorldZ = 0
    local heightWorldX = 0
    local heightWorldZ = g_currentMission.terrainSize

    local x,z, widthX,widthZ, heightX,heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

    -- Reduce straw swaths
    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_STRAW]["index"])
    setDensityCompareParams(g_currentMission.terrainDetailHeightId, "greater", 0)
    addDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 5, 6, g_currentMission.terrainDetailHeightId, 0, 5, -layers)
    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "greater", -1)
    setDensityCompareParams(g_currentMission.terrainDetailHeightId, "greater", -1)

    -- Reduce hay (dry grass) swaths
    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_DRYGRASS_WINDROW]["index"])
    setDensityCompareParams(g_currentMission.terrainDetailHeightId, "greater", 0)
    addDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 5, 6, g_currentMission.terrainDetailHeightId, 0, 5, -layers)
    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "greater", -1)
    setDensityCompareParams(g_currentMission.terrainDetailHeightId, "greater", -1)
end

function ssSwathManager:dayChanged()
    if g_currentMission:getIsServer() then
<<<<<<< HEAD
        ssDensityMapScanner:queueJob("ssSwathManagerReduceSwaths", 1)
=======
        --local reduceLayers = -1/3 * g_seasons.environment.daysInSeason + 5
        -- removing 1 layer each day
        self:reduceGrass(1)
    end
end

function ssSwathManager:hourChanged()
    if g_currentMission:getIsServer() then
        if g_currentMission.environment.timeSinceLastRain < 60 then
            -- removing 1 layer if has been raining the last hour
            self:reduceStrawHay(1)
        end
>>>>>>> master
    end
end

function ssSwathManager:growthStageChanged()
    if g_currentMission:getIsServer() then
        -- removing all swaths at beginning of winter
<<<<<<< HEAD
        if g_seasons.environment:growthTransitionAtDay() == 10 then
            ssDensityMapScanner:queueJob("ssSwathManagerReduceSwaths", 64)
=======
        if g_seasons.environment:currentGrowthTransition() == 10 then
            self:reduceGrass(64)
            self:reduceStrawHay(64)
        else
            -- removing some every growth transition as it will rot if left too long on the ground
            self:reduceStrawHay(1)
>>>>>>> master
        end
    end
end

