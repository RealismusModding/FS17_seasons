----------------------------------------------------------------------------------------------------
-- GRASS FILLABLE SPECIALIZATION
----------------------------------------------------------------------------------------------------
-- Applied to every Fillable in order to rot grass, hay and straw
-- Authors:  Rahkiin, reallogger
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssGrassFillable = {}

function ssGrassFillable:prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Fillable, specializations)
end

function ssGrassFillable:load(savegame)
end

function ssGrassFillable:delete()
end

function ssGrassFillable:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssGrassFillable:keyEvent(unicode, sym, modifier, isDown)
end

function ssGrassFillable:update(dt)
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

-- Fillables with grass will be reduced every midnight
function ssGrassFillable:ssRotGrass(vehicle)
    if vehicleHasFillType(vehicle, FillUtil.FILLTYPE_GRASS_WINDROW) then
        fillToReduce = FillUtil.FILLTYPE_GRASS_WINDROW

        local level = vehicle:getFillLevel(fillType)
        local capacity = vehicle:getCapacity()
        local diff = 0

        local units = vehicle:getFillUnitsWithFillType(fillToReduce)

        if level > capacity / 2 then
            diff = - level / 2
        elseif level < capacity / 4 then
            diff = - level
        else
            diff = - capacity / 4
        end

        -- Update each unit
        for _, fillUnit in pairs(units) do
            local unitLevel = vehicle:getUnitFillLevel(fillUnit.fillUnitIndex)

            -- Add each compartment reduce the same amount (not based on capacity). Don't bother with the details.
            vehicle:setUnitFillLevel(fillUnit.fillUnitIndex, unitLevel + diff / table.getn(units), fillToReduce)
        end
    end
end

function ssGrassFillable:updateTick(dt)
    if self.isServer then
        local fillToReduce = nil

        -- If it rained into the fillable with hay or straw, rot it a bit
        if g_currentMission.environment.timeSinceLastRain < 5
            and self:getAllowFillFromAir()
            and not vehicleInShed(self) then

            if vehicleHasFillType(self, FillUtil.FILLTYPE_DRYGRASS_WINDROW) then
                fillToReduce = FillUtil.FILLTYPE_DRYGRASS_WINDROW

            elseif vehicleHasFillType(self, FillUtil.FILLTYPE_STRAW) then
                fillToReduce = FillUtil.FILLTYPE_STRAW
            end
        end

        if fillToReduce ~= nil then
            local level = self:getFillLevel(fillType)

            local diff = - self.sizeWidth * self.sizeLength * 1000 / 60 / 60 * (dt / 1000) / 10

            -- Update each unit
            local units = self:getFillUnitsWithFillType(fillToReduce)
            for _, fillUnit in pairs(units) do
                local unitLevel = self:getUnitFillLevel(fillUnit.fillUnitIndex)

                -- Add each compartment reduce the same amount (not based on capacity). Don't bother with the details.
                self:setUnitFillLevel(fillUnit.fillUnitIndex, unitLevel + diff / table.getn(units), fillToReduce)
            end
        end
    end
end

function ssGrassFillable:draw()
end
