----------------------------------------------------------------------------------------------------
-- ECONOMY HISTORY SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  History of economic values
-- Authors:  Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssEconomyHistory = {}
g_seasons.economyHistory = ssEconomyHistory

ssEconomyHistory.HISTORY_LENGTH = 1 -- years

ssEconomyHistory.ECONOMY_TYPE_FILL = 1
ssEconomyHistory.ECONOMY_TYPE_ANIMAL = 2
ssEconomyHistory.ECONOMY_TYPE_BALE = 3

function ssEconomyHistory:load(savegame, key)
    self.data = {}

    -- Load data from savegame
    local i = 0
    while true do
        local fillKey = string.format("%s.economy.history.fill(%i)", key, i)
        if not ssXMLUtil.hasProperty(savegame, fillKey) then break end

        local index = ssXMLUtil.getInt(savegame, fillKey .. "#fillType")
        local values = {}

        local j = 0
        while true do
            local dayKey = string.format("%s.value(%i)", fillKey, j)
            if not ssXMLUtil.hasProperty(savegame, dayKey) then break end

            values[ssXMLUtil.getInt(savegame, datKey .. ".day")] = ssXMLUtil.getFloat(savegame, datKey)

            j = j + 1
        end

        self.data[index] = values

        i = i + 1
    end
end

function ssEconomyHistory:save(savegame, key)
    local i = 0
    for index, data in pairs(self.data) do
        local fillKey = string.format("%s.economy.history.fill(%i)", key, i)

        ssXMLUtil.setInt(savegame, fillKey .. "#fillType", index)

        local j = 0
        for day, price in ipairs(data) do
            local k = string.format("%s.value(%i)", fillKey, j)

            ssXMLUtil.setFloat(savegame, k, price)
            ssXMLUtil.setInt(savegame, k .. ".day", day)

            j = j + 1
        end

        i = i + 1
    end
end

function ssEconomyHistory:loadMap(name)
    g_seasons.environment:addSeasonLengthChangeListener(self)
    g_currentMission.environment:addDayChangeListener(self)

    local currentDay = g_seasons.environment:dayInYear()

    for index, fillDesc in pairs(FillUtil.fillTypeIndexToDesc) do
        fillDesc.ssEconomyType = self:getEconomyType(fillDesc)

        if fillDesc.ssEconomyType then
            -- For every fruit, check if values are loaded, otherwise load default data
            local values = Utils.getNoNil(self.data[index], {})

            -- Create values for a whole year
            for i = 1, g_seasons.environment.daysInSeason * 4 do
                if values[i] == nil then
                    local value

                    if i == currentDay then
                        value = self:getPrice(fillDesc)
                    else
                        value = self:getSimulatedPrice(fillDesc, i)
                    end

                    values[i] = value
                end
            end

            self.data[index] = values
        end
    end
end

-- Copy all data into new set, possibly interpolated or truncated
function ssEconomyHistory:seasonLengthChanged()
    local newSize = g_seasons.environment.daysInSeason * 4

    for index, fillDesc in pairs(FillUtil.fillTypeIndexToDesc) do
        if fillDesc.ssEconomyType then
            local oldSize = table.getn(self.data[index])

            if newSize > oldSize then
                self.data[index] = self:expandedArray(self.data[index], newSize)
            elseif newSize < oldSize then
                self.data[index] = self:contractedArray(self.data[index], newSize)
            end
        end
    end
end

function ssEconomyHistory:expandedArray(list, newSize)
    local data = {}
    local oldSize = table.getn(list)
    local expansionFactor = oldSize / newSize

    for i = 1, newSize do
        -- Interpolate value
        local location = (i - 1) * expansionFactor + 1

        local left = list[math.max(math.floor(location), 1)]
        local right = list[math.min(math.ceil(location), oldSize)]
        local alpha = location % 1

        data[i] = (right - left) * alpha + left
    end

    return data
end

function ssEconomyHistory:contractedArray(list, newSize)
    local data = {}
    local oldSize = table.getn(list)
    local contractionFactor = oldSize / newSize

    for i = 1, newSize do
        -- Get average value of section this value replaces
        local left = math.max(math.floor((i - 1) * contractionFactor + 1), 1)
        local right = math.min(math.ceil(i * contractionFactor), oldSize)

        local sum = 0
        for j = left, right do
            sum = sum + list[j]
        end

        data[i] = sum / (right - left + 1)
    end

    return data
end

-- Set all values of the previous day to the historic data to current day (% year, no offset)
function ssEconomyHistory:dayChanged()
    local day = g_seasons.environment:dayInYear(g_seasons.environment:currentDay())

    for index, fillDesc in pairs(FillUtil.fillTypeIndexToDesc) do
        if fillDesc.ssEconomyType then
            local value = self:getPrice(fillDesc)

            self.data[fillDesc.index][day] = value
        end
    end
end

function ssEconomyHistory:getHistory(fillDesc)
    local data = {}
    local unit = ssLang.getText("ui_economy_thousand")

    if fillDesc.ssEconomyType == self.ECONOMY_TYPE_ANIMAL then
        unit = ssLang.getText("ui_economy_animal")
    end

    return {
        data = self:getData(fillDesc),
        unit = unit
    }
end

function ssEconomyHistory:getData(fillDesc)
    return self.data[fillDesc.index]
end

function ssEconomyHistory:getEconomyType(fillDesc)
    if fillDesc.showOnPriceTable then
        return self.ECONOMY_TYPE_FILL
    end

    if ssEconomy.repricing.fills[fillDesc.name] ~= nil then
        return self.ECONOMY_TYPE_FILL
    end

    if ssEconomy.repricing.animals[fillDesc.name] ~= nil then
        return self.ECONOMY_TYPE_ANIMAL
    end

    -- ssEconomy.repricing.bales
    if false then
        return self.ECONOMY_TYPE_BALE
    end

    return nil
end

-- Get the current average price of given fill.
-- Average is over all tiptriggers that accept given fill.
-- Animals is per animal, everything else is per 1000 liters.
function ssEconomyHistory:getPrice(fillDesc)
    local fillType = fillDesc.index

    if fillDesc.ssEconomyType == self.ECONOMY_TYPE_FILL then
        local sum, num = 0, 0

        for _, tipTrigger in pairs(g_currentMission.tipTriggers) do
            if tipTrigger.isSellingPoint and tipTrigger.acceptedFillTypes[fillType] then
                sum = sum + tipTrigger:getEffectiveFillTypePrice(fillType)
                num = num + 1
            end
        end

        if num == 0 then
            return 0
        else
            return 1000 * sum / num -- 1000 liter
        end
    elseif fillDesc.ssEconomyType == self.ECONOMY_TYPE_ANIMAL then
        local animalDesc = AnimalUtil.animalIndexToDesc[AnimalUtil.fillTypeToAnimal[fillType]]

        return animalDesc.price
    elseif fillDesc.ssEconomyType == self.ECONOMY_TYPE_BALE then
        --1000 * fillDesc.pricePerLiter * g_seasons.economy:getBaleFactor(fillDesc.index)
    end

    return 4
end

-- If no historic data is saved, create a price using the default price and the factors
-- of Seasons. This does not include demands from the vanilla game.
function ssEconomyHistory:getSimulatedPrice(fillDesc, day)
    local multiplier = EconomyManager.getPriceMultiplier()

    if fillDesc.ssEconomyType == self.ECONOMY_TYPE_FILL then
        return 1000 * fillDesc.pricePerLiter * g_seasons.economy:getFillFactor(fillDesc.index, day) * multiplier
    elseif fillDesc.ssEconomyType == self.ECONOMY_TYPE_ANIMAL then
        local animalDesc = AnimalUtil.animalIndexToDesc[AnimalUtil.fillTypeToAnimal[fillDesc.index]]

        return Utils.getNoNil(animalDesc.ssOriginalPrice, animalDesc.price) * g_seasons.economy:getAnimalFactor(animalDesc.name, day)
    elseif fillDesc.ssEconomyType == self.ECONOMY_TYPE_BALE then
        return 1000 * fillDesc.pricePerLiter * g_seasons.economy:getBaleFactor(fillDesc.index, day) * multiplier
    end
end
