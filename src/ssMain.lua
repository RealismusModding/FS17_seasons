---------------------------------------------------------------------------------------------------------
-- MAIN SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  Start the seasons, global functionality, modding functionality
-- Authors:  Rahkiin
--

ssMain = {}
getfenv(0)["g_seasons"] = ssMain -- Load in superglobal scope

function ssMain:load(savegame, key)
    self.showControlsInHelpScreen = ssStorage.getXMLBool(savegame, key .. ".settings.showControlsInHelpScreen", true)
end

function ssMain:save(savegame, key)
    ssStorage.setXMLBool(savegame, key .. ".settings.showControlsInHelpScreen", self.showControlsInHelpScreen)
end

function ssMain:loadMap()
end

function ssMain:update(dt)
    if self.showControlsInHelpScreen then
        g_currentMission:addHelpButtonText(g_i18n:getText("input_SEASONS_SHOW_MENU"), InputBinding.SEASONS_SHOW_MENU)
    end

    -- Open the menu
    if InputBinding.hasEvent(InputBinding.SEASONS_SHOW_MENU) then
        g_gui:showGui("SeasonsMenu")
    end
end

-- Withering of the game is not actually used. To not cause any confusion, the withering toggle element
-- is disabled.
local function disableWitherOption(self)
    self.plantWitheringElement:setDisabled(true)
    self.plantWitheringElement:setIsChecked(true)
end
InGameMenu.updateGameSettings = Utils.appendedFunction(InGameMenu.updateGameSettings, disableWitherOption)

-- Disable the tutorial by clearing the onCreate function that is called by vanilla maps
-- This has to be here so it is loaded early before the map is loaded. Otherwise the method
-- is already called.
function TourIcons.onCreate = function (self, id)
    local tourIcons = TourIcons:new(id)
    tourIcons.visible = false
end

