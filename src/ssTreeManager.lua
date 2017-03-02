---------------------------------------------------------------------------------------------------------
-- TREE MANAGER SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  To manage the growth of trees
-- Authors:  reallogger
--

ssTreeManager = {}


function ssTreeManager:loadMap()

    for i, _ in pairs(TreePlantUtil.treeTypes) do
        -- 5 years to fully grown, harvestable after 2 years
        TreePlantUtil.treeTypes[i].growthTimeHours = g_seasons.environment.daysInSeason * 4 * 24 * 5
    end

end

