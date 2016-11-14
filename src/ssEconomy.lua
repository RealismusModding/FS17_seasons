---------------------------------------------------------------------------------------------------------
-- ECONOMY SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  To adjust the economy
-- Authors:  Jarvix
--

ssEconomy = {}
ssEconomy.aiPricePerHour = 2000;

function ssEconomy:loadMap(name)
    g_currentMission.ssEconomy = self

    g_currentMission.environment:addDayChangeListener(self);

    self:fixHiredWorkerWages();
end

function ssEconomy:deleteMap()
    self:unfixHiredWorkerWages();
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
end

function ssEconomy:fixHiredWorkerWages()
    -- Change hired worker costs by hacking the xml function
    local origGetXMLFloat = getfenv(0)["getXMLFloat"];
    self._origGetXMLFloat = origGetXMLFloat;

    local function newGetXMLFloat(file, prop)
        if prop == "vehicle.ai.pricePerHour" then
            return ssEconomy.aiPricePerHour;
        end

        return origGetXMLFloat(file, prop);
    end

    getfenv(0)["getXMLFloat"] = newGetXMLFloat;
end

function ssEconomy:unfixHiredWorkerWages()
    getfenv(0)["getXMLFloat"] = self._origGetXMLFloat;
end


addModEventListener(ssEconomy)
