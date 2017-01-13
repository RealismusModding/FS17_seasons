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

ssMain.DAYS_IN_WEEK = 7
ssMain.SEASONS_IN_YEAR = 4

ssMain.SEASON_SPRING = 0 -- important to start at 0, not 1
ssMain.SEASON_SUMMER = 1
ssMain.SEASON_AUTUMN = 2
ssMain.SEASON_WINTER = 3

----------------------------
-- Installing injections and globals
----------------------------

function ssMain:preLoad()
    local modItem = ModsUtil.findModItemByModName(g_currentModName)
    self.modDir = g_currentModDirectory

    local buildnumber = --<%=buildnumber %>
    self.version = Utils.getNoNil(modItem.version, "?.?.?.?") .. "-" .. buildnumber .. " - " .. tostring(modItem.fileHash)

    -- Set global settings
    self.verbose = --<%=verbose %>
    self.debug = --<%=debug %>
    self.enabled = false -- will be enabled later in the loading process

    logInfo("Loading Seasons " .. self.version);

    -- Do injections
    InGameMenu.updateGameSettings = Utils.appendedFunction(InGameMenu.updateGameSettings, self.inj_disableWitherOption)
    TourIcons.onCreate = self.inj_disableTourIcons

    -- Add values that depend on other classes
    self.dayNames = {
        ssLang.getText("SS_WEEKDAY_MONDAY", "Monday"),
        ssLang.getText("SS_WEEKDAY_TUESDAY", "Tuesday"),
        ssLang.getText("SS_WEEKDAY_WEDNESDAY", "Wednesday"),
        ssLang.getText("SS_WEEKDAY_THURSDAY", "Thursday"),
        ssLang.getText("SS_WEEKDAY_FRIDAY", "Friday"),
        ssLang.getText("SS_WEEKDAY_SATURDAY", "Saturday"),
        ssLang.getText("SS_WEEKDAY_SUNDAY", "Sunday"),
    }

    self.shortDayNames = {
        ssLang.getText("SS_WEEKDAY_MON", "Mon"),
        ssLang.getText("SS_WEEKDAY_TUE", "Tue"),
        ssLang.getText("SS_WEEKDAY_WED", "Wed"),
        ssLang.getText("SS_WEEKDAY_THU", "Thu"),
        ssLang.getText("SS_WEEKDAY_FRI", "Fri"),
        ssLang.getText("SS_WEEKDAY_SAT", "Sat"),
        ssLang.getText("SS_WEEKDAY_SUN", "Sun"),
    }

    self.seasonNames = {
        [0] = ssLang.getText("SS_SEASON_SPRING", "Spring"),
        ssLang.getText("SS_SEASON_SUMMER", "Summer"),
        ssLang.getText("SS_SEASON_AUTUMN", "Autumn"),
        ssLang.getText("SS_SEASON_WINTER", "Winter"),
    }
end

----------------------------
-- Savegame
----------------------------

function ssMain:load(savegame, key)
    self.showControlsInHelpScreen = ssStorage.getXMLBool(savegame, key .. ".settings.showControlsInHelpScreen", true)

    self.daysInSeason = Utils.clamp(ssStorage.getXMLInt(savegame, key .. ".settings.daysInSeason", 9), 3, 12)
    self.latestSeason = ssStorage.getXMLInt(savegame, key .. ".settings.latestSeason", -1)
    self.latestGrowthStage = ssStorage.getXMLInt(savegame, key .. ".settings.latestGrowthStage", 0)
    self.currentDayOffset = ssStorage.getXMLInt(savegame, key .. ".settings.currentDayOffset_DO_NOT_CHANGE", 0)

    -- todo: replace with
    self.isNewGame = savegame == nil
    log("Is enw savegame " .. tostring(g_savegameXML) .. tostring(g_savegamePath))
end

function ssMain:save(savegame, key)
    ssStorage.setXMLBool(savegame, key .. ".settings.showControlsInHelpScreen", self.showControlsInHelpScreen)

    ssStorage.setXMLInt(savegame, key .. ".settings.daysInSeason", self.daysInSeason)
    ssStorage.setXMLInt(savegame, key .. ".settings.latestSeason", self.latestSeason)
    ssStorage.setXMLInt(savegame, key .. ".settings.latestGrowthStage", self.latestGrowthStage)
    ssStorage.setXMLInt(savegame, key .. ".settings.currentDayOffset_DO_NOT_CHANGE", self.currentDayOffset)
end

----------------------------
-- Multiplayer
----------------------------

function ssMain:readStream(streamId, connection)
    self.daysInSeason = streamReadInt32(streamId)
    self.latestSeason = streamReadInt32(streamId)
    self.latestGrowthStage = streamReadInt32(streamId)
    self.currentDayOffset = streamReadInt32(streamId)
end

function ssMain:writeStream(streamId, connection)
    streamWriteInt32(streamId, self.daysInSeason)
    streamWriteInt32(streamId, self.latestSeason)
    streamWriteInt32(streamId, self.latestGrowthStage)
    streamWriteInt32(streamId, self.currentDayOffset)
end

----------------------------
-- Global controls, GUI
----------------------------

function ssMain:loadMap()
    self.seasonListeners = {}
    self.growthStageListeners = {}

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
    if g_savegameXML == nil and not self._doneInitalDayEvent then
        self:callListeners()
        self._doneInitalDayEvent = true
    end

    if self.showControlsInHelpScreen then
        g_currentMission:addHelpButtonText(g_i18n:getText("input_SEASONS_SHOW_MENU"), InputBinding.SEASONS_SHOW_MENU)
    end

    -- Open the menu
    if InputBinding.hasEvent(InputBinding.SEASONS_SHOW_MENU) then
        g_gui:showGui("SeasonsMenu")
    end
end

----------------------------
-- Seasons events
----------------------------

function ssMain:callListeners()
    if g_seasons.enabled then
        local currentSeason = self:season()

        local currentGrowthStage = self:currentGrowthStage()

        -- Call season change events
        if currentSeason ~= self.latestSeason then
            self.latestSeason = currentSeason

            for _, target in pairs(self.seasonListeners) do
                -- No check here, let it crash if the function is missing
                target.seasonChanged(target)
            end
        end

        -- Call growth stage events
        if currentGrowthStage ~= self.latestGrowthStage then
            self.latestGrowthStage = currentGrowthStage

            for _, target in pairs(self.growthStageListeners) do
                -- No check here, let it crash if the function is missing
                target.growthStageChanged(target)
            end
        end
    end
end

-- Listeners for a change of season
function ssMain:addSeasonChangeListener(target)
    if target ~= nil then
        table.insert(self.seasonListeners, target)
    end
end

function ssMain:removeSeasonChangeListener(target)
    if target ~= nil then
        for i = 1, #self.seasonListeners do
            if self.seasonListeners[i] == target then
                table.remove(self.seasonListeners, i)
                break
            end
        end
    end
end

-- Listeners for a change of growth stage
function ssMain:addGrowthStageChangeListener(target)
    if target ~= nil then
        table.insert(self.growthStageListeners, target)
    end
end

function ssMain:removeGrowthStageChangeListener(target)
    if target ~= nil then
        for i = 1, #self.growthStageListeners do
            if self.growthStageListeners[i] == target then
                table.remove(self.growthStageListeners, i)
                break
            end
        end
    end
end

function ssMain:dayChanged()
    self:callListeners()
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
