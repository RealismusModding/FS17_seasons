---------------------------------------------------------------------------------------------------------
-- GROWTH MANAGER SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  to manage growth as the season changes
-- Authors:  theSeb
-- Credits: Inspired by upsidedown's growth manager mod

ssGrowthManager = {}

ssGrowthManager.MAX_STATE = 99; -- needs to be set to the fruit's numGrowthStates if you are setting, or numGrowthStates-1 if you're incrementing
ssGrowthManager.WITHERED = 300;
ssGrowthManager.CUT = 200;
ssGrowthManager.FIRST_LOAD_TRANSITION = 999;
ssGrowthManager.debugView = true;

function Set (list)
    local set = {}
    
    for _, l in ipairs(list) do 
        set[l] = true; 
    end

    return set
end

ssGrowthManager.defaultFruits = {};
ssGrowthManager.growthData = {};
ssGrowthManager.currentGrowthTransitionPeriod = nil;
ssGrowthManager.doGrowthTransition = false;
ssGrowthManager.doResetGrowth = false;

function ssGrowthManager:load(savegame, key)
    if savegame == nil then
        self.doResetGrowth = true;
    end

    self.growthManagerEnabled = ssStorage.getXMLBool(savegame, key .. ".settings.growthManagerEnabled", true);
end

function ssGrowthManager:save(savegame, key)
    if g_currentMission:getIsServer() == true then
        ssStorage.setXMLBool(savegame, key .. ".settings.growthManagerEnabled", self.growthManagerEnabled);
    end
end

function ssGrowthManager:loadMap(name)
    if self.growthManagerEnabled == false then
        log("ssGrowthManager: disabled");
        return
    end
    
    if g_currentMission:getIsServer() == true then
       if self:getGrowthData() == false then
            logInfo("ssGrowthManager: required data not loaded. ssGrowthManager disabled");
            return
        end

        logInfo("ssGrowthManager: Data loaded. Locking growth");
        --lock changing the growth speed option and set growth rate to 1 (no growth)
        g_currentMission:setPlantGrowthRate(1,nil);
        g_currentMission:setPlantGrowthRateLocked(true);
        ssSeasonsMod:addGrowthStageChangeListener(self)   

        if self.doResetGrowth == true then 
            self.currentGrowthTransitionPeriod = self.FIRST_LOAD_TRANSITION;
            self.doGrowthTransition = true;
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
end


function ssGrowthManager:getGrowthData()
    local defaultFruits,growthData = ssGrowthManagerData:loadAllData();
   
    if defaultFruits ~= nil then
        self.defaultFruits = Set(defaultFruits);
    else
        logInfo("ssGrowthManager: default fruits data not found");
        return false
    end

    if growthData ~= nil then
        self.growthData = growthData;
    else
        logInfo("ssGrowthManager: default growth data not found");
        return false
    end
    --print_r(self.growthData);
    --print_r(self.defaultFruits);
    return true
end

function ssGrowthManager:deleteMap()
end

function ssGrowthManager:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssGrowthManager:keyEvent(unicode, sym, modifier, isDown)
    --print(tostring(unicode));
    if (unicode == 47) then
        if self.debugView == false then
            self.debugView = true;
        else
            self.debugView = false;
        end
    --     -- for index,fruit in pairs(g_currentMission.fruits) do
    --     --     local desc = FruitUtil.fruitIndexToDesc[index]
    --     --     local fruitName = desc.name
    --     --     if (self.defaultFruits[fruitName] == nil) then
    --     --         log("GM: Fruit not found in default table: " .. fruitName);
    --     --     else
    --     --         log("GM: Fruit " .. fruitName .. " found");
    --     --     end
    --     -- end

    end
end

function ssGrowthManager:update(dt)
    if self.doGrowthTransition ~= true then
        return
    end
        
    local startWorldX =  self.currentX * g_currentMission.terrainSize / self.mapSegments - g_currentMission.terrainSize / 2;
    local startWorldZ =  self.currentZ * g_currentMission.terrainSize / self.mapSegments - g_currentMission.terrainSize / 2;
    local widthWorldX = startWorldX + g_currentMission.terrainSize / self.mapSegments - 0.1; -- -0.1 to avoid overlap.
    local widthWorldZ = startWorldZ;
    local heightWorldX = startWorldX;
    local heightWorldZ = startWorldZ + g_currentMission.terrainSize / self.mapSegments - 0.1; -- -0.1 to avoid overlap.

    for index,fruit in pairs(g_currentMission.fruits) do
        local desc = FruitUtil.fruitIndexToDesc[index];
        local fruitName = desc.name;

        local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(id, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ);

        --handling new unknown fruits
        if self.defaultFruits[fruitName] == nil then
            log("Fruit not found in default table: " .. fruitName);
            fruitName = "default";
        end

        if self.growthData[self.currentGrowthTransitionPeriod][fruitName] ~= nil then 
            --setGrowthState
            if self.growthData[self.currentGrowthTransitionPeriod][fruitName].setGrowthState ~= nil
                and self.growthData[self.currentGrowthTransitionPeriod][fruitName].desiredGrowthState ~= nil then
                    --log("FruitID " .. fruit.id .. " FruitName: " .. fruitName .. " - reset growth at season transition: " .. self.currentGrowthTransitionPeriod .. " between growth states " .. self.growthData[self.currentGrowthTransitionPeriod][fruitName].setGrowthState .. " and " .. self.growthData[self.currentGrowthTransitionPeriod][fruitName].setGrowthMaxState .. " to growth state: " .. self.growthData[self.currentGrowthTransitionPeriod][fruitName].setGrowthState)
                self:setGrowthState(fruit, fruitName, x, z, widthX, widthZ, heightX, heightZ);
            end
            --increment by 1 for crops between normalGrowthState  normalGrowthMaxState or for crops at normalGrowthState
            if self.growthData[self.currentGrowthTransitionPeriod][fruitName].normalGrowthState ~= nil then
                self:incrementGrowthState(fruit, fruitName, x, z, widthX, widthZ, heightX, heightZ);  
            end
            --increment by extraGrowthFactor between extraGrowthMinState and extraGrowthMaxState
            if self.growthData[self.currentGrowthTransitionPeriod][fruitName].extraGrowthMinState ~= nil
                    and self.growthData[self.currentGrowthTransitionPeriod][fruitName].extraGrowthMaxState ~= nil
                    and self.growthData[self.currentGrowthTransitionPeriod][fruitName].extraGrowthFactor ~= nil then
                self:incrementExtraGrowthState(fruit, fruitName, x, z, widthX, widthZ, heightX, heightZ)
            end
        end  -- end of if self.growthData[self.currentGrowthTransitionPeriod][fruitName] ~= nil then
    end  -- end of for index,fruit in pairs(g_currentMission.fruits) do

    if self.currentZ < self.mapSegments - 1 then -- Starting with column 0 So index of last column is one less then the number of columns.
        -- Next column
        self.currentZ = self.currentZ + 1;
    elseif  self.currentX < self.mapSegments - 1 then -- Starting with row 0
        -- Next row
        self.currentX = self.currentX + 1;
        self.currentZ = 0;
    else
        -- Done with the loop, set up for the next one.
        self.currentX = 0;
        self.currentZ = 0;
        self.doGrowthTransition = false;
    end
end


function ssGrowthManager:draw()
    if self.debugView == true then
        renderText(0.54, 0.98, 0.01, "GM enabled: " .. tostring(self.growthManagerEnabled) .. " doGrowthTransition: " .. tostring(self.doGrowthTransition));
        renderText(0.54, 0.96, 0.01, "Growth Transition: " .. tostring(ssSeasonsUtil:currentGrowthTransition()));
        local cropsThatCanGrow = "";
        
        for index,fruit in pairs(g_currentMission.fruits) do
            local desc = FruitUtil.fruitIndexToDesc[index];
            local fruitName = desc.name;   
            if self:canFruitGrow(fruitName, ssSeasonsUtil:currentGrowthTransition()+1) == true then
                cropsThatCanGrow = cropsThatCanGrow .. fruitName .. " ";
            end
        end 
        renderText(0.54, 0.94, 0.01, "Crops that will grow in next transtition if planted now: " .. cropsThatCanGrow);
    end
end


function ssGrowthManager:growthStageChanged()
    if self.growthManagerEnabled == true then -- redundant but heyho
        local growthTransition = ssSeasonsUtil:currentGrowthTransition();
        log("GrowthManager enabled - growthStateChanged to: " .. growthTransition);
        self.currentGrowthTransitionPeriod = growthTransition;
        self.doGrowthTransition = true;
    end
end

function ssGrowthManager:setGrowthState(fruit, fruitName, x, z, widthX, widthZ, heightX, heightZ)
    local minState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].setGrowthState;
    local desiredGrowthState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].desiredGrowthState;
    local fruitData = FruitUtil.fruitTypeGrowths[fruitName];

    if desiredGrowthState == self.WITHERED then
            desiredGrowthState = fruitData.witheringNumGrowthStates;
    end

    if desiredGrowthState == self.CUT then
        desiredGrowthState = fruitData.cutState;
    end

    if self.growthData[self.currentGrowthTransitionPeriod][fruitName].setGrowthMaxState ~= nil then
        local maxState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].setGrowthMaxState;
        
        if maxState == self.MAX_STATE then
            maxState = fruitData.numGrowthStates;
        end
        setDensityMaskParams(fruit.id, "between",minState,maxState);
    else
        setDensityMaskParams(fruit.id, "equals",minState);
    end

    local numChannels = g_currentMission.numFruitStateChannels;
    local sum = setDensityMaskedParallelogram(fruit.id,x,z, widthX,widthZ, heightX,heightZ,0, numChannels, fruit.id, 0, numChannels, desiredGrowthState);
end

--increment by 1 for crops between normalGrowthState  normalGrowthMaxState or for crops at normalGrowthState
function ssGrowthManager:incrementGrowthState(fruit, fruitName, x, z, widthX, widthZ, heightX, heightZ)
    local minState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].normalGrowthState;

    if self.growthData[self.currentGrowthTransitionPeriod][fruitName].normalGrowthMaxState ~= nil then
        local fruitData = FruitUtil.fruitTypeGrowths[fruitName];
        local maxState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].normalGrowthMaxState;

        if maxState == self.MAX_STATE then
            maxState = fruitData.numGrowthStates-1;
        end
        setDensityMaskParams(fruit.id, "between",minState,maxState);
    else
        setDensityMaskParams(fruit.id, "equals",minState);
    end

    local numChannels = g_currentMission.numFruitStateChannels;
    local sum = addDensityMaskedParallelogram(fruit.id,x,z, widthX,widthZ, heightX,heightZ, 0, numChannels, fruit.id, 0, numChannels, 1);
end

--increment by extraGrowthFactor between extraGrowthMinState and extraGrowthMaxState
function ssGrowthManager:incrementExtraGrowthState(fruit, fruitName, x, z, widthX, widthZ, heightX, heightZ)
    local minState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].extraGrowthMinState;
    local maxState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].extraGrowthMaxState;
    setDensityMaskParams(fruit.id, "between",minState,maxState);

    local extraGrowthFactor = self.growthData[self.currentGrowthTransitionPeriod][fruitName].extraGrowthFactor;
    local numChannels = g_currentMission.numFruitStateChannels;
    local sum = addDensityMaskedParallelogram(fruit.id,x,z, widthX,widthZ, heightX,heightZ, 0, numChannels, fruit.id, 0, numChannels, extraGrowthFactor);
end

function ssGrowthManager:canFruitGrow(fruitName, growthTransition)
    
    if self.growthData[growthTransition][fruitName] == nil then
        return false
    end

    if self.growthData[growthTransition][fruitName].normalGrowthState == 1 then
        return true
    end
    return false
end

function ssGrowthManager:buildCanFruitGrowTable()
    --for each possible fruit
    --for each transition (when it was planted)
    local plantedGrowthTransition = 1; --part of for loop (when it was planted)
    local currentGrowthStage = 1;
    local fruitNumStates = 7; --numGrowthStates
    local fruitName = "barley";
    local maxTransitionsToCheck = 12;
    local transitionToCheck = plantedGrowthTransition + 1; -- need to check the next transition after the planted
    
    while currentGrowthStage < fruitNumStates do --TODO add break safety counter
        if transitionToCheck > 12 then
            transitionToCheck = 1;
        end

        if self.growthData[transitionToCheck][fruitName] ~= nil then
            local growth = self:canGrow(fruitName, transitionToCheck, currentGrowthStage)
            if growth > 0 then
                currentGrowthStage = currentGrowthStage + growth;
            end
        end
                
        transitionToCheck = transitionToCheck + 1;
        end
end


function ssGrowthManagerData:canGrow(transitionToCheck, fruitName, currentGrowthStage)

    return 0
end
