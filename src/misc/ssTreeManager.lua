----------------------------------------------------------------------------------------------------
-- TREE MANAGER SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  To manage the growth of trees
-- Authors:  reallogger, redone by Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssTreeManager = {}

ssTreeManager.MIN_DISTANCE = 9.5 -- meters
ssTreeManager.MIN_DISTANCE_SQ = ssTreeManager.MIN_DISTANCE * ssTreeManager.MIN_DISTANCE

function ssTreeManager:preLoad()
    g_seasons.treeManager = self
end

function ssTreeManager:loadMap()
    if g_currentMission:getIsServer() then
        g_seasons.environment:addSeasonLengthChangeListener(self)

        self:adjust()
    end

    ssUtil.overwrittenFunction(TreePlantUtil, "plantTree", ssTreeManager.plantTree)
    ssUtil.appendedFunction(ChainsawUtil, "cutSplitShapeCallback", ssTreeManager.cutSplitShapeCallback)
end

function ssTreeManager:adjust()
    for i, _ in pairs(TreePlantUtil.treeTypes) do
        -- 5 years to fully grown, harvestable after 2 years
        ssUtil.overwrittenConstant(TreePlantUtil.treeTypes[i], "growthTimeHours", g_seasons.environment.daysInSeason * 4 * 24 * 5)
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
        --    1             0.0000 to 0.1999 > sapling
        --    2             0.2000 to 0.3999 > stage 1
        --    3             0.4000 to 0.5999 > stage 2 and minimum cutable
        --    4             0.6000 to 0.7999 > stage 3
        --    5             0.8000 to 0.9999 > stage 4
        --    6                    1.0000    > stage 5 and fully grown

        -- capping growthState if the distance is too small for the tree to grown
        -- distances are somwehat larger than what should be expected in RL
        if tree.ssNearestDistance < 4.5 and tree.growthState > 0.45 then
            tree.growthState = 0.45
        elseif tree.ssNearestDistance < 6.5 and tree.growthState > 0.65 then
            tree.growthState = 0.65
        elseif tree.ssNearestDistance < self.MIN_DISTANCE and tree.growthState > 0.85 then
            tree.growthState = 0.85
        end
    end
end

function ssTreeManager:isTreeGrowthLimited(tree)
    local limits = {
        [4.5] = 0.45,
        [6.5] = 0.65,
        [self.MIN_DISTANCE] = 0.85,
    }
    local eps = 0.02

    for distance, state in pairs(limits) do
        if tree.ssNearestDistance < distance and tree.growthState < state + eps and tree.growthState > state - eps then
            return true
        end
    end

    return false
end

-- Find the nearest in the small set
function ssTreeManager:updateNearest(tree)
    tree.ssNearestDistance = self.MIN_DISTANCE_SQ + 1

    for other, distance in pairs(tree.ssNear) do
        if distance < tree.ssNearestDistance then
            tree.ssNearestDistance = distance
        end
    end

    tree.ssNearestDistance = math.sqrt(tree.ssNearestDistance)
end

-- This seems to be the function that is called when a tree is planted. If an existing savegame has
-- planted trees, the function is called during loading as well.
-- This code is roughly O(n)
function ssTreeManager:plantTree(superFunc, ...)
    local growingSize = table.getn(g_currentMission.plantedTrees.growingTrees)

    -- Verify if an actual tree was placed
    superFunc(self, ...)

    local latestTreeIndex = table.getn(g_currentMission.plantedTrees.growingTrees)
    if latestTreeIndex == 0 or growingSize == latestTreeIndex then return end

    local plantedTree = g_currentMission.plantedTrees.growingTrees[latestTreeIndex]

    plantedTree.ssNear = {}

    for _, tree in pairs(g_currentMission.plantedTrees.growingTrees) do
        if tree ~= plantedTree then
            local distance = Utils.vector3LengthSq(tree.x - plantedTree.x, tree.y - plantedTree.y, tree.z - plantedTree.z)

            -- If the trees are in distance, store their relation
            if distance < ssTreeManager.MIN_DISTANCE_SQ then
                plantedTree.ssNear[tree] = distance

                tree.ssNear[plantedTree] = distance
                ssTreeManager:updateNearest(tree)
            end
        end
    end

    ssTreeManager:updateNearest(plantedTree)
end

-- This code is about O(5) (theoretically max O(n) but can't plant trees that close)
function ssTreeManager:cutSplitShapeCallback(...)
    local cutTree

    -- Find the tree that was just cut
    for _, tree in pairs(g_currentMission.plantedTrees.growingTrees) do
        -- Cut
        if getChildAt(tree.node, 0) ~= tree.origSplitShape and tree.ssCutHandled ~= true then
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
