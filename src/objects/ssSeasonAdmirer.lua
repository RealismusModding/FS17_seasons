----------------------------------------------------------------------------------------------------
-- SEASON ADMIRER
----------------------------------------------------------------------------------------------------
-- Purpose:  Visibility of objects dependent on the season
-- Authors:  Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssSeasonAdmirer = {}

local ssSeasonAdmirer_mt = Class(ssSeasonAdmirer)

function ssSeasonAdmirer:onCreate(id)
    g_currentMission:addNonUpdateable(ssSeasonAdmirer:new(id))
end

function ssSeasonAdmirer:new(id)
    local self = {}
    setmetatable(self, ssSeasonAdmirer_mt)
    self.id = id

    self.showIn = {}
    self.showIn[g_seasons.environment.SEASON_SPRING] = Utils.getNoNil(getUserAttribute(id, "spring"), true)
    self.showIn[g_seasons.environment.SEASON_SUMMER] = Utils.getNoNil(getUserAttribute(id, "summer"), true)
    self.showIn[g_seasons.environment.SEASON_AUTUMN] = Utils.getNoNil(getUserAttribute(id, "autumn"), true)
    self.showIn[g_seasons.environment.SEASON_WINTER] = Utils.getNoNil(getUserAttribute(id, "winter"), true)

    self:updateVisibility()

    g_seasons.environment:addSeasonChangeListener(self)

    return self
end

function ssSeasonAdmirer:delete()
    if g_seasons and g_seasons.environment then
        g_seasons.environment:removeSeasonChangeListener(self)
    end
end

function ssSeasonAdmirer:updateVisibility()
    local season = g_seasons.environment:currentSeason()

    setVisibility(self.id, self.showIn[season])
end

function ssSeasonAdmirer:seasonChanged()
    self:updateVisibility()
end
