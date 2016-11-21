---------------------------------------------------------------------------------------------------------
-- GROWTH MANAGER SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  to forecast the weather
-- Authors:  theSeb
-- Credits: Inspired by upsidedown's growth manager mod

ssGrowthManager = {};

function ssGrowthManager.preSetup()
end

function ssGrowthManager.setup()
    addModEventListener(ssGrowthManager);
end

function ssGrowthManager:loadMap(name)
    g_currentMission.environment:addDayChangeListener(self);
   self:handleSeason(); 
end

function ssGrowthManager:deleteMap()
end

function ssGrowthManager:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssGrowthManager:keyEvent(unicode, sym, modifier, isDown)
    if (unicode == 107) then
        log("Growth Manager debug");
    end
end

function ssGrowthManager:update(dt)
end

function ssGrowthManager:draw()
end

function ssGrowthManager:dayChanged()
    
end

function ssGrowthManager:handleSeason()
end
