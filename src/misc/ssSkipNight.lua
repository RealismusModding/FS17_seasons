----------------------------------------------------------------------------------------------------
-- SKIP NIGHT SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  Allows player to skip the night by fast forwarding to the morning.
-- Authors:  Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssSkipNight = {}

if GS_IS_CONSOLE_VERSION then
    ssSkipNight.SPEED = 1200
else
    ssSkipNight.SPEED = 6000
end

function ssSkipNight:preLoad()
    g_seasons.skipNight = self
end

function ssSkipNight:loadMap()
    self.skippingNight = false
end

function ssSkipNight:update(dt)
    -- Singleplayer only
    if g_currentMission.missionDynamicInfo.isMultiplayer then return end

    local time = g_currentMission.environment.dayTime / 60 / 1000 -- minutes
    local isEvening = time >= math.max(g_currentMission.environment.nightStart, 20 * 60)
    local isMorning = time >= math.min(g_currentMission.environment.nightEnd, 6 * 60) and time < (12 * 60)

    if isEvening and g_currentMission.controlledVehicle == nil then
        g_currentMission:addHelpButtonText(g_i18n:getText("input_SEASONS_SKIP_NIGHT"), InputBinding.SEASONS_SKIP_NIGHT)

        -- When a player wants to skip the night, fast forward, securily
        if InputBinding.hasEvent(InputBinding.SEASONS_SKIP_NIGHT) then
            self.skippingNight = true
            self.minuteCount = g_currentMission.environment.currentMinute

            g_currentMission.environment:addMinuteChangeListener(self)
            g_currentMission.environment:addHourChangeListener(self)

            self.oldTimeScale = g_currentMission.missionInfo.timeScale
            g_currentMission:setTimeScale(ssSkipNight.SPEED)

            -- Close all dialogs and show a sleeping window
            g_gui:closeAllDialogs()

            self.dialog = g_gui:showDialog("MessageDialog")
            if self.dialog ~= nil then
                self.dialog.target:setDialogType(DialogElement.TYPE_LOADING)
                self.dialog.target:setIsCloseAllowed(false)
                self.dialog.target:setText(ssLang.getText("dialog_sleeping"))
            end
        end
    end

    -- When night ends, stop fast forwarding.
    -- The ssCatchingUp code will synchronize
    if self.skippingNight and isMorning then
        self.skippingNight = false

        g_currentMission.environment:removeMinuteChangeListener(self)
        g_currentMission.environment:removeHourChangeListener(self)

        g_currentMission:setTimeScale(self.oldTimeScale)

        g_gui:closeDialog(self.dialog)
        self.dialog = nil
    end

    -- Ignore any change in timescale by the player
    if self.skippingNight and g_currentMission.missionInfo.timeScale ~= ssSkipNight.SPEED then
        g_currentMission:setTimeScale(ssSkipNight.SPEED)
    end
end

function ssSkipNight:hourChanged()
    if self.minuteCount < 60 then
        -- For every minute not having a minute callback, add an extra callback
        for i = 1, 60 - self.minuteCount, 1 do
            for _, listener in pairs(g_currentMission.environment.minuteChangeListeners) do
                listener:minuteChanged()
            end
        end
    end

    self.minuteCount = 0
end

function ssSkipNight:minuteChanged()
    self.minuteCount = self.minuteCount + 1
end
