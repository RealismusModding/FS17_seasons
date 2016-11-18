---------------------------------------------------------------------------------------------------------
-- MAINTENANCE SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  To adjust the maintenance system
-- Authors:  Jarvixes (Rahkiin), Rival
--

ssMaintenance = {}
ssMaintenance.LIFETIME_FACTOR = 5
ssMaintenance.REPAIR_NIGHT_FACTOR = 1
ssMaintenance.REPAIR_SHOP_FACTOR = 0.5
ssMaintenance.DIRT_FACTOR = 0.2

ssMaintenance.settingsProperties = {}

SpecializationUtil.registerSpecialization("repairable", "ssRepairable", g_currentModDirectory .. "/src/ssRepairable.lua")

function ssMaintenance.preSetup()
    ssSettings.add("maintenance", ssMaintenance)

    Vehicle.getDailyUpKeep = Utils.overwrittenFunction(Vehicle.getDailyUpKeep, ssMaintenance.getDailyUpKeep)
    Vehicle.getSpecValueAge = Utils.overwrittenFunction(Vehicle.getSpecValueAge, ssMaintenance.getSpecValueAge)
    -- Vehicle.getSpecValueDailyUpKeep = Utils.overwrittenFunction(Vehicle.getSpecValueDailyUpKeep, ssMaintenance.getSpecValueDailyUpKeep)

    VehicleSellingPoint.determineCurrentVehicle = Utils.overwrittenFunction(VehicleSellingPoint.determineCurrentVehicle, ssMaintenance.determineCurrentWorkshopVehicle)
end

function ssMaintenance.setup()
    ssSettings.load("maintenance", ssMaintenance)

    addModEventListener(ssMaintenance)
end

function ssMaintenance:loadMap(name)
    self:installRepairableSpecialization()

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

function ssMaintenance:repairCost(vehicle, storeItem, operatingTime)
    RF1 = 0.007 -- FIXME: from file
    RF2 = 2.0   -- FIXME: from file

    local lifetime = storeItem.lifetime
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
    local dealerMultiplier = atDealer and 1.2 or 1
    local difficultyMultiplier = 1 -- FIXME * difficulty mutliplier

    log(tostring((costs + 45) * dealerMultiplier * difficultyMultiplier))

    return (costs + 45) * dealerMultiplier * difficultyMultiplier
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

function ssMaintenance:determineCurrentWorkshopVehicle(superFunc)
    -- Remove inRange property
    if self.currentVehicle ~= nil then
        self.currentVehicle.ssInRangeOfWorkshop = nil
        self.currentVehicle = nil
    end

    for vehicleId, inRange in pairs(self.vehicleInRange) do
        if inRange ~= nil then
            self.currentVehicle = g_currentMission.nodeToVehicle[vehicleId]

            if self.currentVehicle ~= nil then
                -- Add inRange property
                self.currentVehicle.ssInRangeOfWorkshop = self
                break
            end
        end
        -- invalid vehicle (not existing or left), remove from list
        self.vehicleInRange[vehicleId] = nil
    end
end

--[[
    print_r(storeItem)

    storeItem.lifetime
    storeItem.price
    storeItem.specs.power
    storeItem.dailyUpkeep
    ]]

    --getDirtAmount
    --[[
    log("Vehicle dirt "..tostring(self.getDirtAmount))
    [id] => 68
    operatingTime
    speedLimit
    [typeDesc] => "cultivator"
    [price] => 9400
    [age] => 56
    [configFileName] => "data/vehicles/tools/kuhn/kuhnCultimerL300.xml"
    [lastMoveTime] => 16.617000579834
    [dirtAmount] => 0.11339925229549 -- might only be available on "washable", dont use, use the function on the specification

if g_currentMission:getIsServer() then
        g_currentMission:addSharedMoney(-totalTaxes, "vehicleRunningCost")
        g_currentMission:addSharedMoney(-totalMaintenance, "vehicleRunningCost")

        g_currentMission.missionStats:updateStats("expenses", totalTaxes + totalMaintenance)

        g_currentMission:addMoneyChange(-totalTaxes, FSBaseMission.MONEY_TYPE_SINGLE, true, ssLang.getText("SS_VEHICLE_TAXES"))
        g_currentMission:addMoneyChange(-totalMaintenance, FSBaseMission.MONEY_TYPE_SINGLE, true, ssLang.getText("SS_VEHICLE_MAINTENANCE"))
    else
        g_client:getServerConnection():sendEvent(CheatMoneyEvent:new(-totalTaxes))
        g_client:getServerConnection():sendEvent(CheatMoneyEvent:new(-totalMaintenance))
    end
]]
