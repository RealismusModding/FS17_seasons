----------------------------------------------------------------------------------------------------
-- PEDESTRIAN SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  To disable pedestrian spawning in winter
-- Authors:  Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssPedestrianSystem = {}
g_seasons.pedestrianSystem = ssPedestrianSystem

function ssPedestrianSystem:loadMap(name)
    PedestrianSystem.update = Utils.overwrittenFunction(PedestrianSystem.update, ssPedestrianSystem.psUpdate)
end

function ssPedestrianSystem:psUpdate(superFunc, dt)
    local dayTime = g_currentMission.environment.dayTime

    if g_seasons.weather:currentTemperature() < 5 then
        dayTime = 0 -- midnight, do not spawn
    end

    setPedestrianSystemDaytime(self.pedestrianSystemId, dayTime);
end
