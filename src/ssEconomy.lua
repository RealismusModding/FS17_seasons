---------------------------------------------------------------------------------------------------------
-- ECONOMY SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  To adjust the economy
-- Authors:  Rahkiin, reallogger
--

ssEconomy = {}
ssEconomy.EQUITY_LOAN_RATIO = 0.3

function ssEconomy:load(savegame, key)
    self.aiPricePerHourWork = ssStorage.getXMLFloat(savegame, key .. ".settings.aiPricePerHourWork", 1650)
    self.aiPricePerHourOverwork = ssStorage.getXMLFloat(savegame, key .. ".settings.aiPricePerHourOverwork", 2475)
    self.aiDayStart = ssStorage.getXMLFloat(savegame, key .. ".settings.aiDayStart", 6)
    self.aiDayEnd = ssStorage.getXMLFloat(savegame, key .. ".settings.aiDayEnd", 18)
    self.loanMax = ssStorage.getXMLFloat(savegame, key .. ".settings.loanMax", 1000000)
    self.baseLoanInterest = ssStorage.getXMLFloat(savegame, key .. ".settings.baseLoanInterest", 10)
end

function ssEconomy:save(savegame, key)
    ssStorage.setXMLFloat(savegame, key .. ".settings.aiPricePerHourWork", self.aiPricePerHourWork)
    ssStorage.setXMLFloat(savegame, key .. ".settings.aiPricePerHourOverwork", self.aiPricePerHourOverwork)
    ssStorage.setXMLFloat(savegame, key .. ".settings.aiDayStart", self.aiDayStart)
    ssStorage.setXMLFloat(savegame, key .. ".settings.aiDayEnd", self.aiDayEnd)
    ssStorage.setXMLFloat(savegame, key .. ".settings.loanMax", self.loanMax)
    ssStorage.setXMLFloat(savegame, key .. ".settings.baseLoanInterest", self.baseLoanInterest)
end

function ssEconomy:loadMap(name)
    -- Update leasing costs
    EconomyManager.DEFAULT_LEASING_DEPOSIT_FACTOR = 0.04 -- factor of price (vanilla: 0.05)
    EconomyManager.DEFAULT_RUNNING_LEASING_FACTOR = 0.04 -- factor of price (vanilla: 0.05)
    EconomyManager.PER_DAY_LEASING_FACTOR = 0.008 -- factor of price (vanilla: 0.01)

    AIVehicle.updateTick = Utils.overwrittenFunction(AIVehicle.updateTick, ssEconomy.aiUpdateTick)
    FieldDefinition.setFieldOwnedByPlayer = Utils.overwrittenFunction(FieldDefinition.setFieldOwnedByPlayer, ssEconomy.setFieldOwnedByPlayer)

    if g_currentMission:getIsServer() then
        self:setup()
    end
end

function ssEconomy:setup()
    -- Some calculations to make the code faster on the hotpath
    ssEconomy.aiPricePerMSWork = ssEconomy.aiPricePerHourWork / (60 * 60 * 1000)
    ssEconomy.aiPricePerMSOverwork = ssEconomy.aiPricePerHourOverwork / (60 * 60 * 1000)

    g_currentMission.missionStats.loanMax = self:getLoanCap()
    g_currentMission.missionStats.ssLoan = 0
end

function ssEconomy:readStream(streamId, connection)
    self.aiPricePerHourWork = streamReadFloat32(streamId)
    self.aiPricePerHourOverwork = streamReadFloat32(streamId)
    self.aiDayStart = streamReadFloat32(streamId)
    self.aiDayEnd = streamReadFloat32(streamId)
    self.loanMax = streamReadFloat32(streamId)
    self.baseLoanInterest = streamReadFloat32(streamId)

    self:setup()
end

function ssEconomy:writeStream(streamId, connection)
    streamWriteFloat32(streamId, self.aiPricePerHourWork)
    streamWriteFloat32(streamId, self.aiPricePerHourOverwork)
    streamWriteFloat32(streamId, self.aiDayStart)
    streamWriteFloat32(streamId, self.aiDayEnd)
    streamWriteFloat32(streamId, self.loanMax)
    streamWriteFloat32(streamId, self.baseLoanInterest)
end

function ssEconomy:update(dt)
    if g_currentMission:getIsServer() then
        local stats = g_currentMission.missionStats

        if stats.ssLoan ~= stats.loan then
            self:calculateLoanInterestRate()
            stats.ssLoan = stats.loan
        end
    end
end

function ssEconomy:calculateLoanInterestRate()
    -- local stats = g_currentMission.missionStats
    local yearInterest = self.baseLoanInterest / 2 * g_currentMission.missionInfo.difficulty

    -- Convert the interest to be made in a Seasons year to a vanilla year so that the daily interests are correct
    local seasonsYearInterest = yearInterest * (356 / (ssSeasonsUtil.daysInSeason * ssSeasonsUtil.SEASONS_IN_YEAR))

    g_currentMission.missionStats.loanAnnualInterestRate = seasonsYearInterest
end

function ssEconomy.aiUpdateTick(self, superFunc, dt)
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

-- Calculate equity by summing all owned land. I know this is not
-- economically correct but it is the best we got for a value that moves
-- up as the game progresses
function ssEconomy:getEquity()
    local price = 0

    for _, field in pairs(g_currentMission.fieldDefinitionBase.fieldDefs) do
        if field.ownedByPlayer then
            price = price + field.fieldPriceInitial
        end
    end

    return price
end

function ssEconomy:getLoanCap()
    local roundedTo5000 = math.floor(ssEconomy.EQUITY_LOAN_RATIO * self:getEquity() / 5000) * 5000
    return Utils.clamp(roundedTo5000, 300000, ssEconomy.loanMax)
end

function ssEconomy.setFieldOwnedByPlayer(self, superFunc, fieldDef, isOwned)
    local ret = superFunc(self, fieldDef, isOwned)

    g_currentMission.missionStats.loanMax = ssEconomy.getLoanCap(ssEconomy)

    return ret
end

