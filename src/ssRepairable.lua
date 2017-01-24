---------------------------------------------------------------------------------------------------------
-- REPAIRABLE SPECIALIZATION
---------------------------------------------------------------------------------------------------------
-- Authors:  Rahkiin, reallogger, Rival
--

ssRepairable = {}

function ssRepairable:prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Washable, specializations)
end

function ssRepairable:load(savegame)
    self.repairUpdate = SpecializationUtil.callSpecializationsFunction("repairUpdate")
    -- self.ss_getIsPlayerInRange = SpecializationUtil.callSpecializationsFunction("ss_getIsPlayerInRange")
    -- self.ss_isInDistance = SpecializationUtil.callSpecializationsFunction("ss_isInDistance")

    self.ssPlayerInRange = false
    self.ssInRangeOfWorkshop = nil

    self.ssLastRepairDay = g_seasons.environment:currentDay()
    self.ssYesterdayOperatingTime = self.operatingTime
    self.ssCumulativeDirt = 0

    if savegame ~= nil then
        self.ssLastRepairDay = ssStorage.getXMLFloat(savegame.xmlFile, savegame.key .. "#ssLastRepairDay", self.ssLastRepairDay)
        self.ssYesterdayOperatingTime = ssStorage.getXMLFloat(savegame.xmlFile, savegame.key .. "#ssYesterdayOperatingTime", self.ssYesterdayOperatingTime)
        self.ssCumulativeDirt = ssStorage.getXMLFloat(savegame.xmlFile, savegame.key .. "#ssCumulativeDirt", self.ssCumulativeDirt)
    end
end

function ssRepairable:delete()
end

function ssRepairable:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssRepairable:keyEvent(unicode, sym, modifier, isDown)
end

function ssRepairable:loadFromAttributesAndNodes(xmlFile, key)
    return true
end

function ssRepairable:getSaveAttributesAndNodes(nodeIdent)
    local attributes = ""

    if self.ssLastRepairDay ~= nil then
        attributes = attributes .. "ssLastRepairDay=\"" .. self.ssLastRepairDay ..  "\" "
        attributes = attributes .. "ssYesterdayOperatingTime=\"" .. self.ssYesterdayOperatingTime ..  "\" "
        attributes = attributes .. "ssCumulativeDirt=\"" .. self.ssCumulativeDirt ..  "\" "
    end

    return attributes, ""
end

function ssRepairable:readStream(streamId, connection)
    self.ssLastRepairDay = streamReadFloat32(streamId)
    self.ssYesterdayOperatingTime = streamReadFloat32(streamId)
    self.ssCumulativeDirt = streamReadFloat32(streamId)
end

function ssRepairable:writeStream(streamId, connection)
    streamWriteFloat32(streamId, self.ssLastRepairDay)
    streamWriteFloat32(streamId, self.ssYesterdayOperatingTime)
    streamWriteFloat32(streamId, self.ssCumulativeDirt)
end

function ssRepairable:draw()
end

local function isInDistance(self, player, distance, refNode)
    local vx, _, vz = getWorldTranslation(player.rootNode)
    local sx, _, sz = getWorldTranslation(refNode)
    local dx, dz = vx - sx, vz - sz

    if dx * dx + dz * dz < distance * distance then
        return true
    end

    return false
end

-- Jos: Don't ask me why, but putting them inside Repairable breaks all, even with
-- callSpecializationsFunction...
local function getIsPlayerInRange(self, distance, player)
    if self.rootNode ~= 0 and SpecializationUtil.hasSpecialization(Motorized, self.specializations) then
        if player == nil then
            for _, player in pairs(g_currentMission.players) do
                if isInDistance(self, player, distance, self.rootNode) then
                    return true, player
                end
            end
        else
            return isInDistance(self, player, distance, self.rootNode), player
        end
    end

    return false, nil
end

function ssRepairable:updateTick(dt)
    -- Calculate if vehicle is in range for message about repairing
    local isPlayerInRange, player = getIsPlayerInRange(self, 3.5) --, g_currentMission.player)

    if isPlayerInRange then
        self.ssPlayerInRange = player
    else
        self.ssPlayerInRange = nil
    end

    -- Calculate cumulative dirt
    if self.getDirtAmount ~= nil then
        local factor = self:getIsOperating() and 1 or 0.1

        self.ssCumulativeDirt = self.ssCumulativeDirt + self:getDirtAmount() * dt * factor
    end
end

function ssRepairable:update(dt)
    -- Show a message about the repairing
    if self.ssPlayerInRange == g_currentMission.player and self.ssInRangeOfWorkshop ~= nil then
        self:repairUpdate(dt)

    end

    if self.isEntered then
        local serviceHours = ssVehicle.SERVICE_INTERVAL - math.floor((self.operatingTime - self.ssYesterdayOperatingTime)) / 1000 / 60 / 60
        local daysSinceLastRepair = g_currentMission.environment.currentDay - self.ssLastRepairDay

        if daysSinceLastRepair >= ssVehicle.repairInterval or serviceHours < 0 then
            g_currentMission:addExtraPrintText(ssLang.getText("SS_REPAIR_REQUIRED"))
        else
            g_currentMission:addExtraPrintText(string.format(ssLang.getText("SS_REPAIR_REQUIRED_IN"), serviceHours, ssVehicle.repairInterval - daysSinceLastRepair))
        end
    end

    if self.isMotorStarted then
        local overdueFactor = ssVehicle:calculateOverdueFactor(self)
        local p = math.max(2 - overdueFactor^0.001 , 0.2)^(1 / 60 / dt * overdueFactor^2.5)

        if math.random() > p then
            self:stopMotor()

            if self.isEntered then
                g_currentMission:showBlinkingWarning(ssLang.getText("SS_WARN_REPAIR"),2000)
            end
        end
    end
end

function ssRepairable:repairUpdate(dt)
    local repairCost = ssVehicle:getRepairShopCost(self, nil, not self.ssInRangeOfWorkshop.ownWorkshop)

    if repairCost < 1 then return end

    local storeItem = StoreItemsUtil.storeItemsByXMLFilename[self.configFileName:lower()]
    local vehicleName = storeItem.brand .. " " .. storeItem.name

    -- Callback for the Yes No Dialog
    function doRepairCallback(self, yesNo)
        if yesNo then
            -- Deduct
            if g_currentMission:getIsServer() then
                g_currentMission:addSharedMoney(-repairCost, "vehicleRunningCost")
                g_currentMission.missionStats:updateStats("expenses", repairCost)
            else
                g_client:getServerConnection():sendEvent(CheatMoneyEvent:new(-repairCost))
            end

            -- Repair
            if ssVehicle:repair(self, storeItem) then
                -- Show that it was repaired
                local str = string.format(g_i18n:getText("SS_VEHICLE_REPAIRED"), vehicleName, g_i18n:formatMoney(repairCost, 0))
                g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, str)

                g_client:getServerConnection():sendEvent(ssRepairVehicleEvent:new(self))
            end
        end

        g_gui:closeDialogByName("YesNoDialog")
    end

    -- Show repair button
    g_currentMission:addHelpButtonText(string.format(g_i18n:getText("SS_REPAIR_VEHICLE_COST"), vehicleName, g_i18n:formatMoney(repairCost, 0)), InputBinding.SEASONS_REPAIR_VEHICLE)

    if InputBinding.hasEvent(InputBinding.SEASONS_REPAIR_VEHICLE) then
        if g_currentMission:getTotalMoney() >= repairCost then
            local dialog = g_gui:showDialog("YesNoDialog")
            local text = string.format(ssLang.getText("SS_REPAIR_DIALOG"), vehicleName, g_i18n:formatMoney(repairCost, 0))

            dialog.target:setCallback(doRepairCallback, self)
            dialog.target:setTitle(ssLang.getText("SS_REPAIR_DIALOG_TITLE"))
            dialog.target:setText(text)

        else
            g_currentMission:showBlinkingWarning(g_i18n:getText("SS_NOT_ENOUGH_MONEY"), 2000)
        end
    end
end

ssRepairVehicleEvent = {}
ssRepairVehicleEvent_mt = Class(ssRepairVehicleEvent, Event)
InitEventClass(ssRepairVehicleEvent, "ssRepairVehicleEvent")

-- client -> server: hey! I repaired X
--> server -> everyone: hey! X got repaired!

function ssRepairVehicleEvent:emptyNew()
    local self = Event:new(ssRepairVehicleEvent_mt)
    self.className = "ssRepairVehicleEvent"
    return self
end

function ssRepairVehicleEvent:new(vehicle)
    local self = ssRepairVehicleEvent:emptyNew()

    self.vehicle = vehicle
    self.ssLastRepairDay = vehicle.ssLastRepairDay
    self.ssYesterdayOperatingTime = vehicle.ssYesterdayOperatingTime

    return self
end

function ssRepairVehicleEvent:writeStream(streamId, connection)
    writeNetworkNodeObject(streamId, self.vehicle)
    streamWriteFloat32(streamId, self.ssLastRepairDay)
    streamWriteFloat32(streamId, self.ssYesterdayOperatingTime)
end

function ssRepairVehicleEvent:readStream(streamId, connection)
    self.vehicle = readNetworkNodeObject(streamId)
    self.ssLastRepairDay = streamReadFloat32(streamId)
    self.ssYesterdayOperatingTime = streamReadFloat32(streamId)

    self:run(connection)
end

function ssRepairVehicleEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.vehicle)
    end

    if self.vehicle ~= nil then
        self.vehicle.ssLastRepairDay = self.ssLastRepairDay
        self.vehicle.ssYesterdayOperatingTime = self.ssYesterdayOperatingTime
    end
end
