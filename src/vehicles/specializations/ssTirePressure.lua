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
end

function ssTirePressure:load(savegame)
    self.ssInflationPressure = ssTirePressure.PRESSURE_NORMAL

    self.updateInflationPressure = ssTirePressure.updateInflationPressure
    self.getInflationPressure = ssTirePressure.getInflationPressure
    self.doCheckSpeedLimit = Utils.overwrittenFunction(self.doCheckSpeedLimit, ssTirePressure.doCheckSpeedLimit)

    if savegame ~= nil then
        self.ssInflationPressure = ssXMLUtil.getInt(savegame.xmlFile, savegame.key .. "#ssInflationPressure", self.ssInflationPressure)
    end

    self.ssInCabTirePressureControl = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.ssInCabTirePressureControl"), false)

    self.ssAllWheelsCrawlers = true
    local tireTypeCrawler = WheelsUtil.getTireType("crawler")
    for _, wheel in pairs(self.wheels) do
        if wheel.tireType ~= tireTypeCrawler then
            self.ssAllWheelsCrawlers = false
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
    self.ssInflationPressure = streamReadInt(streamId)
end

function ssTirePressure:writeStream(streamId, connection)
    streamWriteInt(streamId, self.ssInflationPressure)
end

function ssTirePressure:updateInflationPressure()
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

    -- Update compaction indicator
    self.ssCompactionIndicatorIsCorrect = false

    -- TODO(Jos) send event with new pressure for vehicle
end

function ssTirePressure:update(dt)
    if self.isClient and self:canPlayerInteractInWorkshop() and not self.ssAllWheelsCrawlers then
        local pressureText = g_i18n:getText("TIRE_PRESSURE_" .. tostring(self.ssInflationPressure))
        g_currentMission:addHelpButtonText(string.format(g_i18n:getText("input_SEASONS_TIRE_PRESSURE"), pressureText), InputBinding.IMPLEMENT_EXTRA2, nil, GS_PRIO_HIGH)

        if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA2) then
            self:updateInflationPressure()
        end
    end
end

function ssTirePressure:draw()
end

function ssTirePressure:getInflationPressure()
    return ssTirePressure.PRESSURES[self.ssInflationPressure]
end

function ssTirePressure:doCheckSpeedLimit(superFunc)
    local parent = false
    if superFunc ~= nil then
        parent = superFunc(self)
    end

    return parent or self.ssInflationPressure == ssTirePressure.PRESSURE_LOW
end

function ssTirePressure:getSpeedLimit()
    local limit = 1000

    if self.ssInflationPressure == ssTirePressure.PRESSURE_LOW then
        return 10
    end

    return limit
end
