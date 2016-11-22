---------------------------------------------------------------------------------------------------------
-- MAINTENANCE SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  To adjust the maintenance system
-- Authors:  Jarvixes (Rahkiin), reallogger, Rival
--

ssMaintenance = {}
ssMaintenance.LIFETIME_FACTOR = 5
ssMaintenance.REPAIR_NIGHT_FACTOR = 1
ssMaintenance.REPAIR_SHOP_FACTOR = 0.5
ssMaintenance.DIRT_FACTOR = 0.2

ssMaintenance.repairFactors = {}

ssMaintenance.settingsProperties = {}

SpecializationUtil.registerSpecialization("repairable", "ssRepairable", ssSeasonsMod.modDir .. "/src/ssRepairable.lua")

function ssMaintenance.preSetup()
    ssSettings.add("maintenance", ssMaintenance)

    Vehicle.getDailyUpKeep = Utils.overwrittenFunction(Vehicle.getDailyUpKeep, ssMaintenance.getDailyUpKeep)
    Vehicle.getSellPrice = Utils.overwrittenFunction(Vehicle.getSellPrice, ssMaintenance.getSellPrice)
    Vehicle.getSpecValueAge = Utils.overwrittenFunction(Vehicle.getSpecValueAge, ssMaintenance.getSpecValueAge)
    -- Vehicle.getSpecValueDailyUpKeep = Utils.overwrittenFunction(Vehicle.getSpecValueDailyUpKeep, ssMaintenance.getSpecValueDailyUpKeep)

    VehicleSellingPoint.sellAreaTriggerCallback = Utils.overwrittenFunction(VehicleSellingPoint.sellAreaTriggerCallback, ssMaintenance.sellAreaTriggerCallback)
end

function ssMaintenance.setup()
    ssSettings.load("maintenance", ssMaintenance)

    addModEventListener(ssMaintenance)
end

function ssMaintenance:loadMap(name)
    self:installRepairableSpecialization()
    self:loadRepairFactors()

    g_currentMission.environment:addDayChangeListener(self)
end

function ssMaintenance:deleteMap()
end

function ssMaintenance:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssMaintenance:keyEvent(unicode, sym, modifier, isDown)
end

function ssMaintenance:draw()
end

function ssMaintenance:update(dt)
end

function ssMaintenance:dayChanged()
    self:resetOperatingTimeAndDirt()
end

function ssMaintenance:installRepairableSpecialization()
    local specWashable = SpecializationUtil.getSpecialization("washable")

    -- Go over all the vehicle types
    for k, vehicleType in pairs(VehicleTypeUtil.vehicleTypes) do
        -- Lua can have nil in its tables
        if vehicleType == nil then break end

        -- If it is washable, we will add our own specialization
        local hasWashable = false
        for i, vs in pairs(vehicleType.specializations) do
            if vs == specWashable then
                hasWashable = true
                break
            end
        end

        if hasWashable then
            table.insert(vehicleType.specializations, SpecializationUtil.getSpecialization("repairable"))
        end
    end
end

function ssMaintenance:loadRepairFactors()
    -- Open file
    local file = loadXMLFile("factors", ssSeasonsMod.modDir .. "/repairFactors.xml")

    ssMaintenance.repairFactors = {}

    local i = 0;
    while true do
        local key = string.format("factors.factor(%d)", i);
        if not hasXMLProperty(file, key) then break end

        local category = getXMLString(file, key .. "#category");
        if category == nil then
            logInfo("repairFactors.xml is invalid")
            break
        end

        local RF1 = getXMLFloat(file, key .. ".RF1#value")
        local RF2 = getXMLFloat(file, key .. ".RF2#value")
        local lifetime = getXMLFloat(file, key .. ".ssLifeTime#value")

        if RF1 == nil or RF2 == nil or lifetime == nil then
            logInfo("repairFactors.xml is invalid")
            break
        end

        local config = {
            ["RF1"] = RF1,
            ["RF2"] = RF2,
            ["lifetime"] = lifetime
        }

        ssMaintenance.repairFactors[category] = config

        i = i + 1
    end

    -- Close file
    delete(file)
end

function ssMaintenance:repairCost(vehicle, storeItem, operatingTime)
    local data = ssMaintenance.repairFactors[storeItem.category]

    if data == nil then
        data = ssMaintenance.repairFactors["other"]
    end

    local RF1 = data.RF1
    local RF2 = data.RF2
    local lifetime = data.lifetime

    local dailyUpkeep = storeItem.dailyUpkeep

    local powerMultiplier = 1
    if storeItem.specs.power ~= nil then
        powerMultiplier = dailyUpkeep / storeItem.specs.power
    end

    if operatingTime < lifetime / ssMaintenance.LIFETIME_FACTOR then
        return 0.025 * storeItem.price * (RF1 * (operatingTime / 5) ^ RF2) * powerMultiplier
    else
        return 0.025 * storeItem.price * (RF1 * (operatingTime / (5 * ssMaintenance.LIFETIME_FACTOR)) ^ RF2) * (1 + (operatingTime - lifetime / ssMaintenance.LIFETIME_FACTOR) / (lifetime / 5) * 2) * powerMultiplier
    end
end

function ssMaintenance:maintenanceRepairCost(vehicle, storeItem, isRepair)
    local prevOperatingTime = vehicle.ssYesterdayOperatingTime / 1000 / 60 / 60
    local operatingTime = vehicle.operatingTime / 1000 / 60 / 60
    local daysSinceLastRepair = ssSeasonsUtil:currentDayNumber() - vehicle.ssLastRepairDay
    local repairFactor = isRepair and ssMaintenance.REPAIR_SHOP_FACTOR or ssMaintenance.REPAIR_NIGHT_FACTOR

    -- Calculate the amount of dirt on the vehicle, on average
    local avgDirtAmount = 0
    if operatingTime ~= prevOperatingTime then
        -- Cum dirt is per ms, while the operating times are in hours.
        avgDirtAmount = (vehicle.ssCumulativeDirt / 1000 / 60 / 60) / math.min(operatingTime - prevOperatingTime, 24)
    end

    -- Calculate the repair costs
    local prevRepairCost = self:repairCost(vehicle, storeItem, prevOperatingTime)
    local newRepairCost = self:repairCost(vehicle, storeItem, operatingTime)

    -- Calculate the final maintenance costs
    local maintenanceCost = 0
    if daysSinceLastRepair >= ssSeasonsUtil.daysInSeason or isRepair then
        maintenanceCost = (newRepairCost - prevRepairCost) * repairFactor * (0.8 + ssMaintenance.DIRT_FACTOR * avgDirtAmount ^ 2)
    end

    return maintenanceCost
end

function ssMaintenance.taxInterestCost(vehicle, storeItem)
    return 0.03 * storeItem.price / (4 * ssSeasonsUtil.daysInSeason)
end

function ssMaintenance:resetOperatingTimeAndDirt()
    for i, vehicle in pairs(g_currentMission.vehicles) do
        if SpecializationUtil.hasSpecialization(ssRepairable, vehicle.specializations) then
            vehicle.ssCumulativeDirt = 0
            vehicle.ssYesterdayOperatingTime = vehicle.operatingTime
        end
    end
end

-- Repair by resetting the last repair day and operating time
function ssMaintenance:repair(vehicle, storeItem)
    vehicle.ssLastRepairDay = ssSeasonsUtil:currentDayNumber()
    vehicle.ssYesterdayOperatingTime = vehicle.operatingTime

    return true
end

function ssMaintenance:getRepairShopCost(vehicle, storeItem, atDealer)
    -- Can't repair twice on same day, that is silly
    if vehicle.ssLastRepairDay == ssSeasonsUtil:currentDayNumber() then
        return 0
    end

    if storeItem == nil then
        storeItem = StoreItemsUtil.storeItemsByXMLFilename[vehicle.configFileName:lower()]
    end

    local costs = ssMaintenance:maintenanceRepairCost(vehicle, storeItem, true)
    local dealerMultiplier = atDealer and 1.1 or 1
    local difficultyMultiplier = 1 -- FIXME * difficulty mutliplier
    local workCosts = atDealer and 45 or 35

    return (costs + workCosts) * dealerMultiplier * difficultyMultiplier
end

function ssMaintenance:getDailyUpKeep(superFunc)
    local storeItem = StoreItemsUtil.storeItemsByXMLFilename[self.configFileName:lower()]

    -- If not repairable, show default amount
    if not SpecializationUtil.hasSpecialization(ssRepairable, self.specializations) then
        return superFunc(self)
    end

    -- This is for visually in the display
    local costs = ssMaintenance:taxInterestCost(self, storeItem)
    costs = costs + ssMaintenance:maintenanceRepairCost(self, storeItem, false)

    return costs
end

function ssMaintenance:getSellPrice(superFunc)
    local storeItem = StoreItemsUtil.storeItemsByXMLFilename[self.configFileName:lower()]
    local price = storeItem.price
    local operatingTime = self.operatingTime / (60 * 60 * 1000) -- hours
    local age = self.age / (ssSeasonsUtil.daysInSeason * ssSeasonsUtil.seasonsInYear) -- year
    local power = Utils.getNoNil(storeItem.specs.power, storeItem.dailyUpkeep)

    local factors = ssMaintenance.repairFactors[storeItem.category]
    local lifetime = storeItem.lifetime
    if factors ~= nil then
        lifetime = Utils.getNoNil(factors.lifetime, lifetime)
    end

    local p1, p2, p3, p4

    if category == "tractors" then
        p1 = -0.015
        p2 = 0.42
        p3 = -4
        p4 = 85
    elseif category == "combines" then
        p1 = -0.015
        p2 = 0.42
        p3 = -4
        p4 = 85
    else
        p1 = -0.015
        p2 = 0.42
        p3 = -4
        p4 = 85
    end

    local depFac = (p1 * age ^ 3 + p2 * age ^ 2 + p3 * age + p4) / 100
    local sellPrice

    if age == 0 and operatingTime < 2 then
        sellPrice = price
    else
        sellPrice = math.max((depFac * price - (depFac * price) * operatingTime / lifetime) * math.sqrt(power / storeItem.dailyUpkeep),1000) + ssSeasonsUtil:ssNormDist(-0.01 * price, 0.02 * price)
    end

    return sellPrice
end

--[[
function ssMaintenance:getSpecValueDailyUpKeep(superFunc, storeItem, realItem)
    log("getSpecValueDailyUpKeep "..tostring(storeItem), tostring(realItem))

    local dailyUpkeep = storeItem.dailyUpkeep

    if realItem ~= nil and realItem.getDailyUpKeep ~= nil then
        dailyUpkeep = realItem:getDailyUpKeep(false)
    end

    dailyUpkeep = 54

    return string.format(g_i18n:getText("shop_maintenanceValue"), g_i18n:formatMoney(dailyUpkeep, 2))
end
]]

-- Replace the age with the age since last repair, because actual age is useless
function ssMaintenance:getSpecValueAge(superFunc, vehicle)
    if vehicle ~= nil and vehicle.ssLastRepairDay ~= nil then
        return string.format(g_i18n:getText("shop_age"), ssSeasonsUtil:currentDayNumber() - vehicle.ssLastRepairDay)
    elseif vehicle ~= nil and vehicle.age ~= nil then
        return "-"
    end

    return nil
end

function ssMaintenance:sellAreaTriggerCallback(superFunc, triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
    if otherShapeId ~= nil and (onEnter or onLeave) then
        if onEnter then
            self.vehicleInRange[otherShapeId] = true

            local vehicle = g_currentMission.nodeToVehicle[otherShapeId]
            if vehicle ~= nil then
                vehicle.ssInRangeOfWorkshop = self
            end
        elseif onLeave then
            self.vehicleInRange[otherShapeId] = nil

            local vehicle = g_currentMission.nodeToVehicle[otherShapeId]
            if vehicle ~= nil then
                vehicle.ssInRangeOfWorkshop = nil
            end
        end

        self:determineCurrentVehicle()
    end
end
