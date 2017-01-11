---------------------------------------------------------------------------------------------------------
-- SEASONS MENU SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  GUI
-- Authors:  Rahkiin (Jarvixes)

ssSeasonsMenu = {}

local ssSeasonsMenu_mt = Class(ssSeasonsMenu, ScreenElement)

function ssSeasonsMenu:new(target, custom_mt)
    if custom_mt == nil then
        custom_mt = ssSeasonsMenu_mt
    end
    local self = ScreenElement:new(target, custom_mt)

    self.currentPageId = 1
    self.currentPageMappingIndex = 1

    self.settingElements = {}

    ------
    self.testValue = 1
    ------

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

    -- settings
    self:updateGameSettings()
    self:updateApplySettingsButton()

    self:updateDebugValues()

    -- Todo: get these values from the XML file. This is messy
    local titles = {ssLang.getText("ui_pageOverview"), ssLang.getText("ui_pageSettings"), ssLang.getText("ui_pageHelp")}
    if ssSeasonsMod.debug then
        table.insert(titles, ssLang.getText("ui_pageDebug"))
    end
    self.pageSelector:setTexts(titles)

    self.pageSelector:setState(self.currentPageMappingIndex, true)
end

function ssSeasonsMenu:onClose(element)
    ssSeasonsMenu:superClass().onClose(self)

    self.mouseDown = false

    -- TODO: Save the settings

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
    self.pagingElement:setPageIdDisabled(ssSeasonsMenu.PAGE_DEBUG, not ssSeasonsMod.debug)
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
    elseif pageId == ssSeasonsMenu.PAGE_HELP then
        -- self:setNavButtonsFocusChange(FocusManager:getElementById("800"), FocusManager:getElementById("800"))
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

function ssSeasonsMenu:onAdminPassword(password)
    g_client:getServerConnection():sendEvent(GetAdminEvent:new(password))
end

function ssSeasonsMenu:onAdminLoginSuccess()
    self:updateServerSettingsVisibility()
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

    -- TODO: load actual data
    self.settingElements.seasonIntros:setIsChecked(not ssSeasonIntro.hideSeasonIntro)
    self.settingElements.seasonLength:setState(math.floor(ssSeasonsUtil.daysInSeason / 3))
    self.settingElements.gm:setIsChecked(ssGrowthManager.growthManagerEnabled)
    self.settingElements.wfHelp:setIsChecked(ssWeatherForecast.keyTextVisible)
    self.settingElements.snow:setState(ssSnow.mode)
    self.settingElements.snowTracks:setIsChecked(ssVehicle.snowTracksEnabled)

    -- Make sure the GUI is consistent
    local tracks = self.settingElements.snowTracks
    if ssSnow.mode == ssSnow.MODE_ON then
        tracks:setDisabled(true)
        tracks:setIsChecked(false)
    else
        tracks:setDisabled(false)
        tracks:setIsChecked(ssVehicle.snowTracksEnabled)
    end
end

function ssSeasonsMenu:updateApplySettingsButton()
    local hasChanges = false

    if self.settingElements.seasonLength:getState() * 3 ~= ssSeasonsUtil.daysInSeason
        or self.settingElements.seasonIntros:getIsChecked() ~= not ssSeasonIntro.hideSeasonIntro
        or self.settingElements.gm:getIsChecked() ~= ssGrowthManager.growthManagerEnabled
        or self.settingElements.wfHelp:getIsChecked() ~= ssWeatherForecast.keyTextVisible
        or self.settingElements.snowTracks:getIsChecked() ~= ssVehicle.snowTracksEnabled
        or self.settingElements.snow:getState() ~= ssSnow.mode then
        -- or  then -- snow
        hasChanges = true
    end

    self.saveButton:setDisabled(not hasChanges)
end

function ssSeasonsMenu:onClickSaveSettings()
    if self.settingElements.seasonLength:getState() * 3 ~= ssSeasonsUtil.daysInSeason
       or self.settingElements.gm:getIsChecked() ~= ssGrowthManager.growthManagerEnabled
       or self.settingElements.snow:getState() ~= ssSnow.mode then
        local text = ssLang.getText("dialog_applySettings")
        g_gui:showYesNoDialog({text=text, callback=self.onYesNoSaveSettings, target=self})
    else
        self:onYesNoSaveSettings(true)
    end
end

function ssSeasonsMenu:onYesNoSaveSettings(yes)
    if yes then
        local newLength = self.settingElements.seasonLength:getState() * 3

        ssSeasonIntro.hideSeasonIntro = not self.settingElements.seasonIntros:getIsChecked()
        ssWeatherForecast.keyTextVisible = self.settingElements.wfHelp:getIsChecked()

        if g_currentMission:getIsServer() then
            ssSnow:setMode(self.settingElements.snow:getState())
            self:updateSnowStatus()

            ssSeasonsUtil:changeDaysInSeason(newLength)

            ssGrowthManager.growthManagerEnabled = self.settingElements.gm:getIsChecked()
            ssVehicle.snowTracksEnabled = self.settingElements.snowTracks:getIsChecked()

            self:updateApplySettingsButton()
        else
            -- TODO: in MP, we need to send this to the server
            -- Then the server makes the changes, and needs to update everything to the client
            -- g_client:getServerConnection():sendEvent(ssApplySettingsEvent:new())
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

-------- WF HELP on/off -------
function ssSeasonsMenu:onCreateWFHelp(element)
    self.settingElements.wfHelp = element
    self:replaceTexts(element)
end

------- SEASON LENGTH -------
function ssSeasonsMenu:onCreateSeasonLength(element)
    self.settingElements.seasonLength = element
    self:replaceTexts(element)

    local texts = {}
    for i = 1, 4 do
        table.insert(texts, string.format(ssLang.getText("ui_days"), i * 3))
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
    local tracks = self.settingElements.snowTracks

    if state == ssSnow.MODE_ON then
        tracks:setDisabled(true)
        tracks:setIsChecked(false)
    else
        tracks:setDisabled(false)
        tracks:setIsChecked(ssVehicle.snowTracksEnabled)
    end

    self:updateApplySettingsButton()
end

------- GM on/off -------
function ssSeasonsMenu:onCreateGrowthManager(element)
    self.settingElements.gm = element
    self:replaceTexts(element)
end

------- Snow Tracks on/off -------
function ssSeasonsMenu:onCreateSnowTracksToggle(element)
    self.settingElements.snowTracks = element
    self:replaceTexts(element)
end

------------------------------------------
-- HELP PAGE
------------------------------------------

function ssSeasonsMenu:onCreatePageHelp(element)
    ssSeasonsMenu.PAGE_HELP = self.pagingElement:getPageIdByElement(element)

    if self.helpLineTextElement == nil then
        self.helpLineTextElement = element
    end
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
    self.debugSnowDepth:setText(string.format("Snow height: %0.2f (%i layers)", ssSnow.appliedSnowDepth, ssSnow.appliedSnowDepth / ssSnow.LAYER_HEIGHT))
end

function ssSeasonsMenu:onClickDebugAutoSnow(state)
    ssSnow.autoSnow = self.autoSnowToggle:getIsChecked()
end

function ssSeasonsMenu:onClickDebugAddSnow(state)
    ssSnow:applySnow(math.max(ssSnow.appliedSnowDepth + ssSnow.LAYER_HEIGHT, ssSnow.LAYER_HEIGHT))

    self:updateSnowStatus()
end

function ssSeasonsMenu:onClickDebugRemoveSnow(state)
    ssSnow:applySnow(ssSnow.appliedSnowDepth - ssSnow.LAYER_HEIGHT)

    self:updateSnowStatus()
end

function ssSeasonsMenu:onClickDebugClearSnow(state)
    ssSnow:applySnow(0)

    self:updateSnowStatus()
end

function ssSeasonsMenu:onClickDebugVehicleRendering(state)
    Vehicle.debugRendering = self.debugVehicleRenderingToggle:getIsChecked()
end

function ssSeasonsMenu:onClickDebugAIRendering(state)
    AIVehicle.aiDebugRendering = self.debugAIRenderingToggle:getIsChecked()
end

function ssSeasonsMenu:onClickDebugResetGM()
    ssGrowthManager:resetGrowth()
end
