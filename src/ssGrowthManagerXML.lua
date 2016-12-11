---------------------------------------------------------------------------------------------------------
-- SEASONS XML SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  For loading season parameters from mod, map or game
-- Authors:  theSeb, based on ssSeasonsXML by Rahkiin (Jarvixes)
--

ssGrowthManagerXML = {};

function ssSeasonsXML:loadFile(path, rootKey, elements, )--parentData, optional)

    local file = loadXMLFile("xml", path);

    if (file == nil) then
        logInfo("Failed to load Growth XML data file " .. path);
    end

    

end