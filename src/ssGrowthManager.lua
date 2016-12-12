---------------------------------------------------------------------------------------------------------
-- GROWTH MANAGER SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  to manage growth as the season changes
-- Authors:  theSeb
-- Credits: Inspired by upsidedown's growth manager mod

ssGrowthManager = {}

MAX_GROWTH_STATE = 99; -- needs to be set to the fruit's numGrowthStates if you are setting, or numGrowthStates-1 if you're incrementing
WITHER_STATE = 100;
FIRST_LOAD_TRANSITION = 999;

function Set (list)
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end


ssGrowthManager.defaultFruits = {};
ssGrowthManager.growthData = {};
ssGrowthManager.currentGrowthTransitionPeriod = nil;
ssGrowthManager.doGrowthTransition = false;


function ssGrowthManager:load(savegame, key)
    self.hasResetGrowth = ssStorage.getXMLBool(savegame, key .. ".settings.hasResetGrowth", false);
    self.growthManagerEnabled = ssStorage.getXMLBool(savegame,key .. ".settings.growthManagerEnabled", true);
end

function ssGrowthManager:save(savegame, key)
    ssStorage.setXMLBool(savegame, key .. ".settings.hasResetGrowth", self.hasResetGrowth);
    ssStorage.setXMLBool(savegame, key .. ".settings.growthManagerEnabled", self.growthManagerEnabled);
end

function ssGrowthManager:loadMap(name)


    if (self.growthManagerEnabled == false) then
        log("ssGrowthManager: disabled");
        return;
    end
    
    --if g_currentMission:getIsServer() then
      
    if self:getGrowthData() == false then
        logInfo("ssGrowthManager: required data not loaded. ssGrowthManager disabled");
        return;
    end

    logInfo("ssGrowthManager - data loaded. Locking growth");
    --lock changing the growth speed option and set growth rate to 1 (no growth)
    g_currentMission:setPlantGrowthRate(1,nil);
    g_currentMission:setPlantGrowthRateLocked(true);
    ssSeasonsMod:addGrowthStageChangeListener(self)   

    if not (self.hasResetGrowth) then 
        self.currentGrowthTransitionPeriod = FIRST_LOAD_TRANSITION;
        self.doGrowthTransition = true;
        self.hasResetGrowth = true;
        self.growthManagerEnabled = true;
        logInfo("ssGrowthManager: First time growth reset - this will only happen once in a new savegame");
    end

    if g_currentMission.missionInfo.timeScale > 120 then
        self.mapSegments = 1 -- Not enought time to do it section by section since it might be called every two hour as worst case.
    else
        self.mapSegments = 16 -- Must be evenly dividable with mapsize.
    end

    self.currentX = 0 -- The row that we are currently updating
    self.currentZ = 0 -- The column that we are currently updating

end


function ssGrowthManager:getGrowthData()
   
    local defaultFruits,growthData = ssGrowthManagerData:loadAllData();
   
    if defaultFruits ~= nil then
        self.defaultFruits = Set(defaultFruits);
    else
        logInfo("ssGrowthManager: default fruits data not found");
        return false;
    end

    if growthData ~= nil then
        self.growthData = growthData;
    else
        logInfo("ssGrowthManager: default growth data not found");
        return false;
    end

    return true;

end

function ssGrowthManager:deleteMap()
end

function ssGrowthManager:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssGrowthManager:keyEvent(unicode, sym, modifier, isDown)
    -- if (unicode == 107) then

    --     -- for index,fruit in pairs(g_currentMission.fruits) do
    --     --     local desc = FruitUtil.fruitIndexToDesc[index]
    --     --     local fruitName = desc.name
    --     --     if (self.defaultFruits[fruitName] == nil) then
    --     --         log("GM: Fruit not found in default table: " .. fruitName);
    --     --     else
    --     --         log("GM: Fruit " .. fruitName .. " found");
    --     --     end
    --     -- end

    -- end
end

function ssGrowthManager:update(dt)

    if self.doGrowthTransition == true then

        local startWorldX =  self.currentX * g_currentMission.terrainSize / self.mapSegments - g_currentMission.terrainSize / 2
        local startWorldZ =  self.currentZ * g_currentMission.terrainSize / self.mapSegments - g_currentMission.terrainSize / 2
        local widthWorldX = startWorldX + g_currentMission.terrainSize / self.mapSegments - 0.1 -- -0.1 to avoid overlap.
        local widthWorldZ = startWorldZ
        local heightWorldX = startWorldX
        local heightWorldZ = startWorldZ + g_currentMission.terrainSize / self.mapSegments - 0.1 -- -0.1 to avoid overlap.

        for index,fruit in pairs(g_currentMission.fruits) do
            local desc = FruitUtil.fruitIndexToDesc[index]
            local fruitName = desc.name

            local x,z, widthX,widthZ, heightX,heightZ = Utils.getXZWidthAndHeight(id, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

            if (self.defaultFruits[fruitName] == nil) then
                log("Fruit not found in default table: " .. fruitName);
                fruitName = "default";
            end

            if self.growthData[self.currentGrowthTransitionPeriod][fruitName] ~= nil then 

                local fruitData = FruitUtil.fruitTypeGrowths[fruitName]

                --setGrowthState
                if self.growthData[self.currentGrowthTransitionPeriod][fruitName].setGrowthState ~= nil
                    and self.growthData[self.currentGrowthTransitionPeriod][fruitName].desiredGrowthState ~= nil then
                        --log("FruitID " .. fruit.id .. " FruitName: " .. fruitName .. " - reset growth at season transition: " .. self.currentGrowthTransitionPeriod .. " between growth states " .. self.growthData[self.currentGrowthTransitionPeriod][fruitName].setGrowthState .. " and " .. self.growthData[self.currentGrowthTransitionPeriod][fruitName].setGrowthMaxState .. " to growth state: " .. self.growthData[self.currentGrowthTransitionPeriod][fruitName].setGrowthState)

                    local minState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].setGrowthState
                    local desiredGrowthState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].desiredGrowthState

                    if desiredGrowthState == WITHER_STATE then
                         desiredGrowthState = fruitData.witheringNumGrowthStates
                    end

                    if self.growthData[self.currentGrowthTransitionPeriod][fruitName].setGrowthMaxState ~= nil then

                        local maxState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].setGrowthMaxState
                        if maxState == MAX_GROWTH_STATE then
                            maxState = fruitData.numGrowthStates
                        end
                        setDensityMaskParams(fruit.id, "between",minState,maxState)
                    else
                        setDensityMaskParams(fruit.id, "equals",minState)
                    end

                    local sum = setDensityMaskedParallelogram(fruit.id,x,z, widthX,widthZ, heightX,heightZ,0, g_currentMission.numFruitStateChannels, fruit.id, 0, g_currentMission.numFruitStateChannels, desiredGrowthState)

                end

                --increment by 1 for crops between normalGrowthState  normalGrowthMaxState or for crops at normalGrowthState
                if self.growthData[self.currentGrowthTransitionPeriod][fruitName].normalGrowthState ~= nil then

                    local minState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].normalGrowthState

                    if self.growthData[self.currentGrowthTransitionPeriod][fruitName].normalGrowthMaxState ~= nil then

                        local maxState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].normalGrowthMaxState

                        if maxState == MAX_GROWTH_STATE then
                            maxState = fruitData.numGrowthStates-1
                        end
                        setDensityMaskParams(fruit.id, "between",minState,maxState)
                    else
                        setDensityMaskParams(fruit.id, "equals",minState)
                    end

                    local sum = addDensityMaskedParallelogram(fruit.id,x,z, widthX,widthZ, heightX,heightZ, 0, g_currentMission.numFruitStateChannels, fruit.id, 0, g_currentMission.numFruitStateChannels, 1)
                end

                --increment by extraGrowthFactor between extraGrowthMinState and extraGrowthMaxState
                if self.growthData[self.currentGrowthTransitionPeriod][fruitName].extraGrowthMinState ~= nil
                    and self.growthData[self.currentGrowthTransitionPeriod][fruitName].extraGrowthMaxState ~= nil
                    and self.growthData[self.currentGrowthTransitionPeriod][fruitName].extraGrowthFactor ~= nil then

                    local minState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].extraGrowthMinState
                    local maxState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].extraGrowthMaxState
                    local extraGrowthFactor = self.growthData[self.currentGrowthTransitionPeriod][fruitName].extraGrowthFactor

                    setDensityMaskParams(fruit.id, "between",minState,maxState)
                    local sum = addDensityMaskedParallelogram(fruit.id,x,z, widthX,widthZ, heightX,heightZ, 0, g_currentMission.numFruitStateChannels, fruit.id, 0, g_currentMission.numFruitStateChannels, extraGrowthFactor )
                end

            end  -- end of if self.growthData[self.currentGrowthTransitionPeriod][fruitName] ~= nil then

        end  -- end of for index,fruit in pairs(g_currentMission.fruits) do

        if self.currentZ < self.mapSegments - 1 then -- Starting with column 0 So index of last column is one less then the number of columns.
            -- Next column
            self.currentZ = self.currentZ + 1
        elseif  self.currentX < self.mapSegments - 1 then -- Starting with row 0
            -- Next row
            self.currentX = self.currentX + 1
            self.currentZ = 0
        else
            -- Done with the loop, set up for the next one.
            self.currentX = 0
            self.currentZ = 0
            self.doGrowthTransition = false
        end
    end -- end of if self.doGrowthTransition == true then
end

function ssGrowthManager:draw()
end

function ssGrowthManager:growthStageChanged()

    if (self.growthManagerEnabled == true) then -- redundant but heyho
        local growthTransition = ssSeasonsUtil:currentGrowthTransition();
        log("GrowthManager enabled - growthStateChanged to: " .. growthTransition);
        self.currentGrowthTransitionPeriod = growthTransition;
        self.doGrowthTransition = true;
    end
end
