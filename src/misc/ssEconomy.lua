---------------------------------------------------------------------------------------------------------
-- ECONOMY SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  To adjust the economy
-- Authors:  Rahkiin, reallogger
--

ssEconomy = {}
g_seasons.economy = ssEconomy

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

    Placeable.finalizePlacement = Utils.appendedFunction(Placeable.finalizePlacement, ssEconomy.placeableFinalizePlacement)
    Placeable.onSell = Utils.appendedFunction(Placeable.onSell, ssEconomy.placeablenOnSell)

    -- Price changes with seasons
    EconomyManager.getPricePerLiter = Utils.overwrittenFunction(EconomyManager.getPricePerLiter, ssEconomy.emGetPricePerLiter)
    EconomyManager.getCostPerLiter = Utils.overwrittenFunction(EconomyManager.getCostPerLiter, ssEconomy.emGetCostPerLiter)
    Bale.getValue = Utils.overwrittenFunction(Bale.getValue, ssEconomy.baleGetValue)
    TipTrigger.getEffectiveFillTypePrice = Utils.overwrittenFunction(TipTrigger.getEffectiveFillTypePrice, ssEconomy.ttGetEffectiveFillTypePrice)

    -- Load economy price changes data
    self.repricing = {}
    self:loadFromXML(g_seasons.modDir .. "data/economy.xml")

    local modPath = ssUtil.getModMapDataPath("seasons_economy.xml")
    if modPath ~= nil then
        self:loadFromXML(modPath)
    end

    -- Change info every day
    g_currentMission.environment:addDayChangeListener(self)
    g_seasons.environment:addSeasonLengthChangeListener(self)

    if g_currentMission:getIsServer() then
        self:setup()
    end
end

function ssEconomy:loadFactorsFromXML(file, key)
    local factors = {}

    -- shortcut for setting all values to 1 or 0
    local allVal = getXMLFloat(file, key .. "#all")
    if allVal ~= nil then
        for i = 1, 12 do
            factors[i] = allVal
        end

        return factors
    end

    -- Load for each
    local i = 0
    while true do
        local fKey = string.format("%s.factor(%d)", key, i)
        if not hasXMLProperty(file, fKey) then break end

        local stage = getXMLInt(file, fKey .. "#stage")
        local value = getXMLFloat(file, fKey)

        factors[stage] = value

        i = i + 1
    end

    if table.getn(factors) ~= 12 then
        logInfo("Problem in economy data: not all stages are configured in " .. key)
    end

    return factors
end

function ssEconomy:loadFromXML(path)
    local file = loadXMLFile("economy", path)

    -- Load fills
    if self.repricing.fills == nil then
        self.repricing.fills = {}
    end

    local i = 0
    while true do
        local key = string.format("economy.fills.fill(%d)", i)
        if not hasXMLProperty(file, key) then break end

        local name = getXMLString(file, key .. "#name")
        if name == nil then
            logInfo("Name of fill unknown")
            break
        end

        local id = FillUtil.getFillTypesByNames(name)[1]
        local factors = self:loadFactorsFromXML(file, key .. ".factors")

        self.repricing.fills[id] = factors

        i = i + 1
    end

    -- Load bales
    if self.repricing.bales == nil then
        self.repricing.bales = {}
    end

    i = 0
    while true do
        local key = string.format("economy.bales.bale(%d)", i)
        if not hasXMLProperty(file, key) then break end

        local type = getXMLString(file, key .. "#type")
        if type == nil then
            logInfo("Type of bale unknown")
            break
        end

        local id = FillUtil.getFillTypesByNames(type)[1]
        local factors = self:loadFactorsFromXML(file, key .. ".factors")

        self.repricing.bales[id] = factors

        i = i + 1
    end

    -- Load animals
    if self.repricing.animals == nil then
        self.repricing.animals = {}
    end

    i = 0
    while true do
        local key = string.format("economy.animals.animal(%d)", i)
        if not hasXMLProperty(file, key) then break end

        local name = getXMLString(file, key .. "#name")
        if name == nil then
            logInfo("Type of animal unknown")
            break
        end

        local factors = self:loadFactorsFromXML(file, key .. ".factors")

        self.repricing.animals[name] = factors

        i = i + 1
    end

    delete(file)
end

function ssEconomy:setup()
    -- Some calculations to make the code faster on the hotpath
    ssEconomy.aiPricePerMSWork = ssEconomy.aiPricePerHourWork / (60 * 60 * 1000)
    ssEconomy.aiPricePerMSOverwork = ssEconomy.aiPricePerHourOverwork / (60 * 60 * 1000)

    g_currentMission.missionStats.loanMax = self:getLoanCap()
    g_currentMission.missionStats.ssLoan = 0

    self:updateAnimals()
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

function ssEconomy:updateTick(dt)
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
    local seasonsYearInterest = yearInterest * (356 / (g_seasons.environment.daysInSeason * g_seasons.environment.SEASONS_IN_YEAR))

    g_currentMission.missionStats.loanAnnualInterestRate = seasonsYearInterest
end

function ssEconomy.aiUpdateTick(self, superFunc, dt)
    if self:getIsActive() then
        local hour = g_currentMission.environment.currentHour
        local dow = ssUtil.dayOfWeek(g_seasons.environment:currentDay())

        if hour >= ssEconomy.aiDayStart and hour <= ssEconomy.aiDayEnd and dow <= 5 then
            self.pricePerMS = ssEconomy.aiPricePerMSWork
        else
            self.pricePerMS = ssEconomy.aiPricePerMSOverwork
        end
    end

    return superFunc(self, dt)
end

---------------------------------------------------------------------------------------------------------
-- Loan cap

-- Calculate equity by summing all owned land. I know this is not
-- economically correct but it is the best we got for a value that moves
-- up as the game progresses
function ssEconomy:getEquity()
    local equity = 0

    if g_currentMission.fieldDefinitionBase ~= nil then -- can be nil on WIP maps
        for _, field in pairs(g_currentMission.fieldDefinitionBase.fieldDefs) do
            if field.ownedByPlayer then
                equity = equity + field.fieldPriceInitial
            end
        end
    end

    for _, type in pairs(g_currentMission.ownedItems) do
        if type.storeItem.species == "placeable" then
            for _, placeable in pairs(type.items) do
                equity = equity + placeable:getSellPrice()
            end
        end
    end

    return equity
end

function ssEconomy:getLoanCap()
    local roundedTo5000 = math.floor(ssEconomy.EQUITY_LOAN_RATIO * self:getEquity() / 5000) * 5000
    return Utils.clamp(roundedTo5000, 300000, ssEconomy.loanMax)
end

function ssEconomy:updateLoan()
    g_currentMission.missionStats.loanMax = self:getLoanCap()
end

function ssEconomy:setFieldOwnedByPlayer(superFunc, fieldDef, isOwned)
    local ret = superFunc(self, fieldDef, isOwned)

    g_seasons.economy:updateLoan()

    return ret
end

function ssEconomy:placeableFinalizePlacement()
    g_seasons.economy:updateLoan()
end

function ssEconomy:placeablenOnSell()
    g_seasons.economy:updateLoan()
end

---------------------------------------------------------------------------------------------------------
-- Pricing

function ssEconomy:dayChanged()
    self:updateAnimals()
end

function ssEconomy:seasonLengthChanged()
    self:updateAnimals()
end

function ssEconomy:getStageAndAlpha()
    local currentGrowthStage = g_seasons.environment:currentGrowthStage()

    local dayInStage = (g_seasons.environment:dayInSeason() - 1) % 3 + 1
    local stageLength = g_seasons.environment.daysInSeason / 3

    return currentGrowthStage, (dayInStage - 1) / stageLength
end

function ssEconomy:lerpFactors(factors)
    local stage, alpha = self:getStageAndAlpha()
    local nextStage = stage % 12 + 1

    return Utils.lerp(factors[stage], factors[nextStage], alpha)
end

function ssEconomy:getBaleFactor(fillType)
    if self.repricing.bales[fillType] == nil then
        return 1
    end

    return self:lerpFactors(self.repricing.bales[fillType])
end

function ssEconomy:getAnimalFactor(animal)
    if self.repricing.animals[animal] == nil then
        return 1
    end

    return self:lerpFactors(self.repricing.animals[animal])
end

function ssEconomy:getFillFactor(fillType)
    if self.repricing.fills[fillType] == nil then
        return 1
    end

    return self:lerpFactors(self.repricing.fills[fillType])
end

function ssEconomy:updateAnimals()
    for animal, desc in pairs(AnimalUtil.animals) do
        if desc.ssOriginalPrice == nil then
            desc.ssOriginalPrice = desc.price
        end

        desc.price = desc.ssOriginalPrice * self:getAnimalFactor(animal)
    end
end

function ssEconomy:emGetPricePerLiter(superFunc, fillType, isBale)
    local price = superFunc(self, fillType)

    if isBale then
        return price * g_seasons.economy:getBaleFactor(fillType)
    else
        return price * g_seasons.economy:getFillFactor(fillType)
    end
end

function ssEconomy:emGetCostPerLiter(superFunc, fillType, isBale)
    local price = superFunc(self, fillType)

    if isBale then
        return price * g_seasons.economy:getBaleFactor(fillType)
    else
        return price * g_seasons.economy:getFillFactor(fillType)
    end
end

function ssEconomy:baleGetValue(superFunc)
    local pricePerLiter = g_currentMission.economyManager:getPricePerLiter(self.fillType, true)

    return self.fillLevel * pricePerLiter * self.baleValueScale
end

function ssEconomy:ttGetEffectiveFillTypePrice(superFunc, fillType)
    local price = superFunc(self, fillType)

    return price * g_seasons.economy:getFillFactor(fillType)
end

--tipTriggers
--Animals
