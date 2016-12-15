---------------------------------------------------------------------------------------------------------
-- ssGrowthManagerData
---------------------------------------------------------------------------------------------------------
-- Purpose:  For loading growth data
-- Authors:  theSeb, based on ssSeasonsXML by Rahkiin (Jarvixes)
--

ssGrowthManagerData = {};

 ssGrowthManagerData.DEFAULT_FILE_PATH = "data/growth.xml";

function ssGrowthManagerData:loadAllData()
    local growthData = {};
    local path = nil;
    local rootKey = "growthManager";

    local modMapDataPath = ssSeasonsUtil:getModMapDataPath("seasons_growth.xml"); 
    if  modMapDataPath ~= nil then
        path = modMapDataPath;
    else
        path = ssSeasonsMod.modDir .. self.DEFAULT_FILE_PATH;
    end

    local file = loadXMLFile("xml", path); 
    
    if file == nil then
        logInfo("ssGrowthManagerData: Failed to load XML growth data file " .. path);
        return nil,nil
    end

    local defaultFruits = self:getDefaultFruitsData(rootKey,file);
    if defaultFruits == nil then
        logInfo("ssGrowthManagerData: Failed to load XML growth data file (defaultFruits) " .. path);
        return nil,nil
    end

    local growthData = self:getGrowthData(rootKey, file);
    if growthData == nil then
        logInfo("ssGrowthManagerData: Failed to load XML growth data file (growthTransitions) " .. path);
        return nil,nil
    end
   
    return defaultFruits, growthData 
end

function ssGrowthManagerData:getGrowthData(rootKey, file)
    local growthData = {};

    local growthTransitionsKey = rootKey .. ".growthTransitions";

    if hasXMLProperty(file,growthTransitionsKey) then

        local transitionsNum = getXMLInt(file,growthTransitionsKey .. "#transitionsNum");
        if transitionsNum == nil then
            logInfo("ssGrowthManagerData: getGrowthData: could not load transitionsNum");
        end

        --load each transitions
        for i=0, transitionsNum-1 do
            local growthTransitionKey = string.format("%s.gt(%i)", growthTransitionsKey, i);
            
            local growthTransitionNumKey = growthTransitionKey .. "#growthTransitionNum";
            local growthTransitionNum = getXMLInt(file,growthTransitionNumKey);
            if growthTransitionNum == nil then
                logInfo("ssGrowthManagerData: getGrowthData: XML loading failed " .. growthTransitionNumKey);  
                return nil
            end

            --insert growth transition into datatable
            table.insert( growthData, growthTransitionNum, {});
            
            --number of fruits in growth transitions
            local fruitsNumKey = growthTransitionKey .. "#fruitsNum"
            
            local fruitsNum =  getXMLInt(file,fruitsNumKey);
            if fruitsNum == nil then
                logInfo("ssGrowthManagerData: getGrowthData: XML loading failed " .. fruitsNumKey);  
                return nil    
            end
            
            growthData = self:getFruitsTransitionStates(growthTransitionKey, file, fruitsNum, growthTransitionNum, growthData);
        end -- for i=0, transitionsNum-1 do
    else
        logInfo("ssGrowthManagerData: getGrowthData: XML loading failed " .. growthTransitionsKey .. " not found");
        return nil
    end

    return growthData
end

function ssGrowthManagerData:getFruitsTransitionStates(growthTransitionKey, file, fruitsNum, growthTransitionNum, parentData)
    local growthData = parentData;
    
    --load each fruit
    for fruit=0,fruitsNum-1 do
        local fruitKey = string.format("%s.fruit(%i)", growthTransitionKey, fruit);
        
        local fruitName = getXMLString(file,fruitKey .. "#fruitName");
        if fruitName == nil then
            logInfo("ssGrowthManagerData: getGrowthData: XML loading failed " .. fruitKey); 
            return nil
        end

        growthData[growthTransitionNum][fruitName] = {};
        growthData[growthTransitionNum][fruitName].fruitName = fruitName;
        
        local normalGrowthState = getXMLInt(file,fruitKey .. "#normalGrowthState");
        if normalGrowthState ~= nil then 
            growthData[growthTransitionNum][fruitName].normalGrowthState = normalGrowthState;
        end


        local normalGrowthMaxState =  getXMLString(file,fruitKey .. "#normalGrowthMaxState");
        if normalGrowthMaxState ~= nil then 
            if normalGrowthState == "MAX_STATE" then
                growthData[growthTransitionNum][fruitName].normalGrowthMaxState = ssGrowthManager.MAX_GROWTH_STATE;
            else
                growthData[growthTransitionNum][fruitName].normalGrowthMaxState = tonumber(normalGrowthMaxState);    
            end
        end

        local setGrowthState =  getXMLInt(file,fruitKey .. "#setGrowthState");
        if setGrowthState ~= nil then 
            growthData[growthTransitionNum][fruitName].setGrowthState = setGrowthState;
        end

        local setGrowthMaxState =  getXMLInt(file,fruitKey .. "#setGrowthMaxState");
        if setGrowthMaxState ~= nil then 
            --growthData[growthTransitionNum][fruitName].setGrowthMaxState = setGrowthMaxState;
            if setGrowthMaxState == "MAX_STATE" then
                growthData[growthTransitionNum][fruitName].setGrowthMaxState = ssGrowthManager.MAX_GROWTH_STATE;
            else
                growthData[growthTransitionNum][fruitName].setGrowthMaxState = tonumber(setGrowthMaxState);    
            end
        end

        local desiredGrowthState =  getXMLString(file,fruitKey .. "#desiredGrowthState");
        if desiredGrowthState ~= nil then 
            if desiredGrowthState == "CUT" then
                growthData[growthTransitionNum][fruitName].desiredGrowthState = ssGrowthManager.CUT_STATE;    
            elseif desiredGrowthState == "WITHERED" then
                growthData[growthTransitionNum][fruitName].desiredGrowthState = ssGrowthManager.WITHER_STATE;
            else
                growthData[growthTransitionNum][fruitName].desiredGrowthState = tonumber(desiredGrowthState);
            end
            --growthData[growthTransitionNum][fruitName].desiredGrowthState = desiredGrowthState;
        end

        local extraGrowthMinState = getXMLInt(file,fruitKey .. "#extraGrowthMinState");
        if extraGrowthMinState ~= nil then 
            growthData[growthTransitionNum][fruitName].extraGrowthMinState = extraGrowthMinState;
        end 

        local extraGrowthMaxState = getXMLInt(file,fruitKey .. "#extraGrowthMaxState");
        if extraGrowthMaxState ~= nil then 
            growthData[growthTransitionNum][fruitName].extraGrowthMinState = extraGrowthMinState;
        end

        local extraGrowthFactor = getXMLInt(file,fruitKey .. "#extraGrowthFactor");
        if extraGrowthFactor ~= nil then 
            growthData[growthTransitionNum][fruitName].extraGrowthFactor = extraGrowthFactor;
        end
    end -- for fruit=0,fruitsNum-1 do

    return growthData
end

function ssGrowthManagerData:getDefaultFruitsData(rootKey, file)
    local defaultFruits = {};
    local defaultFruitsKey =  rootKey .. ".defaultFruits";

    if hasXMLProperty(file, defaultFruitsKey) then
        local fruitsNum = getXMLInt(file, defaultFruitsKey .. "#fruitsNum");

        if fruitsNum ~= nil then
            for i=0,fruitsNum-1 do
                local defaultFruitKey = string.format("%s.defaultFruit(%i)#name", defaultFruitsKey, i);
                local fruitName = getXMLString(file, defaultFruitKey);
                if fruitName ~= nil then 
                    table.insert(defaultFruits,fruitName);
                else
                    logInfo("ssGrowthManagerData: getDefaultFruitsData: XML loading failed " .. defaultFruitKey );
                    return nil
                end
            end
        end
    else
        log("ssGrowthManagerData: getDefaultFruitsData: XML loading failed " .. defaultFruitsKey .. " not found");
        return nil
    end
    
    return defaultFruits 
end