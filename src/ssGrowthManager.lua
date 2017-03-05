---------------------------------------------------------------------------------------------------------
-- GROWTH MANAGER SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  to manage growth as the season changes
-- Authors:  theSeb
-- Credits: Inspired by upsidedown's growth manager mod

ssGrowthManager = {}
g_seasons.growthManager = ssGrowthManager

-- constants
ssGrowthManager.MAX_STATE = 99 -- needs to be set to the fruit's numGrowthStates if you are setting, or numGrowthStates-1 if you're incrementing
ssGrowthManager.CUT = 200
ssGrowthManager.WITHERED = 300
ssGrowthManager.FIRST_LOAD_TRANSITION = 999
ssGrowthManager.FIRST_GROWTH_TRANSITION = 1
ssGrowthManager.fruitNameToCopyForUnknownFruits = "barley"
-- data
ssGrowthManager.defaultFruitsData = {}
ssGrowthManager.growthData = {}
ssGrowthManager.canPlantData = {}
ssGrowthManager.willGerminateData = {}

-- properties 
ssGrowthManager.currentGrowthTransitionPeriod = nil
ssGrowthManager.doResetGrowth = false


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
        log("fruitKey: " .. fruitKey)
        setXMLString(savegame, fruitKey .. "#fruitName", tostring(fruitName))
        setXMLBool(savegame, fruitKey .. "#value", self.willGerminateData[fruitName])
        i = i+1
    end
end

function ssGrowthManager:loadMap(name)
    if self.growthManagerEnabled == false then
        logInfo("ssGrowthManager: disabled")
        return
    end

    --lock changing the growth speed option and set growth rate to 1 (no growth)
    g_currentMission:setPlantGrowthRate(1,nil)
    g_currentMission:setPlantGrowthRateLocked(true)

    if g_currentMission:getIsServer() == true then
       if self:getGrowthData() == false then
            logInfo("ssGrowthManager: required data not loaded. ssGrowthManager disabled")
            return
        end

        g_currentMission.environment:addDayChangeListener(self)
        g_seasons.environment:addGrowthStageChangeListener(self)
        
        ssDensityMapScanner:registerCallback("ssGrowthManagerHandleGrowth", self, self.handleGrowth)

        self:buildCanPlantData(self.defaultFruitsData)
        addConsoleCommand("ssResetGrowth", "Resets growth back to default starting stage", "consoleCommandResetGrowth", self);
        self:dayChanged()
    end
end


function ssGrowthManager:getGrowthData()
    local defaultFruitsData,growthData = ssGrowthManagerData:loadAllData()

    if defaultFruitsData ~= nil then
        self.defaultFruitsData = Set(defaultFruitsData)
    else
        logInfo("ssGrowthManager: default fruits data not found")
        return false
    end

    if growthData ~= nil then
        self.growthData = growthData
    else
        logInfo("ssGrowthManager: default growth data not found")
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
        logInfo("ssGrowthManager: Growth reset")
    end
end

--handle growthStageCHanged event
function ssGrowthManager:growthStageChanged()
    if self.growthManagerEnabled then
        local growthTransition = g_seasons.environment:growthTransitionAtDay()

        if self.isNewSavegame and growthTransition == 1 then
            self.currentGrowthTransitionPeriod = self.FIRST_LOAD_TRANSITION
            logInfo("ssGrowthManager: First time growth reset - this will only happen once in a new savegame")
            self.isNewSavegame = false
             ssDensityMapScanner:queueJob("ssGrowthManagerHandleGrowth", 1)
        else
            log("GrowthManager enabled - growthStateChanged to: " .. growthTransition)
            self.currentGrowthTransitionPeriod = growthTransition
            ssDensityMapScanner:queueJob("ssGrowthManagerHandleGrowth", 1)
            self:rebuildWillGerminateData()
        end
        
    end
end

-- reset the willGerminateData and rebuild it based on the current transition
-- called just after growthStageChanged
function ssGrowthManager:rebuildWillGerminateData()
    self.willGerminateData = {}
    self:dayChanged()    
end

-- handle dayChanged event 
-- check if canSow and update willGerminateData accordingly
function ssGrowthManager:dayChanged()
    for fruitName, growthTransition in pairs(self.canPlantData) do
        if self.canPlantData[fruitName][g_seasons.environment:growthTransitionAtDay()] == true then
            self.willGerminateData[fruitName] = ssWeatherManager:canSow(fruitName)
            --log("fruitName: " .. fruitName .. "canSow: " .. tostring(ssWeatherManager:canSow(fruitName)))
        end
    end
    --print_r(self.canPlantData)
    --log("Printing willGerminateData")
    --print_r(self.willGerminateData)
end

function ssGrowthManager:handleGrowth(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, layers)
    local x,z, widthX,widthZ, heightX,heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

    for index,fruit in pairs(g_currentMission.fruits) do
        local fruitName = FruitUtil.fruitIndexToDesc[index].name

        --handling new unknown fruits
        if self.defaultFruitsData[fruitName] == nil then
            log("Fruit not found in default table: " .. fruitName)
            fruitName = self.fruitNameToCopyForUnknownFruits
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

    local numChannels = g_currentMission.numFruitStateChannels
    local sum = setDensityMaskedParallelogram(fruit.id, x, z, widthX, widthZ, heightX, heightZ, 0, numChannels, fruit.id, 0, numChannels, desiredGrowthState)
    
end

--increment by 1 for crops between normalGrowthState  normalGrowthMaxState or for crops at normalGrowthState
function ssGrowthManager:incrementGrowthState(fruit, fruitName, x, z, widthX, widthZ, heightX, heightZ)
    local minState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].normalGrowthState
    if minState == 1 and self.willGerminateData[fruitName] == false then --check if the fruit has just been planted and delay growth if germination temp not reached
        return
    end

    if self.growthData[self.currentGrowthTransitionPeriod][fruitName].normalGrowthMaxState ~= nil then
        local fruitTypeGrowth = FruitUtil.fruitTypeGrowths[fruitName]
        local maxState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].normalGrowthMaxState

        if maxState == self.MAX_STATE then
            maxState = fruitTypeGrowth.numGrowthStates-1
        end
        setDensityMaskParams(fruit.id, "between", minState, maxState)
    else
        setDensityMaskParams(fruit.id, "equals", minState)
    end

    local numChannels = g_currentMission.numFruitStateChannels
    local sum = addDensityMaskedParallelogram(fruit.id,x,z, widthX,widthZ, heightX,heightZ, 0, numChannels, fruit.id, 0, numChannels, 1)
end

--increment by extraGrowthFactor between extraGrowthMinState and extraGrowthMaxState
function ssGrowthManager:incrementExtraGrowthState(fruit, fruitName, x, z, widthX, widthZ, heightX, heightZ)
    local minState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].extraGrowthMinState
    local maxState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].extraGrowthMaxState
    setDensityMaskParams(fruit.id, "between", minState, maxState)

    local extraGrowthFactor = self.growthData[self.currentGrowthTransitionPeriod][fruitName].extraGrowthFactor
    local numChannels = g_currentMission.numFruitStateChannels
    local sum = addDensityMaskedParallelogram(fruit.id,x,z, widthX,widthZ, heightX,heightZ, 0, numChannels, fruit.id, 0, numChannels, extraGrowthFactor)
end

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
                    local plantedGrowthTransition =  transition
                    local currentGrowthStage = 1
                    local MAX_ALLOWABLE_GROWTH_PERIOD = 12 -- max growth for any fruit = 1 year
                    local maxAllowedCounter = 0
                    local transitionToCheck = plantedGrowthTransition + 1 -- need to start checking from the next transition after planted transition
                    local fruitNumStates = FruitUtil.fruitTypeGrowths[fruitName].numGrowthStates

                    while currentGrowthStage < fruitNumStates and maxAllowedCounter < MAX_ALLOWABLE_GROWTH_PERIOD do
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

function ssGrowthManager:simulateGrowth(fruitName, transitionToCheck, currentGrowthStage)
    local newGrowthState = currentGrowthStage
    --log("ssGrowthManager:canPlant transitionToCheck: " .. transitionToCheck .. " fruitName: " .. fruitName .. " currentGrowthStage: " .. currentGrowthStage)

    if self.growthData[transitionToCheck][fruitName] ~= nil then
        --setGrowthState
        if self.growthData[transitionToCheck][fruitName].setGrowthState ~= nil
            and self.growthData[transitionToCheck][fruitName].desiredGrowthState ~= nil then
            if currentGrowthStage == self.growthData[transitionToCheck][fruitName].setGrowthState then
                newGrowthState = self.growthData[transitionToCheck][fruitName].desiredGrowthState
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

function ssGrowthManager:unknownFruitFound(fruitName)
    self:updateDefaultFruitsData(fruitName)
    self:updateGrowthData(fruitName)
    self:updateCanPlantData(fruitName)
    self:updateWillGerminateData(fruitName)
end

function ssGrowthManager:updateDefaultFruitsData(fruitName)
    log("ssGrowthManager:updateDefaultFruitsData(fruitName) before")
    print_r(self.defaultFruitsData)

    --add fruit to default fruits
    table.insert(self.defaultFruitsData,fruitName)
    log("ssGrowthManager:updateDefaultFruitsData(fruitName) after")
    print_r(self.defaultFruitsData)
end

function ssGrowthManager:updateCanPlantData(fruitName)
    log("ssGrowthManager:updateCanPlantData(fruitName) before")
    print_r(self.canPlantData)
    --copy barley values for index fruitName
    table.insert(self.canPlantData,self.canPlantData[self.fruitNameToCopyForUnknownFruits], fruitName)
    log("ssGrowthManager:updateCanPlantData(fruitName) after")
    print_r(self.canPlantData)
    
end

function ssGrowthManager:updateGrowthData(fruitName)
    log("ssGrowthManager:updateGrowthData(fruitName)")
    print_r(self.growthData)
    --copy barley values for index fruitName
end

function ssGrowthManager:updateWillGerminateData(fruitName)
    log("ssGrowthManager:updateWillGerminateData(fruitName) before")
    print_r(self.willGerminateData)
    --copy barley values for index fruitName
    self.willGerminateData[fruitName] = self.willGerminate[self.fruitNameToCopyForUnknownFruits]
    log("ssGrowthManager:updateWillGerminateData(fruitName) after")
    print_r(self.willGerminateData)
end

function ssGrowthManager:keyEvent(unicode, sym, modifier, isDown)
    if (unicode == 47) then
        self:unknownFruitFound("newFruitTest")
    end
end
