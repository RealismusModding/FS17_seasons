---------------------------------------------------------------------------------------------------------
-- SEASONS XML SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  For loading season parameters from mod, map or game
-- Authors:  theSeb, based on ssSeasonsXML by Rahkiin (Jarvixes)
--

ssGrowthManagerXML = {};

self.DEFAULT_FILE_PATH = "data/growth.xml";

function ssGrowthManagerXML:loadXMLData()

    
    local growthData = {};
    local rootKey = "growthManager";
    local path = ssSeasonsMod.modDir .. self.DEFAULT_FILE_PATH;

    log("Debug 1");
    local file = loadXMLFile("xml", path);
    log("Debug 2");
    if (file == nil) then
        logInfo("ssGrowthManagerXML: Failed to load XML growth data file " .. path);
        return nil;
    end

    local defaultFruits = self:getDefaultFruitsData(rootKey,file);
    local growthData = self:getGrowthData(rootKey, file);
    --todo check if nil
    
    return defaultFruits, growthData; 

end

function ssGrowthManagerXML:getGrowthData(rootKey, file)

end

function ssGrowthManagerXML:getDefaultFruitsData(rootKey, file)

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
                    logInfo("ssGrowthManager: XML loading failed. Is the growth data file malformed?");
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