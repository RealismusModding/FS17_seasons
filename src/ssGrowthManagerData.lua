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

        --load each transitions
        for i=0, transitionsNum-1 do
            local growthTransitionKey = string.format("%s.gt(%i)", growthTransitionsKey, i);
            log("GMXML growthData growthTransitionKey:", growthTransitionKey);

            local growthStageNum = getXMLInt(file,growthTransitionKey .. "#growthStageNum");
            log("GMXML growthData growthStageNum:", growthStageNum);

            local cropsNum =  getXMLInt(file,growthTransitionKey .. "#cropsNum");
            log("GMXML growthData cropsNum:", cropsNum);
            --number of crops in growth transitions
             
            --load each crop
        end


        log("GMXML growthData: transitions num:" .. tostring(transitionsNum));


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