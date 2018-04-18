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

-- constants
ssGrowthGUI.MAX_ALLOWABLE_GROWTH_PERIOD = 12 * 2 -- max growth for any fruit = 2 years

function ssGrowthGUI:preLoad()
    g_seasons.growthGUI = self
end

function ssGrowthGUI:loadMap(name)
    self.canPlantData = {}
    self.canHarvestData = {}
end

--simulates growth and builds the canPlantData which is based on 'will the fruit grow in the next growth transition?'
function ssGrowthGUI:buildCanPlantData(fruitData, growthData)
    for fruitName, value in pairs(fruitData) do
        if FruitUtil.fruitTypeGrowths[fruitName] ~= nil and fruitName ~= "dryGrass" then
            local transitionTable = {}

            local germTemp = g_seasons.weather:germinationTemperature(fruitName)
            local tooColdTransitions = g_seasons.weather:soilTooColdForGrowth(germTemp)
            local fruitNumStates = FruitUtil.fruitTypeGrowths[fruitName].numGrowthStates

            for transition, v in pairs(growthData) do
                if transition == g_seasons.growthManager.FIRST_LOAD_TRANSITION then
                    break
                end

                if tooColdTransitions[transition] then
                    table.insert(transitionTable, transition, false)
                else
                    local plantedTransition = transition
                    local currentGrowthState = 1

                    local maxAllowedCounter = 0
                    local transitionToCheck = plantedTransition + 1 -- need to start checking from the next transition after planted transition

                    while currentGrowthState < fruitNumStates and maxAllowedCounter < self.MAX_ALLOWABLE_GROWTH_PERIOD do
                        if transitionToCheck > g_seasons.environment.TRANSITIONS_IN_YEAR then transitionToCheck = 1 end

                        currentGrowthState = self:simulateGrowth(fruitName, transitionToCheck, currentGrowthState, growthData)
                        if currentGrowthState >= fruitNumStates then -- have to break or transitionToCheck will be incremented when it does not have to be
                            break
                        end

                        transitionToCheck = transitionToCheck + 1
                        maxAllowedCounter = maxAllowedCounter + 1
                    end

                    table.insert(transitionTable, plantedTransition, currentGrowthState == fruitNumStates)
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
            local fruitDesc = FruitUtil.fruitTypes[fruitName]

            local skipFruit = fruitName == "poplar" --or fruitName == "grass"

            for plantedTransition = 1, self.MAX_ALLOWABLE_GROWTH_PERIOD do
                if self.canPlantData[fruitName][plantedTransition] == true and not skipFruit then
                    local growthState = 1

                    local transitionToCheck = plantedTransition + 1
                    if plantedTransition > 12 then
                        transitionToCheck = transitionToCheck - 12
                    end
                    if transitionToCheck == 12 then
                        transitionToCheck = 1
                    end

                    local safetyCheck = 1
                    while growthState <= fruitNumStates do
                        growthState = self:simulateGrowth(fruitName, transitionToCheck, growthState, growthData)

                        if growthState == fruitNumStates or (growthState >= fruitDesc.minHarvestingGrowthState + 1 and growthState <= fruitDesc.maxHarvestingGrowthState + 1) then
                            transitionTable[transitionToCheck] = true
                        end

                        transitionToCheck = transitionToCheck + 1
                        safetyCheck = safetyCheck + 1
                        if transitionToCheck > g_seasons.environment.TRANSITIONS_IN_YEAR then transitionToCheck = 1 end
                        if safetyCheck > self.MAX_ALLOWABLE_GROWTH_PERIOD then break end --so we don't end up in infinite loop if growth pattern is not correct
                    end

                end
            end

            --fill in the gaps
            for plantedTransition = 1, self.MAX_ALLOWABLE_GROWTH_PERIOD do
                if fruitName == "poplar" then --hardcoding for poplar. No withering
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

    if transitionToCheck > 12 then
        transitionToCheck = transitionToCheck - 12
    end

    local data = growthData[transitionToCheck][fruitName]

    if data ~= nil then
        if data.setFromMin ~= nil
            and data.setTo ~= nil then
            if data.setFromMax ~= nil then
                if currentGrowthState >= data.setFromMin and currentGrowthState <= data.setFromMax then
                    newGrowthState = data.setTo
                end
            else
                if currentGrowthState == data.setFromMin then
                    newGrowthState = data.setTo
                end
            end
        end
        
        if data.incrementByMin ~= nil
                and data.incrementByMax ~= nil
                and data.incrementBy ~= nil then
            local incrementByMin = data.incrementByMin
            local incrementByMax = data.incrementByMax

            if currentGrowthState >= incrementByMin and currentGrowthState <= incrementByMax then
                newGrowthState = newGrowthState + data.incrementBy
            end
        end

       if data.incrementByOneMin ~= nil then
            local incrementByOneMin = data.incrementByOneMin
            if data.incrementByOneMax ~= nil then
                local incrementByOneMax = data.incrementByOneMax
                if currentGrowthState >= incrementByOneMin and currentGrowthState <= incrementByOneMax then
                    newGrowthState = newGrowthState + 1
                end
            else
                if currentGrowthState == incrementByOneMin then
                    newGrowthState = newGrowthState + 1
                end
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
