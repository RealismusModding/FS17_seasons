---------------------------------------------------------------------------------------------------------
-- VIEW CONTROLLER SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  to manage info view
-- Authors:  theSeb
-- Credits: 

ssViewController = {}

ssViewController.canPlantDisplayData = {}

function ssViewController:loadMap(name)
    ssSeasonsMod:addGrowthStageChangeListener(self)
    g_currentMission.environment:addDayChangeListener(self)
    self:growthStageChanged();
    self:dayChanged();
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
end

-- handle growthStageCHanged event
function ssViewController:growthStageChanged()
    --self.currentIndicator = ssSeasonsUtil:currentGrowthTransition()
end

-- handle hourChanged event
function ssViewController:dayChanged()
    local growthTransition = ssSeasonsUtil:currentGrowthTransition();
	
	if growthTransition == ssGrowthManager.FIRST_GROWTH_TRANSITION then  
		self:updateData()
	end
end

function ssViewController:updateData()
    self.canPlantDisplayData = Utils.copyTable(ssGrowthManager.canPlantData)
    for fruitName, transition in pairs(ssGrowthManager.canPlantData) do
        if transition[ssGrowthManager.FIRST_GROWTH_TRANSITION] == "maybe" then
            log("here")
            self.canPlantDisplayData[fruitName][transition] = self:canSow()        
        end
    end

end
function ssViewController:canSow() -- dummy function until it's implemented in WM
    return "true"
end
