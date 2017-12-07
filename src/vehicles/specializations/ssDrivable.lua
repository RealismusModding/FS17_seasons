----------------------------------------------------------------------------------------------------
-- DRIVABLE SPECIALIZATION
----------------------------------------------------------------------------------------------------
-- Applied to every Drivable to add some new functionality
-- Authors:  Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssDrivable = {}

function ssDrivable:prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Drivable, specializations)
end

function ssDrivable:load(savegame)
    self.ssShowEngineStartWarningTimer = 0
end

function ssDrivable:delete()
end

function ssDrivable:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssDrivable:keyEvent(unicode, sym, modifier, isDown)
end

function ssDrivable:update(dt)
    log(self.isMotorStarted, self.axisForward, self.cruiseControl.isActive, self.cruiseControl.speed)
    if not self.isMotorStarted and (self.axisForward ~= 0 or (self.cruiseControl.isActive and self.cruiseControl.state ~= Drivable.CRUISECONTROL_STATE_OFF)) then
        self.ssShowEngineStartWarningTimer = self.ssShowEngineStartWarningTimer + dt

        if self.ssShowEngineStartWarningTimer > 800 then
            self.ssShowEngineStartWarning = true
            self.ssShowEngineStartWarningTimer = 0
        end
    else
        self.ssShowEngineStartWarning = false
        self.ssShowEngineStartWarningTimer = 0
    end
end

function ssDrivable:updateTick(dt)
end

function ssDrivable:draw()
    if self.ssShowEngineStartWarning and not self.showWaterWarning then
        g_currentMission:showBlinkingWarning(g_i18n:getText("warning_motorNotStarted"))
    end
end
