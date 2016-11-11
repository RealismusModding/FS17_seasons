---------------------------------------------------------------------------------------------------------
-- ECONOMY SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  To adjust the economy
-- Authors:  Jarvix
--

ssEconomy = {}
ssEconomy.lastUpdate = 0

function ssEconomy:loadMap(name)
    g_currentMission.ssEconomy = self

    g_currentMission.environment:addDayChangeListener(self);
end

function ssEconomy:deleteMap()
    g_currentMission.environment:removeDayChangeListener(self);
end

function ssEconomy:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssEconomy:keyEvent(unicode, sym, modifier, isDown)
end

function ssEconomy:draw()
end

function ssEconomy:update(dt)
end

function ssEconomy:dayChanged()
    logInfo("Day CHANGED");
end

addModEventListener(ssEconomy)
