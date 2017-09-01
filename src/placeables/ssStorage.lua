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
    ssUtil.appendedFunction(Storage, "delete", ssStorage.storageDelete)
    ssUtil.appendedFunction(Storage, "update", ssStorage.storageUpdate)

    Storage.seasonLengthChanged = ssStorage.storageSeasonLengthChanged
    Storage.ssUpdateCosts = ssStorage.ssUpdateCosts
end

function ssStorage:loadMap()
end

function ssStorage:storageUpdate()
    if not self.ssLoadOnce then
        self.ssLoadOnce = true

        self.ssOriginalCost = self.costsPerFillLevelAndDay

        self:ssUpdateCosts()

        g_seasons.environment:addSeasonLengthChangeListener(self)
    end
end

function ssStorage:storageDelete()
    g_seasons.environment:removeSeasonLengthChangeListener(self)
end

function ssStorage:storageSeasonLengthChanged()
    self:ssUpdateCosts()
end

function ssStorage:ssUpdateCosts()
    local difficultyFac = 1 - (2 - g_currentMission.missionInfo.difficulty) * 0.1

    self.costsPerFillLevelAndDay = self.ssOriginalCost / g_seasons.environment.daysInSeason * difficultyFac
end
