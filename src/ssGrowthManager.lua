---------------------------------------------------------------------------------------------------------
-- GROWTH MANAGER SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  to manage growth as the season changes
-- Authors:  theSeb
-- Credits: Inspired by upsidedown's growth manager mod

ssGrowthManager = {};

function ssGrowthManager:loadMap(name)
    g_currentMission.environment:addDayChangeListener(self);
    ssSeasonsMod:addSeasonChangeListener(self);

    log("Growth manager loading");
   self:seasonChanged();
end

function ssGrowthManager:deleteMap()
end

function ssGrowthManager:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssGrowthManager:keyEvent(unicode, sym, modifier, isDown)
    if (unicode == 107) then
        log("Growth Manager debug");
        self:seasonChanged();
    end
end

function ssGrowthManager:update(dt)
end

function ssGrowthManager:draw()
end

function ssGrowthManager:dayChanged()
end

function ssGrowthManager:seasonChanged()
    local currentSeason = ssSeasonsUtil:seasonName();
    log("Today's season:" .. currentSeason);
    log("Today's season number:" .. ssSeasonsUtil:season());

    local funcTable =
    {
        [0] = self.handleSpring,
        [1] = self.handleAutumn,
        [2] = self.handleWinter,
        [3] = self.handleSummer,
    }

    local func = funcTable[ssSeasonsUtil:season()];

    if (func) then
        func();
    else
        log("GrowthManager: Fatal error. Season not found");
    end
end

function ssGrowthManager:scanWorld()
    log("Scanning world");
end

function ssGrowthManager:handleSpring()
    log("Handling spring");
end

function ssGrowthManager:handleAutumn()
    log("Handling autumn");
end

function ssGrowthManager:handleWinter()
    log("Handling winter");
end

function ssGrowthManager:handleSummer()
    log("Handling summer");
end
