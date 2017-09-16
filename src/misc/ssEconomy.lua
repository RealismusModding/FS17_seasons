----------------------------------------------------------------------------------------------------
-- ECONOMY SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  To adjust the economy
-- Authors:  Rahkiin, reallogger, theSeb
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssEconomy = {}

ssEconomy.EQUITY_LOAN_RATIO = 0.8
ssEconomy.DEFAULT_FACTOR = 1
ssEconomy.VANILLA_AI_PER_HOUR = 2000

function ssEconomy:preLoad()
    g_seasons.economy = self

    ssUtil.appendedFunction(AIVehicle, "load", ssEconomy.aiLoad)
    ssUtil.overwrittenFunction(AIVehicle, "updateTick", ssEconomy.aiUpdateTick)
    ssUtil.overwrittenFunction(FieldDefinition, "setFieldOwnedByPlayer", ssEconomy.setFieldOwnedByPlayer)

    ssUtil.appendedFunction(Placeable, "finalizePlacement", ssEconomy.placeableFinalizePlacement)
    ssUtil.appendedFunction(Placeable, "onSell", ssEconomy.placeablenOnSell)

    -- Price changes with seasons
    ssUtil.overwrittenFunction(EconomyManager, "getPricePerLiter", ssEconomy.emGetPricePerLiter)
    ssUtil.overwrittenFunction(EconomyManager, "getCostPerLiter", ssEconomy.emGetCostPerLiter)
    ssUtil.overwrittenFunction(Bale, "getValue", ssEconomy.baleGetValue)
    ssUtil.overwrittenFunction(TipTrigger, "getEffectiveFillTypePrice", ssEconomy.ttGetEffectiveFillTypePrice)
end

function ssEconomy:load(savegame, key)
    self.aiPricePerHourWork = ssXMLUtil.getFloat(savegame, key .. ".settings.aiPricePerHourWork", 1650)
    self.aiPricePerHourOverwork = ssXMLUtil.getFloat(savegame, key .. ".settings.aiPricePerHourOverwork", 2475)
    self.aiDayStart = ssXMLUtil.getFloat(savegame, key .. ".settings.aiDayStart", 6)
    self.aiDayEnd = ssXMLUtil.getFloat(savegame, key .. ".settings.aiDayEnd", 18)
    self.loanMax = ssXMLUtil.getFloat(savegame, key .. ".settings.loanMax", 1500000)
    self.baseLoanInterest = ssXMLUtil.getFloat(savegame, key .. ".settings.baseLoanInterest", 10)
end

function ssEconomy:save(savegame, key)
    ssXMLUtil.setFloat(savegame, key .. ".settings.aiPricePerHourWork", self.aiPricePerHourWork)
    ssXMLUtil.setFloat(savegame, key .. ".settings.aiPricePerHourOverwork", self.aiPricePerHourOverwork)
    ssXMLUtil.setFloat(savegame, key .. ".settings.aiDayStart", self.aiDayStart)
    ssXMLUtil.setFloat(savegame, key .. ".settings.aiDayEnd", self.aiDayEnd)
    ssXMLUtil.setFloat(savegame, key .. ".settings.loanMax", self.loanMax)
    ssXMLUtil.setFloat(savegame, key .. ".settings.baseLoanInterest", self.baseLoanInterest)
end

function ssEconomy:loadMap(name)
    -- Update leasing costs
    ssUtil.overwrittenConstant(EconomyManager, "DEFAULT_LEASING_DEPOSIT_FACTOR", 0.04) -- factor of price (vanilla: 0.05)
    ssUtil.overwrittenConstant(EconomyManager, "DEFAULT_RUNNING_LEASING_FACTOR", 0.04) -- factor of price (vanilla: 0.05)
    ssUtil.overwrittenConstant(EconomyManager, "PER_DAY_LEASING_FACTOR", 0.008) -- factor of price (vanilla: 0.01)

    -- Load economy price changes data
    self.repricing = {}
    self:loadFromXML(g_seasons:getDataPath("economy"))

    for _, path in ipairs(g_seasons:getModPaths("economy")) do
        self:loadFromXML(path)
    end

    -- Change info every day
    g_currentMission.environment:addDayChangeListener(self)
    g_seasons.environment:addSeasonLengthChangeListener(self)
end

function ssEconomy:loadFactorsFromXML(file, key)
    local factors = {}

    -- shortcut for setting all values to 1 or 0
    local allVal = getXMLFloat(file, key .. "#all")
    if allVal ~= nil then
        for i = 1, g_seasons.environment.TRANSITIONS_IN_YEAR do
            factors[i] = allVal
        end

        return factors
    end

    -- Load for each
    local i = 0
    while true do
        local fKey = string.format("%s.factor(%d)", key, i)
        if not hasXMLProperty(file, fKey) then break end

        local transition = getXMLInt(file, fKey .. "#transition")
        local value = getXMLFloat(file, fKey)

        factors[transition] = value

        i = i + 1
    end

    if table.getn(factors) ~= g_seasons.environment.TRANSITIONS_IN_YEAR then
        logInfo("ssEconomy:", "Problem in economy data: not all transitions are configured in " .. key)
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
            logInfo("ssEconomy:", "Name of fill unknown")
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
            logInfo("ssEconomy:", "Type of bale unknown")
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
            logInfo("ssEconomy:", "Type of animal unknown")
            break
        end

        local factors = self:loadFactorsFromXML(file, key .. ".factors")

        self.repricing.animals[name] = factors

        i = i + 1
    end

    --get fieldPriceFactor from economy.xml
    self.fieldPriceFactor = ssXMLUtil.getFloat(file, "economy.fieldPriceFactor", 1.0)

    delete(file)
end

function ssEconomy:loadGameFinished()
    -- Some calculations to make the code faster on the hotpath
    ssEconomy.aiPricePerMSWork = ssEconomy.aiPricePerHourWork / (60 * 60 * 1000)
    ssEconomy.aiPricePerMSOverwork = ssEconomy.aiPricePerHourOverwork / (60 * 60 * 1000)

    -- Factors used to convert vanilla AI prices to Seasons AI prices
    self.aiPriceFactor = self.aiPricePerHourWork / ssEconomy.VANILLA_AI_PER_HOUR
    self.aiPriceOverworkFactor = self.aiPricePerHourOverwork / ssEconomy.VANILLA_AI_PER_HOUR

    g_currentMission.missionStats.loanMax = self:getLoanCap()

    self:calculateLoanInterestRate()
    self:updateAnimals()
    self:updateFieldPrices()
end

function ssEconomy:readStream(streamId, connection)
    self.aiPricePerHourWork = streamReadFloat32(streamId)
    self.aiPricePerHourOverwork = streamReadFloat32(streamId)
    self.aiDayStart = streamReadFloat32(streamId)
    self.aiDayEnd = streamReadFloat32(streamId)
    self.loanMax = streamReadFloat32(streamId)
    self.baseLoanInterest = streamReadFloat32(streamId)
    self.fieldPriceFactor = streamReadFloat32(streamId)
end

function ssEconomy:writeStream(streamId, connection)
    streamWriteFloat32(streamId, self.aiPricePerHourWork)
    streamWriteFloat32(streamId, self.aiPricePerHourOverwork)
    streamWriteFloat32(streamId, self.aiDayStart)
    streamWriteFloat32(streamId, self.aiDayEnd)
    streamWriteFloat32(streamId, self.loanMax)
    streamWriteFloat32(streamId, self.baseLoanInterest)
    streamWriteFloat32(streamId, self.fieldPriceFactor)
end

function ssEconomy:calculateLoanInterestRate()
    -- local stats = g_currentMission.missionStats
    local yearInterest = self.baseLoanInterest / 2 * g_currentMission.missionInfo.difficulty

    -- Convert the interest to be made in a Seasons year to a vanilla year so that the daily interests are correct
    local seasonsYearInterest = yearInterest * (356 / (g_seasons.environment.daysInSeason * g_seasons.environment.SEASONS_IN_YEAR))

    g_currentMission.missionStats.loanAnnualInterestRate = seasonsYearInterest
end

function ssEconomy:aiLoad(savegame)
    -- After loading the aiVehicle, store original pricePerMS in a variable, so pricePerMS can be altered without losing the original value.
    self.ssOriginalPricePerMS = self.pricePerMS
end

function ssEconomy.aiUpdateTick(self, superFunc, dt)
    if self:getIsActive() then
        if self.ssOriginalPricePerMS ~= nil then

            -- Only apply the multiplier when price is positive, to avoid increase in 'worker income' in overtime
            if self.ssOriginalPricePerMS >= 0 then
                local factor = ssUtil.isWorkHours() and g_seasons.economy.aiPriceFactor or g_seasons.economy.aiPriceOverworkFactor
                self.pricePerMS = self.ssOriginalPricePerMS * factor
            end
        else
            -- In case self.originalPricePerMS is nil (should never happen), revert to the old system.
            self.pricePerMS = ssUtil.isWorkHours() and g_seasons.economy.aiPricePerMSWork or g_seasons.economy.aiPricePerMSOverwork
        end
    end

    return superFunc(self, dt)
end

----------------------------------------------------------------------------------------------------
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
    local roundedTo5000 = math.floor(self.EQUITY_LOAN_RATIO * self:getEquity() / 5000) * 5000
    return Utils.clamp(roundedTo5000, 300000, ssEconomy.loanMax)
end

function ssEconomy:updateLoan()
    g_currentMission.missionStats.loanMax = self:getLoanCap()
end

function ssEconomy:setFieldOwnedByPlayer(superFunc, fieldDef, isOwned)
    local ret = superFunc(self, fieldDef, isOwned)

    -- TODO(console) fix
    -- g_seasons.economy:updateLoan()

    return ret
end

function ssEconomy:placeableFinalizePlacement()
    g_seasons.economy:updateLoan()
end

function ssEconomy:placeablenOnSell()
    g_seasons.economy:updateLoan()
end

----------------------------------------------------------------------------------------------------
-- Pricing

function ssEconomy:dayChanged()
    self:updateAnimals()
end

function ssEconomy:seasonLengthChanged()
    self:updateAnimals()
    self:calculateLoanInterestRate()
end

function ssEconomy:getTransitionAndAlpha(day)
    local currentTransition = g_seasons.environment:transitionAtDay(day)

    local transitionLength = g_seasons.environment.daysInSeason / 3
    local dayInTransition = (g_seasons.environment:dayInSeason(day) - 1) % transitionLength + 1

    return currentTransition, (dayInTransition - 1) / transitionLength
end

function ssEconomy:lerpFactors(factors, day)
    local transition, alpha = self:getTransitionAndAlpha(day)
    local nextTransition = transition % g_seasons.environment.TRANSITIONS_IN_YEAR + 1

    return Utils.lerp(factors[transition], factors[nextTransition], alpha)
end

function ssEconomy:getBaleFactor(fillType, day)
    if self.repricing.bales[fillType] == nil then
        return self.DEFAULT_FACTOR
    end

    return self:lerpFactors(self.repricing.bales[fillType], day)
end

function ssEconomy:getAnimalFactor(animal, day)
    if self.repricing.animals[animal] == nil then
        return self.DEFAULT_FACTOR
    end

    return self:lerpFactors(self.repricing.animals[animal], day)
end

function ssEconomy:getFillFactor(fillType, day)
    if self.repricing.fills[fillType] == nil then
        return self.DEFAULT_FACTOR
    end

    return self:lerpFactors(self.repricing.fills[fillType], day)
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
    local orig = g_currentMission.economyManager.getPricePerLiter

    g_currentMission.economyManager.getPricePerLiter = function (self, ...)
        return orig(self, ..., true)
    end

    local pricePerLiter = superFunc(self)

    g_currentMission.economyManager.getPricePerLiter = orig

    return pricePerLiter
end

function ssEconomy:ttGetEffectiveFillTypePrice(superFunc, fillType)
    local price = superFunc(self, fillType)

    if self.isServer then
        local factor = g_seasons.economy:getFillFactor(fillType)

        -- Omit random delta when factor is 0
        if factor == 0 then
            return 0
        else
            return ((self.fillTypePrices[fillType] * factor + self.fillTypePriceRandomDelta[fillType] * 0.2) * self.priceMultipliers[fillType])
        end
    else
        return price
    end
end

-- update field prices
function ssEconomy:updateFieldPrices()
    --don't do anything if map has no fields
    if not (g_currentMission.fieldDefinitionBase ~= nil and g_currentMission.fieldDefinitionBase.fieldDefs ~= nil) then return end

    for _, fieldDef in pairs(g_currentMission.fieldDefinitionBase.fieldDefs) do
        fieldDef.fieldPriceInitial  = fieldDef.fieldPriceInitial * self.fieldPriceFactor
    end
end
