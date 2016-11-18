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
    -- self.repairVehicle = SpecializationUtil.callSpecializationsFunction("repairVehicle")

    self.ssPlayerInRange = false;

    if savegame ~= nil then
        self.ssLastRepairDay = Utils.getNoNil(getXMLFloat(savegame.xmlFile, savegame.key .. "#ssLastRepairDay"), 1)
        self.ssYesterdayOperatingTime = Utils.getNoNil(getXMLFloat(savegame.xmlFile, savegame.key .. "#ssYesterdayOperatingTime"), 0)
        self.ssCumulativeDirt = Utils.getNoNil(getXMLFloat(savegame.xmlFile, savegame.key .. "#ssCumulativeDirt"), 0)
    else
        self.ssLastRepairDay = ssSeasonsUtil:currentDayNumber()
        self.ssYesterdayOperatingTime = self.operatingTime
        self.ssCumulativeDirt = 0
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
    if self.getDirtAmount ~= nil then
        -- self:getDirtAmount() is a value from 0-1, so cum, it can be 60*60*1000*24 max.
        self.ssCumulativeDirt = self.ssCumulativeDirt + self:getDirtAmount() * dt
    end

    --[[
    --if self.isServer then
        if self.rvPIR then
            local newOpTime
            if self.rvLastOperatingTime ~= nil then
                newOpTime = math.max(0, self.operatingTime - self.rvLastOperatingTime)
            else
                newOpTime = self.operatingTime
            end
            local costs = self:getPrice()*0.08*(newOpTime/100000000)
            if costs > 5 then
                local vehicleName = StoreItemsUtil.storeItemsByXMLFilename[self.configFileName:lower()].brand .." ".. StoreItemsUtil.storeItemsByXMLFilename[self.configFileName:lower()].name
                g_currentMission:addHelpButtonText(string.format(g_i18n:getText("REPAIR_VEHICLE_COST"), vehicleName, costs), InputBinding.REPAIR_VEHICLE)
                if InputBinding.hasEvent(InputBinding.REPAIR_VEHICLE) then
                    if g_currentMission:getTotalMoney() > costs then
                        if g_currentMission:getIsServer() then
                            g_currentMission:addSharedMoney(-costs, "other")
                        else
                            g_client:getServerConnection():sendEvent(CheatMoneyEvent:new(-costs))
                        end
                        g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, string.format(g_i18n:getText("VEHICLE_REPAIRED"), vehicleName, costs))
                        self.rvLastOperatingTime = self.operatingTime
                        g_client:getServerConnection():sendEvent(repairVehicleEvent:new(self, self.operatingTime))
                        --repairVehicleEvent.sendEvent(self, self.operatingTime)
                    else
                        g_currentMission:showBlinkingWarning(g_i18n:getText("NOT_ENOUGH_MONEY"), 2000)
                    end
                end
            end
        end
    --end
    --]]
end

function ssRepairable:draw()
end
