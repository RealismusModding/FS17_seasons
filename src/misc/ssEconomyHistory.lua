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

            table.insert(values, {
                price = ssXMLUtil.getFloat(savegame, datKey),
                day = ssXMLUtil.getInt(savegame, datKey .. "day")
            })

            j = j + 1
        end

        self.data[index] = values

        i = i + 1
    end
end

function ssEconomyHistory:save(savegame, key)


    local i = 0
    for index, data in pairs(self.data) do
        local fillKey = key .. string.format(".economy.history.fill(%i)", i)

        ssXMLUtil.setString(savegame, fillKey, "hallo")

        i = i + 1
    end
end

function ssEconomyHistory:loadMap(name)
    g_seasons.environment:addSeasonLengthChangeListener(self)
    g_currentMission.environment:addDayChangeListener(self)

    for index, fillDesc in ipairs(FillUtil.fillTypeIndexToDesc) do
        fillDesc.ssEconomyType = self:getEconomyType(fillDesc)

        if fillDesc.ssEconomyType then
            -- For every fruit, check if values are loaded, otherwise load default data
            local values = Utils.getNoNil(self.data[index], {})

            -- Create values for a whole year
            for i = 1, g_seasons.environment.daysInSeason * 4 do
                if values[i] == nil then
                    values[i] = {
                        price = self:getSimulatedPrice(fillDesc, i),
                        day = i
                    }
                end
            end

            self.data[index] = values
        end
    end

    log("Economy data")
    print_r(self.data)
end

function ssEconomyHistory:seasonLengthChanged()
    -- This might cause all data to be odd, so stuff needs to be 'fixed'
end

-- Add all values of the previous day to the historic data
-- Also remove the first item
function ssEconomyHistory:dayChanged()
end

function ssEconomyHistory:getHistory(fillDesc)
    local data = {}
    local unit = "1000 l"
    local currentDay = g_seasons.environment:currentDay()

    if fillDesc.ssEconomyType == self.ECONOMY_TYPE_ANIMAL then
        unit = "p" -- TODO i18n
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

function ssEconomyHistory:getPriceForDay(fillDesc, day)
    if fillDesc.ssEconomyType == self.ECONOMY_TYPE_FILL then
    elseif fillDesc.ssEconomyType == self.ECONOMY_TYPE_ANIMAL then
    elseif fillDesc.ssEconomyType == self.ECONOMY_TYPE_BALE then
    end

    return self:getSimulatedPrice(fillDesc, day)
end

-- If no historic data is saved, create a price using the default price and the factors
-- of Seasons. This does not include demands from the vanilla game.
function ssEconomyHistory:getSimulatedPrice(fillDesc, day)
    if fillDesc.ssEconomyType == self.ECONOMY_TYPE_FILL then
        return 1000 * fillDesc.pricePerLiter * g_seasons.economy:getFillFactor(fillDesc.index, day)

    elseif fillDesc.ssEconomyType == self.ECONOMY_TYPE_ANIMAL then
        local animalDesc = AnimalUtil.animalIndexToDesc[AnimalUtil.fillTypeToAnimal[fillDesc.index]]

        return Utils.getNoNil(animalDesc.ssOriginalPrice, animalDesc.price) * g_seasons.economy:getAnimalFactor(animalDesc.name, day)

    elseif fillDesc.ssEconomyType == self.ECONOMY_TYPE_BALE then
        return 1000 * fillDesc.pricePerLiter * g_seasons.economy:getBaleFactor(fillDesc.index, day)
    end
end
