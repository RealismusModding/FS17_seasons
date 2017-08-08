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

end

function ssEconomyHistory:save(savegame, key)

end

function ssEconomyHistory:loadMap(name)
    g_seasons.environment:addSeasonLengthChangeListener(self)

    for index, fillDesc in ipairs(FillUtil.fillTypeIndexToDesc) do
        fillDesc.ssEconomyType = self:getEconomyType(fillDesc)
    end
end

function ssEconomyHistory:seasonLengthChanged()
    -- This might cause all data to be odd, so stuff needs to be 'fixed'
end

function ssEconomyHistory:getHistory(fillDesc)
    local data = {}
    local unit = "1000 l"
    local currentDay = g_seasons.environment:currentDay()

    if fillDesc.ssEconomyType == self.ECONOMY_TYPE_ANIMAL then
        unit = "p" -- TODO i18n
    end

    for i = self.HISTORY_LENGTH * g_seasons.environment.daysInSeason * 4, 1, -1 do
        local day = currentDay - i

        table.insert(data, {
            day = day,
            price = self:getPriceForDay(fillDesc, day)
        })
    end

    return {
        data = data,
        unit = unit
    }
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
    if day < g_seasons.environment:currentDay() then
        return self:getPretendPrice(fillDesc, (day % (g_seasons.environment.daysInSeason * 4)) + 1)
    end

    if fillDesc.ssEconomyType == self.ECONOMY_TYPE_FILL then
    elseif fillDesc.ssEconomyType == self.ECONOMY_TYPE_ANIMAL then
    elseif fillDesc.ssEconomyType == self.ECONOMY_TYPE_BALE then
    end

    return self:getPretendPrice(fillDesc, day)
end

-- If no data is available, make up something close
function ssEconomyHistory:getPretendPrice(fillDesc, day)
    if fillDesc.ssEconomyType == self.ECONOMY_TYPE_FILL then
        return 1000 * fillDesc.pricePerLiter * g_seasons.economy:getFillFactor(fillDesc.index, day)
    elseif fillDesc.ssEconomyType == self.ECONOMY_TYPE_ANIMAL then
        local animalDesc = AnimalUtil.animalIndexToDesc[AnimalUtil.fillTypeToAnimal[fillDesc.index]]

        return animalDesc.ssOriginalPrice * g_seasons.economy:getAnimalFactor(animalDesc.name, day)
    elseif fillDesc.ssEconomyType == self.ECONOMY_TYPE_BALE then
        return 1000 * fillDesc.pricePerLiter * g_seasons.economy:getBaleFactor(fillDesc.index, day)
    end
end
