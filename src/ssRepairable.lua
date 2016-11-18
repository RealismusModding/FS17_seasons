---------------------------------------------------------------------------------------------------------
-- REPAIRABLE SPECIALIZATION
---------------------------------------------------------------------------------------------------------
-- Authors:  Jarvixes (Rahkiin), Rival
--

ssRepairable = {}

function ssRepairable:prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Washable, specializations)
end

function ssRepairable:load(savegame)
    self.repairUpdate = SpecializationUtil.callSpecializationsFunction("repairUpdate")

    self.ssPlayerInRange = false;

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
end

function ssRepairable:update(dt)
    local daysSinceLastRepair = ssSeasonsUtil:currentDayNumber() - self.ssLastRepairDay

    -- Show a message about the repairing
    if self.ssPlayerInRange then
        if daysSinceLastRepair >= ssSeasonsUtil.daysInSeason then
            g_currentMission:addExtraPrintText("Repair required")
        else
            g_currentMission:addExtraPrintText(string.format("Repair required in %d days", ssSeasonsUtil.daysInSeason - daysSinceLastRepair))
        end
    end

    -- Calculate cumulative dirt
    if self:getIsOperating() and self.getDirtAmount ~= nil then
        -- self:getDirtAmount() is a value from 0-1, so cum, it can be 60*60*1000*24 max.
        self.ssCumulativeDirt = self.ssCumulativeDirt + self:getDirtAmount() * dt
    end

    if self.ssPlayerInRange then
        self:repairUpdate(dt)
    end
end

function ssRepairable:repairUpdate(dt)
    local repairCost = ssMaintenance:getRepairShopCost(self)
    log("Cost for repair "..tostring(repairCost))

    if repairCost < 1 then return end

    local storeItem = StoreItemsUtil.storeItemsByXMLFilename[self.configFileName:lower()]
    local vehicleName = storeItem.brand .. " " .. storeItem.name

    -- Show repair button
    g_currentMission:addHelpButtonText(string.format(g_i18n:getText("SS_REPAIR_VEHICLE_COST"), vehicleName, g_i18n:formatMoney(repairCost, 0)), InputBinding.SEASONS_REPAIR_VEHICLE)

    if InputBinding.hasEvent(InputBinding.SEASONS_REPAIR_VEHICLE) then
        if g_currentMission:getTotalMoney() >= repairCost then
            -- Deduct
            if g_currentMission:getIsServer() then
                g_currentMission:addSharedMoney(-repairCost, "vehicleRunningCost")
            else
                g_client:getServerConnection():sendEvent(CheatMoneyEvent:new(-repairCost))
            end

            -- Repair
            if ssMaintenance:repair(self, storeItem) then
                -- Show that it was repaired
                local str = string.format(g_i18n:getText("SS_VEHICLE_REPAIRED"), vehicleName, g_i18n:formatMoney(repairCost, 0))
                g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, str);

            --g_client:getServerConnection():sendEvent(repairVehicleEvent:new(self, self.operatingTime));
            end
        else
            g_currentMission:showBlinkingWarning(g_i18n:getText("SS_NOT_ENOUGH_MONEY"), 2000);
        end
    end
end
