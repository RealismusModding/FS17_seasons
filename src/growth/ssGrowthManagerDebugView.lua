----------------------------------------------------------------------------------------------------
-- ssGrowthManagerDebugView SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  to help debug growth
-- Authors:  theSeb
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssGrowthManagerDebugView = {}

--currently for debug view only. this should probably go into ssUtil and will need translations if we use it for the gui
ssGrowthManagerDebugView.transitionIndexToName =
{
    [1] = "Early Spring",
    [2] = "Mid Spring",
    [3] = "Late Spring",
    [4] = "Early Summer",
    [5] = "Mid Summer",
    [6] = "Late Summer",
    [7] = "Early Autumn",
    [8] = "Mid Autumn",
    [9] = "Late Autumn",
    [10] = "Early Winter",
    [11] = "Mid Winter",
    [12] = "Late Winter"
}

ssGrowthManagerDebugView.debugView = false

function ssGrowthManagerDebugView:loadMap(name)
    addConsoleCommand("ssGrowthDebugView", "Displays growth related debug info", "consoleCommandDebugView", self);
end

function ssGrowthManagerDebugView:consoleCommandDebugView()
    if g_currentMission:getIsServer() then
        if self.debugView == false then
            self.debugView = true
        else
            self.debugView = false
        end
    end
end

function ssGrowthManagerDebugView:draw()
    if self.debugView == true then
        renderText(0.44, 0.98, 0.01, "GM enabled: " .. tostring(ssGrowthManager.growthManagerEnabled))
        local transition = g_seasons.environment:transitionAtDay()

        renderText(0.44, 0.96, 0.01, "Growth Transition: " .. transition .. " " .. self.transitionIndexToName[transition])

        local cropsThatCanGrow = ""

        for fruitName in pairs(ssGrowthManager.willGerminateData) do
            if ssGrowthManager.willGerminateData[fruitName] == true then
                cropsThatCanGrow = cropsThatCanGrow .. fruitName .. " "
            end
        end

        renderText(0.44, 0.92, 0.01, "Crops that will grow in next transtition if planted now: " .. cropsThatCanGrow)
        renderText(0.44, 0.90, 0.01, "Soil temp: " .. tostring(ssWeatherManager.soilTemp))
        renderText(0.44, 0.88, 0.01, "Crop moisture content: " .. tostring(ssWeatherManager.cropMoistureContent))
    end
end

