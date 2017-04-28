----------------------------------------------------------------------------------------------------
-- TREE MANAGER SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  To manage the growth of trees
-- Authors:  reallogger
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssTreeManager = {}

function ssTreeManager:loadMap()
    if g_currentMission:getIsServer() then
        g_seasons.environment:addSeasonLengthChangeListener(self)
        g_currentMission.environment:addHourChangeListener(self)

        self:adjust()
    end

    TreePlantUtil.plantTree = Utils.appendedFunction(TreePlantUtil.plantTree, ssTreeManager.plantTree)
end

function ssTreeManager:adjust()
    for i, _ in pairs(TreePlantUtil.treeTypes) do
        -- 5 years to fully grown, harvestable after 2 years
        TreePlantUtil.treeTypes[i].growthTimeHours = g_seasons.environment.daysInSeason * 4 * 24 * 5
    end
end

function ssTreeManager:seasonLengthChanged()
    self:adjust()
end

function ssTreeManager:update(dt)
    local growTrees = g_currentMission.plantedTrees.growingTrees

    for i, _ in pairs(growTrees) do
        --thanks to Dogface at fs-uk.com for finding these values
        --growthStatel         growthState
        --    1             0.0000 to 0.1999
        --    2             0.2000 to 0.3999 minimum cutable
        --    3             0.4000 to 0.5999
        --    4             0.6000 to 0.7999
        --    5             0.8000 to 0.9999
        --    6                    1.0000

        -- capping growthState if the distance is too small for the tree to grown
        -- distances are somwehat larger than what should be expected in RL
        if growTrees[i].minDistanceNeighbour < 1.0 and growTrees[i].growthState > 0.25 then
            g_currentMission.plantedTrees.growingTrees[i].growthState = 0.25

        elseif growTrees[i].minDistanceNeighbour < 2.0 and growTrees[i].growthState > 0.45 then
            g_currentMission.plantedTrees.growingTrees[i].growthState = 0.45

        elseif growTrees[i].minDistanceNeighbour < 3.0 and growTrees[i].growthState > 0.65 then
            g_currentMission.plantedTrees.growingTrees[i].growthState = 0.65

        elseif growTrees[i].minDistanceNeighbour < 4.0 and growTrees[i].growthState > 0.85 then
            g_currentMission.plantedTrees.growingTrees[i].growthState = 0.85
        end
    end
end

function ssTreeManager:hourChanged()
    -- check if any trees have been cut during the last hour
    if ssTreeManager.numGrowingTrees ~= table.getn(g_currentMission.plantedTrees.growingTrees) then

        for i, singleTree in pairs(g_currentMission.plantedTrees.growingTrees) do
            g_currentMission.plantedTrees.growingTrees[i].minDistanceNeighbour = ssTreeManager:calculateDistance(singleTree, 0)
        end

        ssTreeManager.numGrowingTrees = table.getn(g_currentMission.plantedTrees.growingTrees)
    end
end

-- function to calculate minimum distance - to be improved
function ssTreeManager:calculateDistance(singleTree, cutTree)
    local statTrees = g_currentMission.plantedTrees.splitTrees
    local growTrees = g_currentMission.plantedTrees.growingTrees
    local tmpDistance = 100
    local tmpNode = 0

    for i, _ in pairs(statTrees) do
        --only one object. Have not been cut.
        if getNumOfChildren(statTrees[i].node) == 1 then

            local vectorDistance = Utils.vector3Length(statTrees[i].x - singleTree.x, statTrees[i].y - singleTree.y, statTrees[i].z - singleTree.z)

            if vectorDistance < tmpDistance then
                tmpDistance = vectorDistance
                tmpNode = statTrees[i].node
            end
        end
    end

    for i, _ in pairs(growTrees) do
        if growTrees[i].node ~= cutTree then
            local vectorDistance = Utils.vector3Length(growTrees[i].x - singleTree.x, growTrees[i].y - singleTree.y, growTrees[i].z - singleTree.z)

            if vectorDistance ~= 0 and vectorDistance < tmpDistance then
                tmpDistance = vectorDistance
                tmpNode = growTrees[i].node
            end
        end
    end

    return tmpDistance
end

-- This seems to be the function that is called when a tree is planted. If an existing savegame has planted trees, the function is called during loading as well.
function ssTreeManager:plantTree(treesData, treeData, x, y, z, rx, ry, rz, growthState, growthStateI, isGrowing, splitShapeFileId)
    ssTreeManager.numGrowingTrees = table.getn(g_currentMission.plantedTrees.growingTrees)

    if ssTreeManager.numGrowingTrees > 0 then
        for i, singleTree in pairs(g_currentMission.plantedTrees.growingTrees) do
            g_currentMission.plantedTrees.growingTrees[i].minDistanceNeighbour = ssTreeManager:calculateDistance(singleTree, 0)
        end
    end
end
