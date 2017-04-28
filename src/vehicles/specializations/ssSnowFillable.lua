----------------------------------------------------------------------------------------------------
-- SNOW FILLABLE SPECIALIZATION
----------------------------------------------------------------------------------------------------
-- Applied to every Fillable in order to drain snow when it melts
-- Authors:  Rahkiin, reallogger
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

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
        local width = vehicle.sizeWidth / 3
        local length = vehicle.sizeLength / 3
        -- divide by 3 to ensure vehicle is registered as inside the shed even if the mask is not accurate
        -- and/or the vehicle is parked near the border of the mask

        local positionX, positionY, positionZ = getWorldTranslation(vehicle.rootNode)

        local x0 = positionX + width
        local x1 = positionX - width
        local x2 = positionX + width
        local z0 = positionZ - length
        local z1 = positionZ - length
        local z2 = positionZ + length

        local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, x0, z0, x1, z1, x2, z2)
        local density, _, _ = getDensityMaskedParallelogram(ssSnow.snowMaskId, x, z, widthX, widthZ, heightX, heightZ, 0, 5, ssSnow.snowMaskId, ssSnow.SNOW_MASK_FIRST_CHANNEL, ssSnow.SNOW_MASK_NUM_CHANNELS)

        return density ~= 0
    else
        return false
    end
end

function ssSnowFillable:updateTick(dt)
    if self.isServer then
        local temp = g_seasons.weather:currentTemperature()

        -- Empty the fillable of snow when it is warm
        if vehicleHasFillType(self, FillUtil.FILLTYPE_SNOW) and temp > 0 then
            local level = self:getFillLevel(FillUtil.FILLTYPE_SNOW)
            local diff = -0.05 * self.sizeWidth * self.sizeLength * 1000 / 60 / 60 * (dt / 1000) * temp

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
              and g_currentMission.environment.currentRain.rainTypeId == Environment.RAINTYPE_SNOW
              and temp <= 0 then

            local level = self:getFillLevel(FillUtil.FILLTYPE_SNOW)
            local diff = 0.05 * self.sizeWidth * self.sizeLength * 1000 / 60 / 60 * (dt / 1000)

            -- Use this, without force to not override current fills or not-snow fillables.
            self:setFillLevel(level + diff, FillUtil.FILLTYPE_SNOW)
        end
    end
end

function ssSnowFillable:draw()
end

