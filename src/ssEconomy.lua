---------------------------------------------------------------------------------------------------------
-- ECONOMY SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  To adjust the economy
-- Authors:  Rahkiin (Jarvixes)
--

ssEconomy = {}
ssEconomy.aiPricePerHourWork = 1650
ssEconomy.aiPricePerHourOverwork = 2475 -- 1650 * 1.5
ssEconomy.aiDayStart = 6
ssEconomy.aiDayEnd = 18
ssEconomy.loanMax = 5000000
ssEconomy.baseLoadInterest = 5 -- For normal, % per year
ssEconomy.settingsProperties = { "aiPricePerHourWork", "aiPricePerHourOverwork", "aiDayStart", "aiDayEnd", "loanMax", "baseLoadInterest" }


function ssEconomy.preSetup()
    ssSettings.add("economy", ssEconomy)

    AIVehicle.updateTick = Utils.overwrittenFunction(AIVehicle.updateTick, ssEconomy.aiUpdateTick)
end

function ssEconomy.setup()
    ssSettings.load("economy", ssEconomy)

    ssEconomy.aiPricePerMSWork = ssEconomy.aiPricePerHourWork / 60 / 60 / 1000
    ssEconomy.aiPricePerMSOverwork = ssEconomy.aiPricePerHourOverwork / 60 / 60 / 1000

    addModEventListener(ssEconomy)
end

function ssEconomy:loadMap(name)
    g_currentMission.environment:addDayChangeListener(self);

    g_currentMission.missionStats.loanMax = ssEconomy.loanMax
    g_currentMission.missionStats.ssLoan = 0
end

function ssEconomy:deleteMap()
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
    local yearInterest = ssEconomy.baseLoadInterest / 2 * g_currentMission.missionInfo.difficulty

    g_currentMission.missionStats.loanAnnualInterestRate = yearInterest
end

function ssEconomy:dayChanged()
end

function ssEconomy:aiUpdateTick(superFunc, dt)
    if self:getIsActive() then
        local hour = g_currentMission.environment.currentHour
        local dow = ssSeasonsUtil:dayOfWeek()

        if hour >= ssEconomy.aiDayStart and hour <= ssEconomy.aiDayEnd and dow <= 5 then
            self.pricePerMS = ssEconomy.aiPricePerMSWork
        else
            self.pricePerMS = ssEconomy.aiPricePerMSOverWork
        end
    end

    return superFunc(self, dt)
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
