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

function ssSwathManager:preLoad()
    g_seasons.swathManager = self
end

function ssSwathManager:loadMap(name)
    if g_currentMission:getIsServer() then
        g_currentMission.environment:addDayChangeListener(self)
        g_currentMission.environment:addHourChangeListener(self)

        g_seasons.dms:registerCallback("ssReduceGrass", self, self.reduceGrass, nil, true)
        g_seasons.dms:registerCallback("ssReduceStrawHay", self, self.reduceStrawHay, nil, true)
        g_seasons.dms:registerCallback("ssRemoveSwaths", self, self.removeSwaths, nil, true)
    end
end

function ssSwathManager:reduceGrass(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, layers)
    layers = tonumber(layers)

    local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

    -- Reduce grass swaths
    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_GRASS_WINDROW].index)

    local _, _, total, _ = addDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 5, 6, g_currentMission.terrainDetailHeightId, 0, 5, -layers)

    if total ~= 0 then
        -- If height is 0, reset filltype
        setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", 0)
        setDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 0, 5, g_currentMission.terrainDetailHeightId, 5, 6, 0)
    end

    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "greater", -1)
end

function ssSwathManager:reduceStrawHay(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, layers)
    layers = tonumber(layers)

    local changedPixels = false
    local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

    -- Reduce swaths where the windrow is straw
    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_STRAW].index)
    local _, _, total, _ = addDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 5, 6, g_currentMission.terrainDetailHeightId, 0, 5, -layers)
    if total ~= 0 then changedPixels = true end

    -- Reduce swaths where the windrow is hay
    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_DRYGRASS_WINDROW].index)
    local _, _, total, _ = addDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 5, 6, g_currentMission.terrainDetailHeightId, 0, 5, -layers)
    if total ~= 0 then changedPixels = true end

    -- If height is 0, reset filltype
    if changedPixels then
        setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", 0)
        setDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 0, 5, g_currentMission.terrainDetailHeightId, 5, 6, 0)
    end

    -- Reset the params
    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "greater", -1)
end

function ssSwathManager:removeSwaths(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, layers)
    layers = tonumber(layers)

    local changedPixels = false
    local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

    -- Remove grass swaths
    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_GRASS_WINDROW].index)
    local _, _, total, _ = setDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 5, 6, g_currentMission.terrainDetailHeightId, 0, 5, 0)
    if total ~= 0 then changedPixels = true end

    -- Reduce swaths where the windrow is straw
    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_STRAW].index)
    local _, _, total, _ = setDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 5, 6, g_currentMission.terrainDetailHeightId, 0, 5, 0)
    if total ~= 0 then changedPixels = true end

    -- Reduce swaths where the windrow is hay
    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_DRYGRASS_WINDROW].index)
    local _, _, total, _ = setDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 5, 6, g_currentMission.terrainDetailHeightId, 0, 5, 0)
    if total ~= 0 then changedPixels = true end

    if changedPixels then
        setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", 0)
        setDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 0, 5, g_currentMission.terrainDetailHeightId, 5, 6, 0)
    end

    -- Reset the params
    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "greater", -1)
end

function ssSwathManager:dayChanged()
    if g_currentMission:getIsServer() then
        g_seasons.dms:queueJob("ssReduceGrass", 1)
    end
end

function ssSwathManager:hourChanged()
    if g_currentMission:getIsServer() then
        if g_currentMission.environment.timeSinceLastRain < 60 then
            g_seasons.dms:queueJob("ssReduceStrawHay", 1)
        end
    end
end
