----------------------------------------------------------------------------------------------------
-- TIRE PRESSURE SPECIALIZATION
----------------------------------------------------------------------------------------------------
-- Authors:  Rahkiin, reallogger
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssTirePressure = {}

ssTirePressure.MAX_CHARS_TO_DISPLAY = 20

ssTirePressure.PRESSURE_MIN = 80
ssTirePressure.PRESSURE_LOW = 80
ssTirePressure.PRESSURE_NORMAL = 180
ssTirePressure.PRESSURE_MAX = 180

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
    self.setInflationPressure = ssTirePressure.setInflationPressure
    self.doCheckSpeedLimit = Utils.overwrittenFunction(self.doCheckSpeedLimit, ssTirePressure.doCheckSpeedLimit)
    self.toggleTirePressure = ssTirePressure.toggleTirePressure

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

    self:updateInflationPressure()
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
    local tireTypeCrawler = WheelsUtil.getTireType("crawler")

    for _, wheel in pairs(self.wheels) do
        if wheel.tireType ~= tireTypeCrawler then
            if wheel.ssMaxDeformation == nil then
                wheel.ssMaxDeformation = Utils.getNoNil(wheel.maxDeformation,0)
            end

            wheel.ssMaxLoad = self:getTireMaxLoad(wheel, self.ssInflationPressure)
            wheel.maxDeformation = wheel.ssMaxDeformation * ssTirePressure.PRESSURE_NORMAL / self.ssInflationPressure
        end
    end

    -- Update compaction indicator
    self.ssCompactionIndicatorIsCorrect = false
end

function ssTirePressure:update(dt)
    -- self.ssInCabTirePressureControl = true

    if self.isClient and self:getIsActiveForInput(false) and self.ssInCabTirePressureControl and not self.ssAllWheelsCrawlers then
        g_currentMission:addHelpButtonText(string.format(g_i18n:getText("input_SEASONS_TIRE_PRESSURE"), self.ssInflationPressure), InputBinding.SEASONS_TIRE_PRESSURE)

        if InputBinding.hasEvent(InputBinding.SEASONS_TIRE_PRESSURE) then
            self:toggleTirePressure()
        end
    end
end

function ssTirePressure:toggleTirePressure()
    self:setInflationPressure(self.ssInflationPressure < ssTirePressure.PRESSURE_NORMAL and ssTirePressure.PRESSURE_NORMAL or ssTirePressure.PRESSURE_LOW)
end

function ssTirePressure:draw()
end

function ssTirePressure:getInflationPressure()
    return self.ssInflationPressure
end

function ssTirePressure:setInflationPressure(pressure, noEventSend)
    local old = self.ssInflationPressure

    self.ssInflationPressure = Utils.clamp(pressure, ssTirePressure.PRESSURE_MIN, ssTirePressure.PRESSURE_MAX)

    if self.ssInflationPressure ~= old then
        self:updateInflationPressure()

        -- TODO: Send event
    end
end

function ssTirePressure:doCheckSpeedLimit(superFunc)
    local parent = false
    if superFunc ~= nil then
        parent = superFunc(self)
    end

    return parent or self.ssInflationPressure < ssTirePressure.PRESSURE_NORMAL
end

function ssTirePressure:getSpeedLimit()
    local limit = 1000

    -- TODO: linear from normal speed (what is 'normal speed'?)
    if self.ssInflationPressure == ssTirePressure.PRESSURE_LOW then
        return 10
    end

    return limit
end
