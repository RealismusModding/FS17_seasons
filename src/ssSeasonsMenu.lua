---------------------------------------------------------------------------------------------------------
-- SEASONS MENU SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  GUI
-- Authors:  Rahkiin (Jarvixes)

ssSeasonsMenu = {}

ssSeasonsMenu.PAGE_NEXT_ID = 0

local ssSeasonsMenu_mt = Class(ssSeasonsMenu, ScreenElement)

function ssSeasonsMenu:new(target, custom_mt)
    if custom_mt == nil then
        custom_mt = ssSeasonsMenu_mt
    end
    local self = ScreenElement:new(target, custom_mt)

    self.currentPageId = 1
    self.currentPageMappingIndex = 1

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
    if g_currentMission ~= nil then
        -- Only needs MP login when this is a MP session, this is not the server and the user is not logged in
        local needsMPLogin = g_currentMission.missionDynamicInfo.isMultiplayer and not g_currentMission:getIsServer() and not g_currentMission.isMasterUser and g_currentMission.connectedToDedicatedServer

        -- Has access to the server page if this is SP, or MP and this is server or master user
        local hasServerAccess = not g_currentMission.missionDynamicInfo.isMultiplayer or (g_currentMission.missionDynamicInfo.isMultiplayer and (g_currentMission:getIsServer() or g_currentMission.isMasterUser))

        self.pagingElement:setPageIdDisabled(ssSeasonsMenu.PAGE_MULTIPLAYER_LOGIN, not needsMPLogin)
        self.pagingElement:setPageIdDisabled(ssSeasonsMenu.PAGE_SERVER_SETTINGS, not hasServerAccess)
    end
end

-- Called when the current page has changed.
-- In this code, the focus is updated for the newly visible page
function ssSeasonsMenu:onPageChange(pageId, pageMappingIndex)
    -- if self.currentPageId == ssSeasonsMenu.PAGE_MULTIPLAYER_SETTINGS then
    --     self:saveMpSettings()
    -- end

    self.currentPageId = pageId
    self.currentPageMappingIndex = pageMappingIndex
    self:updatePageStates()

--[[
    if pageId == ssSeasonsMenu.PAGE_MAP_OVERVIEW then
        self:setNavButtonsFocusChange(FocusManager:getElementById("10"), FocusManager:getElementById("41_1"))
    elseif pageId == ssSeasonsMenu.PAGE_GAME_SETTINGS_GENERAL then
        self:setNavButtonsFocusChange(FocusManager:getElementById("600"), FocusManager:getElementById("616"))
    elseif pageId == ssSeasonsMenu.PAGE_GAME_SETTINGS_GAME then
    elseif pageId == ssSeasonsMenu.PAGE_HELP_LINE then
        self:setNavButtonsFocusChange(FocusManager:getElementById("800"), FocusManager:getElementById("800"))
    elseif pageId == ssSeasonsMenu.PAGE_MULTIPLAYER_LOGIN then
        self:setNavButtonsFocusChange(FocusManager:getElementById("900"), FocusManager:getElementById("900"))
    elseif pageId == ssSeasonsMenu.PAGE_MULTIPLAYER_SETTINGS then
        self:setNavButtonsFocusChange(FocusManager:getElementById("1000"), FocusManager:getElementById("1011"))
    else
        self:setNavButtonsFocusChange(nil, nil)
    end
    ]]

    self:updateTooltipBox(self.currentPageId)
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
    for i=#self.pageStateBox.elements, 1, -1 do
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

------------------------------------------
-- TOOLTIP
------------------------------------------

-- Focus removed: clear the tooltip
function ssSeasonsMenu:onLeaveSettingsBox(element)
    self:setTooltipText("")
end

function ssSeasonsMenu:onFocusSettingsBox(element)
    if element.toolTip ~= nil then
        self:setTooltipText(element.toolTip)
    end
end

function ssSeasonsMenu:setTooltipText(text)
    self.ssMenuTooltipBoxText:setText(text)
    self:updateTooltipBox(self.currentPageId)
end

-- Update whether the tooltip box is visible
function ssSeasonsMenu:updateTooltipBox(pageId)
    self.ssMenuTooltipBox:setVisible((pageId == ssSeasonsMenu.PAGE_SERVER_SETTINGS or pageId == ssSeasonsMenu.PAGE_CLIENT_SETTINGS) and self.ssMenuTooltipBoxText.text ~= "")
end

------------------------------------------
-- OVERVIEW
------------------------------------------

function ssSeasonsMenu:onCreatePageOverview(element)
    ssSeasonsMenu.PAGE_OVERVIEW = self.pagingElement:getPageIdByElement(element)
end

------------------------------------------
-- MULTIPLAYER LOGIN
------------------------------------------

function ssSeasonsMenu:onCreatePageMultiplayerLogin(element)
    ssSeasonsMenu.PAGE_MULTIPLAYER_LOGIN = self.pagingElement:getPageIdByElement(element)
end

function ssSeasonsMenu:onClickMultiplayerLogin(element)
    g_gui:showPasswordDialog({text=g_i18n:getText("ui_enterAdminPassword"), callback=self.onAdminPassword, target=self, defaultPassword=""})
end

function ssSeasonsMenu:onAdminPassword(password)
    g_client:getServerConnection():sendEvent(GetAdminEvent:new(password))
end

function ssSeasonsMenu:onAdminLoginSuccess()
    self.pagingElement:setPageIdDisabled(ssSeasonsMenu.PAGE_MULTIPLAYER_LOGIN, true)
    self.pagingElement:setPageIdDisabled(ssSeasonsMenu.PAGE_SERVER_SETTINGS, not g_currentMission.missionDynamicInfo.isMultiplayer)

    -- Hide and show menu again, reloading the pages
    g_gui:showGui("")
    g_gui:showGui("ssSeasonsMenu")
end

------------------------------------------
-- CLIENT SETTINGS
------------------------------------------
function ssSeasonsMenu:onCreatePageClientSettings(element)
    ssSeasonsMenu.PAGE_CLIENT_SETTINGS = self.pagingElement:getPageIdByElement(element)
end

------------------------------------------
-- SERVER SETTINGS
------------------------------------------
function ssSeasonsMenu:onCreatePageServerSettings(element)
    ssSeasonsMenu.PAGE_SERVER_SETTINGS = self.pagingElement:getPageIdByElement(element)
end

------------------------------------------
-- ANY SETTINGS
------------------------------------------

function ssSeasonsMenu:updateGameSettings()
    if g_currentMission == nil then
        return
    end

    self.helpTextElement:setIsChecked(true)
end

------------------------------------------
-- HELP
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
-- OTHERS
------------------------------------------

function ssSeasonsMenu:onCreateAutoHelp(element)
    self.helpTextElement = element
end

function ssSeasonsMenu:onClickAutoHelp(state)
    log("Set value for XX: " .. tostring(self.helpTextElement:getIsChecked()))
end

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

