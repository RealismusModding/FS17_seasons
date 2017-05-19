----------------------------------------------------------------------------------------------------
-- TREE MANAGER SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  To manage the growth of trees
-- Authors:  reallogger, redone by Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssTreeManager = {}
g_seasons.treeManager = ssTreeManager

ssTreeManager.MIN_DISTANCE = 4.0 -- meters

function ssTreeManager:loadMap()
    if g_currentMission:getIsServer() then
        g_seasons.environment:addSeasonLengthChangeListener(self)

        self:adjust()
    end

    TreePlantUtil.plantTree = Utils.appendedFunction(TreePlantUtil.plantTree, ssTreeManager.plantTree)
    TreePlantUtil.addTreeCutJoint = Utils.appendedFunction(TreePlantUtil.addTreeCutJoint, ssTreeManager.addTreeCutJoint)
end

function ssTreeManager:adjust()
    for i, _ in pairs(TreePlantUtil.treeTypes) do
        -- 5 years to fully grown, harvestable after 2 years
        -- TreePlantUtil.treeTypes[i].growthTimeHours = g_seasons.environment.daysInSeason * 4 * 24 * 5
        TreePlantUtil.treeTypes[i].growthTimeHours = 4
    end
end

function ssTreeManager:seasonLengthChanged()
    self:adjust()
end

function ssTreeManager:update(dt)
    self.finishedLoading = true

    for _, tree in pairs(g_currentMission.plantedTrees.growingTrees) do
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
        if tree.ssNearestDistance < 1.0 and tree.growthState > 0.25 then
            tree.growthState = 0.25
        elseif tree.ssNearestDistance < 2.0 and tree.growthState > 0.45 then
            tree.growthState = 0.45
        elseif tree.ssNearestDistance < 3.0 and tree.growthState > 0.65 then
            tree.growthState = 0.65
        elseif tree.ssNearestDistance < 4.0 and tree.growthState > 0.85 then
            tree.growthState = 0.85
        end
    end
end

-- Find the nearest in the small set
function ssTreeManager:updateNearest(tree)
    tree.ssNearestDistance = self.MIN_DISTANCE + 1

    for other, distance in pairs(tree.ssNear) do
        if distance < tree.ssNearestDistance then
            tree.ssNearestDistance = distance
        end
    end
end

-- This seems to be the function that is called when a tree is planted. If an existing savegame has
-- planted trees, the function is called during loading as well.
-- This code is roughly O(n)
function ssTreeManager:plantTree(...)
    local plantedTree = g_currentMission.plantedTrees.growingTrees[table.getn(g_currentMission.plantedTrees.growingTrees)]

    plantedTree.ssNear = {}

    for _, tree in pairs(g_currentMission.plantedTrees.growingTrees) do
        if tree ~= plantedTree then
            local distance = Utils.vector3Length(tree.x - plantedTree.x, tree.y - plantedTree.y, tree.z - plantedTree.z)

            -- If the trees are in distance, store their relation
            if distance < ssTreeManager.MIN_DISTANCE then
                plantedTree.ssNear[tree] = distance

                tree.ssNear[plantedTree] = distance
                ssTreeManager:updateNearest(tree)
            end
        end
    end

    ssTreeManager:updateNearest(plantedTree)
end

-- This code is about O(5) (theoretically max O(n) but can't plant trees that close)
function ssTreeManager:addTreeCutJoint(...)
    local cutTree = nil

    -- Find the tree that was just cut
    for _, tree in pairs(g_currentMission.plantedTrees.growingTrees) do
        -- Cut
        if getChildAt(tree.node, 0) ~= tree.origSplitShape and tree.ssHandled ~= true then
            tree.ssCutHandled = true

            cutTree = tree

            break
        end
    end

    if cutTree == nil then return end

    -- Remove the cut tree from all its neighbors
    for otherTree, _ in pairs(cutTree.ssNear) do
        otherTree.ssNear[cutTree] = nil

        ssTreeManager:updateNearest(otherTree)
    end

    cutTree.ssNear = {}
end
