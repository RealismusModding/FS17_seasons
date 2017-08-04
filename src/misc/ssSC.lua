----------------------------------------------------------------------------------------------------
-- SSC SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  To add sc
-- Authors:  
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssSC = {}
g_seasons.sc = ssSC

ssSC.cultivatorDecompactionValue = 1 --set to this value where compaction is greater

function ssSC:preLoad()
end

function ssSC:load(savegame, key)
end

function ssSC:save(savegame, key)
end

function ssSC:loadMap()
    Utils.cutFruitArea = Utils.overwrittenFunction(Utils.cutFruitArea, ssSC.updateCutFruitArea)
    Utils.updateCultivatorArea = Utils.overwrittenFunction(Utils.updateCultivatorArea, function(self, superFunc, x, z, x1, z1, x2, z2, limitToField, limitGrassDestructionToField, angle)
        ssSC.decompactCultivatorArea(self, x, z, x1, z1, x2, z2, limitToField)
        return superFunc(self, x, z, x1, z1, x2, z2, limitToField, limitGrassDestructionToField, angle)
    end)    
end

function ssSC:readStream(streamId, connection)
end

function ssSC:writeStream(streamId, connection)
end

function ssSC:updateCutFruitArea(superFunc, fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, destroySpray, destroySeedingWidth, useMinForageState)
    local tmpNumChannels = g_currentMission.ploughCounterNumChannels

    g_currentMission.ploughCounterNumChannels = 0
    local volume, area, sprayFactor, ploughFactor, growthState, growthStateArea = superFunc(self, fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, destroySpray, destroySeedingWidth, useMinForageState)
    g_currentMission.ploughCounterNumChannels = tmpNumChannels

    local densityC, areaC, _ = getDensityParallelogram(g_currentMission.terrainDetailId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, g_currentMission.ploughCounterFirstChannel, g_currentMission.ploughCounterNumChannels)
    local CLayers = densityC / areaC
    ploughFactor = 2 * CLayers - 5
    
    return volume, area, sprayFactor, ploughFactor, growthState, growthStateArea
end

function ssSC.decompactCultivatorArea(x, z, x1, z1, x2, z2, limitToField)
    local detailId = g_currentMission.terrainDetailId
    local compactFirstChannel = g_currentMission.ploughCounterFirstChannel
    local compactNumChannels = g_currentMission.ploughCounterNumChannels
    local x0, z0, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(detailId, x, z, x1, z1, x2, z2)

    -- Set compaction to decompaction value where compaction is greater
    setDensityCompareParams(detailId, "between", 0, ssSC.cultivatorDecompactionValue)
    setDensityMaskedParallelogram(
        detailId,
        x0, z0, widthX, widthZ, heightX, heightZ,
        compactFirstChannel, compactNumChannels,
        detailId,
        g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels,
        ssSC.cultivatorDecompactionValue
    )
    setDensityCompareParams(detailId, "greater", -1)
end
