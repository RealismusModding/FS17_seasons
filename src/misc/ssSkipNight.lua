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

ssSkipNight.SPEED = 10000

function ssSkipNight:loadMap()
    self.skippingNight = false
end

function ssSkipNight:update(dt)
    -- Singleplayer only
    if not g_currentMission:getIsServer() or not g_currentMission:getIsClient() then return end

    local time = g_currentMission.environment.dayTime / 60 / 1000
    local isEvening = time >= g_currentMission.environment.nightStart
    local isMorning = time >= g_currentMission.environment.nightEnd and time < (12 * 60)

    if isEvening then
        g_currentMission:addHelpButtonText(g_i18n:getText("input_SEASONS_SKIP_NIGHT"), InputBinding.SEASONS_SKIP_NIGHT)

        if InputBinding.hasEvent(InputBinding.SEASONS_SKIP_NIGHT) then
            self.skippingNight = true

            self.oldTimeScale = g_currentMission.missionInfo.timeScale
            g_currentMission.missionInfo.timeScale = ssSkipNight.SPEED
        end
    end

    -- When night ends, stop fast forwarding.
    -- The ssCatchingUp code will synchronize
    if self.skippingNight and isMorning then
        self.skippingNight = false

        g_currentMission.missionInfo.timeScale = self.oldTimeScale
    end
end
