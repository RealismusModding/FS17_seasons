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
    ssUtil.overwrittenFunction(Placeable, "loadFromAttributesAndNodes", ssPlaceable.placeableLoadFromAttributesAndNodes)
    ssUtil.overwrittenFunction(Placeable, "getSaveAttributesAndNodes", ssPlaceable.placeableGetSaveAttributesAndNodes)
    ssUtil.overwrittenFunction(Placeable, "getDailyUpKeep", ssPlaceable.placeableGetDailyUpkeep)
    ssUtil.overwrittenFunction(Placeable, "getSellPrice", ssPlaceable.placeableGetSellPrice)

    ssUtil.appendedFunction(Placeable, "finalizePlacement", ssPlaceable.placeableFinalizePlacement)
    ssUtil.appendedFunction(Placeable, "delete", ssPlaceable.placeableDelete)
    ssUtil.appendedFunction(Placeable, "dayChanged", ssPlaceable.placeableDayChanged)

    Placeable.seasonLengthChanged = ssPlaceable.placeableSeasonLengthChanged
end

function ssPlaceable:loadMap()
end

-- When placing, add listener and update income value
function ssPlaceable:placeableFinalizePlacement()
    self.ssOriginalIncomePerHour = self.incomePerHour

    g_seasons.environment:addSeasonLengthChangeListener(self)
    self:seasonLengthChanged()
end

-- When deleting, also remove listener
function ssPlaceable:placeableDelete()
    if g_seasons ~= nil and g_seasons.environment ~= nil then
        g_seasons.environment:removeSeasonLengthChangeListener(self)
    end
end

function ssPlaceable:placeableSeasonLengthChanged()
    local difficultyFac = 1 - (2 - g_currentMission.missionInfo.difficulty) * 0.1

    self.incomePerHour = 6 / g_seasons.environment.daysInSeason * self.ssOriginalIncomePerHour * difficultyFac
end

function ssPlaceable:placeableDayChanged()
    self.ssYears = self.ssYears + 1 / (4 * g_seasons.environment.daysInSeason)
end

function ssPlaceable:placeableGetDailyUpkeep(superFunc)
    local storeItem = StoreItemsUtil.storeItemsByXMLFilename[self.configFileName:lower()]
    local multiplier = 1 + self.ssYears * 2.5

    if self.incomePerHour == 0 then
        multiplier = 1 + self.ssYears * 0.25
    end

    return StoreItemsUtil.getDailyUpkeep(storeItem, nil) * multiplier * (12 / g_seasons.environment.daysInSeason )
end

function ssPlaceable:placeableGetSellPrice(superFunc)
    local storeItem = StoreItemsUtil.storeItemsByXMLFilename[self.configFileName:lower()]
    local priceMultiplier = 0.5

    if self.incomePerHour == 0 then
        local ageFac = 0.5
        -- for some reason getSellPrice is loaded very early in load before values are loaded from vehicle.xml
        if self.ssYears ~= nil then
            ageFac = 0.5 - 0.05 * self.ssYears
        end

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
            priceMultiplier = math.min(annualProfitPriceRatio, 0.5)
        else
            priceMultiplier = -0.05
        end
    end

    return math.floor(self.price * priceMultiplier)
end

-- Store placeable age in years
function ssPlaceable:placeableLoadFromAttributesAndNodes(superFunc, xmlFile, key, resetVehicles)
    local state = superFunc(self, xmlFile, key, resetVehicles)

    self.ssYears = Utils.getNoNil(getXMLInt(xmlFile, key .. "#ssYears"), self.age / (4 * g_seasons.environment.daysInSeason))

    return state
end

function ssPlaceable:placeableGetSaveAttributesAndNodes(superFunc, nodeIdent)
    local attributes, nodes = superFunc(self, nodeIdent)

    if attributes ~= nil and self.ssYears ~= nil then
        attributes = attributes .. ' ssYears="' .. self.ssYears .. '"'
    end

    return attributes, nodes
end