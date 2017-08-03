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

function ssSC:preLoad()
end

function ssSC:load(savegame, key)
end

function ssSC:save(savegame, key)
end

function ssSC:loadMap()
    Utils.cutFruitArea = Utils.overwrittenFunction(Utils.cutFruitArea, ssSC.updateCutFruitArea)
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

    return volume, area, sprayFactor, ploughFactor, growthState, growthStateArea
end
