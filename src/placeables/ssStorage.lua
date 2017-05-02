----------------------------------------------------------------------------------------------------
-- STORAGE SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  To change storage properties
-- Authors:  Rahkiin, reallogger, theSeb 
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

--FIXME: probably should not be in the placeable subdir but don't see a logical place for it right now. objects? misc?

ssStorage = {}

function ssStorage:preLoad()
    Storage.load = Utils.overwrittenFunction(Storage.load, ssStorage.load)
    Storage.seasonLengthChanged = ssStorage.storageSeasonLengthChanged
    
end

function ssStorage:loadMap()
    g_seasons.environment:addSeasonLengthChangeListener(self)
end

function ssStorage:load(superFunc)
    local ret = superFunc(self)
    self:calculateCosts()
    return ret
end

function ssStorage:storageSeasonLengthChanged()
    self:calculateCosts()
end

function ssStorage:calculateCosts()
    local difficultyFac = 1 - ( g_currentMission.missionInfo.difficulty - 2 ) * 0.1
    self.costsPerFillLevelAndDay = 0.01 / g_seasons.environment.daysInSeason * difficultyFac
end
