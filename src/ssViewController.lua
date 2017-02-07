---------------------------------------------------------------------------------------------------------
-- VIEW CONTROLLER SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  to manage info view
-- Authors:  theSeb
-- Credits:

ssViewController = {}

--currently for debug view only. this should probably go into ssUtil and will need translations if we use it for the gui
ssViewController.growthTransitionIndexToName =
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

ssViewController.canPlantDisplayData = {}
ssViewController.debugView = false

function ssViewController:loadMap(name)
    g_seasons.environment:addGrowthStageChangeListener(self)
    g_currentMission.environment:addDayChangeListener(self)

    self:growthStageChanged()
    self:dayChanged()
    --self:growthTransitionsDisplayData() --for testing only right now
end

function ssViewController:keyEvent(unicode, sym, modifier, isDown)
    if (unicode == 47) then
        if self.debugView == false then
            self.debugView = true
        else
            self.debugView = false
        end
    end
end

function ssViewController:draw()
    if self.debugView == true then
        renderText(0.54, 0.98, 0.01, "GM enabled: " .. tostring(ssGrowthManager.growthManagerEnabled) .. " doGrowthTransition: " .. tostring(ssGrowthManager.doGrowthTransition))
        local growthTransition = g_seasons.environment:growthTransitionAtDay()

        renderText(0.54, 0.96, 0.01, "Growth Transition: " .. growthTransition .. " " .. self.growthTransitionIndexToName[growthTransition])
        renderText(0.54, 0.94, 0.01, "Month: " .. ssUtil.monthNameShort(g_seasons.environment:monthAtDay()))
        local cropsThatCanGrow = ""

        for index,fruit in pairs(g_currentMission.fruits) do
            local fruitName = FruitUtil.fruitIndexToDesc[index].name

            if ssGrowthManager:canFruitGrow(fruitName, growthTransition, self.canPlantDisplayData) == true then
                cropsThatCanGrow = cropsThatCanGrow .. fruitName .. " "
            end
        end
        renderText(0.54, 0.92, 0.01, "Crops that will grow in next transtition if planted now: " .. cropsThatCanGrow)
        renderText(0.54, 0.90, 0.01, "Soil temp: " .. tostring(ssWeatherManager.soilTemp))
    end
end

-- handle growthStageChanged event
function ssViewController:growthStageChanged()
    --self.currentIndicator = g_seasons.environment:growthTransitionAtDay()
end

-- handle hourChanged event
-- this is a hack for  the early spring transition to update the can plant data based on temperature
function ssViewController:dayChanged()
    local growthTransition = g_seasons.environment:growthTransitionAtDay()

    -- FIXME(jos): no clue why this is needed. Why cant the GM just hold growth data?
    self:updateData()
end

function ssViewController:updateData()
    self.canPlantDisplayData = Utils.copyTable(ssGrowthManager.canPlantData)
    for fruitName, transition in pairs(ssGrowthManager.canPlantData) do
        if transition[ssGrowthManager.FIRST_GROWTH_TRANSITION] == ssGrowthManager.MAYBE then
            -- FIXME(jos): Why not handle this in the GM?
            self.canPlantDisplayData[fruitName][ssGrowthManager.FIRST_GROWTH_TRANSITION] = ssGrowthManager:boolToGMBool(ssWeatherManager:canSow())
        end
    end

end


--this function currently has no real purpose. It's testing the calculation of growth transition days in a season and generates a table with 3 entries
--early, mid, late and each entry then has the range of days in that growth transition
--the intention is that this is the day which will be repeated across the top of the growth gui display below each season to show which days fall into
--which transition.
--FIXME: currently the index is bugged. It should be 1,2,3 but it's 1,3,5.
--Will think of a clever way to fix that without cheating
function ssViewController:growthTransitionsDisplayData()
    local growthStagesDisplayData = {}
    local data = ssUtil.calcDaysPerTransition()

    for index,value in pairs(data) do
        if index % 2 == 1 then
            if value == data[index+1] then
                growthStagesDisplayData[index] = tostring(value)
            else
                growthStagesDisplayData[index] = value .. "-" .. data[index+1]
            end
        end
    end

    return growthStagesDisplayData
end
