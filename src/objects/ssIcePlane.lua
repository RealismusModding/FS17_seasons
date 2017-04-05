----------------------------------------------------------------------------------------------------
-- ICE PLANE
----------------------------------------------------------------------------------------------------
-- Purpose:  A layer of ice visible when the ground is frozen
-- Authors:  Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssIcePlane = {}
getfenv(0)["ssIcePlane"] = ssIcePlane

local ssIcePlane_mt = Class(ssIcePlane)

function ssIcePlane:onCreate(id)
    g_currentMission:addNonUpdateable(ssIcePlane:new(id))
end

function ssIcePlane:new(id)
    local self = {}
    setmetatable(self, ssIcePlane_mt)
    self.id = id

    self:updateVisibility()

    g_currentMission.environment:addWeatherChangeListener(self)

    return self
end

function ssIcePlane:delete()
    if g_currentMission.environment ~= nil then
        g_currentMission.environment:removeWeatherChangeListener(self)
    end
end

function ssIcePlane:updateVisibility()
    if g_seasons ~= nil and g_seasons.loaded then
        setVisibility(self.id, g_seasons.weather:isGroundFrozen())
    else
        setVisibility(self.id, false)
    end
end

function ssIcePlane:weatherChanged()
    self:updateVisibility()
end
