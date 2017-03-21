---------------------------------------------------------------------------------------------------------
-- Fruit Manager
---------------------------------------------------------------------------------------------------------
-- Purpose:  To adjust fruit properties
-- Authors:  theSeb
--

ssFruitManager = {}

ssFruitManager.harvestStagesUpdated = false
ssFruitManager.fruitsToExclude = {}

function ssFruitManager:loadMap(name)
   
    self.fruitsToExclude[FruitUtil.FRUITTYPE_POPLAR] = true
    self.fruitsToExclude[FruitUtil.FRUITTYPE_OILSEEDRADISH] = true
    self.fruitsToExclude[FruitUtil.FRUITTYPE_DRYGRASS] = true
    self.fruitsToExclude[FruitUtil.FRUITTYPE_GRASS] = true
    self.fruitsToExclude[FruitUtil.FRUITTYPE_SUGARBEET] = true
    self.fruitsToExclude[FruitUtil.FRUITTYPE_POTATO] = true
end

function ssFruitManager:update(dt)
    if ssFruitManager.harvestStagesUpdated == false then
        self:updateHarvestStages()
        self.harvestStagesUpdated = true
    end
end

function ssFruitManager:updateHarvestStages()
    for index,fruit in pairs(g_currentMission.fruits) do
        local fruitName = FruitUtil.fruitIndexToDesc[index].name

        if self:fruitShouldBeUpdated(index) == true then
            -- Minimize the time a crop can be harvested (1 stage, not ~3)
            FruitUtil.fruitIndexToDesc[index].minHarvestingGrowthState = FruitUtil.fruitIndexToDesc[index].maxHarvestingGrowthState
        end
    end
end

function ssFruitManager:fruitShouldBeUpdated(index)
    return self.fruitsToExclude[index] ~= true
end
