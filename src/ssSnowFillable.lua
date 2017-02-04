---------------------------------------------------------------------------------------------------------
-- SNOW FILLABLE SPECIALIZATION
---------------------------------------------------------------------------------------------------------
-- Applied to every Fillable in order to drain snow when it melts
-- Author:  Rahkiin
--

ssSnowFillable = {}

function ssSnowFillable:prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Fillable, specializations)
end

function ssSnowFillable:load(savegame)
end

function ssSnowFillable:delete()
end

function ssSnowFillable:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssSnowFillable:keyEvent(unicode, sym, modifier, isDown)
end

function ssSnowFillable:update(dt)
end

function ssSnowFillable:updateTick(dt)
    if self.isServer then
        -- This check is not very sanitary but it is faster than using a specialization check
        local level = self:getFillLevel(FillUtil.FILLTYPE_SNOW)
        local temp = g_seasons.weather:currentTemperature()

        if level > 0 and temp > 0 then
            local less = level * 0.0001 * (dt / 1000) -- To be made correctly by reallogger

            local units = self:getFillUnitsWithFillType(FillUtil.FILLTYPE_SNOW)
            for _, fillUnit in pairs(units) do
                self:setUnitFillLevel(fillUnit.fillUnitIndex, level - less, FillUtil.FILLTYPE_SNOW)
            end
        end
    end
end

function ssSnowFillable:draw()
end

