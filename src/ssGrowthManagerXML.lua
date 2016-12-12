---------------------------------------------------------------------------------------------------------
-- SEASONS XML SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  For loading season parameters from mod, map or game
-- Authors:  theSeb, based on ssSeasonsXML by Rahkiin (Jarvixes)
--

ssGrowthManagerXML = {};

function ssGrowthManagerXML:loadFile(path, rootKey, elements)--parentData, optional)

    local defaultFruits = {};
    log("Debug 1");
    local file = loadXMLFile("xml", path);
    log("Debug 2");
    if (file == nil) then
        logInfo("Failed to load Growth XML data file " .. path);
        return nil;
    end

    log("Debug 3");
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