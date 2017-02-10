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
    g_currentMission.environment:addHourChangeListener(self)
    g_currentMission.environment:addDayChangeListener(self)

    Bale.loadFromAttributesAndNodes = Utils.overwrittenFunction(Bale.loadFromAttributesAndNodes, ssBaleManager.loadFromAttributesAndNodes)
    Bale.getSaveAttributesAndNodes = Utils.overwrittenFunction(Bale.getSaveAttributesAndNodes, ssBaleManager.getSaveAttributesAndNodes)

end

function ssBaleManager:reduceFillLevel()

    for index,object in pairs(g_currentMission.itemsToSave) do
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
                    if density == 0 and g_currentMission.environment.timeSinceLastRain < 60 then
                    
                        if object.item.fillType == FillUtil.getFillTypesByNames("straw")[1] or object.item.fillType == FillUtil.getFillTypesByNames("dryGrass")[1] then
                            local origFillLevel = object.item.fillLevel
                            local reductionFactor = self:calculateBaleReduction(object.item)
                            object.item.fillLevel = origFillLevel * reductionFactor
                        end
                    end

                    if object.item.fillType == FillUtil.getFillTypesByNames("grass_windrow")[1] then
                        local origFillLevel = object.item.fillLevel
                        local reductionFactor = self:calculateBaleReduction(object.item)
                        object.item.fillLevel = origFillLevel * reductionFactor
                    end
                
                -- without a snowmask reduce all unwrapped bales
                else
                    local origFillLevel = object.item.fillLevel
                    local reductionFactor = self:calculateBaleReduction(object.item)
                    object.item.fillLevel = origFillLevel * reductionFactor
                end
                
            end
        end
    end
end

function ssBaleManager:hourChanged()
    self:reduceFillLevel()
end

function ssBaleManager:dayChanged()
    self:incrementBaleAge()
    self:removeBale()
end

function ssBaleManager:readStream(streamId, connection)
end

function ssBaleManager:writeStream(streamId, connection)
end

function ssBaleManager:update(dt)
end

function ssBaleManager:removeBale()

    for index,object in pairs(g_currentMission.itemsToSave) do
        if object.className == "Bale" then
            if object.item.fillType == FillUtil.getFillTypesByNames("straw")[1] or object.item.fillType == FillUtil.getFillTypesByNames("dryGrass")[1] then

            elseif object.item.fillType == FillUtil.getFillTypesByNames("grass_windrow")[1] then
                if object.item.age > 2 then
                    self:delete(object.item)
                end
            end
        end
    end
end


function ssBaleManager:delete(singleBale)
    -- from https://gdn.giants-software.com/documentation_scripting.php?version=script&category=65&class=2511#delete34583
    if singleBale.i3dFilename ~= nil then
        Utils.releaseSharedI3DFile(singleBale.i3dFilename, nil, true)
    end
    g_currentMission:removeLimitedObject(FSBaseMission.LIMITED_OBJECT_TYPE_BALE, singleBale)
    unregisterObjectClassName(singleBale)
    g_currentMission:removeItemToSave(singleBale)
    Bale:superClass().delete(singleBale)
end

function ssBaleManager:incrementBaleAge()

    for index,object in pairs(g_currentMission.itemsToSave) do

        if object.className == "Bale" then

            if object.item.age ~= nil then
                local yesterdayAge = object.item.age
                object.item.age = yesterdayAge + 1
            else
                object.item.age = 0
            end

        end
    end
end

function ssBaleManager:calculateBaleReduction(singleBale)

	local reductionFactor = 1
	local daysInSeason = g_seasons.environment.daysInSeason
	
	if singleBale.fillType == FillUtil.getFillTypesByNames("straw")[1] or singleBale.fillType == FillUtil.getFillTypesByNames("dryGrass")[1] then
		reductionFactor = 0.99
	
	elseif singleBale.fillType == FillUtil.getFillTypesByNames("grass_windrow")[1] then
        if singleBale.age == nil then
            singleBale.age = 0
        end
	
    	local dayReductionFactor = 1 - ( ( 2.4 * singleBale.age / daysInSeason + 1.2 )^5.75) / 100
		reductionFactor = 1 - ( 1 - dayReductionFactor)/24

	end

    return reductionFactor
end

function ssBaleManager:loadFromAttributesAndNodes(oldFunc, xmlFile, key, resetVehicles)
    local state = oldFunc(self, xmlFile, key, resetVehicles)
		
	if state then
	    local ageLoad = getXMLString(xmlFile, key .. "#age")
			
		if age ~= nil then
			self.age = ageLoad
		end
	end
		
	return state
end
	
function ssBaleManager:getSaveAttributesAndNodes(oldFunc, nodeIdent)
	local attributes, nodes = oldFunc(self, nodeIdent)
		
	if attributes ~= nil and self.age ~= nil then
		attributes = attributes .. ' age="' .. self.age .. '"'
	end
		
	return attributes, nodes
end