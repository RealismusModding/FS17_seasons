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
    end

    log("Debug 3");
    local defaultFruitKey =  rootKey .. ".defaultFruits";

    if hasXMLProperty(file, defaultFruitKey) then
        log("GMXML: " .. defaultFruitKey .. " found");
        local fruitNum = getXMLInt(file, defaultFruitKey .. "#fruitNum");
        log("GMXML: fruitNum: " .. tostring(fruitNum));

        if fruitNum ~= nil then
            for i=0,fruitNum-1 do
                local childKey = string.format("%s.defaultFruit(%i)#name", defaultFruitKey, i);
                log("GMXML propKey: " .. childKey);
                local fruitName = getXMLString(file, childKey);
                log("GMXML: " .. fruitName);
                table.insert(defaultFruits,fruitName);

            end
        end
    else
        log("GMXML: " .. defaultFruitKey .. " not found");
    end

    
    
    return defaultFruits; 

end