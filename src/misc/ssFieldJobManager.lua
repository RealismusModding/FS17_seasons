---------------------------------------------------------------------------------------------------------
-- FieldJobManager SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  To disable the game's mission system
-- Authors:  theSeb
--

ssFieldJobManager = {}
g_seasons.fieldJobManager = ssFieldJobManager

function ssFieldJobManager:load(savegame, key)
    self.disableMissions = ssStorage.getXMLBool(savegame, key .. ".settings.disableMissions", true)
end

function ssFieldJobManager:save(savegame, key)
    ssStorage.setXMLBool(savegame, key .. ".settings.disableMissions", self.disableMissions)
end

function ssFieldJobManager:loadMap(name)
    if g_currentMission.fieldDefinitionBase.fieldDefs == nil then return end
    
    for _,fieldDef in pairs(g_currentMission.fieldDefinitionBase.fieldDefs) do
        fieldDef.fieldJobUsageAllowed = not self.disableMissions and fieldDef.fieldJobUsageAllowed
    end
end


