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
ssVehicle.SERVICE_INTERVAL = 30

ssVehicle.repairFactors = {}
ssVehicle.allowedInWinter = {}

SpecializationUtil.registerSpecialization("repairable", "ssRepairable", ssSeasonsMod.modDir .. "src/ssRepairable.lua")

function ssVehicle:loadMap()
    g_currentMission.environment:addDayChangeListener(self)

    Vehicle.getDailyUpKeep = Utils.overwrittenFunction(Vehicle.getDailyUpKeep, ssVehicle.getDailyUpKeep)
    Vehicle.getSellPrice = Utils.overwrittenFunction(Vehicle.getSellPrice, ssVehicle.getSellPrice)
    Vehicle.getSpecValueAge = Utils.overwrittenFunction(Vehicle.getSpecValueAge, ssVehicle.getSpecValueAge)
    Vehicle.getSpeedLimit = Utils.overwrittenFunction(Vehicle.getSpeedLimit, ssVehicle.getSpeedLimit)
    Vehicle.draw = Utils.overwrittenFunction(Vehicle.draw, ssVehicle.vehicleDraw)
    -- Vehicle.getSpecValueDailyUpKeep = Utils.overwrittenFunction(Vehicle.getSpecValueDailyUpKeep, ssVehicle.getSpecValueDailyUpKeep)

    InGameMenu.onCreateGarageVehicleAge = Utils.overwrittenFunction(InGameMenu.onCreateGarageVehicleAge, ssVehicle.inGameMenuOnCreateGarageVehicleAge)

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
    for i, vehicle in pairs(g_currentMission.vehicles) do
        if SpecializationUtil.hasSpecialization(ssRepairable, vehicle.specializations) and not SpecializationUtil.hasSpecialization(Motorized, vehicle.specializations) then
            self:repair(vehicle,storeItem)
        end
    end
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
    local file = loadXMLFile("factors", ssSeasonsMod.modDir .. "data/repairFactors.xml")

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
    local prevOperatingTime = math.floor(vehicle.ssYesterdayOperatingTime) / 1000 / 60 / 60
    local operatingTime = math.floor(vehicle.operatingTime) / 1000 / 60 / 60
    local daysSinceLastRepair = ssSeasonsUtil:currentDayNumber() - vehicle.ssLastRepairDay
    local repairFactor = isRepair and ssVehicle.REPAIR_SHOP_FACTOR or ssVehicle.REPAIR_NIGHT_FACTOR

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
    if daysSinceLastRepair >= (ssSeasonsUtil.daysInSeason * 2) or isRepair then
        maintenanceCost = (newRepairCost - prevRepairCost) * repairFactor * (0.8 + ssVehicle.DIRT_FACTOR * avgDirtAmount ^ 2)
    end

    return maintenanceCost
end

function ssVehicle.taxInterestCost(vehicle, storeItem)
    return 0.03 * storeItem.price / (4 * ssSeasonsUtil.daysInSeason)
end

--function ssVehicle:resetOperatingTimeAndDirt()
--    for i, vehicle in pairs(g_currentMission.vehicles) do
--        if SpecializationUtil.hasSpecialization(ssRepairable, vehicle.specializations) then
--            vehicle.ssCumulativeDirt = 0
--            vehicle.ssYesterdayOperatingTime = vehicle.operatingTime
--        end
--    end
--end

-- Repair by resetting the last repair day and operating time
function ssVehicle:repair(vehicle, storeItem)
    vehicle.ssLastRepairDay = ssSeasonsUtil:currentDayNumber()
    vehicle.ssYesterdayOperatingTime = vehicle.operatingTime
    vehicle.ssCumulativeDirt = 0

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

    local overdueFactor = self:calculateOverdueFactor(vehicle) ^ 2

    return (costs + workCosts) * dealerMultiplier * difficultyMultiplier * overdueFactor
end

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

function ssVehicle:calculateOverdueFactor(vehicle)
    local serviceInterval = ssVehicle.SERVICE_INTERVAL - math.floor((vehicle.operatingTime - vehicle.ssYesterdayOperatingTime)) / 1000 / 60 / 60
    local daysSinceLastRepair = ssSeasonsUtil:currentDayNumber() - vehicle.ssLastRepairDay

    if daysSinceLastRepair >= (ssSeasonsUtil.daysInSeason * 2) or serviceInterval < 0 then
        overdueFactor = math.ceil(math.max(daysSinceLastRepair/(ssSeasonsUtil.daysInSeason * 2), math.abs(serviceInterval/ssVehicle.SERVICE_INTERVAL)))
    else
        overdueFactor = 1
    end

    return overdueFactor
end

function ssVehicle:getSellPrice(superFunc)
    local storeItem = StoreItemsUtil.storeItemsByXMLFilename[self.configFileName:lower()]
    local price = storeItem.price
    local minSellPrice = storeItem.price * 0.03
    local sellPrice
    local operatingTime = self.operatingTime / (60 * 60 * 1000) -- hours
    local age = self.age / (ssSeasonsUtil.daysInSeason * ssSeasonsUtil.SEASONS_IN_YEAR) -- year
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

-- Replace the visual age with the age since last repair, because actual age is useless
function ssVehicle:getSpecValueAge(superFunc, vehicle)
    if vehicle ~= nil and vehicle.ssLastRepairDay ~= nil and SpecializationUtil.hasSpecialization(Motorized, vehicle.specializations) then
        return string.format(g_i18n:getText("shop_age"), ssSeasonsUtil.daysInSeason * 2 - (ssSeasonsUtil:currentDayNumber() - vehicle.ssLastRepairDay))
    elseif vehicle ~= nil and vehicle.age ~= nil then
        return "-"
    elseif not SpecializationUtil.hasSpecialization(Motorized, vehicle.specializations) then
        return "at midnight"
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

    if ssWeatherManager:isGroundFrozen()
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
            g_currentMission:showBlinkingWarning(ssLang.getText("SS_WARN_NOTDURINGWINTER"), 2000)
        end
    end

end

function ssVehicle:snowTracks(self,snowDepth)
    local snowDepth = ssWeatherManager:getSnowHeight()
    local targetSnowDepth = math.min(0.48, snowDepth) -- Target snow depth in meters. Never higher than 0.4
    local snowLayers = math.modf(targetSnowDepth/ ssSnow.LAYER_HEIGHT)

    -- partly from Crop destruction mod
    for _, wheel in pairs(self.wheels) do

        local width = 0.35 * wheel.width;
        local length = math.min(0.2, 0.35 * wheel.width);
        local radius = wheel.radius

        local x0,y0,z0;
        local x1,y1,z1;
        local x2,y2,z2;

        local sinkage = 0.7 * targetSnowDepth

        wheel.tireGroundFrictionCoeff = 0.1

        if wheel.repr == wheel.driveNode then
            x0,y0,z0 = localToWorld(wheel.node, wheel.positionX + width, wheel.positionY, wheel.positionZ - length);
            x1,y1,z1 = localToWorld(wheel.node, wheel.positionX - width, wheel.positionY, wheel.positionZ - length);
            x2,y2,z2 = localToWorld(wheel.node, wheel.positionX + width, wheel.positionY, wheel.positionZ + length);
        else
            local x,_,z = localToLocal(wheel.driveNode, wheel.repr, 0,0,0);
            x0,y0,z0 = localToWorld(wheel.repr, x + width, 0, z - length);
            x1,y1,z1 = localToWorld(wheel.repr, x - width, 0, z - length);
            x2,y2,z2 = localToWorld(wheel.repr, x + width, 0, z + length);
        end

        local x,z, widthX,widthZ, heightX,heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, x0,z0, x1,z1, x2,z2)

        setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_SNOW]["index"])
        setDensityCompareParams(g_currentMission.terrainDetailHeightId, "greater", 0)
        local density, area, _ = getDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 5, 6, g_currentMission.terrainDetailHeightId, 0, 5, 0)
        local underTireSnowLayers = density / area
        setDensityMaskParams(g_currentMission.terrainDetailHeightId, "greater", -1)

        if (targetSnowDepth - sinkage) > ssSnow.LAYER_HEIGHT and snowLayers == underTireSnowLayers then
            newSnowDepth = math.modf(sinkage / ssSnow.LAYER_HEIGHT)
            ssSnow:removeSnow(x0,z0, x1,z1, x2,z2, newSnowDepth)
        end
     end
end

function ssVehicle.inGameMenuOnCreateGarageVehicleAge(self, element)
    if self.currentVehicle ~= nil then
        element:setText("Halo")--Vehicle.getSpecValueAge(nil, self.currentVehicle))
        -- if self.currentVehicle:getSellPrice() < self.currentVehicle.price*0.3 then
            element:applyProfile(element.profile.."Negative")
        -- end
    end
end
