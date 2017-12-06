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
end

function ssFruitManager:loadMapFinished()
    self:updateHarvestStates()
end

function ssFruitManager:updateHarvestStates()
    for index, fruit in pairs(g_currentMission.fruits) do
        local fruitName = FruitUtil.fruitIndexToDesc[index].name
        local desc = FruitUtil.fruitIndexToDesc[index]

        if self:fruitShouldBeUpdated(index) == true then
            if desc.minPreparingGrowthState == -1 then
                -- Minimize the time a crop can be harvested (1 state, not ~3)
                desc.minHarvestingGrowthState = desc.maxHarvestingGrowthState
            else
                -- Handle preparingGrowthState properly for sugarcane, sugarbeet and potatoes (and other similar fruits)
                desc.minPreparingGrowthState = desc.maxPreparingGrowthState
            end
        end
    end
end

function ssFruitManager:fruitShouldBeUpdated(index)
    return self.fruitsToExclude[index] ~= true
end
