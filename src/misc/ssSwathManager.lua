----------------------------------------------------------------------------------------------------
-- SWATH MANAGER SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  To reduce swaths
-- Authors:  reallogger
-- (very much based on ssSnow so thank you mrbear)
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssSwathManager = {}

function ssSwathManager:load(savegame, key)
end

function ssSwathManager:save(savegame, key)
end

function ssSwathManager:loadMap(name)
    if g_currentMission:getIsServer() then
        g_seasons.environment:addTransitionChangeListener(self)
        g_currentMission.environment:addDayChangeListener(self)
        g_currentMission.environment:addHourChangeListener(self)

        g_seasons.dms:registerCallback("ssReduceGrass", self, self.reduceGrass)
        g_seasons.dms:registerCallback("ssReduceStrawHay", self, self.reduceStrawHay)
        g_seasons.dms:registerCallback("ssRemoveSwaths", self, self.removeSwaths)
    end
end

function ssSwathManager:reduceGrass(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, layers)
    layers = tonumber(layers)

    local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

    -- Reduce grass swaths
    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_GRASS_WINDROW].index)
    setDensityCompareParams(g_currentMission.terrainDetailHeightId, "greater", 0)

    addDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 5, 6, g_currentMission.terrainDetailHeightId, 0, 5, -layers)

    -- If height is 0, reset filltype
    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", 0)
    setDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 0, 5, g_currentMission.terrainDetailHeightId, 5, 6, 0)

    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "greater", -1)
    setDensityCompareParams(g_currentMission.terrainDetailHeightId, "greater", -1)
end

function ssSwathManager:reduceStrawHay(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, layers)
    layers = tonumber(layers)

    local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

    -- Reduce swaths where the windrow is straw
    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_STRAW].index)
    addDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 5, 6, g_currentMission.terrainDetailHeightId, 0, 5, -layers)

    -- Reduce swaths where the windrow is hay
    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_DRYGRASS_WINDROW].index)
    addDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 5, 6, g_currentMission.terrainDetailHeightId, 0, 5, -layers)

    -- If height is 0, reset filltype
    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", 0)
    setDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 0, 5, g_currentMission.terrainDetailHeightId, 5, 6, 0)

    -- Reset the params
    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "greater", -1)
end

function ssSwathManager:removeSwaths(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, layers)
    layers = tonumber(layers)

    local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

    -- Remove grass swaths
    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_GRASS_WINDROW].index)
    setDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 5, 6, g_currentMission.terrainDetailHeightId, 0, 5, 0)

    -- Reset filltype
    setDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 0, 5, g_currentMission.terrainDetailHeightId, 0, 5, 0)

    -- Reduce swaths where the windrow is straw
    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_STRAW].index)
    setDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 5, 6, g_currentMission.terrainDetailHeightId, 0, 5, 0)

    -- Reset filltype
    setDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 0, 5, g_currentMission.terrainDetailHeightId, 0, 5, 0)

    -- Reduce swaths where the windrow is hay
    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_DRYGRASS_WINDROW].index)
    setDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 5, 6, g_currentMission.terrainDetailHeightId, 0, 5, 0)

    -- Reset filltype
    setDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 0, 5, g_currentMission.terrainDetailHeightId, 0, 5, 0)

    -- Reset the params
    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "greater", -1)
end

function ssSwathManager:dayChanged()
    if g_currentMission:getIsServer() then
        --local reduceLayers = -1 / 3 * g_seasons.environment.daysInSeason + 5
        -- removing 1 layer each day
        g_seasons.dms:queueJob("ssReduceGrass", 1)
    end
end

function ssSwathManager:hourChanged()
    if g_currentMission:getIsServer() then
        if g_currentMission.environment.timeSinceLastRain < 60 then
            -- removing 1 layer if has been raining the last hour
            g_seasons.dms:queueJob("ssReduceStrawHay", 1)
        end
    end
end

function ssSwathManager:transitionChanged()
    if g_currentMission:getIsServer() then
        -- removing all swaths at beginning of winter
        if g_seasons.environment:transitionAtDay() == g_seasons.environment.TRANSITION_EARLY_WINTER then
            g_seasons.dms:queueJob("ssRemoveSwaths")
        else
            -- removing some every growth transition as it will rot if left too long on the ground
            g_seasons.dms:queueJob("ssReduceStrawHay", 1)
        end
    end
end
