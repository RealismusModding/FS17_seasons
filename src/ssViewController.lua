---------------------------------------------------------------------------------------------------------
-- VIEW CONTROLLER SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  to manage info view
-- Authors:  theSeb
-- Credits: 

ssViewController = {}

ssViewController.canPlantDisplayData = {}
ssViewController.debugView = true

function ssViewController:loadMap(name)
    ssSeasonsMod:addGrowthStageChangeListener(self)
    g_currentMission.environment:addDayChangeListener(self)

    self:growthStageChanged()
    self:dayChanged()
    print_r(self.canPlantDisplayData)
end

function ssViewController:deleteMap()
end

function ssViewController:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssViewController:keyEvent(unicode, sym, modifier, isDown)
    --print(tostring(unicode))
end

function ssViewController:update(dt)
end


function ssViewController:draw()
    if self.debugView == true then
        renderText(0.54, 0.98, 0.01, "GM enabled: " .. tostring(ssGrowthManager.growthManagerEnabled) .. " doGrowthTransition: " .. tostring(ssGrowthManager.doGrowthTransition))
        local growthTransition = tostring(ssSeasonsUtil:currentGrowthTransition()
        renderText(0.54, 0.96, 0.01, "Growth Transition: " .. growthTransition))
        local cropsThatCanGrow = ""
        
        for index,fruit in pairs(g_currentMission.fruits) do
            local fruitName = FruitUtil.fruitIndexToDesc[index].name   
            if self:canPlantDisplayData[fruitName][growthTransition] == ssGrowthManager.TRUE then
                cropsThatCanGrow = cropsThatCanGrow .. fruitName .. " "
            end
        end 
        renderText(0.54, 0.94, 0.01, "Crops that will grow in next transtition if planted now: " .. cropsThatCanGrow)
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
