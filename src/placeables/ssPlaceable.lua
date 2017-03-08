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
end

function ssPlaceable:loadMap()
end

-- Currently: GIANTS Vanilla code
function ssPlaceable:placeableGetDailyUpkeep(superFunc)
    local storeItem = StoreItemsUtil.storeItemsByXMLFilename[self.configFileName:lower()]
    local multiplier = 1

    if storeItem.lifetime ~= nil and storeItem.lifetime ~= 0 then
        local ageMultiplier = math.min(self.age / storeItem.lifetime, 1)

        multiplier = EconomyManager.MAX_DAILYUPKEEP_MULTIPLIER * ageMultiplier
    end

    return StoreItemsUtil.getDailyUpkeep(storeItem, nil) * multiplier
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
