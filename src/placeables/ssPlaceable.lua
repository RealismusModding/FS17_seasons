----------------------------------------------------------------------------------------------------
-- PLACEABLE SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  To change placeable properties
-- Authors:  Rahkiin, reallogger
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssPlaceable = {}

function ssPlaceable:preLoad()
    Placeable.getDailyUpKeep = Utils.overwrittenFunction(Placeable.getDailyUpKeep, ssPlaceable.placeableGetDailyUpkeep)
    Placeable.getSellPrice = Utils.overwrittenFunction(Placeable.getSellPrice, ssPlaceable.placeableGetSellPrice)

    Placeable.finalizePlacement = Utils.overwrittenFunction(Placeable.finalizePlacement, ssPlaceable.placeableFinalizePlacement)
    Placeable.delete = Utils.overwrittenFunction(Placeable.delete, ssPlaceable.placeableDelete)
    Placeable.seasonLengthChanged = ssPlaceable.placeableSeasonLengthChanged
end

function ssPlaceable:loadMap()
end

-- When placing, add listener and update income value
function ssPlaceable:placeableFinalizePlacement(superFunc)
    local ret = superFunc(self)

    self.ssOriginalIncomePerHour = self.incomePerHour

    g_seasons.environment:addSeasonLengthChangeListener(self)
    self:seasonLengthChanged()

    return ret
end

-- When deleting, also remove listener
function ssPlaceable:placeableDelete(superFunc)
    superFunc(self)

    if g_seasons ~= nil and g_seasons.environment ~= nil then
        g_seasons.environment:removeSeasonLengthChangeListener(self)
    end
end

function ssPlaceable:placeableSeasonLengthChanged()
    local difficultyFac = 1 - (2 - g_currentMission.missionInfo.difficulty) * 0.1

    self.incomePerHour = 6 / g_seasons.environment.daysInSeason * self.ssOriginalIncomePerHour * difficultyFac
end

function ssPlaceable:placeableGetDailyUpkeep(superFunc)
    local storeItem = StoreItemsUtil.storeItemsByXMLFilename[self.configFileName:lower()]
    local multiplier = 1 + self.age / ( 4 * g_seasons.environment.daysInSeason ) * 2.5

    if self.incomePerHour == 0 then
        multiplier = 1 + self.age / ( 4 * g_seasons.environment.daysInSeason ) * 0.25
    end

    return StoreItemsUtil.getDailyUpkeep(storeItem, nil) * multiplier * (12 / g_seasons.environment.daysInSeason )
end

function ssPlaceable:placeableGetSellPrice(superFunc)
    local storeItem = StoreItemsUtil.storeItemsByXMLFilename[self.configFileName:lower()]
    local priceMultiplier = 0.5

    if self.incomePerHour == 0 then
        local ageFac = 0.5 - 0.05 * self.age / (4 * g_seasons.environment.daysInSeason)

        if ageFac > 0.1 then
            priceMultiplier = ageFac
        else
            priceMultiplier = -0.05
        end

    else
        local annualCost = self:getDailyUpKeep() * 4 * g_seasons.environment.daysInSeason
        local annualIncome = self.incomePerHour * 24 * 4 * g_seasons.environment.daysInSeason
        local annualProfitPriceRatio = ( annualIncome - annualCost ) / self.price

        if annualProfitPriceRatio > 0.1 then
            priceMultiplier = annualProfitPriceRatio
        else
            priceMultiplier = -0.05
        end
    end

    return math.floor(self.price * priceMultiplier)
end
