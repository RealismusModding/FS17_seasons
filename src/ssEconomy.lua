---------------------------------------------------------------------------------------------------------
-- ECONOMY SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  To adjust the economy
-- Authors:  Rahkiin (Jarvixes)
--

ssEconomy = {}
ssEconomy.aiPricePerHour = 2000
ssEconomy.loanMax = 5000000
ssEconomy.baseLoadInterest = 6 -- For normal, % each season. *4 for yearly
ssEconomy.settingsProperties = { "aiPricePerHour", "loanMax", "baseLoadInterest" }


function ssEconomy.preSetup()
    ssSettings.add("economy", ssEconomy)
end

function ssEconomy.setup()
    ssSettings.load("economy", ssEconomy)

    addModEventListener(ssEconomy)
end

function ssEconomy:loadMap(name)
    g_currentMission.environment:addDayChangeListener(self);

    self:fixHiredWorkerWages();

    g_currentMission.missionStats.loanMax = ssEconomy.loanMax
    g_currentMission.missionStats.ssLoan = 0
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
    local stats = g_currentMission.missionStats

    if stats.ssLoan ~= stats.loan then
        self:calculateLoanInterestRate()
        stats.ssLoan = stats.loan
    end
end

function ssEconomy:calculateLoanInterestRate()
    -- local stats = g_currentMission.missionStats
    local seasonInterest = ssEconomy.baseLoadInterest * g_currentMission.missionInfo.difficulty

    local dailyInterest = (seasonInterest / 2) / ssSeasonsUtil.daysInSeason

    g_currentMission.missionStats.loanAnnualInterestRate = dailyInterest * 357
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


-- logInfo("LIFETIME_OPERATINGTIME_RATIO " .. tostring(EconomyManager.LIFETIME_OPERATINGTIME_RATIO))
-- logInfo("MAX_DAILYUPKEEP_MULTIPLIER " .. tostring(EconomyManager.MAX_DAILYUPKEEP_MULTIPLIER))
--[[
CONFIG_CHANGE_PRICE
PRICE_MULTIPLIER
LIFETIME_OPERATINGTIME_RATIO
MAX_DAILYUPKEEP_MULTIPLIER
PRICE_DROP_MIN_PERCENT
PER_DAY_LEASING_FACTOR
DIRECT_SELL_MULTIPLIER
COST_MULTIPLIER
DEFAULT_LEASING_DEPOSIT_FACTOR
MAX_GREAT_DEMANDS

MONEY_TYPE_PROPERTY_INCOME
MONEY_TYPE_VEHICLE_RUNNING_COSTS
MONEY_TYPE_PROPERTY_MAINTENANCE
MONEY_TYPE_ANIMAL_UPKEEP
MONEY_TYPE_LOAN_INTEREST
MONEY_TYPE_LEASING_COSTS


getPricePerLiter
getPriceMultiplier
--]]

--[[for k in pairs(StoreItemsUtil) do
    print(k)
end

for k,v in pairs(StoreItemsUtil.storeItems) do
    print(k .. ": ")
    print_r(v)
end
--]]
--getCosts
--local storeItem = StoreItemsUtil.storeItemsByXMLFilename[self.configFileName:lower()]
