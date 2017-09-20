----------------------------------------------------------------------------------------------------
-- SNOW ADMIRER
----------------------------------------------------------------------------------------------------
-- Purpose:  Visibility of objects dependent on snow
-- Authors:  Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssSnowAdmirer = {}

local ssSnowAdmirer_mt = Class(ssSnowAdmirer)

function ssSnowAdmirer:onCreate(id)
    g_currentMission:addUpdateable(ssSnowAdmirer:new(id))
end

function ssSnowAdmirer:new(id)
    local self = {}
    setmetatable(self, ssSnowAdmirer_mt)
    self.id = id
    self.collisionMask = getCollisionMask(id)

    -- If attribute is set to false, it will only show when there is NO snow
    self.showWhenSnow = Utils.getNoNil(getUserAttribute(id, "snow"), true)
    self.minimumLevel = tonumber(Utils.getNoNil(getUserAttribute(id, "level"), 1))

    return self
end

function ssSnowAdmirer:updateVisibility()
    -- On a game server we have access to the applied snow depth. Use it. Otherwise fall back to weather value
    -- which might not be in sync with what you see as player
    local depth = g_seasons.weather.snowDepth
    if g_currentMission:getIsServer() then
        depth = g_seasons.snow.appliedSnowDepth
    end

    local visible = depth >= g_seasons.snow.LAYER_HEIGHT * self.minimumLevel

    if not self.showWhenSnow then
        visible = not visible
    end

    setVisibility(self.id, visible)
    setCollisionMask(self.id, visible and self.collisionMask or 0)
end

function ssSnowAdmirer:update(dt)
    self:updateVisibility()
end
