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

local function vehicleInShed(vehicle)
    if ssSnow.snowMaskId ~= nil then
        return false
    end
--[[
    -- TODO
    local x0 = x + dim.width
    local x1 = x - dim.width
    local x2 = x + dim.width
    local z0 = z - dim.length
    local z1 = z - dim.length
    local z2 = z + dim.length

    local x,z, widthX,widthZ, heightX,heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, x0,z0, x1,z1, x2,z2)
    local density, _, _ = getDensityMaskedParallelogram(ssSnow.snowMaskId, x, z, widthX, widthZ, heightX, heightZ, 0, 5, ssSnow.snowMaskId, ssSnow.SNOW_MASK_FIRST_CHANNEL, ssSnow.SNOW_MASK_NUM_CHANNELS)

    return density ~= 0
]]
    return false
end

function ssSnowFillable:updateTick(dt)
    if self.isServer then
        local temp = g_seasons.weather:currentTemperature()

        -- Empty the fillable of snow when it is warm
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

        -- When it is snowing, add snow into the fillable (if it accepts snow)
        if self:getAllowFillFromAir() -- For cover
              and not vehicleInShed(self)
              and g_currentMission.environment.currentRain ~= nil
              and g_currentMission.environment.currentRain.rainTypeId == Environment.RAINTYPE_SNOW then

            local level = self:getFillLevel(FillUtil.FILLTYPE_SNOW)
            local diff = 1 * (dt / 1000) -- To be made correctly by reallogger, something with 'size'
            -- 0.01 * length * width * 1000 / 60 / 60

            -- Use this, without force to not override current fills or not-snow fillables.
            self:setFillLevel(level + diff, FillUtil.FILLTYPE_SNOW)
        end
    end
end

function ssSnowFillable:draw()
end

