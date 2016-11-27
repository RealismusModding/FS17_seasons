---------------------------------------------------------------------------------------------------------
-- MAINTENANCE SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  To adjust the maintenance system
-- Authors:  Jarvixes (Rahkiin), reallogger, Rival
--

ssVehicle = {}
ssVehicle.LIFETIME_FACTOR = 5
ssVehicle.REPAIR_NIGHT_FACTOR = 1
ssVehicle.REPAIR_SHOP_FACTOR = 0.5
ssVehicle.DIRT_FACTOR = 0.2

ssVehicle.repairFactors = {}
ssVehicle.allowedInWinter = {}

SpecializationUtil.registerSpecialization("repairable", "ssRepairable", ssSeasonsMod.modDir .. "/src/ssRepairable.lua")

function ssVehicle:loadMap(name)
    g_currentMission.environment:addDayChangeListener(self)

    Vehicle.getDailyUpKeep = Utils.overwrittenFunction(Vehicle.getDailyUpKeep, ssVehicle.getDailyUpKeep)
    Vehicle.getSellPrice = Utils.overwrittenFunction(Vehicle.getSellPrice, ssVehicle.getSellPrice)
    Vehicle.getSpecValueAge = Utils.overwrittenFunction(Vehicle.getSpecValueAge, ssVehicle.getSpecValueAge)
    Vehicle.getSpeedLimit = Utils.overwrittenFunction(Vehicle.getSpeedLimit, ssVehicle.getSpeedLimit)
    Vehicle.draw = Utils.overwrittenFunction(Vehicle.draw, ssVehicle.vehicleDraw)
    -- Vehicle.getSpecValueDailyUpKeep = Utils.overwrittenFunction(Vehicle.getSpecValueDailyUpKeep, ssVehicle.getSpecValueDailyUpKeep)

    VehicleSellingPoint.sellAreaTriggerCallback = Utils.overwrittenFunction(VehicleSellingPoint.sellAreaTriggerCallback, ssVehicle.sellAreaTriggerCallback)

    self:installRepairableSpecialization()
    self:loadRepairFactors()
    self:loadAllowedInWinter()
end

function ssVehicle:deleteMap()
end

function ssVehicle:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssVehicle:keyEvent(unicode, sym, modifier, isDown)
end

function ssVehicle:draw()
end

function ssVehicle:update(dt)
end

function ssVehicle:dayChanged()
    self:resetOperatingTimeAndDirt()
end

function ssVehicle:installRepairableSpecialization()
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

function ssVehicle:loadRepairFactors()
    -- Open file
    local file = loadXMLFile("factors", ssSeasonsMod.modDir .. "/data/repairFactors.xml")

    ssVehicle.repairFactors = {}

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

        ssVehicle.repairFactors[category] = config

        i = i + 1
    end

    -- Close file
    delete(file)
end

function ssVehicle:loadAllowedInWinter()
    ssVehicle.allowedInWinter = {
        [WorkArea.AREATYPE_BALER] = false,
        [WorkArea.AREATYPE_COMBINE] = false,
        [WorkArea.AREATYPE_CULTIVATOR] = false,
        [WorkArea.AREATYPE_CUTTER] = false,
        [WorkArea.AREATYPE_DEFAULT] = false,
        [WorkArea.AREATYPE_FORAGEWAGON] = false,
        [WorkArea.AREATYPE_FRUITPREPARER] = false,
        [WorkArea.AREATYPE_MOWER] = true,
        [WorkArea.AREATYPE_MOWERDROP] = true,
        [WorkArea.AREATYPE_PLOUGH] = false,
        [WorkArea.AREATYPE_RIDGEMARKER] = false,
        [WorkArea.AREATYPE_ROLLER] = true,
        [WorkArea.AREATYPE_SOWINGMACHINE] = false,
        [WorkArea.AREATYPE_SPRAYER] = false,
        [WorkArea.AREATYPE_TEDDER] = false,
        [WorkArea.AREATYPE_TEDDERDROP] = false,
        [WorkArea.AREATYPE_WEEDER] = false,
        [WorkArea.AREATYPE_WINDROWER] = false,
        [WorkArea.AREATYPE_WINDROWERDROP] = false,
    }
end

function ssVehicle:repairCost(vehicle, storeItem, operatingTime)
    local data = ssVehicle.repairFactors[storeItem.category]

    if data == nil then
        data = ssVehicle.repairFactors.other
    end

    local RF1 = data.RF1
    local RF2 = data.RF2
    local lifetime = data.lifetime

    local dailyUpkeep = storeItem.dailyUpkeep

    local powerMultiplier = 1
    if storeItem.specs.power ~= nil then
        powerMultiplier = dailyUpkeep / storeItem.specs.power
    end

    if operatingTime < lifetime / ssVehicle.LIFETIME_FACTOR then
        return 0.025 * storeItem.price * (RF1 * (operatingTime / 5) ^ RF2) * powerMultiplier
    else
        return 0.025 * storeItem.price * (RF1 * (operatingTime / (5 * ssVehicle.LIFETIME_FACTOR)) ^ RF2) * (1 + (operatingTime - lifetime / ssVehicle.LIFETIME_FACTOR) / (lifetime / 5) * 2) * powerMultiplier
    end
end

function ssVehicle:maintenanceRepairCost(vehicle, storeItem, isRepair)
    local prevOperatingTime = vehicle.ssYesterdayOperatingTime / 1000 / 60 / 60
    local operatingTime = vehicle.operatingTime / 1000 / 60 / 60
    local daysSinceLastRepair = ssSeasonsUtil:currentDayNumber() - vehicle.ssLastRepairDay
    local repairFactor = isRepair and ssVehicle.REPAIR_SHOP_FACTOR or ssVehicle.REPAIR_NIGHT_FACTOR

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
        maintenanceCost = (newRepairCost - prevRepairCost) * repairFactor * (0.8 + ssVehicle.DIRT_FACTOR * avgDirtAmount ^ 2)
    end

    return maintenanceCost
end

function ssVehicle.taxInterestCost(vehicle, storeItem)
    return 0.03 * storeItem.price / (4 * ssSeasonsUtil.daysInSeason)
end

function ssVehicle:resetOperatingTimeAndDirt()
    for i, vehicle in pairs(g_currentMission.vehicles) do
        if SpecializationUtil.hasSpecialization(ssRepairable, vehicle.specializations) then
            vehicle.ssCumulativeDirt = 0
            vehicle.ssYesterdayOperatingTime = vehicle.operatingTime
        end
    end
end

-- Repair by resetting the last repair day and operating time
function ssVehicle:repair(vehicle, storeItem)
    vehicle.ssLastRepairDay = ssSeasonsUtil:currentDayNumber()
    vehicle.ssYesterdayOperatingTime = vehicle.operatingTime

    return true
end

function ssVehicle:getRepairShopCost(vehicle, storeItem, atDealer)
    -- Can't repair twice on same day, that is silly
    if vehicle.ssLastRepairDay == ssSeasonsUtil:currentDayNumber() then
        return 0
    end

    if storeItem == nil then
        storeItem = StoreItemsUtil.storeItemsByXMLFilename[vehicle.configFileName:lower()]
    end

    local costs = ssVehicle:maintenanceRepairCost(vehicle, storeItem, true)
    local dealerMultiplier = atDealer and 1.1 or 1
    local difficultyMultiplier = 1 -- FIXME * difficulty mutliplier
    local workCosts = atDealer and 45 or 35

    return (costs + workCosts) * dealerMultiplier * difficultyMultiplier
end

function ssVehicle:getDailyUpKeep(superFunc)
    local storeItem = StoreItemsUtil.storeItemsByXMLFilename[self.configFileName:lower()]

    -- If not repairable, show default amount
    if not SpecializationUtil.hasSpecialization(ssRepairable, self.specializations) then
        return superFunc(self)
    end

    -- This is for visually in the display
    local costs = ssVehicle:taxInterestCost(self, storeItem)
    costs = costs + ssVehicle:maintenanceRepairCost(self, storeItem, false)

    return costs
end

function ssVehicle:getSellPrice(superFunc)
    local storeItem = StoreItemsUtil.storeItemsByXMLFilename[self.configFileName:lower()]
    local price = storeItem.price
    local operatingTime = self.operatingTime / (60 * 60 * 1000) -- hours
    local age = self.age / (ssSeasonsUtil.daysInSeason * ssSeasonsUtil.seasonsInYear) -- year
    local power = Utils.getNoNil(storeItem.specs.power, storeItem.dailyUpkeep)

    local factors = ssVehicle.repairFactors[storeItem.category]
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
        sellPrice = math.max((depFac * price - (depFac * price) * operatingTime / lifetime) * math.sqrt(power / storeItem.dailyUpkeep),1000)
    end

    return sellPrice
end

--[[
function ssVehicle:getSpecValueDailyUpKeep(superFunc, storeItem, realItem)
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
function ssVehicle:getSpecValueAge(superFunc, vehicle)
    if vehicle ~= nil and vehicle.ssLastRepairDay ~= nil then
        return string.format(g_i18n:getText("shop_age"), ssSeasonsUtil:currentDayNumber() - vehicle.ssLastRepairDay)
    elseif vehicle ~= nil and vehicle.age ~= nil then
        return "-"
    end

    return nil
end

-- Tell a vehicle when it is in the area of a workshop. This information is
-- then used in ssRepairable to show or hide the repair option
function ssVehicle:sellAreaTriggerCallback(superFunc, triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
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

-- Limit the speed of working implements and machine on land to 4kmh or 0.25 their normal speed.
-- Only in the winter
function ssVehicle:getSpeedLimit(superFunc, onlyIfWorking)
    local vanillaSpeed, recalc = superFunc(self, onlyIfWorking)

    if not ssSeasonsUtil:isSeason(3)
        or not SpecializationUtil.hasSpecialization(WorkArea, self.specializations) then
       return vanillaSpeed, recalc
    end

    local isLowered = false

    -- Look at the work areas and if it is active (lowered)
    for _, area in pairs(self.workAreas) do
        if ssVehicle.allowedInWinter[area.type] == false
            and self:getIsWorkAreaActive(area) then
            isLowered = true
        end
    end

    if isLowered then
        self.ssNotAllowedInWinter = true
        return 0, recalc
    else
        self.ssNotAllowedInWinter = false
    end

    return vanillaSpeed, recalc
end

function ssVehicle:vehicleDraw(superFunc, dt)
    superFunc(self, dt)

    if self.isClient then
        if self.ssNotAllowedInWinter then
            g_currentMission:showBlinkingWarning(ssLang.getText("SS_WARN_NOTDURINGWINTER"), 2000);
        end
    end
end

