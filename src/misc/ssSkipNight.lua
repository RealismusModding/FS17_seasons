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

source(g_seasons.modDir .. "src/events/ssSkipNightEvent.lua")
source(g_seasons.modDir .. "src/events/ssSkipNightFinishedEvent.lua")

function ssSkipNight:loadMap()
    self.skippingNight = false
    self.mode = ssSkipNight.MODE_MORNING
    self.oldTimeScale = 1

    if g_currentMission.missionDynamicInfo.isMultiplayer then
        ssSkipNight.SPEED = 3000
    end
end

function ssSkipNight:writeStream(streamId, connection)
    streamWriteBool(streamId, self.skippingNight)
    streamWriteInt8(streamId, self.mode)
    streamWriteInt16(streamId, self.oldTimeScale)
end

function ssSkipNight:readStream(streamId, connection)
    self.skippingNight = streamReadBool(streamId)
    self.mode = streamReadInt8(streamId)
    self.oldTimeScale = streamReadInt16(streamId)
end

function ssSkipNight:update(dt)
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

    if isEvening and self:getIsSkipAllowed() then
        g_currentMission:addHelpButtonText(g_i18n:getText("input_SEASONS_SKIP_NIGHT"), InputBinding.SEASONS_SKIP_NIGHT)

        -- When a player wants to skip the night, fast forward, securily
        if InputBinding.hasEvent(InputBinding.SEASONS_SKIP_NIGHT) then
            function result(confirm, option)
                if not confirm then return end

                local mode = option == 1 and ssSkipNight.MODE_MORNING or ssSkipNight.MODE_DAWN

                if g_currentMission.missionDynamicInfo.isMultiplayer then
                    ssSkipNightEvent.sendEvent(mode)
                else
                    self:startSkippingNight(mode)
                end
            end

            -- Calculate dawn of next day
            local julianDay = ssUtil.julianDay(g_seasons.environment:currentDay() + 1)
            local dayStart, _, nightEnd, _ = g_seasons.daylight:calculateStartEndOfDay(julianDay)
            nightEnd = Utils.lerp(nightEnd, dayStart, 0.35) * 60 -- convert to environment var

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
        -- The server might be behind. To prevent a big jump, make the client stop the time as well
        g_currentMission:setTimeScale(self.oldTimeScale, not g_currentMission:getIsServer())

        -- The rest is only for the server. The client removes the listeners and dialogs
        -- when receiving the finished event, so that clients wait for the server to catch up.
        if g_currentMission:getIsServer() then
            self.skippingNight = false

            g_currentMission.environment:removeMinuteChangeListener(self)
            g_currentMission.environment:removeHourChangeListener(self)

            g_gui:closeDialog(self.dialog)
            self.dialog = nil

            g_server:broadcastEvent(EnvironmentTimeEvent:new(g_currentMission.environment.currentDay, g_currentMission.environment.dayTime));
            ssSkipNightFinishedEvent.sendEvent()
        end
    end

    -- Ignore any change in timescale by the player
    if self.skippingNight and g_currentMission.missionInfo.timeScale ~= ssSkipNight.SPEED
        and g_currentMission:getIsServer() then
        g_currentMission:setTimeScale(ssSkipNight.SPEED)
    end

    -- This can occur when the player just joined
    if self.skippingNight and g_currentMission:getIsClient() and self.dialog == nil then
        self:showSkippingDialog()
    end
end

function ssSkipNight:hourChanged()
    local min = g_currentMission.environment.dayTime / 1000 / 60

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

function ssSkipNight:getIsSkipAllowed()
    return g_currentMission:getIsServer() or g_currentMission.isMasterUser
end

function ssSkipNight:startSkippingNight(mode)
    self.mode = mode

    self.skippingNight = true
    self.minuteCount = g_currentMission.environment.currentMinute

    g_currentMission.environment:addMinuteChangeListener(self)
    g_currentMission.environment:addHourChangeListener(self)

    self.oldTimeScale = g_currentMission.missionInfo.timeScale

    if g_currentMission:getIsServer() then
        g_currentMission:setTimeScale(ssSkipNight.SPEED)
    end

    if g_currentMission:getIsClient() then
        self:showSkippingDialog()
    end
end

function ssSkipNight:showSkippingDialog()
    -- Close all dialogs and show a sleeping window
    g_gui:closeAllDialogs()

    self.dialog = g_gui:showDialog("MessageDialog")
    if self.dialog ~= nil then
        self.dialog.target:setDialogType(DialogElement.TYPE_LOADING)
        self.dialog.target:setIsCloseAllowed(false)
        self.dialog.target:setText(ssLang.getText("dialog_sleeping"))
    end
end

-- Called to client when server is finished. Hide dialogs and stop lsiteners
function ssSkipNight:finishSkippingNight()
    self.skippingNight = false

    g_currentMission.environment:removeMinuteChangeListener(self)
    g_currentMission.environment:removeHourChangeListener(self)

    g_gui:closeDialog(self.dialog)
    self.dialog = nil
end
