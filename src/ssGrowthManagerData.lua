---------------------------------------------------------------------------------------------------------
-- ssGrowthManagerData
---------------------------------------------------------------------------------------------------------
-- Purpose:  For loading season parameters from mod, map or game
-- Authors:  theSeb, based on ssSeasonsXML by Rahkiin (Jarvixes)
--

ssGrowthManagerData = {};

 ssGrowthManagerData.DEFAULT_FILE_PATH = "data/growth.xml";

function ssGrowthManagerData:loadData()

    
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
        logInfo("ssGrowthManagerData: Failed to load XML growth data file " .. path);
        return nil,nil;
    end

    local growthData = self:getGrowthData(rootKey, file);

    
    return defaultFruits, growthData; 

end

function ssGrowthManagerData:getGrowthData(rootKey, file)

end

function ssGrowthManagerData:getDefaultFruitsData(rootKey, file)

    local defaultFruits = {};


    local defaultFruitsKey =  rootKey .. ".defaultFruits";

    if hasXMLProperty(file, defaultFruitsKey) then
        log("GMXML: " .. defaultFruitsKey .. " found");
        local fruitNum = getXMLInt(file, defaultFruitsKey .. "#fruitNum");
        log("GMXML: fruitNum: " .. tostring(fruitNum));

        if fruitNum ~= nil then
            for i=0,fruitNum-1 do
                local defaultFruitKey = string.format("%s.defaultFruit(%i)#name", defaultFruitsKey, i);
                log("GMXML propKey: " .. defaultFruitKey);
                local fruitName = getXMLString(file, defaultFruitKey);
                if fruitName ~= nil then 
                    log("GMXML: " .. fruitName);
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