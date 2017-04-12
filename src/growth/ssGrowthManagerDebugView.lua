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
    --self:transitionsDisplayData() --for testing only right now
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

        for fruitName in pairs(ssGrowthManager.willGerminate) do
            if ssGrowthManager.willGerminateData[fruitName] == true then
                cropsThatCanGrow = cropsThatCanGrow .. fruitName .. " "
            end
        end

        renderText(0.44, 0.92, 0.01, "Crops that will grow in next transtition if planted now: " .. cropsThatCanGrow)
        renderText(0.44, 0.90, 0.01, "Soil temp: " .. tostring(ssWeatherManager.soilTemp))
        renderText(0.44, 0.88, 0.01, "Crop moisture content: " .. tostring(ssWeatherManager.cropMoistureContent))
    end
end

--this function currently has no real purpose. It's testing the calculation of growth transition days in a season and generates a table with 3 entries
--early, mid, late and each entry then has the range of days in that growth transition
--the intention is that this is the day which will be repeated across the top of the growth gui display below each season to show which days fall into
--which transition.
--FIXME: currently the index is bugged. It should be 1,2,3 but it's 1,3,5.
--Will think of a clever way to fix that without cheating
function ssGrowthManagerDebugView:getTransitionsDisplayData()
    local transitionsDisplayData = {}
    local data = ssUtil.calcDaysPerTransition()

    for index,value in pairs(data) do
        if index % 2 == 1 then
            if value == data[index+1] then
                transitionsDisplayData[index] = tostring(value)
            else
                transitionsDisplayData[index] = value .. "-" .. data[index+1]
            end
        end
    end

    return transitionsDisplayData
end
