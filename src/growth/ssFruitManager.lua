---------------------------------------------------------------------------------------------------------
-- Fruit Manager
---------------------------------------------------------------------------------------------------------
-- Purpose:  To adjust fruit properties
-- Authors:  theSeb
--

ssFruitManager = {}

ssFruitManager.harvestStagesUpdated = false

--blank function needed
function ssFruitManager:loadMap(name)
    self.fruitsToUpdate = {}
    self.fruitsToUpdate[FruitUtil.FRUITTYPE_POPLAR] = true
    self.fruitsToUpdate[FruitUtil.FRUITTYPE_OILSEEDRADISH] = true
    self.fruitsToUpdate[FruitUtil.FRUITTYPE_DRYGRASS] = true
    self.fruitsToUpdate[FruitUtil.FRUITTYPE_SUGARBEET] = true
    self.fruitsToUpdate[FruitUtil.FRUITTYPE_POTATO] = true
end

function ssFruitManager:update(dt)
    if not ssFruitManager.harvestStagesUpdated then
        self:updateHarvestStages()
        self.harvestStagesUpdated = true
    end
end

function ssFruitManager:updateHarvestStages()
    for index,fruit in pairs(g_currentMission.fruits) do
        local fruitName = FruitUtil.fruitIndexToDesc[index].name

        if self:fruitShouldBeUpdated(index) then
            -- Minimize the time a crop can be harvested (1 stage, not ~3)
            FruitUtil.fruitIndexToDesc[index].minHarvestingGrowthState = FruitUtil.fruitIndexToDesc[index].maxHarvestingGrowthState
        end
    end
end

function ssFruitManager:fruitShouldBeUpdated(index)
    return self.fruitsToUpdate[index] == true
end
