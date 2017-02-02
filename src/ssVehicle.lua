---------------------------------------------------------------------------------------------------------
-- MAINTENANCE SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  To adjust the maintenance system
-- Authors:  Rahkiin, reallogger, Rival
--

ssVehicle = {}
g_seasons.vehicle = ssVehicle

ssVehicle.LIFETIME_FACTOR = 5
ssVehicle.REPAIR_NIGHT_FACTOR = 1
ssVehicle.REPAIR_SHOP_FACTOR = 0.5
ssVehicle.DIRT_FACTOR = 0.2
ssVehicle.SERVICE_INTERVAL = 30

ssVehicle.repairFactors = {}
ssVehicle.allowedInWinter = {}

SpecializationUtil.registerSpecialization("repairable", "ssRepairable", g_seasons.modDir .. "src/ssRepairable.lua")
SpecializationUtil.registerSpecialization("snowtracks", "ssSnowTracks", g_seasons.modDir .. "src/ssSnowTracks.lua")

function ssVehicle:preLoad()
    ssVehicle:registerWheelTypes()
end

function ssVehicle:load(savegame, key)
    self.snowTracksEnabled = ssStorage.getXMLBool(savegame, key .. ".settings.snowTracks", true)
end

function ssVehicle:save(savegame, key)
    ssStorage.setXMLBool(savegame, key .. ".settings.snowTracks", self.snowTracksEnabled)
end

function ssVehicle:loadMap()
    g_currentMission.environment:addDayChangeListener(self)
    g_seasons.environment:addSeasonLengthChangeListener(self)

    Vehicle.getDailyUpKeep = Utils.overwrittenFunction(Vehicle.getDailyUpKeep, ssVehicle.getDailyUpKeep)
    Vehicle.getSellPrice = Utils.overwrittenFunction(Vehicle.getSellPrice, ssVehicle.getSellPrice)
    Vehicle.getSpecValueAge = Utils.overwrittenFunction(Vehicle.getSpecValueAge, ssVehicle.getSpecValueAge)
    Vehicle.getSpeedLimit = Utils.overwrittenFunction(Vehicle.getSpeedLimit, ssVehicle.getSpeedLimit)
    Vehicle.draw = Utils.overwrittenFunction(Vehicle.draw, ssVehicle.vehicleDraw)
    Vehicle.updateWheelFriction = Utils.overwrittenFunction(Vehicle.updateWheelFriction, ssVehicle.updateWheelFriction)
    Vehicle.getGroundType = Utils.overwrittenFunction(Vehicle.getGroundType, ssVehicle.getGroundType)
    -- Vehicle.getSpecValueDailyUpKeep = Utils.overwrittenFunction(Vehicle.getSpecValueDailyUpKeep, ssVehicle.getSpecValueDailyUpKeep)

    InGameMenu.onCreateGarageVehicleAge = Utils.overwrittenFunction(InGameMenu.onCreateGarageVehicleAge, ssVehicle.inGameMenuOnCreateGarageVehicleAge)

    VehicleSellingPoint.sellAreaTriggerCallback = Utils.overwrittenFunction(VehicleSellingPoint.sellAreaTriggerCallback, ssVehicle.sellAreaTriggerCallback)

    ssVehicle.repairInterval = g_seasons.environment.daysInSeason * 2

    self:installVehicleSpecializations()
    self:loadRepairFactors()
    self:loadAllowedInWinter()
end

function ssVehicle:dayChanged()
    for i, vehicle in pairs(g_currentMission.vehicles) do
        if SpecializationUtil.hasSpecialization(ssRepairable, vehicle.specializations) and not SpecializationUtil.hasSpecialization(Motorized, vehicle.specializations) then
            self:repair(vehicle,storeItem)
        end
    end
end

function ssVehicle:seasonLengthChanged()
    self.repairInterval = g_seasons.environment.daysInSeason * 2
end

function ssVehicle:installVehicleSpecializations()
    for _, vehicleType in pairs(VehicleTypeUtil.vehicleTypes) do
        if vehicleType ~= nil and SpecializationUtil.hasSpecialization(Washable, vehicleType.specializations) then
            table.insert(vehicleType.specializations, SpecializationUtil.getSpecialization("repairable"))
            table.insert(vehicleType.specializations, SpecializationUtil.getSpecialization("snowtracks"))
        end
    end
end

function ssVehicle:loadRepairFactors()
    -- Open file
    local file = loadXMLFile("factors", g_seasons.modDir .. "data/repairFactors.xml")

    ssVehicle.repairFactors = {}

    local i = 0
    while true do
        local key = string.format("factors.factor(%d)", i)
        if not hasXMLProperty(file, key) then break end

        local category = getXMLString(file, key .. "#category")
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

-- all
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

-- repairable
function ssVehicle:maintenanceRepairCost(vehicle, storeItem, isRepair)
    local prevOperatingTime = math.floor(vehicle.ssYesterdayOperatingTime) / 1000 / 60 / 60
    local operatingTime = math.floor(vehicle.operatingTime) / 1000 / 60 / 60
    local repairFactor = isRepair and ssVehicle.REPAIR_SHOP_FACTOR or ssVehicle.REPAIR_NIGHT_FACTOR
    local daysSinceLastRepair = g_currentMission.environment.currentDay - vehicle.ssLastRepairDay

    -- Calculate the amount of dirt on the vehicle, on average
    local avgDirtAmount = 0
    if operatingTime ~= prevOperatingTime then
        -- Cum dirt is per ms, while the operating times are in hours.
        avgDirtAmount = (vehicle.ssCumulativeDirt / 1000 / 60 / 60) / Utils.clamp(operatingTime - prevOperatingTime, 1, 24)
    end

    -- Calculate the repair costs
    local prevRepairCost = self:repairCost(vehicle, storeItem, prevOperatingTime)
    local newRepairCost = self:repairCost(vehicle, storeItem, operatingTime)

    -- Calculate the final maintenance costs
    local maintenanceCost = 0

    if daysSinceLastRepair >= ssVehicle.repairInterval or isRepair then
        maintenanceCost = (newRepairCost - prevRepairCost) * repairFactor * (0.8 + ssVehicle.DIRT_FACTOR * avgDirtAmount ^ 2)
    end

    return maintenanceCost
end

-- all
function ssVehicle.taxInterestCost(vehicle, storeItem)
    return 0.03 * storeItem.price / (4 * g_seasons.environment.daysInSeason)
end

--function ssVehicle:resetOperatingTimeAndDirt()
--    for i, vehicle in pairs(g_currentMission.vehicles) do
--        if SpecializationUtil.hasSpecialization(ssRepairable, vehicle.specializations) then
--            vehicle.ssCumulativeDirt = 0
--            vehicle.ssYesterdayOperatingTime = vehicle.operatingTime
--        end
--    end
--end

-- repairable
-- Repair by resetting the last repair day and operating time
function ssVehicle:repair(vehicle, storeItem)
    --compared to game day since g_seasons.environment:currentDay() is shifted when changing season length
    vehicle.ssLastRepairDay = g_currentMission.environment.currentDay
    vehicle.ssYesterdayOperatingTime = vehicle.operatingTime
    vehicle.ssCumulativeDirt = 0

    return true
end

-- repairable
function ssVehicle:getRepairShopCost(vehicle, storeItem, atDealer)
    -- Can't repair twice on same day, that is silly
    if vehicle.ssLastRepairDay == g_currentMission.environment.currentDay then
        return 0
    end

    if storeItem == nil then
        storeItem = StoreItemsUtil.storeItemsByXMLFilename[vehicle.configFileName:lower()]
    end

    local costs = ssVehicle:maintenanceRepairCost(vehicle, storeItem, true)
    local dealerMultiplier = atDealer and 1.1 or 1
    local difficultyMultiplier = 1 -- FIXME * difficulty mutliplier
    local workCosts = atDealer and 45 or 35

    local overdueFactor = self:calculateOverdueFactor(vehicle) ^ 2

    return (costs + workCosts) * dealerMultiplier * difficultyMultiplier * overdueFactor
end

-- all (guard)
function ssVehicle:getDailyUpKeep(superFunc)
    local storeItem = StoreItemsUtil.storeItemsByXMLFilename[self.configFileName:lower()]

    -- If not repairable, show default amount
    if not SpecializationUtil.hasSpecialization(ssRepairable, self.specializations) then
        return superFunc(self)
    end

    local overdueFactor = ssVehicle:calculateOverdueFactor(self)

    -- This is for visually in the display
    local costs = ssVehicle:taxInterestCost(self, storeItem)
    if SpecializationUtil.hasSpecialization(Motorized, self.specializations) then
        costs = (costs + ssVehicle:maintenanceRepairCost(self, storeItem, false)) * overdueFactor
    else
        costs = costs + ssVehicle:maintenanceRepairCost(self, storeItem, false) + ssVehicle:getRepairShopCost(self,storeItem,true)
    end

    return costs
end

-- all
function ssVehicle:calculateOverdueFactor(vehicle)
    local overdueFactor = 1

    if SpecializationUtil.hasSpecialization(ssRepairable, vehicle.specializations) then
        local serviceInterval = ssVehicle.SERVICE_INTERVAL - math.floor((vehicle.operatingTime - vehicle.ssYesterdayOperatingTime)) / 1000 / 60 / 60
        local daysSinceLastRepair = g_currentMission.environment.currentDay - vehicle.ssLastRepairDay

        if daysSinceLastRepair >= ssVehicle.repairInterval or serviceInterval < 0 then
            overdueFactor = math.ceil(math.max(daysSinceLastRepair / ssVehicle.repairInterval, math.abs(serviceInterval / ssVehicle.SERVICE_INTERVAL)))
        end
    end

    return overdueFactor
end

function ssVehicle:getSellPrice(superFunc)
    local storeItem = StoreItemsUtil.storeItemsByXMLFilename[self.configFileName:lower()]
    local price = storeItem.price
    local minSellPrice = storeItem.price * 0.03
    local sellPrice
    local operatingTime = self.operatingTime / (60 * 60 * 1000) -- hours
    local age = self.age / (g_seasons.environment.daysInSeason * g_seasons.environment.SEASONS_IN_YEAR) -- year
    local power = Utils.getNoNil(storeItem.specs.power, storeItem.dailyUpkeep)

    local factors = ssVehicle.repairFactors[storeItem.category]
    local lifetime = storeItem.lifetime
    if factors ~= nil then
        lifetime = Utils.getNoNil(factors.lifetime, lifetime)
    end

    local p1, p2, p3, p4, depFac, brandFac

    if storeItem.category == "tractors" or storeItem.category == "wheelLoaders" or storeItem.category == "teleLoaders" or storeItem.category == "skidSteers" then
        p1 = -0.015
        p2 = 0.42
        p3 = -4
        p4 = 85
        depFac = (p1 * age ^ 3 + p2 * age ^ 2 + p3 * age + p4) / 100
        brandFac = math.min(math.sqrt(power / storeItem.dailyUpkeep),1.1)

    elseif storeItem.category == "harvesters" or storeItem.category == "forageHarvesters" or storeItem.category == "potatoHarvesters" or storeItem.category == "beetHarvesters" then
        p1 = 81
        p2 = -0.105
        depFac = (p1 * math.exp(p2 * age)) / 100
        brandFac = 1

    else
        p1 = -0.0125
        p2 = 0.45
        p3 = -7
        p4 = 65
        depFac = (p1 * age ^ 3 + p2 * age ^ 2 + p3 * age + p4) / 100
        brandFac = 1

    end

    if age == 0 and operatingTime < 2 then
        sellPrice = price
    else
        local overdueFactor = ssVehicle:calculateOverdueFactor(self)
        sellPrice = math.max((depFac * price - (depFac * price) * operatingTime / lifetime) * brandFac / (overdueFactor ^ 0.1), minSellPrice)
    end

    return sellPrice
end

-- Replace the visual age with the age since last repair, because actual age is useless
function ssVehicle:getSpecValueAge(superFunc, vehicle) -- storeItem, realItem
    if vehicle ~= nil and vehicle.ssLastRepairDay ~= nil and SpecializationUtil.hasSpecialization(Motorized, vehicle.specializations) then
        return string.format(g_i18n:getText("shop_age"), g_seasons.environment.daysInSeason * 2 - (g_seasons.environment:currentDay() - vehicle.ssLastRepairDay))
    elseif vehicle ~= nil and vehicle.age ~= nil then
        return "-"
    elseif not SpecializationUtil.hasSpecialization(Motorized, vehicle.specializations) then
        return ssLang.getText("SS_REPAIR_AT_MIDNIGHT", "at midnight")
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

    -- only limit it if it works the ground and the ground is not frozen
    if not ssWeatherManager:isGroundFrozen()
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
        self.ssNotAllowedSoilFrozen = true
        return 0, recalc
    else
        self.ssNotAllowedSoilFrozen = false
    end

    return vanillaSpeed, recalc
end

function ssVehicle:vehicleDraw(superFunc, dt)
    superFunc(self, dt)

    if self.isClient then
        if self.ssNotAllowedSoilFrozen then
            g_currentMission:showBlinkingWarning(ssLang.getText("SS_WARN_SOILFROZEN"), 2000)
        end
    end

end

function ssVehicle:updateWheelTireFriction(superFunc, wheel)
    if self.isServer and self.isAddedToPhysics then
        if wheel.inSnow then
            if wheel.tireType == WheelsUtil.getTireType('studded') or wheel.tireType == WheelsUtil.getTireType('chains') then
                setWheelShapeTireFriction(wheel.node, wheel.wheelShape, wheel.maxLongStiffness, wheel.maxLatStiffness, wheel.maxLatStiffnessLoad, wheel.frictionScale*wheel.tireGroundFrictionCoeff)
            else
                setWheelShapeTireFriction(wheel.node, wheel.wheelShape, wheel.maxLongStiffness, wheel.maxLatStiffness, wheel.maxLatStiffnessLoad, wheel.frictionScale*wheel.tireGroundFrictionCoeff*0.15)
            end
        else
            setWheelShapeTireFriction(wheel.node, wheel.wheelShape, wheel.maxLongStiffness, wheel.maxLatStiffness, wheel.maxLatStiffnessLoad, wheel.frictionScale*wheel.tireGroundFrictionCoeff)
        end
	end
end

function ssVehicle:getGroundType(superFunc,wheel)
    if wheel.inSnow then
        return WheelsUtil.GROUND_SOFT_TERRAIN
    end
end

function ssVehicle:registerWheelTypes()
    local studdedFrictionCoeffs = {}
    local studdedFrictionCoeffsWet = {}
    local snowchainsFrictionCoeffs = {}
    local snowchainsFrictionCoeffsWet = {}

    studdedFrictionCoeffs[WheelsUtil.GROUND_ROAD] = 0.95
    studdedFrictionCoeffs[WheelsUtil.GROUND_HARD_TERRAIN] = 1.1
    studdedFrictionCoeffs[WheelsUtil.GROUND_SOFT_TERRAIN] = 1.0
    studdedFrictionCoeffs[WheelsUtil.GROUND_FIELD] = 0.9

    studdedFrictionCoeffsWet[WheelsUtil.GROUND_ROAD] = 0.90
    studdedFrictionCoeffsWet[WheelsUtil.GROUND_HARD_TERRAIN] = 1.0
    studdedFrictionCoeffsWet[WheelsUtil.GROUND_SOFT_TERRAIN] = 0.85
    studdedFrictionCoeffsWet[WheelsUtil.GROUND_FIELD] = 0.75

    snowchainsFrictionCoeffs[WheelsUtil.GROUND_ROAD] = 0.85
    snowchainsFrictionCoeffs[WheelsUtil.GROUND_HARD_TERRAIN] = 1.0
    snowchainsFrictionCoeffs[WheelsUtil.GROUND_SOFT_TERRAIN] = 1.15
    snowchainsFrictionCoeffs[WheelsUtil.GROUND_FIELD] = 1.1

    snowchainsFrictionCoeffsWet[WheelsUtil.GROUND_ROAD] = 0.8
    snowchainsFrictionCoeffsWet[WheelsUtil.GROUND_HARD_TERRAIN] = 0.95
    snowchainsFrictionCoeffsWet[WheelsUtil.GROUND_SOFT_TERRAIN] = 1.05
    snowchainsFrictionCoeffsWet[WheelsUtil.GROUND_FIELD] = 0.95

    WheelsUtil.registerTireType("studded",studdedFrictionCoeffs,studdedFrictionCoeffsWet)
    WheelsUtil.registerTireType("chains",snowchainsFrictionCoeffs,snowchainsFrictionCoeffsWet)

end
