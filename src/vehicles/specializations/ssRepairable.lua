----------------------------------------------------------------------------------------------------
-- REPAIRABLE SPECIALIZATION
----------------------------------------------------------------------------------------------------
-- Authors:  Rahkiin, reallogger, Rival
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssRepairable = {}

source(g_seasons.modDir .. "src/events/ssRepairVehicleEvent.lua")

function ssRepairable:prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Washable, specializations)
end

function ssRepairable:load(savegame)
    self.ssRepairUpdate = SpecializationUtil.callSpecializationsFunction("ssRepairUpdate")
    self.ssRepair = SpecializationUtil.callSpecializationsFunction("ssRepair")

    self.ssPlayerInRange = false
    self.ssInRangeOfWorkshop = nil

    self.ssLastRepairDay = g_currentMission.environment.currentDay
    self.ssLastRepairOperatingTime = self.operatingTime
    self.ssCumulativeDirt = 0

    if savegame ~= nil then
        self.ssLastRepairDay = ssXMLUtil.getFloat(savegame.xmlFile, savegame.key .. "#ssLastRepairDay", self.ssLastRepairDay)
        self.ssLastRepairOperatingTime = ssXMLUtil.getFloat(savegame.xmlFile, savegame.key .. "#ssYesterdayOperatingTime", self.ssLastRepairOperatingTime)
        self.ssCumulativeDirt = ssXMLUtil.getFloat(savegame.xmlFile, savegame.key .. "#ssCumulativeDirt", self.ssCumulativeDirt)
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
        attributes = attributes .. "ssYesterdayOperatingTime=\"" .. self.ssLastRepairOperatingTime ..  "\" "
        attributes = attributes .. "ssCumulativeDirt=\"" .. self.ssCumulativeDirt ..  "\" "
    end

    return attributes, ""
end

function ssRepairable:readStream(streamId, connection)
    self.ssLastRepairDay = streamReadFloat32(streamId)
    self.ssLastRepairOperatingTime = streamReadFloat32(streamId)
    self.ssCumulativeDirt = streamReadFloat32(streamId)
end

function ssRepairable:writeStream(streamId, connection)
    streamWriteFloat32(streamId, self.ssLastRepairDay)
    streamWriteFloat32(streamId, self.ssLastRepairOperatingTime)
    streamWriteFloat32(streamId, self.ssCumulativeDirt)
end

function ssRepairable:draw()
end

local function isInDistance(self, player, maxDistance, refNode)
    local vx, _, vz = getWorldTranslation(player.rootNode)
    local sx, _, sz = getWorldTranslation(refNode)

    local dist = Utils.vector2Length(vx - sx, vz - sz)

    return dist <= maxDistance
end

-- Jos: Don't ask me why, but putting them inside Repairable breaks all, even with
-- callSpecializationsFunction...
local function getIsPlayerInRange(self, distance, player)
    if self.rootNode ~= 0 and SpecializationUtil.hasSpecialization(Motorized, self.specializations) then

        if player == nil then -- this is a dedi server
--[[
            for _, player in pairs(g_currentMission.players) do
                -- FIXME this can only result in a single player
                if isInDistance(self, player, distance, self.rootNode) then
                    return true, player
                end
            end
]]
        else
            return isInDistance(self, player, distance, self.rootNode), player
        end
    end

    return false, nil
end

function ssRepairable:updateTick(dt)
    -- Calculate if vehicle is in range for message about repairing
    if self.isClient then
        local isPlayerInRange, player = getIsPlayerInRange(self, 4.0, g_currentMission.player)

        if isPlayerInRange then
            self.ssPlayerInRange = player
        else
            self.ssPlayerInRange = nil
        end
    end

    -- Calculate cumulative dirt
    if self.getDirtAmount ~= nil then
        local factor = self:getIsOperating() and 1 or 0.1

        self.ssCumulativeDirt = self.ssCumulativeDirt + self:getDirtAmount() * dt * factor
    end
end

function ssRepairable:update(dt)
    -- Show a message about the repairing
    if self.isClient and self.ssPlayerInRange == g_currentMission.player and self.ssInRangeOfWorkshop ~= nil then
        self:ssRepairUpdate(dt)
    end

    if self.isEntered and self.isClient then
        local serviceHours = ssVehicle.SERVICE_INTERVAL - math.floor((self.operatingTime - self.ssLastRepairOperatingTime)) / 1000 / 60 / 60
        local daysSinceLastRepair = g_currentMission.environment.currentDay - self.ssLastRepairDay

        if daysSinceLastRepair >= ssVehicle.repairInterval or serviceHours < 0 then
            g_currentMission:addExtraPrintText(ssLang.getText("SS_REPAIR_REQUIRED"))
        else
            g_currentMission:addExtraPrintText(string.format(ssLang.getText("SS_REPAIR_REQUIRED_IN"), serviceHours, ssVehicle.repairInterval - daysSinceLastRepair))
        end
    end

    -- stupid fix for setting ssLastRepairOperatingTime to operatingTime for a new savegame
    if self.ssLastRepairOperatingTime == 0 then
        self.ssLastRepairOperatingTime = self.operatingTime
    end
end

function ssRepairable:ssRepairUpdate(dt)
    local repairCost = ssVehicle:getRepairShopCost(self, nil, not self.ssInRangeOfWorkshop.ownWorkshop)

    if repairCost < 1 then return end

    local storeItem = StoreItemsUtil.storeItemsByXMLFilename[self.configFileName:lower()]
    local vehicleName = storeItem.brand .. " " .. storeItem.name

    -- Show repair button
    g_currentMission:addHelpButtonText(string.format(g_i18n:getText("SS_REPAIR_VEHICLE_COST"), vehicleName, g_i18n:formatMoney(repairCost, 0)), InputBinding.SEASONS_REPAIR_VEHICLE)

    if InputBinding.hasEvent(InputBinding.SEASONS_REPAIR_VEHICLE) then
        if g_currentMission:getTotalMoney() >= repairCost then
            self:ssRepair(true, repairCost, vehicleName)
        else
            g_currentMission:showBlinkingWarning(g_i18n:getText("SS_NOT_ENOUGH_MONEY"), 2000)
        end
    end
end

-- Do a repair.
-- @param showDialog True if you want a confirmation dialog shown
-- @param cost Different cost. Keep nil for auto cost calculations
-- @note This must only be called from an Update function.
function ssRepairable:ssRepair(showDialog, cost, vehicleName)
    local repairCost = cost
    if cost == nil then
        cost = ssVehicle:getRepairShopCost(self, nil, not self.ssInRangeOfWorkshop.ownWorkshop)
    end

    if repairCost < 1 then return end

    function performRepair(self)
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

    -- Callback for the Yes No Dialog
    function doRepairCallback(self, yesNo)
        if yesNo then
            performRepair(self)
        end

        g_gui:closeDialogByName("YesNoDialog")
    end

    if showDialog then
        local dialog = g_gui:showDialog("YesNoDialog")
        local text = string.format(ssLang.getText("SS_REPAIR_DIALOG"), vehicleName, g_i18n:formatMoney(repairCost, 0))

        dialog.target:setCallback(doRepairCallback, self)
        dialog.target:setTitle(ssLang.getText("SS_REPAIR_DIALOG_TITLE"))
        dialog.target:setText(text)
    else
        performRepair(self)
    end
end

