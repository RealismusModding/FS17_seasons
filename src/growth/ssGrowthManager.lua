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
ssGrowthManager.TMP_TRANSITION = 900
ssGrowthManager.FIRST_LOAD_TRANSITION = 999
ssGrowthManager.UNKNOWN_FRUIT_COPY_SOURCE = "barley"

-- data
ssGrowthManager.defaultFruitsData = {}
ssGrowthManager.growthData = {}
ssGrowthManager.willGerminateData = {}

-- properties
ssGrowthManager.additionalFruitsChecked = false
ssGrowthManager.dayHasChanged = false
ssGrowthManager.isActivatedOnOldSave = false

function ssGrowthManager:load(savegame, key)
    self.isNewSavegame = savegame == nil

    self.growthManagerEnabled = ssXMLUtil.getBool(savegame, key .. ".settings.growthManagerEnabled", true)

    if savegame == nil then return end

    self.willGerminateData[g_seasons.environment:transitionAtDay()] = {}
    local i = 0

    if g_seasons.savegameVersion <= g_seasons.CONTEST_SAVEGAME_VERSION then --old save game
        i = self:loadSavedGerminationData(savegame, string.format("%s.growthManager.willGerminate", key), g_seasons.environment:transitionAtDay())
    else --current save game version
        while true do
            local transitionKey = string.format("%s.growthManager.willGerminate.transition(%i)", key, i)
            if not hasXMLProperty(savegame, transitionKey) then break end

            local transitionNum = getXMLInt(savegame, transitionKey .. "#gt")
            self.willGerminateData[transitionNum] = {}
            self:loadSavedGerminationData(savegame, transitionKey, transitionNum)

            i = i + 1
        end
    end

    if i == 0 then
        self.isActivatedOnOldSave = true
    end
end

function ssGrowthManager:loadSavedGerminationData(savegame, key, transitionNum)
    local j = 0

    while true do
        local fruitKey = string.format("%s.fruit(%i)", key, j)
        if not hasXMLProperty(savegame, fruitKey) then break end

        local fruitName = getXMLString(savegame, fruitKey .. "#fruitName")
        self.willGerminateData[transitionNum][fruitName] = getXMLBool(savegame, fruitKey .. "#value", false)

        j = j + 1
    end

    return j
end

function ssGrowthManager:save(savegame, key)
    ssXMLUtil.setBool(savegame, key .. ".settings.growthManagerEnabled", self.growthManagerEnabled)
    local i = 0

    for transition, data in pairs(self.willGerminateData) do
        local transitionKey = string.format("%s.growthManager.willGerminate.transition(%i)", key, i)
        setXMLInt(savegame, transitionKey .. "#gt", transition)
        local j = 0

        for fruitName, value in pairs(data) do
            local fruitKey = string.format("%s.fruit(%i)", transitionKey, j)

            setXMLString(savegame, fruitKey .. "#fruitName", tostring(fruitName))
            setXMLBool(savegame, fruitKey .. "#value", value)

            j = j + 1
        end

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

    g_seasons.growthGUI:buildCanPlantData(self.defaultFruitsData, self.growthData)
    g_seasons.growthGUI:buildCanHarvestData(self.growthData)

    if g_currentMission:getIsServer() then
        g_currentMission.environment:addDayChangeListener(self)
        g_seasons.environment:addTransitionChangeListener(self)

        ssDensityMapScanner:registerCallback("ssGrowthManagerHandleGrowth", self, self.handleGrowth, self.finishGrowth)
    end
end

function ssGrowthManager:loadMapFinished()
    if g_currentMission:getIsServer() then
        if self.isNewSavegame == true or self.isActivatedOnOldSave == true then --if new game or mod enabled on existing save
            self:rebuildWillGerminateData()
        end
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

--reset growth to first_load_transition for all fields
function ssGrowthManager:resetGrowth()
    if self.growthManagerEnabled == true and g_currentMission:getIsServer() then
        ssDensityMapScanner:queueJob("ssGrowthManagerHandleGrowth", self.FIRST_LOAD_TRANSITION)
        logInfo("ssGrowthManager:", "Growth reset")
    end
end

--handle transitionChanged event
function ssGrowthManager:transitionChanged()
    if self.growthManagerEnabled == false then return end

    local transition = g_seasons.environment:transitionAtDay()
    g_seasons.growthDebug:setFakeTransition(transition)
    
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
    if self.growthManagerEnabled == false then return end

    if self.additionalFruitsChecked == false then
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
end

-- reset the willGerminateData and rebuild it based on the current transition
function ssGrowthManager:rebuildWillGerminateData()
    self.willGerminateData[g_seasons.environment:transitionAtDay()] = {}
    local canPlantData = g_seasons.growthGUI:getCanPlantData()
    for fruitName, transition in pairs(canPlantData) do
        if canPlantData[fruitName][g_seasons.environment:transitionAtDay()] == true then
            self.willGerminateData[g_seasons.environment:transitionAtDay()][fruitName] = ssWeatherManager:canSow(fruitName)
        end
    end
end

-- handle dayChanged event
-- check if canSow and update willGerminate accordingly
function ssGrowthManager:dayChanged()
  --self.dayHasChanged = true
  self:rebuildWillGerminateData()
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

function ssGrowthManager:finishGrowth(transition)
    self.willGerminateData[g_seasons.environment:previousTransition(transition)] = nil
end

--set growth state of fruit to a particular state based on transition
function ssGrowthManager:setGrowthState(fruit, fruitName, x, z, widthX, widthZ, heightX, heightZ, transition)
    local useMaxState = false
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
        useMaxState = true
    else -- else only use minState
        setDensityMaskParams(fruit.id, "equals", minState)
    end

    local numFruitStateChannels = g_currentMission.numFruitStateChannels
    local growthResult = setDensityMaskedParallelogram(fruit.id, x, z, widthX, widthZ, heightX, heightZ, 0, numFruitStateChannels, fruit.id, 0, numFruitStateChannels, desiredGrowthState)
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

    setDensityMaskParams(fruit.id, "greater", 0) -- reset
end

--increment by 1 for crops between normalGrowthState  normalGrowthMaxState or for crops at normalGrowthState
function ssGrowthManager:incrementGrowthState(fruit, fruitName, x, z, widthX, widthZ, heightX, heightZ, transition)
    local useMaxState = false
    local minState = self.growthData[transition][fruitName].normalGrowthState
    local fruitTypeGrowth = FruitUtil.fruitTypeGrowths[fruitName]

    if self.growthData[transition][fruitName].normalGrowthMaxState ~= nil then
        local maxState = self.growthData[transition][fruitName].normalGrowthMaxState

        if minState == 1 and self.willGerminateData[g_seasons.environment:previousTransition(transition)][fruitName] == false then
            minState = 2
        end

        if maxState == self.MAX_STATE then
            maxState = fruitTypeGrowth.numGrowthStates - 1
        end
        setDensityMaskParams(fruit.id, "between", minState, maxState)
        useMaxState = true
    else
        if minState == 1 and self.willGerminateData[g_seasons.environment:previousTransition(transition)][fruitName] == false then
            return
        end
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

    setDensityMaskParams(fruit.id, "greater", 0) -- reset
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

    setDensityMaskParams(fruit.id, "greater", 0) -- reset
end

function ssGrowthManagerWillGerminate(transition, fruitName)
    
end

-- update all GM data for a custom unknown fruit
function ssGrowthManager:unknownFruitFound(fruitName)
    self:updateDefaultFruitsData(fruitName)
    self:updateGrowthData(fruitName)
    g_seasons.growthGUI:updateCanPlantData(fruitName)
    g_seasons.growthGUI:updateCanHarvestData(fruitName)
    self:updateWillGerminateData(fruitName)
end

function ssGrowthManager:updateDefaultFruitsData(fruitName)
    self.defaultFruitsData[fruitName] = {}
    self.defaultFruitsData[fruitName].maxSprayGrowthState = self.defaultFruitsData[self.UNKNOWN_FRUIT_COPY_SOURCE].maxSprayGrowthState
end

function ssGrowthManager:updateGrowthData(fruitName)
    for transition, fruit in pairs(self.growthData) do
        if self.growthData[transition][self.UNKNOWN_FRUIT_COPY_SOURCE] ~= nil then
            self.growthData[transition][fruitName] = Utils.copyTable(self.growthData[transition][self.UNKNOWN_FRUIT_COPY_SOURCE])
            self.growthData[transition][fruitName].fruitName = fruitName
        end
    end
end

function ssGrowthManager:updateWillGerminateData(fruitName)
    self.willGerminateData[g_seasons.environment:transitionAtDay()][fruitName] = self.willGerminateData[g_seasons.environment:transitionAtDay()][self.UNKNOWN_FRUIT_COPY_SOURCE]
end