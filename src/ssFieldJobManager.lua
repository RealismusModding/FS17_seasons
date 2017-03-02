---------------------------------------------------------------------------------------------------------
-- FieldJobManager SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  To disable the game's mission system'
-- Authors:  theSeb
--

ssFieldJobManager = {}
g_seasons.fieldJobManager = ssFieldJobManager

function ssFieldJobManager:loadMap(name)
    for _,fieldDef in pairs(g_currentMission.fieldDefinitionBase.fieldDefs) do
        fieldDef.fieldJobUsageAllowed = false
    end
end


