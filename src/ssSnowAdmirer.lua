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

    g_currentMission.environment:addWeatherChangeListener(self)

    return self
end

function ssSnowAdmirer:delete()
    if g_currentMission.environment ~= nil then
        g_currentMission.environment:removeWeatherChangeListener(self)
    end
end

function ssSnowAdmirer:updateVisibility()
    setVisibility(self.id, g_seasons.weatherManager:getSnowHeight() > 0)
end

function ssSnowAdmirer:weatherChanged()
    self:updateVisibility()
end
