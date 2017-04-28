----------------------------------------------------------------------------------------------------
-- ssCropDestruction
----------------------------------------------------------------------------------------------------
-- Purpose:  To fix the incompatibility issue with CropDestruction mod
-- Authors:  theSeb
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssCropDestruction = {}

function ssCropDestruction:loadMap(name)
    if not g_modIsLoaded["FS17_ForRealModule01_CropDestruction"] then return end

    local cdMod = getfenv(0)["FS17_ForRealModule01_CropDestruction"]
    if cdMod ~= nil and cdMod.CropDestruction ~= nil then
        logInfo("ssCropDestruction:", "Crop Destruction mod found. Modifying...")
        cdMod.CropDestruction.destroyFruitArea = Utils.overwrittenFunction(cdMod.CropDestruction.destroyFruitArea, self.seasonsDestroyFruitArea)
    end
end

function ssCropDestruction:seasonsDestroyFruitArea(superFunc, x0, z0, x1, z1, x2, z2)
    local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(nil, x0, z0, x1, z1, x2, z2);

    for index, entry in pairs(g_currentMission.fruits) do

        local desc = FruitUtil.fruitIndexToDesc[index];
        if desc.allowsSeeding then
            local detailId = g_currentMission.terrainDetailId;

            if desc.preparingOutputName ~= nil and entry.preparingOutputId ~= nil then
                setDensityCompareParams(entry.preparingOutputId, "greater", -1);
                setDensityMaskParams(entry.id, "between", 2, desc.maxPreparingGrowthState + 1);
                setDensityMaskedParallelogram(entry.preparingOutputId, x, z, widthX, widthZ, heightX, heightZ, 0, 1, entry.id, 0, g_currentMission.numFruitStateChannels, 1);
                setDensityCompareParams(entry.preparingOutputId, "greater", -1);
                setDensityMaskParams(entry.id, "greater", 0);

                setDensityCompareParams(entry.id, "between", 2, desc.maxPreparingGrowthState + 1);
                setDensityParallelogram(entry.id, x, z, widthX, widthZ, heightX, heightZ, 0, g_currentMission.numFruitStateChannels, desc.cutState + 1);
                setDensityCompareParams(entry.id, "greater", -1);
            elseif index == FruitUtil.FRUITTYPE_GRASS then --desc.cutState < desc.minHarvestingGrowthState then
                -- grass
                setDensityCompareParams(entry.id, "between", desc.minHarvestingGrowthState + 1, desc.maxHarvestingGrowthState + 1);
                setDensityParallelogram(entry.id, x, z, widthX, widthZ, heightX, heightZ, 0, g_currentMission.numFruitStateChannels, desc.cutState + 2);
                setDensityCompareParams(entry.id, "greater", -1);
            elseif index == FruitUtil.FRUITTYPE_OILSEEDRADISH then  --desc.minHarvestingGrowthState == desc.maxHarvestingGrowthState then
                -- oilseed, no destruction
            else
                -- all other/normal fruits
                setDensityCompareParams(entry.id, "greater", 2);
                setDensityMaskedParallelogram(entry.id, x, z, widthX, widthZ, heightX, heightZ, 0, g_currentMission.numFruitDensityMapChannels, detailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, desc.cutState + 1);
                setDensityCompareParams(entry.id, "greater", -1); 
            end
        end
    end
end
