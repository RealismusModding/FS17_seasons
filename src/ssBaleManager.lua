---------------------------------------------------------------------------------------------------------
-- BALE MANAGER SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  To reduce fillLevel of bales
-- Authors:  reallogger 
--

ssBaleManager = {}

function ssBaleManager:load(savegame, key)
end

function ssBaleManager:save(savegame, key)
end

function ssBaleManager:loadMap(name)
    g_seasons.environment:addGrowthStageChangeListener(self)
    g_currentMission.environment:addDayChangeListener(self)

    if g_currentMission:getIsServer() == true then
        ssDensityMapScanner:registerCallback("ssBaleManagerReduceVolume", self, self.reduceVolume)
    end
end

function ssBaleManager:reduceVolume(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, reductionFactor)
    reductionFactor = tonumber(reductionFactor)

    for _,object in pairs(g_currentMission.itemsToSave) do
        -- only check bales
        if object.className == "Bale" then
            
            -- wrapped bales are not affected
            if object.item.wrappingState ~= 1 then
    
                -- with a snowmask only reduce hay and hay bales outside and grass bales inside/outside
                if ssSnow.snowMaskId ~= nil then
                    local dim = {}

                    if object.item.baleDiameter ~= nil then
                        dim.width = object.item.baleWidth
                        dim.length = object.item.baleDiameter
                    else
                        dim.width = object.item.baleWidth
                        dim.length = object.item.length
                    end
                        
                    local x0 = object.item.sendPosX + dim.width
                    local x1 = object.item.sendPosX - dim.width
                    local x2 = object.item.sendPosX + dim.width
                    local z0 = object.item.sendPosZ - dim.length
                    local z1 = object.item.sendPosZ - dim.length
                    local z2 = object.item.sendPosZ + dim.length

                    local x,z, widthX,widthZ, heightX,heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, x0,z0, x1,z1, x2,z2)

                    local density, _ , _ = getDensityMaskedParallelogram(ssSnow.snowMaskId, x, z, widthX, widthZ, heightX, heightZ, 0, 5, ssSnow.snowMaskId, ssSnow.SNOW_MASK_FIRST_CHANNEL, ssSnow.SNOW_MASK_NUM_CHANNELS)

                    -- check if the bale is outside and there has been rain during the day
                    if density == 0 and g_currentMission.environment.timeSinceLastRain < 1440 then
                        
                        --if object.item.fillType == FillUtil:getFillTypesByNames("straw") or object.item.fillType == FillUtil:getFillTypesByNames("dryGrass") then
                            local origFillLevel = object.item.fillLevel
                            object.item.fillLevel = origFillLevel * reductionFactor
                        --end
                    --elseif object.item.fillType == FillUtil:getFillTypesByNames("grass") then
                    --    local origFillLevel = object.item.fillLevel
                    --    object.item.fillLevel = origFillLevel * reductionFactor
                    end
                
                -- without a snowmask reduce all unwrapped bales
                else
                    local origFillLevel = object.item.fillLevel
                    object.item.fillLevel = origFillLevel * reductionFactor
                end
            end
        end
    end
end

function ssBaleManager:dayChanged()
    ssDensityMapScanner:queuJob("ssBaleManagerReduceVolume", 0.75)
end

function ssBaleManager:growthStageChanged()
end

function ssBaleManager:readStream(streamId, connection)
end

function ssBaleManager:writeStream(streamId, connection)
end

function ssBaleManager:update(dt)
end

