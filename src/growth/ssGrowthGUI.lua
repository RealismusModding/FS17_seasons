----------------------------------------------------------------------------------------------------
-- GROWTH GUI SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  To calculate when it is possible to plant and harvest
-- Authors:  theSeb
-- Credits:  
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssGrowthGUI = {}
g_seasons.growthGUI = ssGrowthGUI

-- constants
ssGrowthGUI.MAX_ALLOWABLE_GROWTH_PERIOD = 12 -- max growth for any fruit = 1 year

-- data
ssGrowthGUI.canPlantData = {}
ssGrowthGUI.canHarvestData = {}

--methods
function ssGrowthGUI:loadMap(name)
end

--simulates growth and builds the canPlantData which is based on 'will the fruit grow in the next growth transition?'
function ssGrowthGUI:buildCanPlantData(fruitData, growthData)
    for fruitName, value in pairs(fruitData) do
        if FruitUtil.fruitTypeGrowths[fruitName] ~= nil and fruitName ~= "dryGrass" then
            local transitionTable = {}
            for transition, v in pairs(growthData) do
                if transition == g_seasons.growthManager.FIRST_LOAD_TRANSITION then
                    break
                end

                if transition == g_seasons.environment.TRANSITION_EARLY_WINTER
                        or transition == g_seasons.environment.TRANSITION_MID_WINTER
                        or transition == g_seasons.environment.TRANSITION_LATE_WINTER then --hack for winter planting
                    table.insert(transitionTable, transition , false)
                else
                    local plantedTransition = transition
                    local currentGrowthState = 1

                    local maxAllowedCounter = 0
                    local transitionToCheck = plantedTransition + 1 -- need to start checking from the next transition after planted transition
                    local fruitNumStates = FruitUtil.fruitTypeGrowths[fruitName].numGrowthStates

                    while currentGrowthState < fruitNumStates and maxAllowedCounter < self.MAX_ALLOWABLE_GROWTH_PERIOD do
                        if transitionToCheck > g_seasons.environment.TRANSITIONS_IN_YEAR then transitionToCheck = 1 end

                        currentGrowthState = self:simulateGrowth(fruitName, transitionToCheck, currentGrowthState, growthData)
                        if currentGrowthState >= fruitNumStates then -- have to break or transitionToCheck will be incremented when it does not have to be
                            break
                        end

                        transitionToCheck = transitionToCheck + 1
                        maxAllowedCounter = maxAllowedCounter + 1
                    end
                    if currentGrowthState == fruitNumStates then
                        table.insert(transitionTable, plantedTransition , true)
                    else
                        table.insert(transitionTable, plantedTransition , false)
                    end
                end
            end
            self.canPlantData[fruitName] = transitionTable
        end
    end
end

-- simulates growth based on canPlantData to find out when a fruit will be harvestable
function ssGrowthGUI:buildCanHarvestData(growthData)
    for fruitName, transition in pairs(self.canPlantData) do
        if FruitUtil.fruitTypeGrowths[fruitName] ~= nil then
            local transitionTable = {}
            local plantedTransition = 1
            local fruitNumStates = FruitUtil.fruitTypeGrowths[fruitName].numGrowthStates

            for plantedTransition = 1, self.MAX_ALLOWABLE_GROWTH_PERIOD do
                if self.canPlantData[fruitName][plantedTransition] == true and fruitName ~= "poplar" and fruitName ~= "grass" then
                    local growthState = 1
                    local transitionToCheck = plantedTransition + 1
                    if plantedTransition == self.MAX_ALLOWABLE_GROWTH_PERIOD then
                        transitionToCheck = 1
                    end
                    local safetyCheck = 1
                    while growthState <= fruitNumStates do
                        growthState = self:simulateGrowth(fruitName, transitionToCheck, growthState, growthData)
                        if growthState == fruitNumStates then
                            transitionTable[transitionToCheck] = true
                        end

                        transitionToCheck = transitionToCheck + 1
                        safetyCheck = safetyCheck + 1
                        if transitionToCheck > g_seasons.environment.TRANSITIONS_IN_YEAR then transitionToCheck = 1 end
                        if safetyCheck > 15 then break end --so we don't end up in infinite loop if growth pattern is not correct
                    end

                end
            end
            --fill in the gaps
            for plantedTransition = 1, self.MAX_ALLOWABLE_GROWTH_PERIOD do
                if fruitName == "poplar" then --hardcoding for poplar
                    transitionTable[plantedTransition] = true
                elseif fruitName == "grass" and plantedTransition > g_seasons.environment.TRANSITION_EARLY_SPRING and plantedTransition < g_seasons.environment.TRANSITION_EARLY_WINTER then
                    transitionTable[plantedTransition] = true
                elseif transitionTable[plantedTransition] ~= true then
                    transitionTable[plantedTransition] = false
                end
            end
            self.canHarvestData[fruitName] = transitionTable
        end
    end
end

-- simulate growth helper function to calculate the next growth state based on current growth state and the current transition
function ssGrowthGUI:simulateGrowth(fruitName, transitionToCheck, currentGrowthState, growthData)
    local newGrowthState = currentGrowthState

    if growthData[transitionToCheck][fruitName] ~= nil then
        --setGrowthState
        if growthData[transitionToCheck][fruitName].setGrowthState ~= nil
            and growthData[transitionToCheck][fruitName].desiredGrowthState ~= nil then
            if growthData[transitionToCheck][fruitName].setGrowthMaxState ~= nil then
                if currentGrowthState >= growthData[transitionToCheck][fruitName].setGrowthState and currentGrowthState <= growthData[transitionToCheck][fruitName].setGrowthMaxState then
                    newGrowthState = growthData[transitionToCheck][fruitName].desiredGrowthState
                end
            else
                if currentGrowthState == growthData[transitionToCheck][fruitName].setGrowthState then
                    newGrowthState = growthData[transitionToCheck][fruitName].desiredGrowthState
                end
            end
        end
        --increment by 1 for crops between normalGrowthState  normalGrowthMaxState or for crops at normalGrowthState
        if growthData[transitionToCheck][fruitName].normalGrowthState ~= nil then
            local normalGrowthState = growthData[transitionToCheck][fruitName].normalGrowthState
            if growthData[transitionToCheck][fruitName].normalGrowthMaxState ~= nil then
                local normalGrowthMaxState = growthData[transitionToCheck][fruitName].normalGrowthMaxState
                if currentGrowthState >= normalGrowthState and currentGrowthState <= normalGrowthMaxState then
                    newGrowthState = newGrowthState + 1
                end
            else
                if currentGrowthState == normalGrowthState then
                    newGrowthState = newGrowthState + 1
                end
            end
        end
        --increment by extraGrowthFactor between extraGrowthMinState and extraGrowthMaxState
        if growthData[transitionToCheck][fruitName].extraGrowthMinState ~= nil
                and growthData[transitionToCheck][fruitName].extraGrowthMaxState ~= nil
                and growthData[transitionToCheck][fruitName].extraGrowthFactor ~= nil then
            local extraGrowthMinState = growthData[transitionToCheck][fruitName].extraGrowthMinState
            local extraGrowthMaxState = growthData[transitionToCheck][fruitName].extraGrowthMaxState

            if currentGrowthState >= extraGrowthMinState and currentGrowthState <= extraGrowthMaxState then
                newGrowthState = newGrowthState + growthData[transitionToCheck][fruitName].extraGrowthFactor
            end
        end
    end
    return newGrowthState
end

function ssGrowthGUI:updateCanPlantData(fruitName)
    self.canPlantData[fruitName] = Utils.copyTable(self.canPlantData[g_seasons.growthManager.UNKNOWN_FRUIT_COPY_SOURCE])
end

function ssGrowthGUI:updateCanHarvestData(fruitName)
    self.canHarvestData[fruitName] = Utils.copyTable(self.canHarvestData[g_seasons.growthManager.UNKNOWN_FRUIT_COPY_SOURCE])
end

function ssGrowthGUI:getCanPlantData()
    return self.canPlantData
end

function ssGrowthGUI:canFruitBePlanted(fruitName, transition)
    if self.canPlantData[fruitName][transition] ~= nil then
        return self.canPlantData[fruitName][transition]
    else
        return false
    end
end

function ssGrowthGUI:getCanHarvestData()
    return self.canHarvestData
end

function ssGrowthGUI:canFruitBeHarvested(fruitName, transition)
    if self.canHarvestData[fruitName][transition] ~= nil then
        return self.canHarvestData[fruitName][transition]
    else
        return false
    end
end