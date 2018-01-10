----------------------------------------------------------------------------------------------------
-- TIRE PRESSURE SPECIALIZATION
----------------------------------------------------------------------------------------------------
-- Authors:  Rahkiin, reallogger
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssTirePressure = {}

ssTirePressure.MAX_CHARS_TO_DISPLAY = 20

ssTirePressure.PRESSURE_LOW = 1
ssTirePressure.PRESSURE_NORMAL = 2
ssTirePressure.PRESSURE_MAX = ssTirePressure.PRESSURE_NORMAL

ssTirePressure.PRESSURES = { 80, 180 }
ssTirePressure.NORMAL_PRESSURE = 180 -- vanilla

function ssTirePressure:prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Motorized, specializations) and
           SpecializationUtil.hasSpecialization(ssAtWorkshop, specializations) and
           SpecializationUtil.hasSpecialization(ssSoilCompaction, specializations)
end

function ssTirePressure:preLoad()
    self.updateInflationPressure = ssTirePressure.updateInflationPressure
    self.getInflationPressure = ssTirePressure.getInflationPressure
end

function ssTirePressure:load(savegame)
    self.ssInflationPressure = ssTirePressure.PRESSURE_NORMAL

    if savegame ~= nil then
        self.ssInflationPressure = ssXMLUtil.getInt(savegame.xmlFile, savegame.key .. "#ssInflationPressure", self.ssInflationPressure)
    end

    self.ssAllWheelsCrawlers = true
    for _, wheel in pairs(self.wheels) do
        local tireTypeCrawler = WheelsUtil.getTireType("crawler")

        if wheel.tireType ~= tireTypeCrawler then
            self.ssAllWheelsCrawlers = true
        end
    end

end

function ssTirePressure:delete()
end

function ssTirePressure:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssTirePressure:keyEvent(unicode, sym, modifier, isDown)
end

function ssTirePressure:loadFromAttributesAndNodes(xmlFile, key)
    return true
end

function ssTirePressure:getSaveAttributesAndNodes(nodeIdent)
    local attributes = ""

    attributes = attributes .. "ssInflationPressure=\"" .. self.ssInflationPressure ..  "\" "

    return attributes, ""
end

function ssTirePressure:readStream(streamId, connection)
end

function ssTirePressure:writeStream(streamId, connection)
end

function ssTirePressure:updateInflationPressure(self)
    self.ssInflationPressure = self.ssInflationPressure + 1
    if self.ssInflationPressure > ssTirePressure.PRESSURE_MAX then
        self.ssInflationPressure = ssTirePressure.PRESSURE_LOW
    end

    local pressure = ssTirePressure.PRESSURES[self.ssInflationPressure]
    local tireTypeCrawler = WheelsUtil.getTireType("crawler")

    for _, wheel in pairs(self.wheels) do
        if wheel.tireType ~= tireTypeCrawler then  
        
            if wheel.ssMaxDeformation == nil then
                wheel.ssMaxDeformation = wheel.maxDeformation
            end

            wheel.ssMaxLoad = self:getTireMaxLoad(wheel, pressure)
            wheel.maxDeformation = wheel.ssMaxDeformation * ssTirePressure.NORMAL_PRESSURE / pressure
        end
    end

    -- TODO(Jos) send event with new pressure for vehicle
end

function ssTirePressure:update(dt)
    if self.isClient and self:canPlayerInteractInWorkshop() or not self.ssAllWheelsCrawlers then
        local storeItem = StoreItemsUtil.storeItemsByXMLFilename[self.configFileName:lower()]
        local vehicleName = storeItem.brand .. " " .. storeItem.name

        -- Show text for changing inflation pressure
        local storeItemName = storeItem.name
        if string.len(storeItemName) > ssTirePressure.MAX_CHARS_TO_DISPLAY then
            storeItemName = ssUtil.trim(string.sub(storeItemName, 1, ssTirePressure.MAX_CHARS_TO_DISPLAY - 3)) .. "..."
        end

        local pressureText = g_i18n:getText("TIRE_PRESSURE_" .. tostring(self.ssInflationPressure))
        g_currentMission:addHelpButtonText(string.format(g_i18n:getText("input_SEASONS_TIRE_PRESSURE"), pressureText), InputBinding.IMPLEMENT_EXTRA2, nil, GS_PRIO_HIGH)

        if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA2) then
            ssTirePressure:updateInflationPressure(self)
        end
    end

    self.ssTireLoadExceed = nil
    for _, wheel in pairs(self.wheels) do
        if wheel.hasGroundContact and not wheel.mrNotAWheel and wheel.load ~= nil and wheel.ssMaxLoad ~= nil then
            -- only exceed rated tire load for low tire pressure
            if wheel.load > wheel.ssMaxLoad and self.ssInflationPressure == ssTirePressure.PRESSURE_LOW then
                self.ssTireLoadExceed = wheel
                break -- already a value, no need to look at others
            end
        end
    end
end

function ssTirePressure:draw()
    local storeItem = StoreItemsUtil.storeItemsByXMLFilename[self.configFileName:lower()]

    if self.isEntered and self.ssTireLoadExceed then
        g_currentMission:showBlinkingWarning(string.format(g_i18n:getText("warning_tireload"), storeItem.name), 2000)
    end
end

function ssTirePressure:getInflationPressure()
    return ssTirePressure.PRESSURES[self.ssInflationPressure]
end
