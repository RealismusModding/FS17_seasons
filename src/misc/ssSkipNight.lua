----------------------------------------------------------------------------------------------------
-- SKIP NIGHT SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  Allows player to skip the night by fast forwarding to the morning.
-- Authors:  Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssSkipNight = {}
g_seasons.skipNight = ssSkipNight

ssSkipNight.SPEED = 6000
ssSkipNight.MODE_MORNING = 1
ssSkipNight.MODE_DAWN = 2

function ssSkipNight:loadMap()
    self.skippingNight = false
    self.mode = ssSkipNight.MODE_MORNING
end

function ssSkipNight:update(dt)
    -- Singleplayer only
    if g_currentMission.missionDynamicInfo.isMultiplayer then return end

    local time = g_currentMission.environment.dayTime / 60 / 1000 -- minutes

    local isEvening = time >= math.min(g_currentMission.environment.nightStart, 20 * 60)
    local isMorning = false

    if time < (12 * 60) then
        if self.mode == ssSkipNight.MODE_DAWN then
            isMorning = time >= g_currentMission.environment.nightEnd
        else
            isMorning = time >= (6 * 60)
        end
    end

    if isEvening then
        g_currentMission:addHelpButtonText(g_i18n:getText("input_SEASONS_SKIP_NIGHT"), InputBinding.SEASONS_SKIP_NIGHT)

        -- When a player wants to skip the night, fast forward, securily
        if InputBinding.hasEvent(InputBinding.SEASONS_SKIP_NIGHT) then
            function result(confirm, option)
                if not confirm then return end

                self.mode = option == 1 and ssSkipNight.MODE_MORNING or ssSkipNight.MODE_DAWN

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

            -- Calculate dawn of next day
            local julianDay = ssUtil.julianDay(g_seasons.environment:currentDay() + 1)
            local _, _, nightEnd, _ = g_seasons.daylight:calculateStartEndOfDay(julianDay)

            local dawnTime = string.format("%0.2d:%0.2d", math.floor(nightEnd / 60), nightEnd % 60)
            local dialog = g_gui:showDialog("TwoOptionDialog")

            dialog.target:setText(string.format(ssLang.getText("dialog_skipNight_text"), dawnTime))
            dialog.target:setDialogType(DialogElement.TYPE_QUESTION)
            dialog.target:setCallback(result, nil)
            dialog.target:setButtonTexts(ssLang.getText("dialog_skipNight_morning"),
                                         string.format(ssLang.getText("dialog_skipNight_dawn"), dawnTime))
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
