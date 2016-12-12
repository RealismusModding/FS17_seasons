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
    local rootKey = "growthManager";
    local path = ssSeasonsMod.modDir .. self.DEFAULT_FILE_PATH;
    
    local file = loadXMLFile("xml", path);
    
    if (file == nil) then
        logInfo("ssGrowthManagerData: Failed to load XML growth data file " .. path);
        return nil;
    end

    local defaultFruits = self:getDefaultFruitsData(rootKey,file);
    if defaultFruits == nil then
        logInfo("ssGrowthManagerData: Failed to load XML growth data file (defaultFruits) " .. path);
        return nil,nil;
    end

    local growthData = self:getGrowthData(rootKey, file);

    
    return defaultFruits, growthData; 

end

function ssGrowthManagerData:getGrowthData(rootKey, file)
    local growthData = {};

    local growthTransitionsKey = rootKey .. ".growthTransitions";

    if hasXMLProperty(file,growthTransitionsKey) then
        log("GMXML growthData: " .. growthTransitionsKey .. " found");    

        local transitionsNum = getXMLInt(file,growthTransitionsKey .. "#transitionsNum");
        if transitionsNum == nil then
            log("GMXML growthData: could not load transitionsNum");
        end
        
        log("GMXML growthData: transitions num:" .. tostring(transitionsNum));

        --load each transitions
        for i=0, transitionsNum-1 do
            local growthTransitionKey = string.format("%s.gt(%i)", growthTransitionsKey, i);
            log("GMXML growthData growthTransitionKey:", growthTransitionKey);

            local growthTransitionNumKey = growthTransitionKey .. "#growthTransitionNum"
            local growthTransitionNum = getXMLInt(file,growthTransitionNumKey);
            if growthTransitionNum == nil then
                logInfo("ssGrowthManagerData: XML loading failed " .. growthTransitionNumKey);  
                return nil; 
            end

            log("GMXML growthData growthTransitionNum:", growthTransitionNum);
            
            --number of fruits in growth transitions
            local fruitsNumKey = growthTransitionKey .. "#fruitsNum"
            
            local fruitsNum =  getXMLInt(file,fruitsNumKey);
            if fruitsNum == nil then
                logInfo("ssGrowthManagerData: XML loading failed " .. fruitsNumKey);  
                return nil;     
            end

            log("GMXML growthData fruitsNum:", fruitsNum);

            --load each fruit

            for fruit=0,fruitsNum-1 do
                local fruitKey = string.format("%s.fruit(%i)", growthTransitionKey, fruit);
                local fruitName = getXMLString(file,fruitKey .. "#fruitName")
                if fruitName == nil then
                    logInfo("ssGrowthManagerData: XML loading failed " .. fruitKey); 
                    return nil;
                end

                log("GMXML: fruit: " .. fruitName .. " transition: " .. i+1)
                
                local normalGrowthState = getXMLInt(file,fruitKey .. "#normalGrowthState");
                if normalGrowthState ~= nil then 
                    log("GMXML: normalGrowthState: " .. normalGrowthState);
                end

                local normalGrowthMaxState =  getXMLInt(file,fruitKey .. "#normalGrowthMaxState");
                if normalGrowthMaxState ~= nil then 
                    log("GMXML: normalGrowthMaxState: " .. normalGrowthMaxState);
                end

                local setGrowthState =  getXMLInt(file,fruitKey .. "#setGrowthState");
                if setGrowthState ~= nil then 
                    log("GMXML: setGrowthState: " .. setGrowthState);
                end

                local desiredGrowthState =  getXMLInt(file,fruitKey .. "#desiredGrowthState");
                if desiredGrowthState ~= nil then 
                    log("GMXML: desiredGrowthState: " .. desiredGrowthState);
                end

            end -- for fruit=0,fruitsNum-1 do
        end -- for i=0, transitionsNum-1 do


        


    else
        log("GMXML: " .. growthTransitionsKey .. " NOT FOUND");
        return nil;
    end

    return growthData;

end

function ssGrowthManagerData:getDefaultFruitsData(rootKey, file)

    local defaultFruits = {};


    local defaultFruitsKey =  rootKey .. ".defaultFruits";

    if hasXMLProperty(file, defaultFruitsKey) then
       -- log("GMXML: " .. defaultFruitsKey .. " found");
        local fruitNum = getXMLInt(file, defaultFruitsKey .. "#fruitNum");
        --log("GMXML: fruitNum: " .. tostring(fruitNum));

        if fruitNum ~= nil then
            for i=0,fruitNum-1 do
                local defaultFruitKey = string.format("%s.defaultFruit(%i)#name", defaultFruitsKey, i);
                --log("GMXML propKey: " .. defaultFruitKey);
                local fruitName = getXMLString(file, defaultFruitKey);
                if fruitName ~= nil then 
                    --log("GMXML: " .. fruitName);
                    table.insert(defaultFruits,fruitName);
                else
                    logInfo("ssGrowthManagerData: XML loading failed. Is the growth data file malformed?");
                    return nil;
                end


            end
        end
    else
        log("GMXML: " .. defaultFruitsKey .. " not found");
        return nil;
    end

    
    
    return defaultFruits; 

end