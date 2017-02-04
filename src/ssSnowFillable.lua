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
        local level = self:getFillLevel(FillUtil.FILLTYPE_SNOW)
        local temp = g_seasons.weather:currentTemperature()

        local diff = 0

        if level > 0 and temp > 0 then
            diff = -1 * level * 0.0001 * (dt / 1000) -- To be made correctly by reallogger

            -- FIXME(jos): with multiple units, too much (or less) is removed. Need to do this all per unit.
            local units = self:getFillUnitsWithFillType(FillUtil.FILLTYPE_SNOW)
            for _, fillUnit in pairs(units) do
                self:setUnitFillLevel(fillUnit.fillUnitIndex, level + diff, FillUtil.FILLTYPE_SNOW)
            end
        end

        -- if temp < 0 and IT SNOWS AND (is snow OR is empty) then
        --     -- If the cover is closed it should automatically not add snow, as no filltype is then
        --     -- 'allowed'
        --     diff = level * 0.0001 * (dt / 1000) -- To be made correctly by reallogger

        --     self:setFillLevel(level + diff, FillUtil.FILLTYPE_SNOW)
        -- end
    end
end

function ssSnowFillable:draw()
end

