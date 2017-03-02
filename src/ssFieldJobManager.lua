---------------------------------------------------------------------------------------------------------
-- FieldJobManager SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  To disable the game's mission system
-- Authors:  theSeb
--

ssFieldJobManager = {}
g_seasons.fieldJobManager = ssFieldJobManager

ssFieldJobManager.disableMissions = true

function ssFieldJobManager:load(savegame, key)
    self.disableMissions = ssStorage.getXMLBool(savegame, key .. ".settings.disableMissions", true)
end

function ssFieldJobManager:save(savegame, key)
    if g_currentMission:getIsServer() == true then
        ssStorage.setXMLBool(savegame, key .. ".settings.disableMissions", self.disableMissions)
    end
end

function ssFieldJobManager:loadMap(name)
    for _,fieldDef in pairs(g_currentMission.fieldDefinitionBase.fieldDefs) do
        fieldDef.fieldJobUsageAllowed = not self.disableMissions
    end
end


