---------------------------------------------------------------------------------------------------------
-- MAIN SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  Start the seasons, global functionality, modding functionality
-- Authors:  Rahkiin
--

ssMain = {}
getfenv(0)["g_seasons"] = ssMain -- Load in superglobal scope

----------------------------
-- Constants
----------------------------

----------------------------
-- Installing injections and globals
----------------------------

function ssMain:preLoad()
    local modItem = ModsUtil.findModItemByModName(g_currentModName)
    self.modDir = g_currentModDirectory

    local buildnumber = false--<%=buildnumber %>
    self.version = Utils.getNoNil(modItem.version, "?.?.?.?") .. "-" .. tostring(buildnumber) .. " - " .. tostring(modItem.fileHash)

    -- Set global settings
    self.verbose = false--<%=verbose %>
    self.debug = false--<%=debug %>
    self.enabled = false -- will be enabled later in the loading process

    logInfo("Loading Seasons " .. self.version);

    -- Do injections
    InGameMenu.updateGameSettings = Utils.appendedFunction(InGameMenu.updateGameSettings, self.inj_disableWitherOption)
    TourIcons.onCreate = self.inj_disableTourIcons
end

----------------------------
-- Savegame
----------------------------

function ssMain:load(savegame, key)
    self.showControlsInHelpScreen = ssStorage.getXMLBool(savegame, key .. ".settings.showControlsInHelpScreen", true)
end

function ssMain:save(savegame, key)
    ssStorage.setXMLBool(savegame, key .. ".settings.showControlsInHelpScreen", self.showControlsInHelpScreen)
end

----------------------------
-- Multiplayer
----------------------------

function ssMain:readStream(streamId, connection)
end

function ssMain:writeStream(streamId, connection)
end

----------------------------
-- Global controls, GUI
----------------------------

function ssMain:loadMap()
    -- Create the GUI
    self.mainMenu = ssSeasonsMenu:new()

    -- Load additional GUI profiles
    g_gui:loadProfiles(self.modDir .. "resources/gui/profiles.xml")

    -- Load the GUI configurations
    g_gui:loadGui(self.modDir .. "resources/gui/SeasonsMenu.xml", "SeasonsMenu", self.mainMenu)

    -- Add day change listener for Season events
    g_currentMission.environment:addDayChangeListener(self)
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

function ssMain:dayChanged()
end

----------------------------
-- Injection functions
----------------------------

-- Withering of the game is not actually used. To not cause any confusion, the withering toggle element
-- is disabled.
function ssMain.inj_disableWitherOption(self)
    self.plantWitheringElement:setDisabled(true)
    self.plantWitheringElement:setIsChecked(true)
end

-- Disable the tutorial by clearing the onCreate function that is called by vanilla maps
-- This has to be here so it is loaded early before the map is loaded. Otherwise the method
-- is already called.
function ssMain.inj_disableTourIcons(self, id)
    local tourIcons = TourIcons:new(id)
    tourIcons.visible = false
end

----------------------------
-- Important data
----------------------------
