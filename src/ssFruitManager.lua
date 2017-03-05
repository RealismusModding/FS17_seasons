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
        if index != FruitUtil.FRUITTYPE_POPLAR and index != FruitUtil.FRUITTYPE_OILSEEDRADISH and index != FruitUtil.FRUITTYPE_DRYGRASS
                and index != FruitUtil.FRUITTYPE_SUGARBEET and index != FruitUtil.FRUITTYPE_POTATO then
            FruitUtil.fruitIndexToDesc[index].minHarvestingGrowthState = FruitUtil.fruitIndexToDesc[index].maxHarvestingGrowthState
        end
    end
end



