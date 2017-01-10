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

        -- Has access to the server page if this is SP, or MP and this is server or master user
        local hasServerAccess = not g_currentMission.missionDynamicInfo.isMultiplayer or (g_currentMission.missionDynamicInfo.isMultiplayer and (g_currentMission:getIsServer() or g_currentMission.isMasterUser))

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
    self.settingElements.seasonIntros:setIsChecked(true)
    self.settingElements.seasonLength:setState(3) -- 9
    self.settingElements.snow:setState(2) -- if MP: 1, if no snow mask: 1
    self.settingElements.gm:setIsChecked(true)
end

function ssSeasonsMenu:onClickSaveSettings()
    log("Save settings")
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

function ssSeasonsMenu:onClickSeasonIntros(state)
    log("Set value for INTROS: " .. tostring(self.settingElements.seasonIntros:getIsChecked()))
end

------- SEASON LENGTH -------
function ssSeasonsMenu:onCreateSeasonLength(element)
    self.settingElements.seasonLength = element
    self:replaceTexts(element)

    element:setTexts({"3", "6", "9", "12"})
end

function ssSeasonsMenu:onClickSeasonLength(state)
    -- log("Set value for SEASON LENGTH: " .. tostring(self.settingElements.seasonLength:getIsChecked()))
end

------- SNOW on/off -------
function ssSeasonsMenu:onCreateSnow(element)
    self.settingElements.snow = element
    self:replaceTexts(element)

    element:setTexts({ssLang.getText("ui_off"), ssLang.getText("ui_snowOneLayer"), ssLang.getText("ui_on")})
end

function ssSeasonsMenu:onClickSnow(state)
    log("Set value for SNOW: " .. tostring(self.settingElements.snow:getIsChecked()))
end

------- GM on/off -------
function ssSeasonsMenu:onCreateGrowthManager(element)
    self.settingElements.gm = element
    self:replaceTexts(element)
end

function ssSeasonsMenu:onClickGrowthManager(state)
    log("Set value for GM: " .. tostring(self.settingElements.gm:getIsChecked()))
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

--[[
function ssSeasonsMenu:onCreateHelpLineImage(element)
    if self.helpLineImageElement == nil then
        self.helpLineImageElement = element
    end
end

function ssSeasonsMenu:onCreateHelpLineCategorySelector(element)
    self.helpLineCategorySelectorElement = element
end

function ssSeasonsMenu:onClickHelpLineCategorySelector(state)
    self:setupHelpLine()
end

function ssSeasonsMenu:setupHelpLine()
    self.helpLineList:deleteListItems()

    local categoryIndex = self.helpLineCategorySelectorElement:getState()

    if categoryIndex > 0 and self.helpLineCategories[categoryIndex] ~= nil then
        local category = self.helpLineCategories[categoryIndex]
        for _, helpItem in pairs(category.helpLines) do
            if self.helpLineListItemTemplate ~= nil then
                local new = self.helpLineListItemTemplate:clone(self.helpLineList)
                new.elements[1]:setText(g_i18n:getText(helpItem.title))
                new:updateAbsolutePosition()
            end
        end
        self.helpLineList:setSelectedRow(1)
        self:onHelpLineListSelectionChanged(1)
    end
end

function ssSeasonsMenu:onHelpLineListSelectionChanged(rowIndex)
    for i=#self.helpLineContentBox.elements, 1, -1 do
        self.helpLineContentBox.elements[i]:delete()
    end
    local categoryIndex = self.helpLineCategorySelectorElement:getState()
    if categoryIndex > 0 and self.helpLineCategories[categoryIndex] ~= nil then
        local category = self.helpLineCategories[categoryIndex]
        local helpLineItem = category.helpLines[rowIndex]
        if helpLineItem ~= nil then
            local text, _ = string.gsub(g_i18n:getText(helpLineItem.title), "$CURRENCY_SYMBOL", g_i18n:getCurrencySymbol(true))
            self.helpLineTitleElement:setText(text)
            for _, item in pairs(helpLineItem.items) do

                if item.type == "text" then
                    local textElem = self.helpLineTextElement:clone(self.helpLineContentBox)
                    local text, _ = string.gsub(g_i18n:getText(item.value), "$CURRENCY_SYMBOL", g_i18n:getCurrencySymbol(true))
                    textElem:setText(text)
                    local height = textElem:getTextHeight()
                    textElem.margin[4] = self.helpLineTextElement.margin[4] + height - textElem.textSize
                elseif item.type == "image" then
                    local imageElem = self.helpLineImageElement:clone(self.helpLineContentBox)
                    imageElem:setSize(nil, self.helpLineImageElement.size[2]*item.heightScale)
                    imageElem:setImageFilename(item.value)
                end
            end

            self.helpLineContentBox:invalidateLayout(true)
        end
    end
end
]]

------------------------------------------
-- DEBUG PAGE
------------------------------------------

function ssSeasonsMenu:onCreatePageDebug(element)
    ssSeasonsMenu.PAGE_DEBUG = self.pagingElement:getPageIdByElement(element)
end

function ssSeasonsMenu:updateDebugValues()
    self.autoSnowToggle:setIsChecked(ssSnow.autoSnow)

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

------------------------------------------
-- OLD
------------------------------------------

--[[function ssSeasonsMenu:onCreateMoneyUnit(element)
    self.moneyUnitElement = element
    local texts = {g_i18n:getText("unit_euro"), g_i18n:getText("unit_dollar"), g_i18n:getText("unit_pound")}
    element:setTexts(texts)
end

function ssSeasonsMenu:onClickMoneyUnit(state)
    g_currentMission:setMoneyUnit(state)

    local borrowText,_ = string.gsub(self.financesBorrowText, "$CURRENCY_SYMBOL", g_i18n:getCurrencySymbol(true))
    self.financesBorrowElement:setText(borrowText)
    local repayText,_ = string.gsub(self.financesRepayText, "$CURRENCY_SYMBOL", g_i18n:getCurrencySymbol(true))
    self.financesRepayElement:setText(repayText)

    self:updateGarage()
end
]]

