---------------------------------------------------------------------------------------------------------
-- GROWTH MANAGER SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  to manage growth as the season changes
-- Authors:  theSeb
-- Credits: Inspired by upsidedown's growth manager mod

ssGrowthManager = {}
g_seasons.growthManager = ssGrowthManager

ssGrowthManager.MAX_STATE = 99 -- needs to be set to the fruit's numGrowthStates if you are setting, or numGrowthStates-1 if you're incrementing
ssGrowthManager.WITHERED = 300
ssGrowthManager.CUT = 200
ssGrowthManager.FIRST_LOAD_TRANSITION = 999
ssGrowthManager.FIRST_GROWTH_TRANSITION = 1
ssGrowthManager.TRUE = "true"
ssGrowthManager.FALSE = "false"
ssGrowthManager.MAYBE = "maybe"

ssGrowthManager.defaultFruits = {}
ssGrowthManager.growthData = {}
ssGrowthManager.currentGrowthTransitionPeriod = nil
ssGrowthManager.doResetGrowth = false

ssGrowthManager.canPlantData = {}

function ssGrowthManager:load(savegame, key)
    self.isNewSavegame = savegame == nil

    self.growthManagerEnabled = ssStorage.getXMLBool(savegame, key .. ".settings.growthManagerEnabled", true)
end

function ssGrowthManager:save(savegame, key)
    if g_currentMission:getIsServer() == true then
        ssStorage.setXMLBool(savegame, key .. ".settings.growthManagerEnabled", self.growthManagerEnabled)
    end
end

function ssGrowthManager:loadMap(name)
    if self.growthManagerEnabled == false then
        log("ssGrowthManager: disabled")
        return
    end

    if g_currentMission:getIsServer() == true then
       if self:getGrowthData() == false then
            log("ssGrowthManager: required data not loaded. ssGrowthManager disabled")
            return
        end

        --lock changing the growth speed option and set growth rate to 1 (no growth)
        g_currentMission:setPlantGrowthRate(1,nil)
        g_currentMission:setPlantGrowthRateLocked(true)

        g_seasons.environment:addGrowthStageChangeListener(self)

        ssDensityMapScanner:registerCallback("ssGrowthManagerHandleGrowth", self, self.handleGrowth)

        self:buildCanPlantData()
        addConsoleCommand("ssResetGrowth", "Resets growth back to default starting stage", "consoleCommandResetGrowth", self);

        -- log("monthAtDay 1: " .. tostring(g_seasons.environment:monthAtDay(1)))
        -- log("monthAtDay 2: " .. tostring(g_seasons.environment:monthAtDay(2)))
        -- log("monthAtDay 3: " .. tostring(g_seasons.environment:monthAtDay(3)))
        -- log("monthAtDay 4: " .. tostring(g_seasons.environment:monthAtDay(4)))
        -- log("monthAtDay 5: " .. tostring(g_seasons.environment:monthAtDay(5)))
        -- log("monthAtDay 6: " .. tostring(g_seasons.environment:monthAtDay(6)))
        -- log("monthAtDay 7: " .. tostring(g_seasons.environment:monthAtDay(7)))
        -- log("monthAtDay 8: " .. tostring(g_seasons.environment:monthAtDay(8)))
        -- log("monthAtDay 9: " .. tostring(g_seasons.environment:monthAtDay(9)))
        -- log("monthAtDay 10: " .. tostring(g_seasons.environment:monthAtDay(10)))
        -- log("monthAtDay 11: " .. tostring(g_seasons.environment:monthAtDay(11)))
        -- log("monthAtDay 12: " .. tostring(g_seasons.environment:monthAtDay(12)))

        -- log("monthAtGrowthTransitionNumber 1: " .. tostring(g_seasons.environment:monthAtGrowthTransitionNumber(1)))
        -- log("monthAtGrowthTransitionNumber 2: " .. tostring(g_seasons.environment:monthAtGrowthTransitionNumber(2)))
        -- log("monthAtGrowthTransitionNumber 3: " .. tostring(g_seasons.environment:monthAtGrowthTransitionNumber(3)))
        -- log("monthAtGrowthTransitionNumber 4: " .. tostring(g_seasons.environment:monthAtGrowthTransitionNumber(4)))
        -- log("monthAtGrowthTransitionNumber 5: " .. tostring(g_seasons.environment:monthAtGrowthTransitionNumber(5)))
        -- log("monthAtGrowthTransitionNumber 6: " .. tostring(g_seasons.environment:monthAtGrowthTransitionNumber(6)))
        -- log("monthAtGrowthTransitionNumber 7: " .. tostring(g_seasons.environment:monthAtGrowthTransitionNumber(7)))
        -- log("monthAtGrowthTransitionNumber 8: " .. tostring(g_seasons.environment:monthAtGrowthTransitionNumber(8)))
        -- log("monthAtGrowthTransitionNumber 9: " .. tostring(g_seasons.environment:monthAtGrowthTransitionNumber(9)))
        -- log("monthAtGrowthTransitionNumber 10: " .. tostring(g_seasons.environment:monthAtGrowthTransitionNumber(10)))
        -- log("monthAtGrowthTransitionNumber 11: " .. tostring(g_seasons.environment:monthAtGrowthTransitionNumber(11)))
        -- log("monthAtGrowthTransitionNumber 12: " .. tostring(g_seasons.environment:monthAtGrowthTransitionNumber(12)))

        -- log("monthNameShort 1: " .. ssUtil.monthNameShort(1))
        -- log("monthNameShort 2: " .. ssUtil.monthNameShort(2))
        -- log("monthNameShort 3: " .. ssUtil.monthNameShort(3))
        -- log("monthNameShort 4: " .. ssUtil.monthNameShort(4))
        -- log("monthNameShort 5: " .. ssUtil.monthNameShort(5))
        -- log("monthNameShort 6: " .. ssUtil.monthNameShort(6))
        -- log("monthNameShort 7: " .. ssUtil.monthNameShort(7))
        -- log("monthNameShort 8: " .. ssUtil.monthNameShort(8))
        -- log("monthNameShort 9: " .. ssUtil.monthNameShort(9))
        -- log("monthNameShort 10: " .. ssUtil.monthNameShort(10))
        -- log("monthNameShort 11: " .. ssUtil.monthNameShort(11))
        -- log("monthNameShort 12: " .. ssUtil.monthNameShort(12))

        -- log("season 1: " .. tostring(g_seasons.environment:seasonAtDay(1)))
        -- log("season 2: " .. tostring(g_seasons.environment:seasonAtDay(2)))
        -- log("season 3: " .. tostring(g_seasons.environment:seasonAtDay(3)))
        -- log("season 4: " .. tostring(g_seasons.environment:seasonAtDay(4)))
        -- log("season 5: " .. tostring(g_seasons.environment:seasonAtDay(5)))
        -- log("season 6: " .. tostring(g_seasons.environment:seasonAtDay(6)))
        -- log("season 7: " .. tostring(g_seasons.environment:seasonAtDay(7)))
        -- log("season 8: " .. tostring(g_seasons.environment:seasonAtDay(8)))
        -- log("season 9: " .. tostring(g_seasons.environment:seasonAtDay(9)))
        -- log("season 10: " .. tostring(g_seasons.environment:seasonAtDay(10)))
        -- log("season 11: " .. tostring(g_seasons.environment:seasonAtDay(11)))
        -- log("season 12: " .. tostring(g_seasons.environment:seasonAtDay(12)))

        -- log("gt 1: " .. tostring(g_seasons.environment:growthTransitionAtDay(1)))
        -- log("gt 2: " .. tostring(g_seasons.environment:growthTransitionAtDay(2)))
        -- log("gt 3: " .. tostring(g_seasons.environment:growthTransitionAtDay(3)))
        -- log("gt 4: " .. tostring(g_seasons.environment:growthTransitionAtDay(4)))
        -- log("gt 5: " .. tostring(g_seasons.environment:growthTransitionAtDay(5)))
        -- log("gt 6: " .. tostring(g_seasons.environment:growthTransitionAtDay(6)))
        -- log("gt 7: " .. tostring(g_seasons.environment:growthTransitionAtDay(7)))
        -- log("gt 8: " .. tostring(g_seasons.environment:growthTransitionAtDay(8)))
        -- log("gt 9: " .. tostring(g_seasons.environment:growthTransitionAtDay(9)))
        -- log("gt 10: " .. tostring(g_seasons.environment:growthTransitionAtDay(10)))
        -- log("gt 11: " .. tostring(g_seasons.environment:growthTransitionAtDay(11)))
        -- log("gt 12: " .. tostring(g_seasons.environment:growthTransitionAtDay(12)))
    end
end


function ssGrowthManager:getGrowthData()
    local defaultFruits,growthData = ssGrowthManagerData:loadAllData()

    if defaultFruits ~= nil then
        self.defaultFruits = Set(defaultFruits)
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


function ssGrowthManager:handleGrowth(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, layers)
    local x,z, widthX,widthZ, heightX,heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

    for index,fruit in pairs(g_currentMission.fruits) do
        local fruitName = FruitUtil.fruitIndexToDesc[index].name

        --handling new unknown fruits
        if self.defaultFruits[fruitName] == nil then
            log("Fruit not found in default table: " .. fruitName)
            fruitName = "barley"
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

function ssGrowthManager:consoleCommandResetGrowth()
    if g_currentMission:getIsServer() then
        self:resetGrowth()
    end
end

function ssGrowthManager:resetGrowth()
    if self.growthManagerEnabled == true then
        self.currentGrowthTransitionPeriod = self.FIRST_LOAD_TRANSITION
        ssDensityMapScanner:queuJob("ssGrowthManagerHandleGrowth", 1)
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
        else
            log("GrowthManager enabled - growthStateChanged to: " .. growthTransition)
            self.currentGrowthTransitionPeriod = growthTransition
        end
        ssDensityMapScanner:queuJob("ssGrowthManagerHandleGrowth", 1)
    end
end

function ssGrowthManager:setGrowthState(fruit, fruitName, x, z, widthX, widthZ, heightX, heightZ)
    local minState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].setGrowthState
    local desiredGrowthState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].desiredGrowthState
    local fruitTypeGrowth = FruitUtil.fruitTypeGrowths[fruitName]

    if desiredGrowthState == self.WITHERED then
            desiredGrowthState = fruitTypeGrowth.witheringNumGrowthStates
    end

    if desiredGrowthState == self.CUT then
        desiredGrowthState = FruitUtil.fruitTypes[fruitName].cutState + 1
    end

    if self.growthData[self.currentGrowthTransitionPeriod][fruitName].setGrowthMaxState ~= nil then
        local maxState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].setGrowthMaxState

        if maxState == self.MAX_STATE then
            maxState = fruitTypeGrowth.numGrowthStates
        end
        setDensityMaskParams(fruit.id, "between",minState,maxState)
    else
        setDensityMaskParams(fruit.id, "equals",minState)
    end

    local numChannels = g_currentMission.numFruitStateChannels
    local sum = setDensityMaskedParallelogram(fruit.id, x, z, widthX, widthZ, heightX, heightZ, 0, numChannels, fruit.id, 0, numChannels, desiredGrowthState)
end

--increment by 1 for crops between normalGrowthState  normalGrowthMaxState or for crops at normalGrowthState
function ssGrowthManager:incrementGrowthState(fruit, fruitName, x, z, widthX, widthZ, heightX, heightZ)
    local minState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].normalGrowthState

    if self.growthData[self.currentGrowthTransitionPeriod][fruitName].normalGrowthMaxState ~= nil then
        local fruitTypeGrowth = FruitUtil.fruitTypeGrowths[fruitName]
        local maxState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].normalGrowthMaxState

        if maxState == self.MAX_STATE then
            maxState = fruitTypeGrowth.numGrowthStates-1
        end
        setDensityMaskParams(fruit.id, "between",minState,maxState)
    else
        setDensityMaskParams(fruit.id, "equals",minState)
    end

    local numChannels = g_currentMission.numFruitStateChannels
    local sum = addDensityMaskedParallelogram(fruit.id,x,z, widthX,widthZ, heightX,heightZ, 0, numChannels, fruit.id, 0, numChannels, 1)
end

--increment by extraGrowthFactor between extraGrowthMinState and extraGrowthMaxState
function ssGrowthManager:incrementExtraGrowthState(fruit, fruitName, x, z, widthX, widthZ, heightX, heightZ)
    local minState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].extraGrowthMinState
    local maxState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].extraGrowthMaxState
    setDensityMaskParams(fruit.id, "between",minState,maxState)

    local extraGrowthFactor = self.growthData[self.currentGrowthTransitionPeriod][fruitName].extraGrowthFactor
    local numChannels = g_currentMission.numFruitStateChannels
    local sum = addDensityMaskedParallelogram(fruit.id,x,z, widthX,widthZ, heightX,heightZ, 0, numChannels, fruit.id, 0, numChannels, extraGrowthFactor)
end


-- FIXME: dont move to Util. But don't require data. Use self.canPlantData instead. Also, default
-- to the current transition state. Also need to update fruitData
function ssGrowthManager:canFruitGrow(fruitName, growthTransition, data)
    if data[fruitName] ~= nil then
        if data[fruitName][growthTransition] == nil then
            return false
        end

        --log(data[fruitName][growthTransition])
        if data[fruitName][growthTransition] == self.TRUE then
            return true
        end
    end
    return false
end

function ssGrowthManager:buildCanPlantData()
    for fruitName, value in pairs(self.defaultFruits) do
        if fruitName ~= "dryGrass" then
            local transitionTable = {}
            for transition,v in pairs(self.growthData) do
                if transition == self.FIRST_LOAD_TRANSITION then
                    break
                end

                if transition == 10 or transition == 11 or transition == 12 then --hack for winter planting
                    table.insert(transitionTable, transition , self.FALSE)
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
                        if plantedGrowthTransition == 1 then
                            table.insert(transitionTable, plantedGrowthTransition , self.MAYBE)
                        else
                            table.insert(transitionTable, plantedGrowthTransition , self.TRUE)
                        end
                    else
                        table.insert(transitionTable, plantedGrowthTransition , self.FALSE)
                    end
                end
            end
            self.canPlantData[fruitName] = transitionTable
        end
    end
end

--TODO: the 3 if statements should be refactored to 3 functions if possible. They are used in two places
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

function ssGrowthManager:boolToGMBool(value)
    if value == true then
        return self.TRUE
    else
        return self.FALSE
    end
end
