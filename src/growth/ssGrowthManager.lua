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
ssGrowthManager.MAX_STATE = 99 -- needs to be set to the fruit's numGrowthStates if you are setting, or numGrowthStates - 1 if you're incrementing
ssGrowthManager.CUT = 200
ssGrowthManager.WITHERED = 300
ssGrowthManager.FIRST_LOAD_TRANSITION = 999
ssGrowthManager.fruitNameToCopyForUnknownFruits = "barley"
ssGrowthManager.MAX_ALLOWABLE_GROWTH_PERIOD = 12 -- max growth for any fruit = 1 year

-- data
ssGrowthManager.defaultFruitsData = {}
ssGrowthManager.growthData = {}
ssGrowthManager.canPlantData = {}
ssGrowthManager.canHarvestData = {}
ssGrowthManager.willGerminateData = {}
ssGrowthManager.previousWillGerminateData = {}

-- properties
ssGrowthManager.fakeTransition = 1
ssGrowthManager.additionalFruitsChecked = false

function ssGrowthManager:load(savegame, key)
    self.isNewSavegame = savegame == nil

    self.growthManagerEnabled = ssXMLUtil.getBool(savegame, key .. ".settings.growthManagerEnabled", true)

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
    ssXMLUtil.setBool(savegame, key .. ".settings.growthManagerEnabled", self.growthManagerEnabled)

    local i = 0
    for fruitName in pairs(self.willGerminateData) do
        local fruitKey = string.format("%s.growthManager.willGerminate.fruit(%i)", key, i)

        setXMLString(savegame, fruitKey .. "#fruitName", tostring(fruitName))
        setXMLBool(savegame, fruitKey .. "#value", self.willGerminateData[fruitName])

        i = i + 1
    end
end

function ssGrowthManager:loadMap(name)
    if self.growthManagerEnabled == false then
        logInfo("ssGrowthManager:", "disabled")
        return
    end

    --lock changing the growth speed option and set growth rate to 1 (no growth)
    g_currentMission:setPlantGrowthRate(1, nil)
    g_currentMission:setPlantGrowthRateLocked(true)

    if not self:getGrowthData() then
        logInfo("ssGrowthManager:" , "required data not loaded. ssGrowthManager disabled")
        return
    end

    self:buildCanPlantData(self.defaultFruitsData)
    self:buildCanHarvestData()

    if g_currentMission:getIsServer() then
        g_currentMission.environment:addDayChangeListener(self)
        g_seasons.environment:addTransitionChangeListener(self)

        ssDensityMapScanner:registerCallback("ssGrowthManagerHandleGrowth", self, self.handleGrowth)

        addConsoleCommand("ssResetGrowth", "Resets growth back to default starting state", "consoleCommandResetGrowth", self)
        addConsoleCommand("ssIncrementGrowth", "Increments growth for test purposes", "consoleCommandIncrementGrowthState", self)
        addConsoleCommand("ssSetGrowthState", "Sets growth for test purposes", "consoleCommandSetGrowthState", self)
        --addConsoleCommand("ssTestStuff", "Tests stuff", "consoleCommandTestStuff", self)
        self:dayChanged()
    end
end


-- load all growth data
-- returns false, if error
function ssGrowthManager:getGrowthData()
    local defaultFruitsData, growthData = ssGrowthManagerData:loadAllData()

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

--handle reset growth console command
function ssGrowthManager:consoleCommandResetGrowth()
    if g_currentMission:getIsServer() then
        self:resetGrowth()
    end
end

--reset growth to first_load_transition for all fields
function ssGrowthManager:resetGrowth()
    if self.growthManagerEnabled == true then
        ssDensityMapScanner:queueJob("ssGrowthManagerHandleGrowth", self.FIRST_LOAD_TRANSITION)
        logInfo("ssGrowthManager:", "Growth reset")
    end
end

--handle transitionChanged event
function ssGrowthManager:transitionChanged()
    if self.growthManagerEnabled == false then return end

    local transition = g_seasons.environment:transitionAtDay()

    if self.isNewSavegame and transition == g_seasons.environment.TRANSITION_EARLY_SPRING then
        logInfo("ssGrowthManager:", "First time growth reset - this will only happen once in a new savegame")
        self.isNewSavegame = false
        ssDensityMapScanner:queueJob("ssGrowthManagerHandleGrowth", self.FIRST_LOAD_TRANSITION)
    else
        log("GrowthManager enabled - transition changed to: " .. transition)
        ssDensityMapScanner:queueJob("ssGrowthManagerHandleGrowth", transition)
    end
end

function ssGrowthManager:update(dt)
    if self.additionalFruitsChecked == true or self.growthManagerEnabled == false then return end

    self.additionalFruitsChecked = true
    for index, fruit in pairs(g_currentMission.fruits) do
        local fruitName = FruitUtil.fruitIndexToDesc[index].name
        --handling new unknown fruits
        if self.defaultFruitsData[fruitName] == nil then
            log("ssGrowthManager:update: Fruit not found in default table: " .. fruitName)
            self:unknownFruitFound(fruitName)
        end
    end

end

-- reset the willGerminateData and rebuild it based on the current transition
function ssGrowthManager:rebuildWillGerminateData()
    self.willGerminateData = {}

    for fruitName, transition in pairs(self.canPlantData) do
        if self.canPlantData[fruitName][g_seasons.environment:transitionAtDay()] == true then
            self.willGerminateData[fruitName] = ssWeatherManager:canSow(fruitName)
        end
    end
end

-- handle dayChanged event
-- check if canSow and update willGerminate accordingly
function ssGrowthManager:dayChanged()
    if self.isNewSavegame == true then
        self:rebuildWillGerminateData()
        self.previousWillGerminateData = Utils.copyTable(self.willGerminateData)
    else
        self.previousWillGerminateData = Utils.copyTable(self.willGerminateData)
        self:rebuildWillGerminateData()
    end
end

-- called by ssDensityScanner to make fruit grow
function ssGrowthManager:handleGrowth(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, transition)
    local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    transition = tonumber(transition)

    for index, fruit in pairs(g_currentMission.fruits) do
        local fruitName = FruitUtil.fruitIndexToDesc[index].name

        if self.growthData[transition][fruitName] ~= nil then
            --set growth state
            if self.growthData[transition][fruitName].setGrowthState ~= nil
                and self.growthData[transition][fruitName].desiredGrowthState ~= nil then
                    --log("FruitID " .. fruit.id .. " FruitName: " .. fruitName .. " - reset growth at season transition: " .. transition .. " between growth states " .. self.growthData[transition][fruitName].setGrowthState .. " and " .. self.growthData[transition][fruitName].setGrowthMaxState .. " to growth state: " .. self.growthData[transition][fruitName].setGrowthState)
                self:setGrowthState(fruit, fruitName, x, z, widthX, widthZ, heightX, heightZ, transition)
            end
            --increment by 1 for crops between normalGrowthState  normalGrowthMaxState or for crops at normalGrowthState
            if self.growthData[transition][fruitName].normalGrowthState ~= nil then
                self:incrementGrowthState(fruit, fruitName, x, z, widthX, widthZ, heightX, heightZ, transition)
            end
            --increment by extraGrowthFactor between extraGrowthMinState and extraGrowthMaxState
            if self.growthData[transition][fruitName].extraGrowthMinState ~= nil
                    and self.growthData[transition][fruitName].extraGrowthMaxState ~= nil
                    and self.growthData[transition][fruitName].extraGrowthFactor ~= nil then
                self:incrementExtraGrowthState(fruit, fruitName, x, z, widthX, widthZ, heightX, heightZ, transition)
            end
        end  -- end of if self.growthData[transition][fruitName] ~= nil then
    end  -- end of for index, fruit in pairs(g_currentMission.fruits) do
end

--set growth state of fruit to a particular state based on transition
function ssGrowthManager:setGrowthState(fruit, fruitName, x, z, widthX, widthZ, heightX, heightZ, transition)
    local minState = self.growthData[transition][fruitName].setGrowthState
    local desiredGrowthState = self.growthData[transition][fruitName].desiredGrowthState
    local fruitTypeGrowth = FruitUtil.fruitTypeGrowths[fruitName]

    if desiredGrowthState == self.WITHERED then
        desiredGrowthState = fruitTypeGrowth.witheringNumGrowthStates
    elseif desiredGrowthState == self.CUT then
        desiredGrowthState = FruitUtil.fruitTypes[fruitName].cutState + 1
    end

    if self.growthData[transition][fruitName].setGrowthMaxState ~= nil then --if maxState exists
        local maxState = self.growthData[transition][fruitName].setGrowthMaxState

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
function ssGrowthManager:incrementGrowthState(fruit, fruitName, x, z, widthX, widthZ, heightX, heightZ, transition)
    local useMaxState = false
    local minState = self.growthData[transition][fruitName].normalGrowthState
    if minState == 1 and self.previousWillGerminateData[fruitName] == false then --check if the fruit has just been planted and delay growth if germination temp not reached
        return
    end

    local fruitTypeGrowth = FruitUtil.fruitTypeGrowths[fruitName]

    if self.growthData[transition][fruitName].normalGrowthMaxState ~= nil then

        local maxState = self.growthData[transition][fruitName].normalGrowthMaxState

        if maxState == self.MAX_STATE then
            maxState = fruitTypeGrowth.numGrowthStates - 1
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
        if fruitTypeGrowth.resetsSpray and minState <= self.defaultFruitsData[fruitName].maxSprayGrowthState then
            if useMaxState == true then
                setDensityMaskParams(fruit.id, "between", minState, self.defaultFruitsData[fruitName].maxSprayGrowthState)
            end
            local sprayResetResult = setDensityMaskedParallelogram(terrainDetailId, x, z, widthX, widthZ, heightX, heightZ, g_currentMission.sprayFirstChannel, g_currentMission.sprayNumChannels, fruit.id, 0, numFruitStateChannels, 0)
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
function ssGrowthManager:incrementExtraGrowthState(fruit, fruitName, x, z, widthX, widthZ, heightX, heightZ, transition)
    local minState = self.growthData[transition][fruitName].extraGrowthMinState
    local maxState = self.growthData[transition][fruitName].extraGrowthMaxState
    setDensityMaskParams(fruit.id, "between", minState, maxState) --because we always expect min and max with an incrementExtraGrowthState command

    local extraGrowthFactor = self.growthData[transition][fruitName].extraGrowthFactor
    local numFruitStateChannels = g_currentMission.numFruitStateChannels
    local growthResult = addDensityMaskedParallelogram(fruit.id, x, z, widthX, widthZ, heightX, heightZ, 0, numFruitStateChannels, fruit.id, 0, numFruitStateChannels, extraGrowthFactor)

    if growthResult ~= 0 then
        local fruitTypeGrowth = FruitUtil.fruitTypeGrowths[fruitName]
        local terrainDetailId = g_currentMission.terrainDetailId
        if fruitTypeGrowth.resetsSpray and minState <= self.defaultFruitsData[fruitName].maxSprayGrowthState then
            setDensityMaskParams(fruit.id, "between", minState, self.defaultFruitsData[fruitName].maxSprayGrowthState)
            local sprayResetResult = setDensityMaskedParallelogram(terrainDetailId, x, z, widthX, widthZ, heightX, heightZ, g_currentMission.sprayFirstChannel, g_currentMission.sprayNumChannels, fruit.id, 0, numFruitStateChannels, 0)
        end
    end
    setDensityMaskParams(fruit.id, "greater", -1) -- reset
end

--simulates growth and builds the canPlantData which is based on 'will the fruit grow in the next growth transition?'
function ssGrowthManager:buildCanPlantData(fruitData)
    for fruitName, value in pairs(fruitData) do
        if fruitName ~= "dryGrass" then
            local transitionTable = {}
            for transition, v in pairs(self.growthData) do
                if transition == self.FIRST_LOAD_TRANSITION then
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

                        currentGrowthState = self:simulateGrowth(fruitName, transitionToCheck, currentGrowthState)
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
function ssGrowthManager:buildCanHarvestData()
    for fruitName, transition in pairs(self.canPlantData) do
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
                    growthState = self:simulateGrowth(fruitName, transitionToCheck, growthState)
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

-- simulate growth helper function to calculate the next growth state based on current growth state and the current transition
function ssGrowthManager:simulateGrowth(fruitName, transitionToCheck, currentGrowthState)
    local newGrowthState = currentGrowthState

    if self.growthData[transitionToCheck][fruitName] ~= nil then
        --setGrowthState
        if self.growthData[transitionToCheck][fruitName].setGrowthState ~= nil
            and self.growthData[transitionToCheck][fruitName].desiredGrowthState ~= nil then
            if self.growthData[transitionToCheck][fruitName].setGrowthMaxState ~= nil then
                if currentGrowthState >= self.growthData[transitionToCheck][fruitName].setGrowthState and currentGrowthState <= self.growthData[transitionToCheck][fruitName].setGrowthMaxState then
                    newGrowthState = self.growthData[transitionToCheck][fruitName].desiredGrowthState
                end
            else
                if currentGrowthState == self.growthData[transitionToCheck][fruitName].setGrowthState then
                    newGrowthState = self.growthData[transitionToCheck][fruitName].desiredGrowthState
                end
            end
        end
        --increment by 1 for crops between normalGrowthState  normalGrowthMaxState or for crops at normalGrowthState
        if self.growthData[transitionToCheck][fruitName].normalGrowthState ~= nil then
            local normalGrowthState = self.growthData[transitionToCheck][fruitName].normalGrowthState
            if self.growthData[transitionToCheck][fruitName].normalGrowthMaxState ~= nil then
                local normalGrowthMaxState = self.growthData[transitionToCheck][fruitName].normalGrowthMaxState
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
        if self.growthData[transitionToCheck][fruitName].extraGrowthMinState ~= nil
                and self.growthData[transitionToCheck][fruitName].extraGrowthMaxState ~= nil
                and self.growthData[transitionToCheck][fruitName].extraGrowthFactor ~= nil then
            local extraGrowthMinState = self.growthData[transitionToCheck][fruitName].extraGrowthMinState
            local extraGrowthMaxState = self.growthData[transitionToCheck][fruitName].extraGrowthMaxState

            if currentGrowthState >= extraGrowthMinState and currentGrowthState <= extraGrowthMaxState then
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
    self.defaultFruitsData[fruitName].maxSprayGrowthState = self.defaultFruitsData[self.fruitNameToCopyForUnknownFruits].maxSprayGrowthState
end

function ssGrowthManager:updateGrowthData(fruitName)
    for transition, fruit in pairs(self.growthData) do
        if self.growthData[transition][self.fruitNameToCopyForUnknownFruits] ~= nil then
            self.growthData[transition][fruitName] = Utils.copyTable(self.growthData[transition][self.fruitNameToCopyForUnknownFruits])
            self.growthData[transition][fruitName].fruitName = fruitName
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

function ssGrowthManager:canFruitBePlanted(fruitName, transition)
    if self.canPlantData[fruitName][transition] ~= nil then
        return self.canPlantData[fruitName][transition]
    else
        return false
    end
end

function ssGrowthManager:getCanHarvestData()
    return self.canHarvestData
end

function ssGrowthManager:canFruitBeHarvested(fruitName, transition)
    if self.canHarvestData[fruitName][transition] ~= nil then
        return self.canHarvestData[fruitName][transition]
    else
        return false
    end
end

-- debug console commands

function ssGrowthManager:consoleCommandIncrementGrowthState()
    self.fakeTransition = self.fakeTransition + 1
    if self.fakeTransition > g_seasons.environment.TRANSITIONS_IN_YEAR then self.fakeTransition = 1 end
    logInfo("ssGrowthManager:", "enabled - growthStateChanged to: " .. self.fakeTransition)
    ssDensityMapScanner:queueJob("ssGrowthManagerHandleGrowth", self.fakeTransition)
    self:rebuildWillGerminateData()
end

function ssGrowthManager:consoleCommandSetGrowthState(newGrowthState)
    self.fakeTransition = Utils.getNoNil(tonumber(newGrowthState), 1)
    logInfo("ssGrowthManager:", "enabled - growthStateChanged to: " .. self.fakeTransition)
    ssDensityMapScanner:queueJob("ssGrowthManagerHandleGrowth", self.fakeTransition)
    self:rebuildWillGerminateData()
end

function ssGrowthManager:consoleCommandTestStuff()
    --put stuff to test in here
end
