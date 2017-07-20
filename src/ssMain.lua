----------------------------------------------------------------------------------------------------
-- MAIN SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  Start the seasons, global functionality, modding functionality
-- Authors:  Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssMain = {}

if g_seasons ~= nil then
    error("Seasons seems to be loaded already, and is trying to be loaded again. Make sure you only have one (1) Seasons mod selected in your mod selection screen.")
end

getfenv(0)["g_seasons"] = ssMain -- Load in superglobal scope

g_seasons.lang = ssLang
g_seasons.xmlUtil = ssXMLUtil
g_seasons.multiplayer = ssMultiplayer
g_seasons.xml = ssSeasonsXML

ssMain.SAVEGAME_VERSION = 3
ssMain.CONTEST_SAVEGAME_VERSION = 2

----------------------------
-- Installing injections and globals
----------------------------

function ssMain:preLoad()
    local modItem = ModsUtil.findModItemByModName(g_currentModName)
    self.modDir = g_currentModDirectory

    local buildnumber = nil --<%=buildnumber %>
    self.descVersion = Utils.getNoNil(modItem.version, "0.0.0.0")
    self.version = self.descVersion .. "-" .. tostring(buildnumber) .. " - " .. tostring(modItem.fileHash)

    -- Simple version number for comparing minimum required version of seasons
    self.simpleVersion = 2 --<%=simpleVersion %>

    -- Set global settings
    self.enabled = false -- will be enabled later in the loading process
    self.verbose = false --<%=verbose %>
    self.debug = false --<%=debug %>

    logInfo("Loading Seasons " .. self.version)

    ssMain.xmlDirectories = {}

    -- Do injections
    InGameMenu.updateGameSettings = Utils.appendedFunction(InGameMenu.updateGameSettings, self.inj_disableMenuOptions)

    -- Disable the tutorial by clearing showTourDialog
    -- This has to be here so it is loaded early before the map is loaded. Otherwise the method
    -- is already called.
    TourIcons.showTourDialog = function () end
end

----------------------------
-- Savegame
----------------------------

function ssMain:load(savegame, key)
    self.showControlsInHelpScreen = ssXMLUtil.getBool(savegame, key .. ".settings.showControlsInHelpScreen", true)

    self.savegameVersion = ssXMLUtil.getInt(savegame, key .. ".version", self.SAVEGAME_VERSION)
    if self.savegameVersion > self.SAVEGAME_VERSION then
        error("Your savegame was created with a newer version of the Seasons mod and cannot be loaded")
    end

    self.isNewSavegame = savegame == nil
    self.isOldSavegame = savegame ~= nil and not hasXMLProperty(savegame, key) -- old game, no seasons
end

function ssMain:save(savegame, key)
    ssXMLUtil.setBool(savegame, key .. ".settings.showControlsInHelpScreen", self.showControlsInHelpScreen)
    ssXMLUtil.setInt(savegame, key .. ".version", self.SAVEGAME_VERSION)
end

----------------------------
-- Multiplayer
----------------------------

function ssMain:readStream(streamId, connection)
    self.showControlsInHelpScreen = true
end

function ssMain:writeStream(streamId, connection)
end

----------------------------
-- Global controls, GUI
----------------------------

function ssMain:loadMap()
    -- Call upon all 4th party mod functions
    for modName, isLoaded in pairs(g_modIsLoaded) do
        if isLoaded then
            self:loadMod(modName)
        end
    end

    -- Create the GUI
    self.mainMenu = ssSeasonsMenu:new()

    -- Load additional GUI profiles
    g_gui:loadProfiles(self.modDir .. "resources/gui/profiles.xml")

    -- Load the GUI configurations
    g_gui:loadGui(self.modDir .. "resources/gui/SeasonsMenu.xml", "SeasonsMenu", self.mainMenu)
    FocusManager:setGui("MPLoadingScreen")

    -- Remove the (hacked) store items
    StoreItemsUtil.removeStoreItem(StoreItemsUtil.storeItemsByXMLFilename[string.lower(self.modDir .. "resources/fakeStoreItem/item.xml")].id)
    StoreItemsUtil.removeStoreItem(StoreItemsUtil.storeItemsByXMLFilename[string.lower(self.modDir .. "resources/fakeStoreItem/item2.xml")].id)

    if self.descVersion == "0.0.0.0" then
        local w, h = getNormalizedScreenValues(512, 128)
        self.devOverlay = Overlay:new("devOverlay", Utils.getFilename("resources/gui/dev.dds", self.modDir), 0, 0, w, h)
        self.devOverlay:setPosition(0.5, 1 - h / 15)
        self.devOverlay:setDimension(w / 4, h / 4)
        self.devOverlay:setAlignment(Overlay.ALIGN_VERTICAL_TOP, Overlay.ALIGN_HORIZONTAL_CENTER)
    end

    if g_currentMission:getIsServer() then
        self.loaded = true
    end
end

function ssMain:update(dt)
    if self.showControlsInHelpScreen then
        g_currentMission:addHelpButtonText(g_i18n:getText("input_SEASONS_SHOW_MENU"), InputBinding.SEASONS_SHOW_MENU, nil, GS_PRIO_VERY_LOW)
    end

    -- Open the menu
    if InputBinding.hasEvent(InputBinding.SEASONS_SHOW_MENU) then
        g_gui:showGui("SeasonsMenu")
    end

    -- A dedicated server must always reset growth
    if g_currentMission:getIsServer() and g_dedicatedServerInfo ~= nil and not self.isNewSaveGame and self.isOldSaveGame then
        ssGrowthManager:resetGrowth()
    elseif not self.isNewSavegame and self.isOldSavegame and not self.showedResetWarning and g_gui.currentGui == nil then
        function resetAction(self, yesNo)
            if yesNo then
                ssGrowthManager:resetGrowth()
            end

            g_gui:showGui("")
        end

        g_gui:showYesNoDialog({
            text = ssLang.getText("dialog_resetGrowth"),
            title = ssLang.getText("dialog_resetGrowth_title"),
            dialogType = DialogElement.TYPE_WARNING,
            callback = resetAction,
            target = self,
            yesText = ssLang.getText("dialog_resetGrowth_yes"),
            noText = ssLang.getText("dialog_resetGrowth_no")
        })

        self.showedResetWarning = true
    end
end

function ssMain:draw()
    if self.devOverlay then
        self.devOverlay:render()
    end
end

----------------------------
-- Registering other mods
----------------------------

function ssMain:loadMod(modName)
    local desc = ModsUtil.findModItemByModName(modName)
    local xmlFile = loadXMLFile("ModFile", desc.modFile);

    local modType = getXMLString(xmlFile, "modDesc.seasons.type");
    local dataFolder = getXMLString(xmlFile, "modDesc.seasons.dataFolder");
    local seasonsApiVersion = getXMLInt(xmlFile, "modDesc.seasons#version")

    delete(xmlFile)

    -- If it has a seasons block, use that
    if seasonsApiVersion ~= nil then
        if seasonsApiVersion > self.simpleVersion then
            logInfo("Error: Version of Seasons is lower than version in mod", modName)
            return
        end

        if modType == "geo" then
            if self.hasGeoMod then
                logInfo("Error: Multiple Seasons GEO mods are loaded. This is bad practice. Skipping to load", modName)
                return
            else
                self.hasGeoMod = true
            end
        end

        if dataFolder then
            self:registerXMLDirectory(modName, desc.modDir .. dataFolder)
        end
    end

    local modEnv = getfenv(0)[modName]

    if modEnv ~= nil and modEnv.g_rm_seasons_load ~= nil then
        modEnv.g_rm_seasons_load(self)
    end
end

function ssMain:registerXMLDirectory(id, path)
    if id == nil or id == "" or path == nil or path == "" then
        logInfo("Invalid parameters to :registerXMLDirectory")
        return
    end

    if self.xmlDirectories[id] ~= nil then
        logInfo("Error: XML directory for id '" .. tostring(id) .. "' already registered")
        return
    end

    self.xmlDirectories[id] = path
end

function ssMain:getModPaths(name)
    local ret = {}

    -- Map first
    if g_currentMission.missionInfo.map.isModMap then
        local mapPath = g_currentMission.missionInfo.map.baseDirectory .. "seasons_" .. name .. ".xml"
        if fileExists(mapPath) then
            table.insert(ret, mapPath)
        end
    end

    -- Then all mods, in order
    for id, prefix in pairs(self.xmlDirectories) do
        local path = prefix .. "seasons_" .. name .. ".xml"

        if fileExists(path) then
            table.insert(ret, path)
        end
    end

    return ret
end

----------------------------
-- Injection functions
----------------------------

-- Withering of the game is not actually used. To not cause any confusion, the withering toggle element
-- is disabled. Also, the new engine break system does not like the automatic engine start, so we disable
-- it all together as well. It does not fit with Realism anyways.
function ssMain.inj_disableMenuOptions(self)
    self.plantWitheringElement:setDisabled(true)
    self.plantWitheringElement:setIsChecked(true)

    self.motorStartElement:setIsChecked(false)
    self.motorStartElement:setDisabled(true)
end
