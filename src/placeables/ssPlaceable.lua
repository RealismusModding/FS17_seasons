---------------------------------------------------------------------------------------------------------
-- PLACEABLE SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  To change placeable properties
-- Authors:  Rahkiin
--

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
    self.incomePerHour = 6 / g_seasons.environment.daysInSeason * self.ssOriginalIncomePerHour
end

function ssPlaceable:placeableGetDailyUpkeep(superFunc)
    local storeItem = StoreItemsUtil.storeItemsByXMLFilename[self.configFileName:lower()]
    local multiplier = 1

    if storeItem.lifetime ~= nil and storeItem.lifetime ~= 0 then
        local ageMultiplier = math.min(self.age / storeItem.lifetime, 1)

        multiplier = EconomyManager.MAX_DAILYUPKEEP_MULTIPLIER * ageMultiplier
    end

    -- Add simple factor
    return StoreItemsUtil.getDailyUpkeep(storeItem, nil) * multiplier * (6 / g_seasons.environment.daysInSeason)
end

-- Currently: GIANTS Vanilla code
function ssPlaceable:placeableGetSellPrice(superFunc)
    local priceMultiplier = 0.5
    local maxVehicleAge = StoreItemsUtil.storeItemsByXMLFilename[self.configFileName:lower()].lifetime

    if maxVehicleAge ~= nil and maxVehicleAge ~= 0 then
        priceMultiplier = priceMultiplier * math.exp(-3.5 * math.min(self.age / maxVehicleAge, 1))
    end

    return math.floor(self.price * math.max(priceMultiplier, 0.05))
end
