---------------------------------------------------------------------------------------------------------
-- VIEW CONTROLLER SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  to manage info view
-- Authors:  theSeb
-- Credits: 

ssViewController = {}


function ssViewController:loadMap(name)
    ssSeasonsMod:addGrowthStageChangeListener(self)
    g_currentMission.environment:addDayChangeListener(self)
    self:hourChanged();
    self:dayChanged();
    print_r(ssGrowthManager.canPlantData)
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
		if self:canSow() then
			 ssGrowthManager.canPlantData[ssGrowthManager.FIRST_GROWTH_TRANSITION] = "true"
		else
			 ssGrowthManager.canPlantData[ssGrowthManager.FIRST_GROWTH_TRANSITION] = "false"
		end	
	end
end

function ssViewController:canSow() -- dummy function until it's implemented in WM
    return true
end
