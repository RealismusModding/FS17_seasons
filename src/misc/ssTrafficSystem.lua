----------------------------------------------------------------------------------------------------
-- TRAFFIXSYSTEM SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  To fix the lights of the traffic
-- Authors:  Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssTrafficSystem = {}

function ssTrafficSystem:preLoad()
    g_seasons.trafficSystem = self
end

function ssTrafficSystem:loadMap(name)
    ssUtil.overwrittenFunction(TrafficSystem, "update", ssTrafficSystem.tsUpdate)

    self.trafficLightOn = 21.00 * 60
    self.trafficLightOff = 8.00 * 60
end

function ssTrafficSystem:tsUpdate(superFunc, dt)
    -- The traffic system does not listen to the environment.endNight startNight variables
    -- that we use to toggle lights on and off.
    -- The traffic system turns on traffic light at 2100 and turns it off at 800.
    -- We will fake the dayTime to give the correct light effects.

    setTrafficSystemDaytime(self.trafficSystemId, g_seasons.trafficSystem:calculateAdjustedDayTime());
end

function ssTrafficSystem:calculateAdjustedDayTime()
    -- Get all in minutes
    local dayTime = g_currentMission.environment.dayTime / 60 / 1000
    local nightBegin = g_currentMission.environment.nightStart
    local nightEnd = g_currentMission.environment.nightEnd

    local resultTime = 0

    if dayTime >= nightBegin or dayTime < nightEnd then -- lights must be on
        if dayTime > 12 * 60 then -- evening
            resultTime = math.max(self.trafficLightOn, dayTime)
        else -- morning
            resultTime = math.min(self.trafficLightOff, dayTime)
        end
    else
        if dayTime > 12 * 60 then -- evening
            resultTime = math.min(self.trafficLightOn - 0.01, dayTime)
        else -- morning
            resultTime = math.max(self.trafficLightOff + 0.01, dayTime)
        end
    end

    return resultTime * 60 * 1000
end
