---------------------------------------------------------------------------------------------------------
-- VIEW CONTROLLER SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  to manage info view
-- Authors:  theSeb
-- Credits: 

ssViewController = {}

--currently for debug view only. this should probably go into ssSeasonsUtil and will need translations if we use it for the gui
ssViewController.growthTransitionIndexToName =
{
    [1] = "Early Spring",
    [2] = "Mid Spring",
    [3] = "Late Spring",
    [4] = "Early Summer",
    [5] = "Mid Summer",
    [6] = "Late Summer",
    [7] = "Early Autumn",
    [8] = "Mid Autumn",
    [9] = "Late Autumn",
    [10] = "Early Winter",
    [11] = "Mid Winter",
    [12] = "Late Winter"
}

ssViewController.canPlantDisplayData = {}
ssViewController.debugView = true

function ssViewController:loadMap(name)
    ssSeasonsMod:addGrowthStageChangeListener(self)
    g_currentMission.environment:addDayChangeListener(self)

    self:growthStageChanged()
    self:dayChanged()
    --print_r(self.growthTransitionIndexToName)
    --print(self.growthTransitionIndexToName[1])
    --print_r(self.canPlantDisplayData)
    --log("drygrass: " .. FruitUtil.fruitTypeGrowths["dryGrass"].name)
end

function ssViewController:deleteMap()
end

function ssViewController:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssViewController:keyEvent(unicode, sym, modifier, isDown)
    --print(tostring(unicode))
    if (unicode == 47) then
        if self.debugView == false then
            self.debugView = true
        else
            self.debugView = false
        end
    end
end

function ssViewController:update(dt)
end

function ssViewController:draw()
    if self.debugView == true then
        renderText(0.54, 0.98, 0.01, "GM enabled: " .. tostring(ssGrowthManager.growthManagerEnabled) .. " doGrowthTransition: " .. tostring(ssGrowthManager.doGrowthTransition))
        local growthTransition = ssSeasonsUtil:currentGrowthTransition()
        
        renderText(0.54, 0.96, 0.01, "Growth Transition: " .. growthTransition .. " " .. self.growthTransitionIndexToName[growthTransition])
        local cropsThatCanGrow = ""
        
        for index,fruit in pairs(g_currentMission.fruits) do
            local fruitName = FruitUtil.fruitIndexToDesc[index].name   
            
            if ssGrowthManager:canFruitGrow(fruitName, growthTransition, self.canPlantDisplayData) == true then
                cropsThatCanGrow = cropsThatCanGrow .. fruitName .. " "
            end
        end 
        renderText(0.54, 0.94, 0.01, "Crops that will grow in next transtition if planted now: " .. cropsThatCanGrow)
        renderText(0.54, 0.92, 0.01, "Soil temp: " .. tostring(ssWeatherManager.soilTemp))
    end
end

-- handle growthStageCHanged event
function ssViewController:growthStageChanged()
    --self.currentIndicator = ssSeasonsUtil:currentGrowthTransition()
end

-- handle hourChanged event
function ssViewController:dayChanged()
    local growthTransition = ssSeasonsUtil:currentGrowthTransition()
	
	if growthTransition == ssGrowthManager.FIRST_GROWTH_TRANSITION then  
        self:updateData()
	end
end

function ssViewController:updateData()
    self.canPlantDisplayData = Utils.copyTable(ssGrowthManager.canPlantData)
    for fruitName, transition in pairs(ssGrowthManager.canPlantData) do
        if transition[ssGrowthManager.FIRST_GROWTH_TRANSITION] == ssGrowthManager.MAYBE then
            self.canPlantDisplayData[fruitName][ssGrowthManager.FIRST_GROWTH_TRANSITION] = ssGrowthManager:boolToGMBool(ssWeatherManager:canSow())
        end
    end

end
function ssViewController:canSow() -- dummy function until it's implemented in WM
    return ssGrowthManager.TRUE
end


