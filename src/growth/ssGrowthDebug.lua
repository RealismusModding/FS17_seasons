----------------------------------------------------------------------------------------------------
-- GROWTH MANAGER SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  to help debug growth
-- Authors:  theSeb
-- Credits:  
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssGrowthDebug = {}
g_seasons.growthDebug = ssGrowthDebug

--constants
ssGrowthDebug.TMP_TRANSITION = 900

--properties
ssGrowthDebug.debugView = false
ssGrowthDebug.fakeTransition = 1

--functions
function ssGrowthDebug:loadMap(name)
    if g_currentMission:getIsServer() then
        addConsoleCommand("ssResetGrowth", "Resets growth back to default starting state", "consoleCommandResetGrowth", self)
        addConsoleCommand("ssIncrementGrowth", "Increments growth for test purposes", "consoleCommandIncrementGrowthState", self)
        addConsoleCommand("ssSetGrowthState", "Sets growth for test purposes", "consoleCommandSetGrowthState", self)
        addConsoleCommand("ssPrintDebugInfo", "Prints debug info", "consoleCommandPrintDebugInfo", self)
        addConsoleCommand("ssChangeFruitGrowthState", "ssChangeFruitGrowthState fruit currentState desiredState", "consoleCommandChangeFruitGrowthState", self)
        addConsoleCommand("ssGrowthDebugView", "Displays growth related debug info", "consoleCommandDebugView", self);
    end
end

function ssGrowthDebug:setFakeTransition(transition)
    self.fakeTransition = transition
end

function ssGrowthDebug:draw()
    if self.debugView == true then
        renderText(0.44, 0.78, 0.01, "GM enabled: " .. tostring(g_seasons.growthManager.growthManagerEnabled))
        local transition = g_seasons.environment:transitionAtDay()

        renderText(0.44, 0.76, 0.01, "Growth Transition: " .. transition .. " " .. ssUtil.fullSeasonName(transition))

        local cropsThatCanGrow = ""

        for fruitName in pairs(g_seasons.growthManager.willGerminateData) do
            if g_seasons.growthManager.willGerminateData[transition][fruitName] == true then
                cropsThatCanGrow = cropsThatCanGrow .. fruitName .. " "
            end
        end

        renderText(0.44, 0.72, 0.01, "Crops that will grow in next transtition if planted now: " .. cropsThatCanGrow)
        renderText(0.44, 0.70, 0.01, "Soil temp: " .. tostring(g_seasons.weather.soilTemp))
        renderText(0.44, 0.68, 0.01, "Crop moisture content: " .. tostring(g_seasons.weather.cropMoistureContent))
    end
end

--debug console commands

function ssGrowthDebug:consoleCommandDebugView()
    if g_currentMission:getIsServer() then
        if self.debugView == false then
            self.debugView = true
        else
            self.debugView = false
        end
    end
end

function ssGrowthDebug:consoleCommandResetGrowth()
    g_seasons.growthManager:resetGrowth()
end

function ssGrowthDebug:consoleCommandIncrementGrowthState()
    self.fakeTransition = self.fakeTransition + 1
    if self.fakeTransition > g_seasons.environment.TRANSITIONS_IN_YEAR then self.fakeTransition = 1 end
    logInfo("ssGrowthManager:", "enabled - growthStateChanged to: " .. self.fakeTransition)
    g_seasons.growthManager.willGerminateData[g_seasons.environment:previousTransition(self.fakeTransition)] = Utils.copyTable(g_seasons.growthManager.willGerminateData[g_seasons.environment:transitionAtDay()])
    ssDensityMapScanner:queueJob("ssGrowthManagerHandleGrowth", self.fakeTransition)
end

function ssGrowthDebug:consoleCommandSetGrowthState(newGrowthState)
    self.fakeTransition = Utils.getNoNil(tonumber(newGrowthState), 1)
    logInfo("ssGrowthManager:", "enabled - growthStateChanged to: " .. self.fakeTransition)
    g_seasons.growthManager.willGerminateData[g_seasons.environment:previousTransition(self.fakeTransition)] = Utils.copyTable(g_seasons.growthManager.willGerminateData[g_seasons.environment:transitionAtDay()])
    ssDensityMapScanner:queueJob("ssGrowthManagerHandleGrowth", self.fakeTransition)
end

function ssGrowthDebug:consoleCommandChangeFruitGrowthState(userInput)
    local inputs = {}
    for input in string.gmatch(userInput, "%w+") do table.insert(inputs, input) end

    local fruitName = inputs[1]
    g_seasons.growthManager.growthData[self.TMP_TRANSITION] = {}
    g_seasons.growthManager.growthData[self.TMP_TRANSITION][fruitName] = {}
    g_seasons.growthManager.growthData[self.TMP_TRANSITION][fruitName].setGrowthState = tonumber(inputs[2])
    g_seasons.growthManager.growthData[self.TMP_TRANSITION][fruitName].desiredGrowthState = tonumber(inputs[3])
    g_seasons.growthManager.willGerminateData[g_seasons.environment:previousTransition(self.TMP_TRANSITION)] = Utils.copyTable(g_seasons.growthManager.willGerminateData[g_seasons.environment:transitionAtDay()])
    ssDensityMapScanner:queueJob("ssGrowthManagerHandleGrowth", self.TMP_TRANSITION)
end

function ssGrowthDebug:consoleCommandPrintDebugInfo()
    local transition = g_seasons.environment:transitionAtDay()
    logInfo("------------------------------------------")
    logInfo("Seasons Debug Info")
    print("")
    logInfo("Savegame version: " .. tostring(g_seasons.savegameVersion))
    print("")
    logInfo("Growth Transition: " .. tostring(transition) .. " " .. ssUtil.fullSeasonName(transition))
    logInfo("Soil temp: " .. tostring(ssWeatherManager.soilTemp))
    logInfo("Crop moisture content: " .. tostring(ssWeatherManager.cropMoistureContent))
    print("")
    local cropsThatCanGrow = ""

    for fruitName in pairs(g_seasons.growthManager.willGerminateData[g_seasons.environment:transitionAtDay()]) do
        if g_seasons.growthManager.willGerminateData[g_seasons.environment:transitionAtDay()][fruitName] == true then
            cropsThatCanGrow = cropsThatCanGrow .. fruitName .. " "
        end
    end

    logInfo("Crops that will grow in next transtition if planted now: " .. cropsThatCanGrow)
    print("")
    logInfo("Previous willGerminateData")
    print_r(g_seasons.growthManager.willGerminateData[g_seasons.environment:previousTransition()])
    print("")
    logInfo("Current willGerminateData")
    print_r(g_seasons.growthManager.willGerminateData[g_seasons.environment:transitionAtDay()])
    print("")
    logInfo("Full germinate Data")
    print_r(g_seasons.growthManager.willGerminateData)
    logInfo("------------------------------------------")
end
