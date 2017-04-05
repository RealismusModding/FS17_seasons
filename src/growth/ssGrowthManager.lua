----------------------------------------------------------------------------------------------------
-- GROWTH MANAGER SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  to manage growth as the season changes
-- Authors:  theSeb
-- Credits:  Inspired by upsidedown's growth manager mod
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssGrowthManager = {}
g_seasons.growthManager = ssGrowthManager

-- constants
ssGrowthManager.MAX_STATE = 99 -- needs to be set to the fruit's numGrowthStates if you are setting, or numGrowthStates-1 if you're incrementing
ssGrowthManager.CUT = 200
ssGrowthManager.WITHERED = 300
ssGrowthManager.FIRST_LOAD_TRANSITION = 999
ssGrowthManager.FIRST_GROWTH_TRANSITION = 1
ssGrowthManager.fruitNameToCopyForUnknownFruits = "barley"
ssGrowthManager.MAX_ALLOWABLE_GROWTH_PERIOD = 12 -- max growth for any fruit = 1 year

-- data
ssGrowthManager.defaultFruitsData = {}
ssGrowthManager.growthData = {}
ssGrowthManager.canPlantData = {}
ssGrowthManager.canHarvestData = {}
ssGrowthManager.willGerminateData = {}

-- properties
ssGrowthManager.currentGrowthTransitionPeriod = nil
ssGrowthManager.doResetGrowth = false
ssGrowthManager.fakeGrowthTransitionNum = 1

function ssGrowthManager:load(savegame, key)
    self.isNewSavegame = savegame == nil

    self.growthManagerEnabled = ssStorage.getXMLBool(savegame, key .. ".settings.growthManagerEnabled", true)
    self.currentGrowthTransitionPeriod = ssStorage.getXMLInt(savegame, key .. ".growthManager.currentGrowthTransitionPeriod", 0)

    if savegame == nil then return end

    local i = 0
    while true do
        local fruitKey = string.format("%s.growthManager.willGerminate.fruit(%i)", key, i)
        if not hasXMLProperty(savegame, fruitKey) then break end

        local fruitName = getXMLString(savegame, fruitKey .. "#fruitName")
        self.willGerminateData[fruitName] = getXMLBool(savegame, fruitKey .. "#value", false)

        i = i + 1
    end
end

function ssGrowthManager:save(savegame, key)
    ssStorage.setXMLBool(savegame, key .. ".settings.growthManagerEnabled", self.growthManagerEnabled)
    ssStorage.setXMLInt(savegame, key .. ".growthManager.currentGrowthTransitionPeriod", self.currentGrowthTransitionPeriod)

    local i = 0
    for fruitName in pairs(self.willGerminateData) do
        local fruitKey = string.format("%s.growthManager.willGerminate.fruit(%i)", key, i)

        setXMLString(savegame, fruitKey .. "#fruitName", tostring(fruitName))
        setXMLBool(savegame, fruitKey .. "#value", self.willGerminateData[fruitName])

        i = i+1
    end
end

function ssGrowthManager:loadMap(name)
    if self.growthManagerEnabled == false then
        logInfo("ssGrowthManager:", "disabled")
        return
    end

    --lock changing the growth speed option and set growth rate to 1 (no growth)
    g_currentMission:setPlantGrowthRate(1,nil)
    g_currentMission:setPlantGrowthRateLocked(true)

    if not self:getGrowthData() then
        logInfo("ssGrowthManager:" ,"required data not loaded. ssGrowthManager disabled")
        return
    end
    
    self:buildCanPlantData(self.defaultFruitsData)
    self:buildCanHarvestData()

    if g_currentMission:getIsServer() then
        g_currentMission.environment:addDayChangeListener(self)
        g_seasons.environment:addGrowthStageChangeListener(self)

        ssDensityMapScanner:registerCallback("ssGrowthManagerHandleGrowth", self, self.handleGrowth)

        addConsoleCommand("ssResetGrowth", "Resets growth back to default starting stage", "consoleCommandResetGrowth", self)
        addConsoleCommand("ssIncrementGrowth", "Increments growth for test purposes", "consoleCommandIncrementGrowthStage", self)
        addConsoleCommand("ssSetGrowthStage", "Sets growth for test purposes", "consoleCommandSetGrowthStage", self)
        addConsoleCommand("ssTestStuff", "Tests stuff", "consoleCommandTestStuff", self)
        self:dayChanged()
    end
end

function ssGrowthManager:getGrowthData()
    local defaultFruitsData,growthData = ssGrowthManagerData:loadAllData()

    if defaultFruitsData ~= nil then
        self.defaultFruitsData = defaultFruitsData
    else
        logInfo("ssGrowthManager:", "default fruits data not found")
        return false
    end

    if growthData ~= nil then
        self.growthData = growthData
    else
        logInfo("ssGrowthManager:", "default growth data not found")
        return false
    end
    return true
end

function ssGrowthManager:consoleCommandResetGrowth()
    if g_currentMission:getIsServer() then
        self:resetGrowth()
    end
end

function ssGrowthManager:resetGrowth()
    if self.growthManagerEnabled == true then
        self.currentGrowthTransitionPeriod = self.FIRST_LOAD_TRANSITION
        ssDensityMapScanner:queueJob("ssGrowthManagerHandleGrowth", 1)
        logInfo("ssGrowthManager:", "Growth reset")
    end
end

--handle growthStageCHanged event
function ssGrowthManager:growthStageChanged()
    if self.growthManagerEnabled == false then return end

    local growthTransition = g_seasons.environment:growthTransitionAtDay()

    if self.isNewSavegame and growthTransition == self.FIRST_GROWTH_TRANSITION then
        self.currentGrowthTransitionPeriod = self.FIRST_LOAD_TRANSITION
        logInfo("ssGrowthManager:", "First time growth reset - this will only happen once in a new savegame")
        self.isNewSavegame = false
            ssDensityMapScanner:queueJob("ssGrowthManagerHandleGrowth", 1)
    else
        log("GrowthManager enabled - growthStateChanged to: " .. growthTransition)
        self.currentGrowthTransitionPeriod = growthTransition
        ssDensityMapScanner:queueJob("ssGrowthManagerHandleGrowth", 1)
        self:rebuildWillGerminateData()
    end
end

-- reset the willGerminateData and rebuild it based on the current transition
-- called just after growthStageChanged
function ssGrowthManager:rebuildWillGerminateData()
    self.willGerminateData = {}
    self:dayChanged()
end

-- handle dayChanged event
-- check if canSow and update willGerminate accordingly
function ssGrowthManager:dayChanged()
    if self.growthManagerEnabled == false then return end

    for fruitName, growthTransition in pairs(self.canPlantData) do
        if self.canPlantData[fruitName][g_seasons.environment:growthTransitionAtDay()] == true then
            self.willGerminateData[fruitName] = ssWeatherManager:canSow(fruitName)
        end
    end
end

function ssGrowthManager:handleGrowth(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, layers)
    local x,z, widthX,widthZ, heightX,heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

    for index,fruit in pairs(g_currentMission.fruits) do
        local fruitName = FruitUtil.fruitIndexToDesc[index].name

        --handling new unknown fruits
        if self.defaultFruitsData[fruitName] == nil then
            log("Fruit not found in default table: " .. fruitName)
            self:unknownFruitFound(fruitName)
        end

        if self.growthData[self.currentGrowthTransitionPeriod][fruitName] ~= nil then
            --setGrowthState
            if self.growthData[self.currentGrowthTransitionPeriod][fruitName].setGrowthState ~= nil
                and self.growthData[self.currentGrowthTransitionPeriod][fruitName].desiredGrowthState ~= nil then
                    --log("FruitID " .. fruit.id .. " FruitName: " .. fruitName .. " - reset growth at season transition: " .. self.currentGrowthTransitionPeriod .. " between growth states " .. self.growthData[self.currentGrowthTransitionPeriod][fruitName].setGrowthState .. " and " .. self.growthData[self.currentGrowthTransitionPeriod][fruitName].setGrowthMaxState .. " to growth state: " .. self.growthData[self.currentGrowthTransitionPeriod][fruitName].setGrowthState)
                self:setGrowthState(fruit, fruitName, x, z, widthX, widthZ, heightX, heightZ)
            end
            --increment by 1 for crops between normalGrowthState  normalGrowthMaxState or for crops at normalGrowthState
            if self.growthData[self.currentGrowthTransitionPeriod][fruitName].normalGrowthState ~= nil then
                self:incrementGrowthState(fruit, fruitName, x, z, widthX, widthZ, heightX, heightZ)
            end
            --increment by extraGrowthFactor between extraGrowthMinState and extraGrowthMaxState
            if self.growthData[self.currentGrowthTransitionPeriod][fruitName].extraGrowthMinState ~= nil
                    and self.growthData[self.currentGrowthTransitionPeriod][fruitName].extraGrowthMaxState ~= nil
                    and self.growthData[self.currentGrowthTransitionPeriod][fruitName].extraGrowthFactor ~= nil then
                self:incrementExtraGrowthState(fruit, fruitName, x, z, widthX, widthZ, heightX, heightZ)
            end
        end  -- end of if self.growthData[self.currentGrowthTransitionPeriod][fruitName] ~= nil then
    end  -- end of for index,fruit in pairs(g_currentMission.fruits) do
end

function ssGrowthManager:setGrowthState(fruit, fruitName, x, z, widthX, widthZ, heightX, heightZ)
    local minState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].setGrowthState
    local desiredGrowthState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].desiredGrowthState
    local fruitTypeGrowth = FruitUtil.fruitTypeGrowths[fruitName]

    if desiredGrowthState == self.WITHERED then
        desiredGrowthState = fruitTypeGrowth.witheringNumGrowthStates
    elseif desiredGrowthState == self.CUT then
        desiredGrowthState = FruitUtil.fruitTypes[fruitName].cutState + 1
    end

    if self.growthData[self.currentGrowthTransitionPeriod][fruitName].setGrowthMaxState ~= nil then --if maxState exists
        local maxState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].setGrowthMaxState

        if maxState == self.MAX_STATE then
            maxState = fruitTypeGrowth.numGrowthStates
        end

        setDensityMaskParams(fruit.id, "between", minState, maxState)
    else -- else only use minState
        setDensityMaskParams(fruit.id, "equals", minState)
    end

    local numFruitStateChannels = g_currentMission.numFruitStateChannels
    local growthResult = setDensityMaskedParallelogram(fruit.id, x, z, widthX, widthZ, heightX, heightZ, 0, numFruitStateChannels, fruit.id, 0, numFruitStateChannels, desiredGrowthState)
    setDensityMaskParams(fruit.id, "greater", -1) -- reset
end

--increment by 1 for crops between normalGrowthState  normalGrowthMaxState or for crops at normalGrowthState
function ssGrowthManager:incrementGrowthState(fruit, fruitName, x, z, widthX, widthZ, heightX, heightZ)
    local useMaxState = false
    local minState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].normalGrowthState
    if minState == 1 and self.willGerminateData[fruitName] == false then --check if the fruit has just been planted and delay growth if germination temp not reached
        return
    end

    local fruitTypeGrowth = FruitUtil.fruitTypeGrowths[fruitName]

    if self.growthData[self.currentGrowthTransitionPeriod][fruitName].normalGrowthMaxState ~= nil then

        local maxState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].normalGrowthMaxState

        if maxState == self.MAX_STATE then
            maxState = fruitTypeGrowth.numGrowthStates-1
        end
        setDensityMaskParams(fruit.id, "between", minState, maxState)
        useMaxState = true
    else
        setDensityMaskParams(fruit.id, "equals", minState)
    end

    local numFruitStateChannels = g_currentMission.numFruitStateChannels
    local growthResult = addDensityMaskedParallelogram(fruit.id, x, z, widthX, widthZ, heightX, heightZ, 0, numFruitStateChannels, fruit.id, 0, numFruitStateChannels, 1)

    if growthResult ~= 0 then
        local terrainDetailId = g_currentMission.terrainDetailId
        if fruitTypeGrowth.resetsSpray and minState <= self.defaultFruitsData[fruitName].maxSprayGrowthStage then
            if useMaxState == true then
                setDensityMaskParams(fruit.id, "between", minState, self.defaultFruitsData[fruitName].maxSprayGrowthStage)
            end
            local sprayResetResult = addDensityMaskedParallelogram(terrainDetailId, x, z, widthX, widthZ, heightX, heightZ, g_currentMission.sprayFirstChannel, g_currentMission.sprayNumChannels, fruit.id, 0, numFruitStateChannels, -1)
        end
        if fruitTypeGrowth.groundTypeChanged > 0 then --grass
            setDensityCompareParams(terrainDetailId, "greater", 0)
            local sum = setDensityMaskedParallelogram(terrainDetailId, x, z, widthX, widthZ, heightX, heightZ, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, fruit.id, fruitTypeGrowth.groundTypeChangeGrowthState, numFruitStateChannels, fruitTypeGrowth.groundTypeChanged)
            setDensityCompareParams(terrainDetailId, "greater", -1) -- reset
        end
    end
    setDensityMaskParams(fruit.id, "greater", -1) -- reset
end

--increment by extraGrowthFactor between extraGrowthMinState and extraGrowthMaxState
function ssGrowthManager:incrementExtraGrowthState(fruit, fruitName, x, z, widthX, widthZ, heightX, heightZ)
    local minState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].extraGrowthMinState
    local maxState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].extraGrowthMaxState
    setDensityMaskParams(fruit.id, "between", minState, maxState) --because we always expect min and max with an incrementExtraGrowthState command

    local extraGrowthFactor = self.growthData[self.currentGrowthTransitionPeriod][fruitName].extraGrowthFactor
    local numFruitStateChannels = g_currentMission.numFruitStateChannels
    local growthResult = addDensityMaskedParallelogram(fruit.id, x, z, widthX, widthZ, heightX, heightZ, 0, numFruitStateChannels, fruit.id, 0, numFruitStateChannels, extraGrowthFactor)

    if growthResult ~= 0 then
        local fruitTypeGrowth = FruitUtil.fruitTypeGrowths[fruitName]
        local terrainDetailId = g_currentMission.terrainDetailId
        if fruitTypeGrowth.resetsSpray and minState <= self.defaultFruitsData[fruitName].maxSprayGrowthStage then
            setDensityMaskParams(fruit.id, "between", minState, self.defaultFruitsData[fruitName].maxSprayGrowthStage)
            local sprayResetResult = addDensityMaskedParallelogram(terrainDetailId, x, z, widthX, widthZ, heightX, heightZ, g_currentMission.sprayFirstChannel, g_currentMission.sprayNumChannels, fruit.id, 0, numFruitStateChannels, -1)
        end
    end
    setDensityMaskParams(fruit.id, "greater", -1) -- reset
end

--simulates growth and builds the canPlantData which is based on 'will the fruit grow in the next growth transition?'
function ssGrowthManager:buildCanPlantData(fruitData)
    for fruitName, value in pairs(fruitData) do
        if fruitName ~= "dryGrass" then
            local transitionTable = {}
            for transition,v in pairs(self.growthData) do
                if transition == self.FIRST_LOAD_TRANSITION then
                    break
                end

                if transition == 10 or transition == 11 or transition == 12 then --hack for winter planting
                    table.insert(transitionTable, transition , false)
                else
                    local plantedGrowthTransition = transition
                    local currentGrowthStage = 1

                    local maxAllowedCounter = 0
                    local transitionToCheck = plantedGrowthTransition + 1 -- need to start checking from the next transition after planted transition
                    local fruitNumStates = FruitUtil.fruitTypeGrowths[fruitName].numGrowthStates

                    while currentGrowthStage < fruitNumStates and maxAllowedCounter < self.MAX_ALLOWABLE_GROWTH_PERIOD do
                        if transitionToCheck > 12 then
                            transitionToCheck = 1
                        end

                        currentGrowthStage = self:simulateGrowth(fruitName, transitionToCheck, currentGrowthStage)
                        if currentGrowthStage >= fruitNumStates then -- have to break or transitionToCheck will be incremented when it does not have to be
                            break
                        end

                        transitionToCheck = transitionToCheck + 1
                        maxAllowedCounter = maxAllowedCounter + 1
                    end
                    if currentGrowthStage == fruitNumStates then
                        table.insert(transitionTable, plantedGrowthTransition , true)
                    else
                        table.insert(transitionTable, plantedGrowthTransition , false)
                    end
                end
            end
            self.canPlantData[fruitName] = transitionTable
        end
    end
end

-- simulates growth based on canPlantData to find out when a fruit will be harvestable
function ssGrowthManager:buildCanHarvestData()
    for fruitName, transition in pairs(self.canPlantData) do
        local transitionTable = {}
        local plantedGrowthTransition = 1
        local fruitNumStates = FruitUtil.fruitTypeGrowths[fruitName].numGrowthStates
        --log(fruitName)

        for plantedGrowthTransition = 1, self.MAX_ALLOWABLE_GROWTH_PERIOD do
             if self.canPlantData[fruitName][plantedGrowthTransition] == true and fruitName ~= "poplar" and fruitName ~= "grass" then
                local growthStage = 1
                local transitionToCheck = plantedGrowthTransition + 1
                if plantedGrowthTransition == self.MAX_ALLOWABLE_GROWTH_PERIOD then
                    transitionToCheck = 1
                end
                local safetyCheck = 1
                while growthStage <= fruitNumStates do
                    growthStage = self:simulateGrowth(fruitName, transitionToCheck, growthStage)
                    if growthStage == fruitNumStates then
                        --log("Inserting table for transition: " .. tostring(transitionToCheck-1))
                        transitionTable[transitionToCheck] = true
                        --print_r(transitionTable)
                    end
                    --log("plantedGrowthTransition: " .. plantedGrowthTransition  .. " fruitName: " .. fruitName .. " transitionToCheck: " .. transitionToCheck .. " growthStage: " .. growthStage .. " fruitNumStates" .. fruitNumStates)
                    transitionToCheck = transitionToCheck + 1
                    safetyCheck = safetyCheck + 1
                    if transitionToCheck > 12 then transitionToCheck = 1 end
                    if safetyCheck > self.self.MAX_ALLOWABLE_GROWTH_PERIOD then break end --so we don't end up in infinite loop if growth pattern is not correct
                end
                
            end
        end
        --fill in the gaps
        for plantedGrowthTransition = 1, self.MAX_ALLOWABLE_GROWTH_PERIOD do
            if fruitName == "poplar" then --hardcoding for poplar
                transitionTable[plantedGrowthTransition] = true
            elseif fruitName == "grass" and plantedGrowthTransition > ssEnvironment.TRANSITION_LATE_SPRING and plantedGrowthTransition < ssEnvironment.TRANSITION_EARLY_WINTER then
                transitionTable[plantedGrowthTransition] = true
            elseif transitionTable[plantedGrowthTransition] ~= true then
                transitionTable[plantedGrowthTransition] = false
            end
        end
        self.canHarvestData[fruitName] = transitionTable
    end
end

function ssGrowthManager:simulateGrowth(fruitName, transitionToCheck, currentGrowthStage)
    local newGrowthState = currentGrowthStage

    if self.growthData[transitionToCheck][fruitName] ~= nil then
        --setGrowthState
        if self.growthData[transitionToCheck][fruitName].setGrowthState ~= nil
            and self.growthData[transitionToCheck][fruitName].desiredGrowthState ~= nil then
            if self.growthData[transitionToCheck][fruitName].setGrowthMaxState ~= nil then
                if currentGrowthStage >= self.growthData[transitionToCheck][fruitName].setGrowthState and currentGrowthStage <= self.growthData[transitionToCheck][fruitName].setGrowthMaxState then
                    newGrowthState = self.growthData[transitionToCheck][fruitName].desiredGrowthState
                end
            else
                if currentGrowthStage == self.growthData[transitionToCheck][fruitName].setGrowthState then
                    newGrowthState = self.growthData[transitionToCheck][fruitName].desiredGrowthState
                end
            end
        end
        --increment by 1 for crops between normalGrowthState  normalGrowthMaxState or for crops at normalGrowthState
        if self.growthData[transitionToCheck][fruitName].normalGrowthState ~= nil then
            local normalGrowthState = self.growthData[transitionToCheck][fruitName].normalGrowthState
            if self.growthData[transitionToCheck][fruitName].normalGrowthMaxState ~= nil then
                local normalGrowthMaxState = self.growthData[transitionToCheck][fruitName].normalGrowthMaxState
                if currentGrowthStage >= normalGrowthState and currentGrowthStage <= normalGrowthMaxState then
                    newGrowthState = newGrowthState + 1
                end
            else
                if currentGrowthStage == normalGrowthState then
                    newGrowthState = newGrowthState + 1
                end
            end
        end
        --increment by extraGrowthFactor between extraGrowthMinState and extraGrowthMaxState
        if self.growthData[transitionToCheck][fruitName].extraGrowthMinState ~= nil
                and self.growthData[transitionToCheck][fruitName].extraGrowthMaxState ~= nil
                and self.growthData[transitionToCheck][fruitName].extraGrowthFactor ~= nil then
            local extraGrowthMinState = self.growthData[transitionToCheck][fruitName].extraGrowthMinState
            local extraGrowthMaxState = self.growthData[transitionToCheck][fruitName].extraGrowthMaxState

            if currentGrowthStage >= extraGrowthMinState and currentGrowthStage <= extraGrowthMaxState then
                newGrowthState = newGrowthState + self.growthData[transitionToCheck][fruitName].extraGrowthFactor
            end
        end
    end
    return newGrowthState
end

-- update all GM data for a custom unknown fruit
function ssGrowthManager:unknownFruitFound(fruitName)
    self:updateDefaultFruitsData(fruitName)
    self:updateGrowthData(fruitName)
    self:updateCanPlantData(fruitName)
    self:updateCanHarvestData(fruitName)
    self:updateWillGerminateData(fruitName)
end

function ssGrowthManager:updateCanPlantData(fruitName)
    self.canPlantData[fruitName] = Utils.copyTable(self.canPlantData[self.fruitNameToCopyForUnknownFruits])
end

function ssGrowthManager:updateCanHarvestData(fruitName)
    self.canHarvestData[fruitName] = Utils.copyTable(self.canHarvestData[self.fruitNameToCopyForUnknownFruits])
end

function ssGrowthManager:updateDefaultFruitsData(fruitName)
    self.defaultFruitsData[fruitName] = {}
    self.defaultFruitsData[fruitName].maxSprayGrowthStage = self.defaultFruitsData[self.fruitNameToCopyForUnknownFruits].maxSprayGrowthStage
end

function ssGrowthManager:updateGrowthData(fruitName)
    for growthTransition, fruit in pairs(self.growthData) do
        if self.growthData[growthTransition][self.fruitNameToCopyForUnknownFruits] ~= nil then
            self.growthData[growthTransition][fruitName] = Utils.copyTable(self.growthData[growthTransition][self.fruitNameToCopyForUnknownFruits])
            self.growthData[growthTransition][fruitName].fruitName = fruitName
        end
    end
end

function ssGrowthManager:updateWillGerminateData(fruitName)
    self.willGerminateData[fruitName] = self.willGerminateData[self.fruitNameToCopyForUnknownFruits]
end

-- growth gui functions

function ssGrowthManager:getCanPlantData()
    return self.canPlantData
end

function ssGrowthManager:canFruitBePlanted(fruitName, growthTransition)
    if self.canPlantData[fruitName][growthTransition] ~= nil then
        return self.canPlantData[fruitName][growthTransition]
    else
        return false
    end
end

function ssGrowthManager:getCanHarvestData()
    return self.canHarvestData
end

function ssGrowthManager:canFruitBeHarvested(fruitName, growthTransition)
    if self.canHarvestData[fruitName][growthTransition] ~= nil then
        return self.canHarvestData[fruitName][growthTransition]
    else
        return false
    end
end

-- debug console commands

function ssGrowthManager:consoleCommandIncrementGrowthStage()
    self.fakeGrowthTransitionNum = self.fakeGrowthTransitionNum + 1
    if self.fakeGrowthTransitionNum > 12 then self.fakeGrowthTransitionNum = 1 end
    logInfo("ssGrowthManager:", "enabled - growthStateChanged to: " .. self.fakeGrowthTransitionNum)
    self.currentGrowthTransitionPeriod = self.fakeGrowthTransitionNum
    ssDensityMapScanner:queueJob("ssGrowthManagerHandleGrowth", 1)
    self:rebuildWillGerminateData()
end

function ssGrowthManager:consoleCommandSetGrowthStage(newGrowthStage)
    self.fakeGrowthTransitionNum = Utils.getNoNil(tonumber(newGrowthStage), 1)
    logInfo("ssGrowthManager:", "enabled - growthStateChanged to: " .. self.fakeGrowthTransitionNum)
    self.currentGrowthTransitionPeriod = self.fakeGrowthTransitionNum
    ssDensityMapScanner:queueJob("ssGrowthManagerHandleGrowth", 1)
    self:rebuildWillGerminateData()
end

function ssGrowthManager:consoleCommandTestStuff()
    -- logInfo("ssGrowthManager: canPlantData")
    -- print_r(self.canPlantData)
    -- -- logInfo("ssGrowthManager: willGerminateData")
    -- -- print_r(self.willGerminateData)
    -- self:buildCanHarvestData()
    -- logInfo("ssGrowthManager: canHarvestData")
    -- print_r(self.canHarvestData)
    --print_r(self.defaultFruitsData)
    self:unknownFruitFound("whatever")
    

end
