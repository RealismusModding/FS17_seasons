---------------------------------------------------------------------------------------------------------
-- MOTOR FAILURE SPECIALIZATION
---------------------------------------------------------------------------------------------------------
-- Applied to every Motorized in order to fail the motor when no maintenance is done
-- Authors:  Rahkiin, reallogger
--

ssMotorFailure = {}

ssMotorFailure.BROKEN_OVERDUE_FACTOR = 4

function ssMotorFailure:prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Motorized, specializations)
end

function ssMotorFailure:load(savegame)
    self.startMotor = Utils.overwrittenFunction(self.startMotor, ssMotorFailure.startMotor)
    self.stopMotor = Utils.overwrittenFunction(self.stopMotor, ssMotorFailure.stopMotor)

    self.ssMotorStartFailDuration = math.min(self.motorStartDuration / 2, 500)
    self.ssMotorStartTries = 0
    self.ssMotorStartSoundTime = 0
    self.ssMotorStartMustFail = false
end

function ssMotorFailure:delete()
end

function ssMotorFailure:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssMotorFailure:keyEvent(unicode, sym, modifier, isDown)
end

function ssMotorFailure:update(dt)
    -- Run a repetition sound by killing the engine sound before it finishes
    if self:getIsMotorStarted() then
        -- Do the retry sound effects when starting an unmaintained motor
        if self.isClient and self:getIsActiveForSound() and SoundUtil.isSamplePlaying(self.sampleMotorStart, 1.5 * dt) then
            if self.ssMotorStartSoundTime + self.ssMotorStartFailDuration < g_currentMission.time then
                if self.ssMotorStartTries > 1 then
                    SoundUtil.stopSample(self.sampleMotorStart, false)

                    SoundUtil.playSample(self.sampleMotorStart, 1, 0, nil)

                    self.ssMotorStartTries = self.ssMotorStartTries - 1
                    self.ssMotorStartSoundTime = g_currentMission.time
                elseif self.ssMotorStartTries == 1 and self.ssMotorStartMustFail then
                    self:stopMotor()
                end
            end
        elseif self.isServer and self.motorStartTime < g_currentMission.time then
            -- A motor might die when it is unmaintained
            local overdueFactor = ssVehicle:calculateOverdueFactor(self)
            local p = math.max(2 - overdueFactor ^ 0.001 , 0.2) ^ (1 / 60 / dt * overdueFactor ^ 2.5)

            if math.random() > p then
                self:stopMotor(nil, true)
            end
        end
    end
end

function ssMotorFailure:updateTick(dt)
end

function ssMotorFailure:draw()
end

-- Code from GDN, adjusted to add (semi-)broken motor mechanics
function ssMotorFailure:startMotor(superFunc, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(SetMotorTurnedOnEvent:new(self, true), nil, nil, self)
        else
            g_client:getServerConnection():sendEvent(SetMotorTurnedOnEvent:new(self, true))
        end
    end

    if not self.isMotorStarted then
        self.isMotorStarted = true

        if self.isClient then
            if self.exhaustParticleSystems ~= nil then
                for _, ps in pairs(self.exhaustParticleSystems) do
                    ParticleUtil.setEmittingState(ps, true)
                end
            end

            if self:getIsActiveForSound() then
                SoundUtil.playSample(self.sampleMotorStart, 1, 0, nil)
            end

            if self.exhaustEffects ~= nil then
                for _, effect in pairs(self.exhaustEffects) do
                    setVisibility(effect.effectNode, true)
                    effect.xRot = effect.xzRotationsOffset[1]
                    effect.zRot = effect.xzRotationsOffset[2]
                    setShaderParameter(effect.effectNode, "param", effect.xRot, effect.zRot, 0, 0, false)

                    local color = effect.minRpmColor
                    setShaderParameter(effect.effectNode, "exhaustColor", color[1], color[2], color[3], color[4], false)
                end
            end
        end

        local overdueFactor = Utils.clamp(ssVehicle:calculateOverdueFactor(self), 1, ssMotorFailure.BROKEN_OVERDUE_FACTOR)

        local p = Utils.clamp((ssMotorFailure.BROKEN_OVERDUE_FACTOR - (overdueFactor - 1)) * (0.9 / ssMotorFailure.BROKEN_OVERDUE_FACTOR) + 0.1, 0.1, 1)
        local willStart = math.random() < p

        self.ssMotorStartTries = overdueFactor
        self.ssMotorStartSoundTime = g_currentMission.time
        self.ssMotorStartMustFail = not willStart

        local hiccupTime = (self.ssMotorStartTries - 1) * self.ssMotorStartFailDuration * 3
        self.motorStartTime = g_currentMission.time + self.motorStartDuration + hiccupTime

        self.compressionSoundTime = g_currentMission.time + math.random(5000, 20000) * overdueFactor
        self.lastRoundPerMinute = 0

        if self.fuelFillLevelHud ~= nil then
            VehicleHudUtils.setHudValue(self, self.fuelFillLevelHud, self.fuelFillLevel, self.fuelCapacity)
        end
    end
end

-- Code from GDN, adjusted to add (semi-)broken motor mechanics
function ssMotorFailure:stopMotor(superFunc, noEventSend, broken)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(SetMotorTurnedOnEvent:new(self, false), nil, nil, self)
        else
            g_client:getServerConnection():sendEvent(SetMotorTurnedOnEvent:new(self, false))
        end
    end

    self.isMotorStarted = false

    Motorized.onDeactivateSounds(self)

    if self.isClient then
        if self.exhaustParticleSystems ~= nil then
            for _, ps in pairs(self.exhaustParticleSystems) do
                ParticleUtil.setEmittingState(ps, false)
            end
        end

        -- Only play stop sound if the motor has successfully started
        if not self.ssMotorStartMustFail and self.ssMotorStartTries <= 1 and broken ~= true then
            if self:getIsActiveForSound() then
                SoundUtil.playSample(self.sampleMotorStop, 1, 0, nil)
                SoundUtil.playSample(self.sampleBrakeCompressorStop, 1, 0, nil)
            end

            local airConsumption = self:getMaximalAirConsumptionPerFullStop()
            self.brakeCompressor.fillLevel = math.max(0, self.brakeCompressor.fillLevel - airConsumption)
            self.brakeCompressor.startSoundPlayed = false
            self.brakeCompressor.runSoundActive = false
        end

        if self.exhaustEffects ~= nil then
            for _, effect in pairs(self.exhaustEffects) do
                setVisibility(effect.effectNode, false)
            end
        end
        if self.exhaustFlap ~= nil then
            setRotation(self.exhaustFlap.node, 0, 0, 0)
        end

        if self.rpmHud ~= nil then
            VehicleHudUtils.setHudValue(self, self.rpmHud, 0, self.motor:getMaxRpm())
        end
        if self.speedHud ~= nil then
            VehicleHudUtils.setHudValue(self, self.speedHud, 0, g_i18n:getSpeed(self.motor:getMaximumForwardSpeed()))
        end
        if self.fuelFillLevelHud ~= nil then
            VehicleHudUtils.setHudValue(self, self.fuelFillLevelHud, 0, self.fuelCapacity)
        end
    end

    Motorized.turnOffImplement(self)
end
