---------------------------------------------------------------------------------------------------------
-- REPAIRABLE SPECIALIZATION
---------------------------------------------------------------------------------------------------------
-- Authors:  Jarvixes (Rahkiin), reallogger, Rival
--

ssRepairable = {}

function ssRepairable:prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Washable, specializations)
end

function ssRepairable:load(savegame)
    self.repairUpdate = SpecializationUtil.callSpecializationsFunction("repairUpdate")

    self.ssPlayerInRange = false
    self.ssInRangeOfWorkshop = nil

    self.ssLastRepairDay = ssSeasonsUtil:currentDayNumber()
    self.ssYesterdayOperatingTime = self.operatingTime
    self.ssCumulativeDirt = 0

    if savegame ~= nil then
        self.ssLastRepairDay = Utils.getNoNil(getXMLFloat(savegame.xmlFile, savegame.key .. "#ssLastRepairDay"), self.ssLastRepairDay)
        self.ssYesterdayOperatingTime = Utils.getNoNil(getXMLFloat(savegame.xmlFile, savegame.key .. "#ssYesterdayOperatingTime"), self.ssYesterdayOperatingTime)
        self.ssCumulativeDirt = Utils.getNoNil(getXMLFloat(savegame.xmlFile, savegame.key .. "#ssCumulativeDirt"), self.ssCumulativeDirt)
    end
end

function ssRepairable:delete()
end

function ssRepairable:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssRepairable:keyEvent(unicode, sym, modifier, isDown)
end

function ssRepairable:getSaveAttributesAndNodes(nodeIdent)
    local attributes = ""

    if self.ssLastRepairDay ~= nil then
        attributes = attributes .. "ssLastRepairDay=\"" .. self.ssLastRepairDay ..  "\""
        attributes = attributes .. "ssYesterdayOperatingTime=\"" .. self.ssYesterdayOperatingTime ..  "\""
        attributes = attributes .. "ssCumulativeDirt=\"" .. self.ssCumulativeDirt ..  "\""
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

function ssRepairable:updateTick(dt)
    -- Calculate if vehicle is in range for message about repairing
    if g_currentMission.player ~= nil then
        local vx, vy, vz = getWorldTranslation(g_currentMission.player.rootNode)
        local sx, sy, sz = getWorldTranslation(self.rootNode)
        local distance = Utils.vector3Length(sx-vx, sy-vy, sz-vz)

        self.ssPlayerInRange = distance < 3.5
    end

    -- Calculate cumulative dirt
    if self.getDirtAmount ~= nil then
        local factor = self:getIsOperating() and 1 or 0.1

        self.ssCumulativeDirt = self.ssCumulativeDirt + self:getDirtAmount() * dt * factor
    end
end

function ssRepairable:update(dt)
    local daysSinceLastRepair = ssSeasonsUtil:currentDayNumber() - self.ssLastRepairDay

    -- Show a message about the repairing
    if self.ssPlayerInRange and self.ssInRangeOfWorkshop ~= nil then
        self:repairUpdate(dt)
    end

    if self.isEntered then
        if daysSinceLastRepair >= ssSeasonsUtil.daysInSeason then
            g_currentMission:addExtraPrintText(ssLang.getText("SS_REPAIR_REQUIRED"))
        else
            g_currentMission:addExtraPrintText(string.format(ssLang.getText("SS_REPAIR_REQUIRED_IN"), ssSeasonsUtil.daysInSeason - daysSinceLastRepair))
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
            else
                g_client:getServerConnection():sendEvent(CheatMoneyEvent:new(-repairCost))
            end

            -- Repair
            if ssVehicle:repair(self, storeItem) then
                -- Show that it was repaired
                local str = string.format(g_i18n:getText("SS_VEHICLE_REPAIRED"), vehicleName, g_i18n:formatMoney(repairCost, 0))
                g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, str)

            --g_client:getServerConnection():sendEvent(repairVehicleEvent:new(self, self.operatingTime))
            end
        end

        g_gui:closeDialogByName("YesNoDialog")
    end

    -- Show repair button
    g_currentMission:addHelpButtonText(string.format(g_i18n:getText("SS_REPAIR_VEHICLE_COST"), vehicleName, g_i18n:formatMoney(repairCost, 0)), InputBinding.SEASONS_REPAIR_VEHICLE)

    if InputBinding.hasEvent(InputBinding.SEASONS_REPAIR_VEHICLE) then
        if g_currentMission:getTotalMoney() >= repairCost then
            log("Show Dialog")
            local dialog = g_gui:showDialog("YesNoDialog")
            local title = string.format("Do you want to repair the %s vehicle for %s?", vehicleName, g_i18n:formatMoney(repairCost, 0))

            dialog.target:setCallback(doRepairCallback, self)
            dialog.target:setTitle(title)

        else
            g_currentMission:showBlinkingWarning(g_i18n:getText("SS_NOT_ENOUGH_MONEY"), 2000)
        end
    end
end
