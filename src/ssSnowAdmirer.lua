---------------------------------------------------------------------------------------------------------
-- SNOW ADMIRER
---------------------------------------------------------------------------------------------------------
-- Purpose:  Visibility of objects dependent on snow
-- Authors:  Rahkiin
--

ssSnowAdmirer = {}

local ssSnowAdmirer_mt = Class(ssSnowAdmirer)

function ssSnowAdmirer:onCreate(id)
    g_currentMission:addNonUpdateable(ssSnowAdmirer:new(id))
end

function ssSnowAdmirer:new(id)
    local self = {}
    setmetatable(self, ssSnowAdmirer_mt)
    self.id = id

    -- If attribute is set to false, it will only show when there is NO snow
    self.showWhenSnow = Utils.getNoNil(getUserAttribute(id, "snow"), true)

    self:updateVisibility()

    g_seasons.environment:addSeasonChangeListener(self)

    return self
end

function ssSnowAdmirer:delete()
    if g_seasons and g_seasons.environment then
        g_seasons.environment:removeSeasonChangeListener(self)
    end
end

function ssSnowAdmirer:updateVisibility()
    setVisibility(self.id, g_seasons.weatherManager.snowDepth > 0)
end

function ssSnowAdmirer:seasonChanged()
    self:updateVisibility()
end
