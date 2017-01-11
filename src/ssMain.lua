---------------------------------------------------------------------------------------------------------
-- MAIN SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  Start the seasons, global functionality, modding functionality
-- Authors:  Rahkiin
--

ssMain = {}
getfenv(0)["g_seasons"] = ssMain -- Load in superglobal scope

function ssMain:load(savegame, key)
end

function ssMain:save(savegame, key)
end

function ssMain:loadMap()
end



-- Withering of the game is not actually used. To not cause any confusion, the withering toggle element
-- is disabled.
local function disableWitherOption(self)
    self.plantWitheringElement:setDisabled(true)
end
InGameMenu.updateGameSettings = Utils.appendedFunction(InGameMenu.updateGameSettings, disableWitherOption)
