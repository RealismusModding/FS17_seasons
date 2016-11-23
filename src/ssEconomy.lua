---------------------------------------------------------------------------------------------------------
-- ECONOMY SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  To adjust the economy
-- Authors:  Rahkiin (Jarvixes), reallogger
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

    ssEconomy.aiPricePerMSWork = ssEconomy.aiPricePerHourWork / (60 * 60 * 1000)
    ssEconomy.aiPricePerMSOverwork = ssEconomy.aiPricePerHourOverwork / (60 * 60 * 1000)

    addModEventListener(ssEconomy)
end

function ssEconomy:loadMap(name)
    g_currentMission.environment:addDayChangeListener(self);

    -- Update leasing costs
    EconomyManager.DEFAULT_LEASING_DEPOSIT_FACTOR = 0.04 -- factor of price (vanilla: 0.05)
    EconomyManager.DEFAULT_RUNNING_LEASING_FACTOR = 0.04 -- factor of price (vanilla: 0.05)
    EconomyManager.PER_DAY_LEASING_FACTOR = 0.008 -- factor of price (vanilla: 0.01)

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
            self.pricePerMS = ssEconomy.aiPricePerMSOverwork
        end
    end

    return superFunc(self, dt)
end

--[[
FieldJobManager.startFieldJob(...)
FieldJobMissionScreen.setStartCallback(...)


EconomyManager.DEFAULT_LEASING_DEPOSIT_FACTOR
EconomyManager.DEFAULT_RUNNING_LEASING_FACTOR

Gui.showYesNoDialog(...)
subclass YesNoDialog
    onClickBack
    onClickOk
    onClose
    onCreate
    onOpen
    setButtonTexts
    setCallback
    setTitle
]]
