---------------------------------------------------------------------------------------------------------
-- PEDESTRIAN SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  To disable pedestrian spawning in winter
-- Authors:  Rahkiin
--

ssPedestrianSystem = {}

function ssPedestrianSystem:loadMap(name)
    ssSeasonsMod:addSeasonChangeListener(self)

    PedestrianSystem.update = Utils.overwrittenFunction(PedestrianSystem.update, ssPedestrianSystem.originalUpdate)

    if g_currentMission:getIsServer() then
        -- Initial setuo (it changed from nothing)
        self:seasonChanged()
    end
end

function ssPedestrianSystem:readStream(streamId, connection)
    -- Load after data for seasonUtils is loaded
    self:seasonChanged()
end

function ssPedestrianSystem:seasonChanged()
    local season = ssSeasonsUtil:season()

    self.showPedestrians = not (season == ssSeasonsUtil.SEASON_WINTER)
end

function ssPedestrianSystem.originalUpdate(pedestrianSystem, dt)
    local dayTime = g_currentMission.environment.dayTime

    if not ssPedestrianSystem.showPedestrians then
        dayTime = 0 -- midnight, do not spawn
    end

    setPedestrianSystemDaytime(pedestrianSystem.pedestrianSystemId, dayTime);
end
