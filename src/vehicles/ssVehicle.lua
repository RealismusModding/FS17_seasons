----------------------------------------------------------------------------------------------------
-- MAINTENANCE SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  To adjust the maintenance system
-- Authors:  Rahkiin, reallogger, Rival
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssVehicle = {}

ssVehicle.LIFETIME_FACTOR = 3
ssVehicle.REPAIR_NIGHT_FACTOR = 1
ssVehicle.REPAIR_SHOP_FACTOR = 0.5
ssVehicle.DIRT_FACTOR = 0.2
ssVehicle.SERVICE_INTERVAL = 30

-- This must be loaded at once, during source-time.
source(ssSeasonsMod.directory .. "src/events/ssRepairVehicleEvent.lua")
source(ssSeasonsMod.directory .. "src/events/ssVariableTreePlanterEvent.lua")

function ssVehicle:preLoad()
    g_seasons.vehicle = ssVehicle

    ssUtil.registerSpecialization("repairable", "ssRepairable", g_seasons.modDir .. "src/vehicles/specializations/ssRepairable.lua")
    ssUtil.registerSpecialization("snowtracks", "ssSnowTracks", g_seasons.modDir .. "src/vehicles/specializations/ssSnowTracks.lua")
    ssUtil.registerSpecialization("snowfillable", "ssSnowFillable", g_seasons.modDir .. "src/vehicles/specializations/ssSnowFillable.lua")
    ssUtil.registerSpecialization("grassfillable", "ssGrassFillable", g_seasons.modDir .. "src/vehicles/specializations/ssGrassFillable.lua")
    ssUtil.registerSpecialization("motorFailure", "ssMotorFailure", g_seasons.modDir .. "src/vehicles/specializations/ssMotorFailure.lua")
    ssUtil.registerSpecialization("variableTreePlanter", "ssVariableTreePlanter", g_seasons.modDir .. "src/vehicles/specializations/ssVariableTreePlanter.lua")
    ssUtil.registerSpecialization("ss_tedder", "ssTedder", g_seasons.modDir .. "src/vehicles/specializations/ssTedder.lua")

    ssVehicle:registerWheelTypes()

    ssUtil.overwrittenFunction(Vehicle, "getDailyUpKeep", ssVehicle.vehicleGetDailyUpKeep)
    ssUtil.overwrittenFunction(Vehicle, "getSellPrice", ssVehicle.vehicleGetSellPrice)
    ssUtil.overwrittenFunction(Vehicle, "getSpecValueAge", ssVehicle.vehicleGetSpecValueAge)
    ssUtil.overwrittenFunction(Vehicle, "getSpeedLimit", ssVehicle.getSpeedLimit)
    ssUtil.overwrittenFunction(Vehicle, "draw", ssVehicle.vehicleDraw)
    ssUtil.overwrittenFunction(Combine, "getIsThreshingAllowed", ssVehicle.getIsThreshingAllowed)
    ssUtil.appendedFunction(AIVehicle, "update", ssVehicle.aiVehicleUpdate)
    ssUtil.appendedFunction(VehicleSellingPoint, "sellAreaTriggerCallback", ssVehicle.sellAreaTriggerCallback)
    ssUtil.overwrittenFunction(Washable, "updateTick", ssVehicle.washableUpdateTick)

    ssUtil.appendedFunction(DirectSellDialog, "setVehicle", ssVehicle.directSellDialogSetVehicle)
    ssUtil.overwrittenFunction(DirectSellDialog, "onClickOk", ssVehicle.directSellDialogOnClickOk)

    -- Functions for ssMotorFailure, needs to be reloaded every game
    ssUtil.overwrittenConstant(Motorized, "startMotor", ssMotorFailure.startMotor)
    ssUtil.overwrittenConstant(Motorized, "stopMotor", ssMotorFailure.stopMotor)
end

function ssVehicle:load(savegame, key)
    self.snowTracksEnabled = ssXMLUtil.getBool(savegame, key .. ".settings.snowTracks", true)
end

function ssVehicle:save(savegame, key)
    ssXMLUtil.setBool(savegame, key .. ".settings.snowTracks", self.snowTracksEnabled)
end

function ssVehicle:loadMap()
    g_currentMission.environment:addDayChangeListener(self)
    g_seasons.environment:addSeasonLengthChangeListener(self)

    g_currentMission:setAutomaticMotorStartEnabled(false)

    ssVehicle.repairFactors = {}
    ssVehicle.allowedInWinter = {}

    if g_currentMission:getIsServer() then
        self:updateRepairInterval()
    end

    if g_addCheatCommands then
        addConsoleCommand("ssRepairVehicle", "Repair vehicle you are entered", "consoleCommandRepairVehicle", self)
        addConsoleCommand("ssRepairAllVehicles", "Repair all vehicles", "consoleCommandRepairAllVehicles", self)
    end

    if g_seasons.debug then
        addConsoleCommand("ssTestVehicle", "Test vehicle", "consoleCommandTestVehicle", self)
    end

    -- Override the i18n for threshing during rain, as it is now not allowed when moisture is too high
    -- Show the same warning when the moisture system is disabled.
    ssUtil.overwrittenConstant(getfenv(0)["g_i18n"].texts, "warning_doNotThreshDuringRainOrHail", ssLang.getText("warning_doNotThreshWithMoisture"))

    self:installVehicleSpecializations()
    self:loadRepairFactors()
    self:loadAllowedInWinter()
end

function ssVehicle:deleteMap()
    if g_addCheatCommands then
        removeConsoleCommand("ssRepairVehicle")
        removeConsoleCommand("ssRepairAllVehicles")
    end

    if g_seasons.debug then
        removeConsoleCommand("ssTestVehicle")
    end
end

function ssVehicle:readStream(streamId, connection)
    self:updateRepairInterval()

    self.snowTracksEnabled = streamReadBool(streamId)
end

function ssVehicle:writeStream(streamId, connection)
    streamWriteBool(streamId, self.snowTracksEnabled)
end

function ssVehicle:updateRepairInterval()
    self.repairInterval = g_seasons.environment.daysInSeason * 4
end

function ssVehicle:dayChanged()
    for _, vehicle in pairs(g_currentMission.vehicles) do
        if SpecializationUtil.hasSpecialization(ssRepairable, vehicle.specializations) and not SpecializationUtil.hasSpecialization(Motorized, vehicle.specializations) then
            self:repair(vehicle)
        end
        if SpecializationUtil.hasSpecialization(ssGrassFillable, vehicle.specializations) then
            ssGrassFillable:ssRotGrass(vehicle)
        end
    end
end

function ssVehicle:seasonLengthChanged()
    self:updateRepairInterval()
end

function ssVehicle:installVehicleSpecializations()
    for _, vehicleType in pairs(VehicleTypeUtil.vehicleTypes) do
        if vehicleType ~= nil then
            table.insert(vehicleType.specializations, SpecializationUtil.getSpecialization("repairable"))

            if SpecializationUtil.hasSpecialization(Washable, vehicleType.specializations) then
                table.insert(vehicleType.specializations, SpecializationUtil.getSpecialization("snowtracks"))
            end

            if SpecializationUtil.hasSpecialization(Fillable, vehicleType.specializations) then
                table.insert(vehicleType.specializations, SpecializationUtil.getSpecialization("snowfillable"))
                table.insert(vehicleType.specializations, SpecializationUtil.getSpecialization("grassfillable"))
            end

            if SpecializationUtil.hasSpecialization(Motorized, vehicleType.specializations) then
                table.insert(vehicleType.specializations, SpecializationUtil.getSpecialization("motorFailure"))
            end

            if SpecializationUtil.hasSpecialization(Tedder, vehicleType.specializations) then
                table.insert(vehicleType.specializations, SpecializationUtil.getSpecialization("ss_tedder"))
            end

            if SpecializationUtil.hasSpecialization(TreePlanter, vehicleType.specializations) then
                table.insert(vehicleType.specializations, SpecializationUtil.getSpecialization("variableTreePlanter"))
            end
        end
    end
end

function ssVehicle:loadRepairFactors()
    -- Open file
    local file = loadXMLFile("factors", g_seasons:getDataPath("repairFactors"))

    ssVehicle.repairFactors = {}

    local i = 0
    while true do
        local key = string.format("factors.factor(%d)", i)
        if not hasXMLProperty(file, key) then break end

        local category = getXMLString(file, key .. "#category")
        if category == nil then
            logInfo("ssVehicle:", "repairFactors.xml is invalid")
            break
        end

        local RF1 = getXMLFloat(file, key .. ".RF1#value")
        local RF2 = getXMLFloat(file, key .. ".RF2#value")
        local lifetime = getXMLFloat(file, key .. ".ssLifeTime#value")

        if RF1 == nil or RF2 == nil or lifetime == nil then
            logInfo("ssVehicle:", "repairFactors.xml is invalid")
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
        [WorkArea.AREATYPE_BALER] = true,
        [WorkArea.AREATYPE_COMBINE] = true,
        [WorkArea.AREATYPE_CULTIVATOR] = false,
        [WorkArea.AREATYPE_CUTTER] = true,
        [WorkArea.AREATYPE_DEFAULT] = true,
        [WorkArea.AREATYPE_FORAGEWAGON] = true,
        [WorkArea.AREATYPE_FRUITPREPARER] = true,
        [WorkArea.AREATYPE_MOWER] = true,
        [WorkArea.AREATYPE_MOWERDROP] = true,
        [WorkArea.AREATYPE_PLOUGH] = false,
        [WorkArea.AREATYPE_RIDGEMARKER] = false,
        [WorkArea.AREATYPE_ROLLER] = true,
        [WorkArea.AREATYPE_SOWINGMACHINE] = false,
        [WorkArea.AREATYPE_SPRAYER] = false,
        [WorkArea.AREATYPE_TEDDER] = true,
        [WorkArea.AREATYPE_TEDDERDROP] = true,
        [WorkArea.AREATYPE_WEEDER] = false,
        [WorkArea.AREATYPE_WINDROWER] = true,
        [WorkArea.AREATYPE_WINDROWERDROP] = true,
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
        powerMultiplier = Utils.clamp(dailyUpkeep / storeItem.specs.power, 0.5, 2.5)
    end

    local endOfLifeRepairCost = 0.025 * storeItem.price * (RF1 * (lifetime / ssVehicle.LIFETIME_FACTOR^2) ^ RF2) * powerMultiplier

    if operatingTime < lifetime / ssVehicle.LIFETIME_FACTOR then
        return 0.025 * storeItem.price * (RF1 * (operatingTime / ssVehicle.LIFETIME_FACTOR) ^ RF2) * powerMultiplier
    else
        return 0.025 * storeItem.price  * (RF1 * (lifetime / ssVehicle.LIFETIME_FACTOR^2) ^ RF2) * (1 + (operatingTime - lifetime / ssVehicle.LIFETIME_FACTOR)) / (lifetime / ssVehicle.LIFETIME_FACTOR) * 2 * powerMultiplier + endOfLifeRepairCost
    end
end

-- repairable
function ssVehicle:maintenanceRepairCost(vehicle, storeItem, isRepair)
    local prevOperatingTime = math.floor(vehicle.ssLastRepairOperatingTime) / 1000 / 60 / 60
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
        maintenanceCost = math.min((newRepairCost - prevRepairCost) * repairFactor * (0.8 + ssVehicle.DIRT_FACTOR * avgDirtAmount ^ 2), storeItem.price * 1.5)
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
--            vehicle.ssLastRepairOperatingTime = vehicle.operatingTime
--        end
--    end
--end

-- repairable
-- Repair by resetting the last repair day and operating time
function ssVehicle:repair(vehicle)
    --compared to game day since g_seasons.environment:currentDay() is shifted when changing season length
    vehicle.ssLastRepairDay = g_currentMission.environment.currentDay
    vehicle.ssLastRepairOperatingTime = vehicle.operatingTime
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
    local workCosts = atDealer and 45 or 35

    local overdueFactor = self:calculateOverdueFactor(vehicle)

    return math.min((costs + workCosts + 50 * (overdueFactor - 1)) * dealerMultiplier * EconomyManager.getCostMultiplier() * overdueFactor^2, 1.5 * storeItem.price)
end

-- all (guard)
function ssVehicle:vehicleGetDailyUpKeep(superFunc)
    local storeItem = StoreItemsUtil.storeItemsByXMLFilename[self.configFileName:lower()]

    -- If not repairable, show default amount
    if not SpecializationUtil.hasSpecialization(ssRepairable, self.specializations) then
        return superFunc(self)
    end

    local overdueFactor = ssVehicle:calculateOverdueFactor(self)

    -- This is for visually in the display
    local costs = ssVehicle:taxInterestCost(self, storeItem)
    if SpecializationUtil.hasSpecialization(Motorized, self.specializations) then
        costs = (costs + ssVehicle:maintenanceRepairCost(self, storeItem, false))
    else
        -- not calling getRepairShopCost since it was unstable. ssLastRepairDay was sometimes equal to currentDay
        costs = costs + ssVehicle:maintenanceRepairCost(self, storeItem, true)
    end

    return costs
end

-- all
function ssVehicle:calculateOverdueFactor(vehicle)
    local overdueFactor = 1

    if SpecializationUtil.hasSpecialization(ssRepairable, vehicle.specializations) then
        local serviceInterval = ssVehicle.SERVICE_INTERVAL - math.floor((vehicle.operatingTime - vehicle.ssLastRepairOperatingTime)) / 1000 / 60 / 60
        local daysSinceLastRepair = g_currentMission.environment.currentDay - vehicle.ssLastRepairDay

        if daysSinceLastRepair >= ssVehicle.repairInterval or serviceInterval < 0 then
            overdueFactor = math.ceil(math.max(daysSinceLastRepair / ssVehicle.repairInterval, math.abs(serviceInterval / ssVehicle.SERVICE_INTERVAL)))
        end
    end

    return overdueFactor
end

function ssVehicle:vehicleGetSellPrice(superFunc)
    local storeItem = StoreItemsUtil.storeItemsByXMLFilename[self.configFileName:lower()]
    local price = ssVehicle:getFullBuyPrice(self,storeItem)
    local minSellPrice = price * 0.03
    local sellPrice
    local operatingTime = self.operatingTime / (60 * 60 * 1000) -- hours
    local age = self.age / (g_seasons.environment.daysInSeason * g_seasons.environment.SEASONS_IN_YEAR * 4) -- year
    local power = Utils.getNoNil(storeItem.specs.power, storeItem.dailyUpkeep)

    local factors = ssVehicle.repairFactors[storeItem.category]
    if factors == nil then
        factors = ssVehicle.repairFactors["other"]
    end
    lifetime = factors.lifetime

    local p1, p2, p3, p4, depFac, brandFac

    if storeItem.category == "tractors" or storeItem.category == "wheelLoaders" or storeItem.category == "teleLoaders" or storeItem.category == "skidSteers" then
        p1 = -0.015
        p2 = 0.42
        p3 = -4
        p4 = 85
        depFac = math.max(p1 * age ^ 3 + p2 * age ^ 2 + p3 * age + p4, 0) / 100
        brandFac = math.min(math.sqrt(power / storeItem.dailyUpkeep), 1.1)

    elseif storeItem.category == "harvesters" or storeItem.category == "forageHarvesters" or storeItem.category == "potatoHarvesters" or storeItem.category == "beetHarvesters" then
        p1 = 81
        p2 = -0.105
        depFac = math.max(p1 * math.exp(p2 * age), 0) / 100
        brandFac = 1

    else
        p1 = -0.0125
        p2 = 0.45
        p3 = -7
        p4 = 65
        depFac = math.max(p1 * age ^ 3 + p2 * age ^ 2 + p3 * age + p4, 0) / 100
        brandFac = 1

    end

    if age == 0 and operatingTime < 0.5 then
        sellPrice = price
    else
        local overdueFactor = ssVehicle:calculateOverdueFactor(self)
        sellPrice = math.max((depFac * price - (depFac * price) * operatingTime / (lifetime / ssVehicle.LIFETIME_FACTOR)) * brandFac / (overdueFactor ^ 0.1), minSellPrice)
    end

    return sellPrice
end

-- Replace the visual age with the age since last repair, because actual age is useless
function ssVehicle.vehicleGetSpecValueAge(superFunc, storeItem, realItem) -- storeItem, realItem
    if realItem ~= nil and realItem.ssLastRepairDay ~= nil and SpecializationUtil.hasSpecialization(Motorized, realItem.specializations) then
        local daysUntil = math.max(ssVehicle.repairInterval - (g_seasons.environment:currentDay() - realItem.ssLastRepairDay), 0)

        return string.format(g_i18n:getText("shop_age"), daysUntil)
    elseif realItem ~= nil and realItem.age ~= nil then
        return "-"

    -- FIXME this is never called because all vehicles have an age
    elseif not SpecializationUtil.hasSpecialization(Motorized, realItem.specializations) then
        return ssLang.getText("SS_REPAIR_AT_MIDNIGHT", "at midnight")
    end

    return nil
end

-- Tell a vehicle when it is in the area of a workshop. This information is
-- then used in ssRepairable to show or hide the repair option
function ssVehicle:sellAreaTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
    if otherShapeId ~= nil and (onEnter or onLeave) then
        if onEnter then
            local vehicle = g_currentMission.nodeToVehicle[otherShapeId]

            if vehicle ~= nil then
                vehicle.ssInRangeOfWorkshop = self
            end
        elseif onLeave then
            local vehicle = g_currentMission.nodeToVehicle[otherShapeId]

            if vehicle ~= nil then
                vehicle.ssInRangeOfWorkshop = nil
            end
        end
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
            g_currentMission:showBlinkingWarning(ssLang.getText("warning_soilIsFrozen"), 2000)
        end
    end
end

-- Add wheel types for special snow wheels that have more friction in snow but less on other surfaces (e.g. chains)
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

    ssUtil.registerTireType("studded", studdedFrictionCoeffs, studdedFrictionCoeffsWet)
    ssUtil.registerTireType("chains", snowchainsFrictionCoeffs, snowchainsFrictionCoeffsWet)
end

-- Override the threshing for the moisture system
function ssVehicle:getIsThreshingAllowed(superFunc, earlyWarning)
    if not g_seasons.weather.moistureEnabled then
        return superFunc(self, earlyWarning)
    end

    if self.allowThreshingDuringRain or g_seasons.vehicle:isRootCropRelated(self) then
        return true
    end

    return not g_seasons.weather:isCropWet()
end

function ssVehicle:isRootCropRelated(vehicle)
    -- Self propelled harvesters, either with or without a topper are detected using this fruitPreparer
    if vehicle.fruitPreparer ~= nil then
        return true
    end

    -- Detect trailed harvesters by looking at their fill types.
    -- If they only accept either potatoes or sugarBeets, then allow them to harvest
    local fillTypes = vehicle.ssFillTypes
    if fillTypes == nil then
        local item = StoreItemsUtil.storeItemsByXMLFilename[vehicle.configFileName:lower()]
        fillTypes = StoreItemsUtil.storeItemSpecsNameToDesc["fillTypes"].getValueFunc(item)

        vehicle.ssFillTypes = fillTypes
    end

    local potatoId = FruitUtil.getFruitTypesByNames("potato")[1]
    local beetId = FruitUtil.getFruitTypesByNames("sugarBeets")[1]

    if table.getn(vehicle.ssFillTypes) == 1 and (vehicle.ssFillTypes[1] == potatoId or vehicle.ssFillTypes[1] == beetId) then
        return true
    end

    return false
end

function ssVehicle:aiVehicleUpdate(dt)
    -- Only adjust lights if available and if hired
    if not self.isHired or self.aiLightsTypesMask == nil then return end

    -- check light and turn on dependent on daytime
    local dayMinutes = g_currentMission.environment.dayTime / (1000 * 60)
    local needLights = (dayMinutes > g_currentMission.environment.nightStart
                        or dayMinutes < g_currentMission.environment.nightEnd)

    if needLights then
        if self.lightsTypesMask ~= self.aiLightsTypesMask then
            self:setLightsTypesMask(self.aiLightsTypesMask)
        end
    else
        if self.lightsTypesMask ~= 0 then
            self:setLightsTypesMask(0)
        end
    end
end

function ssVehicle:getFullBuyPrice(vehicle, storeItem)
    local priceConfig = 0

    if storeItem.configurations ~= nil then
        for configName, configIds in pairs(vehicle.boughtConfigurations) do
            local configItem = storeItem.configurations[configName]

            if configItem ~= nil then
                for id, _ in pairs(configIds) do
                    if configItem[id] then
                        priceConfig = priceConfig + configItem[id].price
                    end
                end
            end
        end

    end

    return storeItem.price + priceConfig
end

function ssVehicle:washableUpdateTick(superFunc, dt)
    if self.washableNodes ~= nil and self.isServer then
        local env = g_currentMission.environment;

        -- Work the scale to affect rain-cleaning
        local oldScale = env.lastRainScale
        if env.currentRain == nil or env.currentRain ~= "rain" then
            -- If event is not rain, do not clean
            env.lastRainScale = 0
        end

        -- Work the duration to add more factors
        local oldDuration = self.dirtDuration
        local wetnessMultiplier = 0
        if not ssWeatherManager:isGroundFrozen() then
            wetnessMultiplier = (env.groundWetness ^ 2 + 0.1) * 3
        end

        -- If ground is frozen, no dirtification: multi is 0. Otherwise mult regarding wetness
        self.dirtDuration = self.dirtDuration * wetnessMultiplier

        -- Call the actual function
        superFunc(self, dt)

        self.dirtDuration = oldDuration
        env.lastRainScale = oldScale
    else
        return superFunc(self, dt)
    end
end

---------------------
-- Repairing at shop
---------------------

function ssVehicle:directSellDialogSetVehicle(vehicle, owner, ownWorkshop)
    function setSellButtonState(disabled, text)
        if self.sellButton ~= nil then
            self.sellButton:setText(text)
            self.sellButton:setDisabled(disabled);
        end

        if self.sellButtonConsole ~= nil then
            self.sellButtonConsole:setText(text)
            self.sellButtonConsole:setVisible(not disabled);
        end
    end

    if self.sellButton["onClickCallback"] ~= ssVehicle.directSellDialogOnClickOk then
        ssUtil.overwrittenConstant(self.sellButton, "onClickCallback", ssVehicle.directSellDialogOnClickOk)
    end

    if vehicle ~= nil and vehicle.propertyState == Vehicle.PROPERTY_STATE_OWNED then
        -- If there is something to repair, always give repair option
        -- If it is not but own workshop, show disabled repair button
        -- Otherwise do vanilla behaviour (sell button)
        local repairCost = ssVehicle:getRepairShopCost(vehicle, nil, not ownWorkshop)

        if repairCost >= 1 then
            setSellButtonState(false, ssLang.getText("ui_doRepair"))
            self.headerText:setText(g_i18n:getText("ui_repairOrCustomizeVehicleTitle"))
        elseif repairCost < 1 and ownWorkshop then
            setSellButtonState(true, ssLang.getText("ui_doRepair"))
            self.headerText:setText(g_i18n:getText("ui_repairOrCustomizeVehicleTitle"))
        else
            self.headerText:setText(g_i18n:getText("ui_sellOrCustomizeVehicleTitle"))
        end
    end
end

function ssVehicle:repairVehicle(vehicle, showDialog, ownWorkshop, sellDialog)
    local repairCost = ssVehicle:getRepairShopCost(vehicle, nil, not ownWorkshop)
    if repairCost < 1 then return end

    local storeItem = StoreItemsUtil.storeItemsByXMLFilename[vehicle.configFileName:lower()]
    local vehicleName = storeItem.brand .. " " .. storeItem.name

    function performRepair(self)
        -- Deduct
        if g_currentMission:getIsServer() then
            g_currentMission:addSharedMoney(-repairCost, "vehicleRunningCost")
            g_currentMission.missionStats:updateStats("expenses", repairCost)
        else
            g_client:getServerConnection():sendEvent(CheatMoneyEvent:new(-repairCost))
        end

        -- Repair
        if ssVehicle:repair(vehicle) then
            -- Show that it was repaired
            local str = string.format(g_i18n:getText("SS_VEHICLE_REPAIRED"), vehicleName, g_i18n:formatMoney(repairCost, 0))
            g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, str)

            g_client:getServerConnection():sendEvent(ssRepairVehicleEvent:new(vehicle))
        end
    end

    -- Callback for the Yes No Dialog
    function doRepairCallback(self, yesNo)
        if yesNo then
            performRepair(vehicle)

            if sellDialog ~= nil then
                sellDialog:onClickBack();
                if sellDialog.owner ~= nil then
                    sellDialog.owner:onActivateObject()
                end
            end
        end

        g_gui:closeDialogByName("YesNoDialog")
    end

    if showDialog then
        local dialog = g_gui:showDialog("YesNoDialog")
        local text = string.format(ssLang.getText("SS_REPAIR_DIALOG"), vehicleName, g_i18n:formatMoney(repairCost, 0))

        dialog.target:setCallback(doRepairCallback, vehicle)
        dialog.target:setTitle(ssLang.getText("SS_REPAIR_DIALOG_TITLE"))
        dialog.target:setText(text)
    else
        performRepair(vehicle)
    end
end

function ssVehicle:directSellDialogOnClickOk(superFunc)
    if self.inputDelay < self.time and self.vehicle ~= nil then
        if self.vehicle.propertyState ~= Vehicle.PROPERTY_STATE_OWNED then
            return superFunc(self)
        end

        local repairCost = ssVehicle:getRepairShopCost(self.vehicle, nil, not self.ownWorkshop)

        -- Allow selling when no repair cost
        if repairCost >= 1 then
            ssVehicle:repairVehicle(self.vehicle, true, self.ownWorkshop, self)
        else
            superFunc(self)
        end
    end
end


---------------------
-- Console commands
---------------------

function ssVehicle:consoleCommandRepairVehicle()
    local vehicle = g_currentMission.controlledVehicle

    if vehicle == nil then
        return "You are not in a vehicle"
    end

    -- Repair it, for free
    if self:repair(vehicle) then
        g_client:getServerConnection():sendEvent(ssRepairVehicleEvent:new(vehicle))
    end
end

function ssVehicle:consoleCommandRepairAllVehicles()
    local n = 0

    for _, vehicle in pairs(g_currentMission.vehicles) do
        if SpecializationUtil.hasSpecialization(Washable, vehicle.specializations) then
            self:repair(vehicle)
            n = n + 1
        end
    end

    return "Repaired " .. tostring(n) .. " vehicles"
end

function ssVehicle:consoleCommandTestVehicle()
    local vehicle = g_currentMission.controlledVehicle

    if vehicle == nil then
        return "You are not in a vehicle"
    end

    local storeItem = StoreItemsUtil.storeItemsByXMLFilename[vehicle.configFileName:lower()]

    log("configs")
    print_r(storeItem.configurations)

    log("bought configs")
    print_r(vehicle.boughtConfigurations)

    return ""
end
