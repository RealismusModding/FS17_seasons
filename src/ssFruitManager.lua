---------------------------------------------------------------------------------------------------------
-- Fruit Manager
---------------------------------------------------------------------------------------------------------
-- Purpose:  To adjust fruit properties
-- Authors:  theSeb
--

ssFruitManager = {}

ssFruitManager.harvestStagesUpdated = false

function ssFruitManager:update(dt)
    if ssFruitManager.harvestStagesUpdated == false then
        self:updateHarvestStages()
        self.harvestStagesUpdated = true
    end    
end

function ssFruitManager:updateHarvestStages()
    for index,fruit in pairs(g_currentMission.fruits) do
        local fruitName = FruitUtil.fruitIndexToDesc[index].name
        print_r(fruit)    
    end
end



