---------------------------------------------------------------------------------------------------------
-- SEASONS MENU SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  GUI
-- Authors:  Rahkiin

ssSeasonsMenu = {}

local ssSeasonsMenu_mt = Class(ssSeasonsMenu, ScreenElement)

source(g_currentModDirectory .. "src/events/ssSettingsEvent.lua")

function ssSeasonsMenu:new(target, custom_mt)
    if custom_mt == nil then
        custom_mt = ssSeasonsMenu_mt
    end
    local self = ScreenElement:new(target, custom_mt)

    self.currentPageId = 1
    self.currentPageMappingIndex = 1

    self.settingElements = {}

    return self
end

function ssSeasonsMenu:onCreate(gui)

end

function ssSeasonsMenu:onCreatePageState(element)
    if self.pageStateElement == nil then
        self.pageStateElement = element
    end
end

function ssSeasonsMenu:onOpen(element)
    ssSeasonsMenu:superClass().onOpen(self)

    if g_currentMission ~= nil then
        g_currentMission:setCurrentSoundState(true)

        -- setup menus
        self:updatePages()
    end

    -- layout
    self:setPageStates()
    self:updatePageStates()

    self:updateServerSettingsVisibility()

    -- settings
    self:updateGameSettings()
    self:updateApplySettingsButton()

    self:updateDebugValues()

    -- Todo: get these values from the XML file. This is messy
    local titles = {ssLang.getText("ui_pageOverview"), ssLang.getText("ui_pageSettings")}
    if g_seasons.debug then
        table.insert(titles, ssLang.getText("ui_pageDebug"))
    end
    self.pageSelector:setTexts(titles)

    self.pageSelector:setState(self.currentPageMappingIndex, true)
end

function ssSeasonsMenu:onClose(element)
    ssSeasonsMenu:superClass().onClose(self)

    self.mouseDown = false

    if g_currentMission ~= nil then
        g_currentMission:setCurrentSoundState(false)
    end
end

-- Close the menu when the player clicks 'Back'
function ssSeasonsMenu:onClickBack()
    ssSeasonsMenu:superClass().onClickBack(self)

    g_gui:showGui("")
end

-- Update the current page when the player clicks the left/right button
function ssSeasonsMenu:onClickPageSelection(state)
    self.pagingElement:setPage(state)
end

-- Update the visible pages
function ssSeasonsMenu:updatePages()
    self.pagingElement:setPageIdDisabled(ssSeasonsMenu.PAGE_DEBUG, not g_seasons.debug)
end

-- Called when the current page has changed.
-- In this code, the focus is updated for the newly visible page
function ssSeasonsMenu:onPageChange(pageId, pageMappingIndex)
    self.currentPageId = pageId
    self.currentPageMappingIndex = pageMappingIndex
    self:updatePageStates()

    self.saveButton:setVisible(pageId == ssSeasonsMenu.PAGE_SETTINGS)

    if pageId == ssSeasonsMenu.PAGE_OVERVIEW then
        -- self:setNavButtonsFocusChange(FocusManager:getElementById("10"), FocusManager:getElementById("41_1"))
    elseif pageId == ssSeasonsMenu.PAGE_SETTINGS then
        self:setNavButtonsFocusChange(FocusManager:getElementById("200"), FocusManager:getElementById("221"))
    else
        self:setNavButtonsFocusChange(nil, nil)
    end

    self:updateToolTipBox(self.currentPageId)
end

-- Update the tiny balls at the bottom to indicate the current page
function ssSeasonsMenu:updatePageStates()
    for index, state in pairs(self.pageStateBox.elements) do
        if index == self.pageSelector:getState() then
            state.state = GuiOverlay.STATE_FOCUSED
        else
            state.state = GuiOverlay.STATE_NORMAL
        end
    end
end

-- Called with onPageUpdate
function ssSeasonsMenu:onPageUpdate()
   self:setPageStates()
end

-- Update the layout with titles
function ssSeasonsMenu:setPageStates()
    for i = #self.pageStateBox.elements, 1, -1 do
        self.pageStateBox.elements[i]:delete()
    end

    local texts = self.pagingElement:getPageTitles()
    for _, _ in pairs(texts) do
        self.pageStateElement:clone(self.pageStateBox)
    end

    self.pageSelector:setTexts(texts)
    self.pageStateBox:invalidateLayout()

    self.pageSelector:setDisabled(#texts == 1)
end

function ssSeasonsMenu:update(dt)
    ssSeasonsMenu:superClass().update(self, dt)

    self.alreadyClosed = false
end

function ssSeasonsMenu:onAdminOK()
    g_gui:closeAllDialogs()
end

function ssSeasonsMenu:setNavButtonsFocusChange(targetElementTop, targetElementBottom)
    if targetElementTop ~= nil and targetElementBottom ~= nil then
        local buttonBack = FocusManager:getElementById("100")
        local pageSelector = FocusManager:getElementById("1")
        buttonBack.focusChangeData[FocusManager.TOP] = targetElementBottom.focusId
        pageSelector.focusChangeData[FocusManager.BOTTOM] = targetElementTop.focusId
    end

    local focusElement = FocusManager:getFocusedElement()

    FocusManager:unsetFocus(focusElement)
    FocusManager:setFocus(focusElement)
end

------------------------------------------
-- TOOLTIP
------------------------------------------

-- Focus removed: clear the tooltip
function ssSeasonsMenu:onLeaveSettingsBox(element)
    self:setToolTipText("")
end

function ssSeasonsMenu:onFocusSettingsBox(element)
    if element.toolTip ~= nil then
        self:setToolTipText(element.toolTip)
    end
end

function ssSeasonsMenu:setToolTipText(text)
    self.ssMenuToolTipBoxText:setText(ssLang.getText(text, text))
    self:updateToolTipBox(self.currentPageId)
end

-- Update whether the tooltip box is visible
function ssSeasonsMenu:updateToolTipBox(pageId)
    self.ssMenuToolTipBox:setVisible((pageId == ssSeasonsMenu.PAGE_SETTINGS or pageId == ssSeasonsMenu.PAGE_DEBUG) and self.ssMenuToolTipBoxText.text ~= "")
end

------------------------------------------
-- OVERVIEW PAGE
------------------------------------------

function ssSeasonsMenu:onCreatePageOverview(element)
    ssSeasonsMenu.PAGE_OVERVIEW = self.pagingElement:getPageIdByElement(element)
end

------------------------------------------
-- MULTIPLAYER LOGIN ELEMENT
------------------------------------------

function ssSeasonsMenu:onCreateMultiplayerLogin(element)
    self:updateServerSettingsVisibility()
end

function ssSeasonsMenu:updateServerSettingsVisibility()
    if g_currentMission ~= nil then
        -- Only needs MP login when this is a MP session, this is not the server and the user is not logged in
        local needsMPLogin = g_currentMission.missionDynamicInfo.isMultiplayer and not g_currentMission:getIsServer() and not g_currentMission.isMasterUser and g_currentMission.connectedToDedicatedServer

        self.multiplayerLogin:setVisible(needsMPLogin)
        self.settingsColumn2:setVisible(not needsMPLogin)
        self.settingsColumn3:setVisible(not needsMPLogin)
    end
end

function ssSeasonsMenu:onClickMultiplayerLogin(element)
    g_gui:showPasswordDialog({text=g_i18n:getText("ui_enterAdminPassword"), callback=self.onAdminPassword, target=self, defaultPassword=""})
end

function ssSeasonsMenu:onAdminPassword(password, login)
    if login then
        g_client:getServerConnection():sendEvent(GetAdminEvent:new(password))
    else
        g_gui:closeDialogByName("PasswordDialog")
    end
end

function GetAdminAnswerEvent.onAnswerOk(args)
    if args ~= nil and args[1] == true then
        if g_gui.currentGuiName == "SeasonsMenu" then
            g_seasons.mainMenu:updateServerSettingsVisibility()
        else
            g_inGameMenu:onAdminLoginSuccess()
        end
    end
end

------------------------------------------
-- SETTINGS PAGE
------------------------------------------

function ssSeasonsMenu:onCreatePageSettings(element)
    ssSeasonsMenu.PAGE_SETTINGS = self.pagingElement:getPageIdByElement(element)
end

function ssSeasonsMenu:onCreateSaveButton(element)
    element:setText(ssLang.getText("ui_buttonSave"))
end


function ssSeasonsMenu:updateGameSettings()
    if g_currentMission == nil then
        return
    end

    self.settingElements.seasonIntros:setIsChecked(not ssSeasonIntro.hideSeasonIntro)
    self.settingElements.seasonLength:setState(math.floor(g_seasons.environment.daysInSeason / 3))
    self.settingElements.controlsHelp:setIsChecked(g_seasons.showControlsInHelpScreen)
    self.settingElements.controlsTemperature:setIsChecked(ssWeatherForecast.degreeFahrenheit)
    self.settingElements.snow:setState(g_seasons.snow.mode)
    self.settingElements.snowTracks:setIsChecked(g_seasons.vehicle.snowTracksEnabled)
    self.settingElements.moisture:setIsChecked(g_seasons.weather.moistureEnabled)

    -- Make sure the GUI is consistent
    self:updateTracksDisablement()
end

function ssSeasonsMenu:updateTracksDisablement()
    local tracks = self.settingElements.snowTracks

    if self.settingElements.snow:getState() == ssSnow.MODE_ON then
        -- Tracks only work with more than 1 layer of snow, so it doesnt make sense to have an
        -- option to turn them on when snow is off or max 1 layer
        tracks:setDisabled(false)
        tracks:setIsChecked(g_seasons.vehicle.snowTracksEnabled)
    else
        tracks:setDisabled(true)
        tracks:setIsChecked(false)
    end
end

function ssSeasonsMenu:updateApplySettingsButton()
    local hasChanges = false

    if self.settingElements.seasonLength:getState() * 3 ~= g_seasons.environment.daysInSeason
        or self.settingElements.seasonIntros:getIsChecked() ~= not ssSeasonIntro.hideSeasonIntro
        or self.settingElements.controlsHelp:getIsChecked() ~= g_seasons.showControlsInHelpScreen
        or self.settingElements.controlsTemperature:getIsChecked() ~= ssWeatherForecast.degreeFahrenheit
        or self.settingElements.snowTracks:getIsChecked() ~= ssVehicle.snowTracksEnabled
        or self.settingElements.snow:getState() ~= ssSnow.mode
        or self.settingElements.moisture:getIsChecked() ~= g_seasons.weather.moistureEnabled then
        -- or  then -- snow
        hasChanges = true
    end

    self.saveButton:setDisabled(not hasChanges)
end

function ssSeasonsMenu:onClickSaveSettings()
    if self.settingElements.seasonLength:getState() * 3 ~= g_seasons.environment.daysInSeason
       or self.settingElements.snow:getState() ~= ssSnow.mode then
        local text = ssLang.getText("dialog_applySettings")
        g_gui:showYesNoDialog({text=text, callback=self.onYesNoSaveSettings, target=self})
    else
        self:onYesNoSaveSettings(true)
    end
end

function ssSeasonsMenu:onYesNoSaveSettings(yes)
    if yes then
        ssSeasonIntro.hideSeasonIntro = not self.settingElements.seasonIntros:getIsChecked()
        g_seasons.showControlsInHelpScreen = self.settingElements.controlsHelp:getIsChecked()
        ssWeatherForecast.degreeFahrenheit = self.settingElements.controlsTemperature:getIsChecked()

        if g_currentMission:getIsServer() then
            local newLength = self.settingElements.seasonLength:getState() * 3

            g_seasons.snow:setMode(self.settingElements.snow:getState())
            self:updateSnowStatus()

            g_seasons.environment:changeDaysInSeason(newLength)

            g_seasons.vehicle.snowTracksEnabled = self.settingElements.snowTracks:getIsChecked()
            g_seasons.weather.moistureEnabled = self.settingElements.moisture:getIsChecked()

            self:updateApplySettingsButton()

            -- Sync new data to all the clients
            ssSettingsEvent.sendEvent()
        elseif g_currentMission.isMasterUser then
            -- Sync to the server
            ssSettingsEvent.sendEvent()
        end
    end
end

function ssSeasonsMenu:replaceTexts(element)
    for _, el in pairs(element.elements) do
        if el.text ~= nil then
           el.text = ssLang.getText(el.text, el.text)
        end
    end
end

------- SEASON INTORS on/off -------
function ssSeasonsMenu:onCreateSeasonIntros(element)
    self.settingElements.seasonIntros = element
    self:replaceTexts(element)
end

-------- CONTROLS HELP on/off -------
function ssSeasonsMenu:onCreateControlsHelp(element)
    self.settingElements.controlsHelp = element
    self:replaceTexts(element)
end

function ssSeasonsMenu:onCreateControlsTemperature(element)
    self.settingElements.controlsTemperature = element
    self:replaceTexts(element)

    element:setTexts({ssLang.getText("ui_temperatureCelcius"), ssLang.getText("ui_temperatureFahrenheit")})
end

------- SEASON LENGTH -------
function ssSeasonsMenu:onCreateSeasonLength(element)
    self.settingElements.seasonLength = element
    self:replaceTexts(element)

    local texts = {}
    for i = 1, 4 do
        table.insert(texts, string.format(ssLang.getText("ui_days", "%i days"), i * 3))
    end
    element:setTexts(texts)
end

------- SNOW on/off -------
function ssSeasonsMenu:onCreateSnow(element)
    self.settingElements.snow = element
    self:replaceTexts(element)

    element:setTexts({ssLang.getText("ui_off"), ssLang.getText("ui_snowOneLayer"), ssLang.getText("ui_on")})
end

function ssSeasonsMenu:onClickSnowToggle(state)
    self:updateTracksDisablement()

    self:updateApplySettingsButton()
end

------- Snow Tracks on/off -------
function ssSeasonsMenu:onCreateSnowTracksToggle(element)
    self.settingElements.snowTracks = element
    self:replaceTexts(element)
end

function ssSeasonsMenu:onCreateMoistureToggle(element)
    self.settingElements.moisture = element
    self:replaceTexts(element)
end

------------------------------------------
-- DEBUG PAGE
------------------------------------------

function ssSeasonsMenu:onCreatePageDebug(element)
    ssSeasonsMenu.PAGE_DEBUG = self.pagingElement:getPageIdByElement(element)
end

function ssSeasonsMenu:updateDebugValues()
    self.autoSnowToggle:setIsChecked(ssSnow.autoSnow)
    self.debugVehicleRenderingToggle:setIsChecked(Vehicle.debugRendering)
    self.debugAIRenderingToggle:setIsChecked(AIVehicle.aiDebugRendering)

    self:updateSnowStatus()
end

function ssSeasonsMenu:updateSnowStatus()
    if g_currentMission:getIsServer() then
        self.debugSnowDepth:setText(string.format("Snow height: %0.2f (%i layers)", ssSnow.appliedSnowDepth, ssSnow.appliedSnowDepth / ssSnow.LAYER_HEIGHT))
    end
end

function ssSeasonsMenu:onClickDebugAutoSnow(state)
    if g_currentMission:getIsServer() then
        ssSnow.autoSnow = self.autoSnowToggle:getIsChecked()
    end
end

function ssSeasonsMenu:onClickDebugAddSnow(state)
    if g_currentMission:getIsServer() then
        ssSnow:applySnow(math.max(ssSnow.appliedSnowDepth + ssSnow.LAYER_HEIGHT, ssSnow.LAYER_HEIGHT))

        self:updateSnowStatus()
    end
end

function ssSeasonsMenu:onClickDebugRemoveSnow(state)
    if g_currentMission:getIsServer() then
        ssSnow:applySnow(ssSnow.appliedSnowDepth - ssSnow.LAYER_HEIGHT)

        self:updateSnowStatus()
    end
end

function ssSeasonsMenu:onClickDebugClearSnow(state)
    if g_currentMission:getIsServer() then
        ssSnow:applySnow(0)

        self:updateSnowStatus()
    end
end

function ssSeasonsMenu:onClickDebugVehicleRendering(state)
    Vehicle.debugRendering = self.debugVehicleRenderingToggle:getIsChecked()
end

function ssSeasonsMenu:onClickDebugAIRendering(state)
    AIVehicle.aiDebugRendering = self.debugAIRenderingToggle:getIsChecked()
end

function ssSeasonsMenu:onClickDebugResetGM()
    if g_currentMission:getIsServer() then
        ssGrowthManager:resetGrowth()
    end
end
