----------------------------------------------------------------------------------------------------
-- Fruit Manager
----------------------------------------------------------------------------------------------------
-- Purpose:  To adjust fruit properties
-- Authors:  theSeb
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssFruitManager = {}

ssFruitManager.harvestStatesUpdated = false
ssFruitManager.fruitsToExclude = {}

function ssFruitManager:loadMap(name)
    self.fruitsToExclude[FruitUtil.FRUITTYPE_POPLAR] = true
    self.fruitsToExclude[FruitUtil.FRUITTYPE_OILSEEDRADISH] = true
    self.fruitsToExclude[FruitUtil.FRUITTYPE_DRYGRASS] = true
    self.fruitsToExclude[FruitUtil.FRUITTYPE_GRASS] = true
    self.fruitsToExclude[FruitUtil.FRUITTYPE_SUGARBEET] = true
    self.fruitsToExclude[FruitUtil.FRUITTYPE_POTATO] = true
end

-- function ssFruitManager:update(dt)
--     if ssFruitManager.harvestStatesUpdated == false then
--         self:updateHarvestStates()
--         self.harvestStatesUpdated = true
--     end
-- end

function ssFruitManager:loadMapFinished()
    self:updateHarvestStates()
end

function ssFruitManager:updateHarvestStates()
    for index, fruit in pairs(g_currentMission.fruits) do
        local fruitName = FruitUtil.fruitIndexToDesc[index].name
        local desc = FruitUtil.fruitIndexToDesc[index]

        if self:fruitShouldBeUpdated(index) == true then
            -- Minimize the time a crop can be harvested (1 state, not ~3)
            desc.minHarvestingGrowthState = desc.maxHarvestingGrowthState
        end

        -- Sugarcane is a very special fruit
        if index == FruitUtil.FRUITTYPE_SUGARCANE then
            desc.minPreparingGrowthState = desc.maxPreparingGrowthState
        end
    end
end

function ssFruitManager:fruitShouldBeUpdated(index)
    return self.fruitsToExclude[index] ~= true
end
