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

local function vehicleHasFillType(vehicle, type)
    local types = vehicle:getCurrentFillTypes()

    for _, typ in pairs(types) do
        if typ == type then
            return true
        end
    end

    return false
end

function ssSnowFillable:updateTick(dt)
    if self.isServer then
        local temp = g_seasons.weather:currentTemperature()

        if vehicleHasFillType(self, FillUtil.FILLTYPE_SNOW) and temp > 0 then
            local level = self:getFillLevel(FillUtil.FILLTYPE_SNOW)
            local diff = -1 * level * 0.0001 * (dt / 1000) -- To be made correctly by reallogger

            -- Update each unit
            local units = self:getFillUnitsWithFillType(FillUtil.FILLTYPE_SNOW)
            for _, fillUnit in pairs(units) do
                local unitLevel = self:getUnitFillLevel(fillUnit.fillUnitIndex)

                -- Add each compartment the same amount of snow (not based on capacity). Don't bother with the details.
                self:setUnitFillLevel(fillUnit.fillUnitIndex, unitLevel + diff / table.getn(units), FillUtil.FILLTYPE_SNOW)
            end
        end

        if temp < 0 and vehicle:allowFillFromAir() -- For cover
              and g_currentMission.environment.currentRain ~= nil
              and g_currentMission.environment.currentRain.rainTypeId == Environment.RAINTYPE_SNOW then
            local level = self:getFillLevel(FillUtil.FILLTYPE_SNOW)
            local diff = level * 0.0001 * (dt / 1000) -- To be made correctly by reallogger

            -- Use this, without force to not override current fills.
            -- Jos: I am not sure this works.. It did not seem to for the emptying.. WIP, needs testing
            self:setFillLevel(level + diff, FillUtil.FILLTYPE_SNOW)
        end
    end
end

function ssSnowFillable:draw()
end

