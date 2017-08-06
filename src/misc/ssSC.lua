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

ssSC.cultivatorDecompactionValue = 1 -- Set to this value where compaction is greater
ssSC.overlayColor = {} -- Additional colors for the compaction overlay (false/true: useColorblindMode)   
ssSC.overlayColor[false] =  {
                        {0.6172, 0.0510, 0.0510, 1},
                        {0.6400, 0.1710, 0.1710, 1},
                        {0.6672, 0.3333, 0.3333, 1},
                            }
ssSC.overlayColor[true] =   {
                        {0.6172, 0.0510, 0.0510, 1},
                        {0.6400, 0.1710, 0.1710, 1},
                        {0.6672, 0.3333, 0.3333, 1},
                            }

function ssSC:preLoad()
end

function ssSC:load(savegame, key)
end

function ssSC:save(savegame, key)
end

function ssSC:loadMap()
    InGameMenu.generateFruitOverlay = Utils.overwrittenFunction(InGameMenu.generateFruitOverlay, ssSC.generateFruitOverlay)
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

-- Draw all the different states of compaction in overlay menu
function ssSC:generateFruitOverlay(superFunc)

    -- If ploughing overlay is selected we override everything being drawn
    if self.mapNeedsPlowing and self.mapSelectorMapping[self.mapOverviewSelector:getState()] == InGameMenu.MAP_SOIL then
        if g_currentMission ~= nil and g_currentMission.terrainDetailId ~= 0 then

            -- Begin draw foliage state overlay
            resetFoliageStateOverlay(self.foliageStateOverlay)

            local colors = ssSC.overlayColor[g_gameSettings:getValue("useColorblindMode")];
            local maxSCLayer = bitShiftLeft(1, g_currentMission.ploughCounterNumChannels)-1;
            for level=1,maxSCLayer do
                local color = colors[math.min(level, #colors)];
                setFoliageStateOverlayGroundStateColor(self.foliageStateOverlay, g_currentMission.terrainDetailId, bitShiftLeft(bitShiftLeft(1, g_currentMission.terrainDetailTypeNumChannels)-1, g_currentMission.terrainDetailTypeFirstChannel), g_currentMission.ploughCounterFirstChannel, g_currentMission.ploughCounterNumChannels, level-1, color[1], color[2], color[3]);
            end

            -- End draw foliage state overlay
            generateFoliageStateOverlay(self.foliageStateOverlay)
            self.foliageStateOverlayIsReady = false;
            self.dynamicMapImageLoading:setVisible(true)
            self:checkFoliageStateOverlayReady()
        end
    -- Else if ploughing is not selected use vanilla functionality
    else 
        superFunc(self)
    end
end
