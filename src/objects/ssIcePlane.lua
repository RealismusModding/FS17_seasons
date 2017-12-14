----------------------------------------------------------------------------------------------------
-- ICE PLANE
----------------------------------------------------------------------------------------------------
-- Purpose:  A layer of ice visible when the ground is frozen
-- Authors:  Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssIcePlane = {}

local ssIcePlane_mt = Class(ssIcePlane)

function ssIcePlane:onCreate(id)
    g_currentMission:addUpdateable(ssIcePlane:new(id))
end

function ssIcePlane:new(id)
    local self = {}
    setmetatable(self, ssIcePlane_mt)
    self.id = id
    self.collisionMask = getCollisionMask(id)

    g_currentMission.environment:addWeatherChangeListener(self)

    return self
end

function ssIcePlane:delete()
    if g_currentMission.environment ~= nil then
        g_currentMission.environment:removeWeatherChangeListener(self)
    end
end

function ssIcePlane:updateVisibility()
    local visible = g_seasons.weather:isGroundFrozen()

    setVisibility(self.id, visible)
    setCollisionMask(self.id, visible and self.collisionMask or 0)
end

function ssIcePlane:weatherChanged()
    self:updateVisibility()
end

function ssIcePlane:update(dt)
    if self.once ~= true then
        self:updateVisibility()

        self.once = true
    end
end
