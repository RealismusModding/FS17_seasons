----------------------------------------------------------------------------------------------------
-- Fruit Manager
----------------------------------------------------------------------------------------------------
-- Purpose:  To adjust fruit properties
-- Authors:  theSeb
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssFruitManager = {}

function ssFruitManager:loadMap(name)
    self.harvestStatesUpdated = false
    self.fruitsToExclude = {}

    self.fruitsToExclude[FruitUtil.FRUITTYPE_POPLAR] = true
    self.fruitsToExclude[FruitUtil.FRUITTYPE_OILSEEDRADISH] = true
    self.fruitsToExclude[FruitUtil.FRUITTYPE_DRYGRASS] = true
    self.fruitsToExclude[FruitUtil.FRUITTYPE_GRASS] = true
    self.fruitsToExclude[FruitUtil.FRUITTYPE_SUGARBEET] = true
    self.fruitsToExclude[FruitUtil.FRUITTYPE_POTATO] = true
end

function ssFruitManager:deleteMap()
    -- Reset min harvesting growth state
    for index, fruit in pairs(g_currentMission.fruits) do
        local item = FruitUtil.fruitIndexToDesc[index]

        if item.ssOriginalMinHarvestingGrowthState ~= nil then
            item.minHarvestingGrowthState = item.ssOriginalMinHarvestingGrowthState
        end

        if item.ssOriginalMinPreparingGrowthState ~= nil then
            item.minPreparingGrowthState = item.ssOriginalMinPreparingGrowthState
        end
    end
end

function ssFruitManager:loadMapFinished()
    self:updateHarvestStates()
end

function ssFruitManager:updateHarvestStates()
    for index, fruit in pairs(g_currentMission.fruits) do
        local desc = FruitUtil.fruitIndexToDesc[index]

        if self:fruitShouldBeUpdated(index) == true then
            -- Minimize the time a crop can be harvested (1 state, not ~3)
            if desc.ssOriginalMinHarvestingGrowthState == nil then
                desc.ssOriginalMinHarvestingGrowthState = desc.minHarvestingGrowthState
            end

            desc.minHarvestingGrowthState = desc.maxHarvestingGrowthState
        end

        -- Sugarcane is a very special fruit
        if index == FruitUtil.FRUITTYPE_SUGARCANE then
            desc.ssOriginalMinPreparingGrowthState = desc.minPreparingGrowthState

            desc.minPreparingGrowthState = desc.maxPreparingGrowthState
        end
    end
end

function ssFruitManager:fruitShouldBeUpdated(index)
    return self.fruitsToExclude[index] ~= true
end
