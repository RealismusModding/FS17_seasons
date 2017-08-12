----------------------------------------------------------------------------------------------------
-- SSC SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  To add sc
-- Authors:  baron, reallogger
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssSC = {}
g_seasons.soilCompaction = ssSC

ssSC.superFunc = {} -- To store function pointers in Utils that we intend to overwrite
ssSC.cultivatorDecompactionDelta = 1 -- Cultivators additive effect on the compaction layer
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
    self.compactionEnabled = ssXMLUtil.getBool(savegame, key .. ".settings.soilCompactionEnabled", true)
end

function ssSC:save(savegame, key)
    ssXMLUtil.setBool(savegame, key .. ".settings.soilCompactionEnabled", self.compactionEnabled)
end

function ssSC:loadMap()
    -- Overwritten functions
    InGameMenu.generateFruitOverlay = Utils.overwrittenFunction(InGameMenu.generateFruitOverlay, ssSC.generateFruitOverlay)

    Utils.cutFruitArea = ssUtil.overwrittenStaticFunction(Utils.cutFruitArea, ssSC.cutFruitArea)
    Utils.updateCultivatorArea = ssUtil.overwrittenStaticFunction(Utils.updateCultivatorArea, ssSC.updateCultivatorArea)
end

function ssSC:readStream(streamId, connection)
    self.compactionEnabled = streamReadBool(streamId)
end

function ssSC:writeStream(streamId, connection)
    streamWriteBool(streamId, self.compactionEnabled)
end

function ssSC.cutFruitArea(superFunc, fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, destroySpray, destroySeedingWidth, useMinForageState)
    local tmpNumChannels = g_currentMission.ploughCounterNumChannels

    g_currentMission.ploughCounterNumChannels = 0
    local volume, area, sprayFactor, ploughFactor, growthState, growthStateArea = superFunc(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, destroySpray, destroySeedingWidth, useMinForageState)
    g_currentMission.ploughCounterNumChannels = tmpNumChannels

    local x0, z0, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(detailId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    local densityC, areaC, _ = getDensityParallelogram(g_currentMission.terrainDetailId, x0, z0, widthX, widthZ, heightX, heightZ, g_currentMission.ploughCounterFirstChannel, g_currentMission.ploughCounterNumChannels)
    local CLayers = densityC / areaC
    ploughFactor = 2 * CLayers - 5

    if fruitId == FruitUtil.FRUITTYPE_GRASS then
      local sprayRatio = g_currentMission.harvestSprayScaleRatio
      local ploughRatio = g_currentMission.harvestPloughScaleRatio
      local oldPloughFactor = ploughFactor

      ploughFactor = (1 + oldPloughFactor * ploughRatio + sprayFactor * sprayRatio) / (1 + ploughRatio + sprayFactor * sprayRatio)
      volume = volume * ploughFactor
    end

    return volume, area, sprayFactor, ploughFactor, growthState, growthStateArea
end

function ssSC.updateCultivatorArea(superFunc, x, z, x1, z1, x2, z2, ...)
    local detailId = g_currentMission.terrainDetailId
    local compactFirstChannel = g_currentMission.ploughCounterFirstChannel
    local compactNumChannels = g_currentMission.ploughCounterNumChannels
    local x0, z0, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(detailId, x, z, x1, z1, x2, z2)

    -- Apply decompaction delta where ground is field but not yet cultivated
    setDensityMaskParams(detailId, "greater", g_currentMission.cultivatorValue);
    setDensityCompareParams(detailId, "greater", 0)
    addDensityMaskedParallelogram(
        detailId,
        x0, z0, widthX, widthZ, heightX, heightZ,
        compactFirstChannel, compactNumChannels,
        detailId,
        g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels,
        ssSC.cultivatorDecompactionDelta
    )
    setDensityMaskParams(detailId, "greater", 0)
    setDensityCompareParams(detailId, "greater", -1)

    return superFunc(x, z, x1, z1, x2, z2, ...)
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
