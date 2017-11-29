----------------------------------------------------------------------------------------------------
-- SEASONS MENU SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  GUI
-- Authors:  Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssSeasonsMenu = {}

local ssSeasonsMenu_mt = Class(ssSeasonsMenu, ScreenElement)

source(g_currentModDirectory .. "src/events/ssSettingsEvent.lua")

ssSeasonsMenu.BLOCK_TYPE_PLANTABLE = 1
ssSeasonsMenu.BLOCK_TYPE_HARVESTABLE = 2

ssSeasonsMenu.BLOCK_COLORS = {}
ssSeasonsMenu.BLOCK_COLORS[false] = {
    [ssSeasonsMenu.BLOCK_TYPE_PLANTABLE] = {0.0143, 0.2582, 0.0126, 1},
    [ssSeasonsMenu.BLOCK_TYPE_HARVESTABLE] = {0.8308, 0.5841, 0.0529, 1}
}

ssSeasonsMenu.BLOCK_COLORS[true] = {
    [ssSeasonsMenu.BLOCK_TYPE_PLANTABLE] = {0.2122, 0.1779, 0.0027, 1},
    [ssSeasonsMenu.BLOCK_TYPE_HARVESTABLE] = {0.3372, 0.4397, 0.9911, 1}
}

function ssSeasonsMenu:new(target, custom_mt)
    if custom_mt == nil then
        custom_mt = ssSeasonsMenu_mt
    end
    local self = ScreenElement:new(target, custom_mt)

    self.currentPageId = 1
    self.currentPageMappingIndex = 1

    self.settingElements = {}

    ssUtil.overwrittenFunction(InGameMenu, "onAdminLoginSuccess", ssSeasonsMenu.ingameOnAdminLoginSuccess)

    return self
end

function ssSeasonsMenu:delete()
    self:deleteOverview()

    if self.economy.graph then
        self.economy.graph:delete()
    end
end

function ssSeasonsMenu:onCreate(gui)
    if GS_IS_CONSOLE_VERSION and gui ~= nil then
        self:removeNavigationItems(gui.elements, {"1", "2", "100", "101", "102"});
    else
        self.backButton = FocusManager:getElementById("100")
    end
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

    if not self.createPageContent then
        self.createPageContent = true

        self:updateCalendar()
        self:updateEconomy()
    end

    -- settings
    self:updateGameSettings()

    self:updateDebugValues()

    -- Todo: get these values from the XML file. This is messy
    local titles = {ssLang.getText("ui_pageCalender"), ssLang.getText("ui_pageEconomy"), ssLang.getText("ui_pageSettings")}
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

    if self:saveSettings() then
        g_gui:showGui("")
    end
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

    self:saveSettings()

    if pageId == ssSeasonsMenu.PAGE_CALENDAR then
        self:setNavButtonsFocusChange(FocusManager:getElementById("200"), FocusManager:getElementById("200"))
    elseif pageId == ssSeasonsMenu.PAGE_ECONOMY then
        self:setNavButtonsFocusChange(FocusManager:getElementById("300"), FocusManager:getElementById("300"))
    elseif pageId == ssSeasonsMenu.PAGE_SETTINGS then
        self:setNavButtonsFocusChange(FocusManager:getElementById("210"), FocusManager:getElementById("223"))
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
    if not GS_IS_CONSOLE_VERSION then
        if targetElementTop ~= nil and targetElementBottom ~= nil then
            local buttonBack = FocusManager:getElementById("100")
            local pageSelector = FocusManager:getElementById("1")
            buttonBack.focusChangeData[FocusManager.TOP] = targetElementBottom.focusId
            pageSelector.focusChangeData[FocusManager.BOTTOM] = targetElementTop.focusId
        end

        local focusElement = FocusManager:getFocusedElement()
        if focusElement ~= nil then
            FocusManager:unsetFocus(focusElement)
            FocusManager:setFocus(focusElement)
        end
    else
        local focusElement = FocusManager:getFocusedElement()

        if focusElement ~= nil then
            FocusManager:unsetFocus(focusElement)
        end

        if targetElementTop ~= nil then
            FocusManager:setFocus(targetElementTop)
        end
    end
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
-- CALENDAR PAGE
------------------------------------------

function ssSeasonsMenu:onCreatePageOverview(element)
    ssSeasonsMenu.PAGE_CALENDAR = self.pagingElement:getPageIdByElement(element)

    local width, height = getNormalizedScreenValues(1, 1)
    self.pixel = Overlay:new("pixel", Utils.getFilename("resources/gui/pixel.png", g_seasons.modDir), 0, 0, width, height)

    self.lastSoilTemperature = math.floor(Utils.getNoNil(ssWeatherManager.soilTemp, 0), 0)
end

function ssSeasonsMenu:updateCalendar()
    local canPlant = g_seasons.growthGUI:getCanPlantData()
    local canHarvest = g_seasons.growthGUI:getCanHarvestData()

    function generateBlocks(blocks, fruitName, data, type)
        if data == nil or data[fruitName] == nil then return end

        local currentBlock = nil

        -- Go over the data
        -- When you find a true
            -- If no block open, make new block
            -- If block open, set end of block to new true
        -- When find false
            -- Add block, reset current block
        for i = 1, g_seasons.environment.TRANSITIONS_IN_YEAR do
            if data[fruitName][i] then
                if currentBlock == nil then
                    currentBlock = {}
                    currentBlock.type = type
                    currentBlock.s = i
                end
                currentBlock.e = i
            else
                table.insert(blocks, currentBlock)
                currentBlock = nil
            end
        end
        if currentBlock ~= nil then table.insert(blocks, currentBlock) end --handle case where there is no false (like poplar)
    end

    self.calendarList:deleteListItems()
    self.calendarTemps = {}

    for index, fruitDesc in ipairs(FruitUtil.fruitIndexToDesc) do
        if fruitDesc.allowsSeeding then -- must be in list
            local item = {}
            local fillTypeDesc = FillUtil.fillTypeIndexToDesc[FruitUtil.fruitTypeToFillType[index]]

            item.name = fruitDesc.name
            item.nameI18N = fillTypeDesc.nameI18N
            item.fillTypeDesc = fillTypeDesc

            item.temperature = g_seasons.weather:germinationTemperature(fruitDesc.name)

            item.blocks = {}
            generateBlocks(item.blocks, fruitDesc.name, canPlant, ssSeasonsMenu.BLOCK_TYPE_PLANTABLE)
            generateBlocks(item.blocks, fruitDesc.name, canHarvest, ssSeasonsMenu.BLOCK_TYPE_HARVESTABLE)

            self.currentItem = item
            -- self.currentItemIsOdd = i % 2 == 0

            local row = self.calendarListItemTemplate:clone(self.calendarList)
            row:updateAbsolutePosition()

        end
    end

    self.currentItem = nil
end

function ssSeasonsMenu:deleteOverview()
    self.pixel:delete()
    self.calendarHeader:delete()
end

function ssSeasonsMenu:onCreateCalendarListItem(element)
    if self.currentItem ~= nil then
    end
end

function ssSeasonsMenu:onCreateCalendarItemFruitIcon(element)
    if self.currentItem ~= nil then
        element:setImageFilename(self.currentItem.fillTypeDesc.hudOverlayFilenameSmall)
    end
end

function ssSeasonsMenu:onCreateCalendarItemFruitName(element)
    if self.currentItem ~= nil then
        element:setText(self.currentItem.nameI18N)
    end
end

function ssSeasonsMenu:onCreateCalendarItemGermination(element)
    if self.currentItem ~= nil then
        element:setText(ssLang.formatTemperature(self.currentItem.temperature))

        table.insert(self.calendarTemps, { element, self.currentItem.temperature })

        if math.floor(Utils.getNoNil(ssWeatherManager.soilTemp, 0), 0) < self.currentItem.temperature then
            element:applyProfile(element.profile .. "Frigid")
        end
    end
end

function ssSeasonsMenu:onCreateCalendarItemData(element)
    if self.currentItem ~= nil then
        element.item = self.currentItem
    end
end

function ssSeasonsMenu:onDrawCalendarToday(element)
    local pixel = self.pixel
    local dayInYear = g_seasons.environment:dayInSeason() + g_seasons.environment:currentSeason() * g_seasons.environment.daysInSeason
    local daySize = element.size[1] / (g_seasons.environment.daysInSeason * 4) * (dayInYear - 1)
    local guideWidth, _ = getNormalizedScreenValues(2, 0)
    local colorBlind = g_gameSettings:getValue("useColorblindMode")

    pixel:setPosition(element.absPosition[1] + daySize, element.absPosition[2])
    pixel:setDimension(guideWidth, element.size[2])
    pixel:setColor(unpack(colorBlind and {1.0000, 0.8632, 0.0232, 1} or {0.8069, 0.0097, 0.0097, 1}))
    pixel:render()
end

function ssSeasonsMenu:onDrawCalendarItemData(element)
    if not element:getIsVisible() then return end

    local transitionWidth, _ = getNormalizedScreenValues(45, 0)
    local pixel = self.pixel
    local colorBlind = g_gameSettings:getValue("useColorblindMode")

    local transitionHeight = element.size[2] / 2

    for _, block in pairs(element.item.blocks) do
        local blockInY = block.type ~= ssSeasonsMenu.BLOCK_TYPE_HARVESTABLE and transitionHeight or 0

        pixel:setPosition(element.absPosition[1] + (block.s - 1) * transitionWidth,
                          element.absPosition[2] + blockInY)

        pixel:setDimension(transitionWidth * (block.e - block.s + 1), transitionHeight)
        pixel:setColor(unpack(ssSeasonsMenu.BLOCK_COLORS[colorBlind][block.type]))

        pixel:render()
    end
end

function ssSeasonsMenu:onCreateCalendarHeader(element)
    self.calendarHeader = ssGuiSeasonsHeader:new(element)
    self.calendarHeader:setMargin(getNormalizedScreenValues(0, 50))
end

function ssSeasonsMenu:onDrawCalendarHeader(element)
    self.calendarHeader:draw(element)
end

function ssSeasonsMenu:onDrawCalendarFooter(element)
    local transitionWidth, transitionHeight = getNormalizedScreenValues(45, 16)
    local offsetX, offsetY = getNormalizedScreenValues(5, 5)
    local pixel = self.pixel
    local colorBlind = g_gameSettings:getValue("useColorblindMode")
    local x, y = unpack(element.absPosition)
    local _, textSize = getNormalizedScreenValues(0, 14)

    -- Draw legend in the footer
    setTextColor(1, 1, 1, 1)
    setTextAlignment(RenderText.ALIGN_LEFT)

    local footerY = 10

    -- Planting and harvest icons
    pixel:setDimension(transitionWidth, transitionHeight)

    pixel:setPosition(x, y + transitionHeight + offsetY)
    pixel:setColor(unpack(ssSeasonsMenu.BLOCK_COLORS[colorBlind][ssSeasonsMenu.BLOCK_TYPE_PLANTABLE]))
    pixel:render()

    pixel:setPosition(x, y)
    pixel:setColor(unpack(ssSeasonsMenu.BLOCK_COLORS[colorBlind][ssSeasonsMenu.BLOCK_TYPE_HARVESTABLE]))
    pixel:render()

    renderText(
        x + transitionWidth + offsetX,
        y + transitionHeight + offsetY,
        textSize,
        ssLang.getText("ui_plantingSeason")
    )

    renderText(
        x + transitionWidth + offsetX,
        y,
        textSize,
        ssLang.getText("ui_harvestSeason")
    )
end

function ssSeasonsMenu:onDrawPageCalendar()
    local curTemp = math.floor(ssWeatherManager.soilTemp, 0)
    if curTemp ~= self.lastSoilTemperature then
        self.lastSoilTemperature = curTemp

        for i, data in pairs(self.calendarTemps) do
            if curTemp < data[2] then
                data[1]:applyProfile("ssCalendarItemGerminationFrigid")
            else
                data[1]:applyProfile("ssCalendarItemGermination")
            end
        end
    end
end

------------------------------------------
-- ECONOMY PAGE
------------------------------------------

function ssSeasonsMenu:onCreatePageEconomy(element)
    ssSeasonsMenu.PAGE_ECONOMY = self.pagingElement:getPageIdByElement(element)

    self.economy = {}

    self.economyList:deleteListItems()
    self.economy.fills = {}
end

function ssSeasonsMenu:loadEconomyItems()
    for index, fillDesc in ipairs(FillUtil.fillTypeIndexToDesc) do
        if fillDesc.ssEconomyType ~= nil then
            table.insert(self.economy.fills, fillDesc)

            local new = self.economyListItemTemplate:clone(self.economyList)

            new.elements[1]:setText(self:economyGetFillTitle(fillDesc))
            new:updateAbsolutePosition()
        end
    end

    self.economyList:setSelectedRow(1)
    self:onEconomyListSelectionChanged(1)
end

function ssSeasonsMenu:updateEconomy()
    if table.getn(self.economy.fills) == 0 then
        self:loadEconomyItems()
    end
end

function ssSeasonsMenu:createEconomyGraph(element)
    local graph = ssGraph:new(element)
    self.economy.graph = graph

    self:onEconomyListSelectionChanged(1)
end

function ssSeasonsMenu:drawEconomyGraph(element)
    if self.firstEconomyDraw == nil then
        self:createEconomyGraph(element)

        self.firstEconomyDraw = false
    end

    self.economy.graph:setCurrentDay(g_seasons.environment:dayInYear())
    self.economy.graph:draw()
end

function ssSeasonsMenu:economyGetFillTitle(fillDesc)
    local title = fillDesc.nameI18N

    if fillDesc.ssEconomyType == g_seasons.economyHistory.ECONOMY_TYPE_BALE then
        title = string.format("%s (%s)", title, ssLang.getText("ui_economy_bale"))
    end

    return title
end

function ssSeasonsMenu:onEconomyListSelectionChanged(rowIndex)
    if rowIndex < 1 or self.economy.graph == nil then return end

    local fillDesc = self.economy.fills[rowIndex]
    local data = g_seasons.economyHistory:getHistory(fillDesc)

    self.economy.graph:setData(data.data)
    self.economy.graph:setYUnit(data.unit)
    self.economy.graph:setTitle(self:economyGetFillTitle(fillDesc))
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
    if not g_currentMission.isMasterUser then
        g_gui:showPasswordDialog({
            text = g_i18n:getText("ui_enterAdminPassword"),
            callback = self.onAdminPassword,
            target = self,
            defaultPassword = ""
        })
    end
end

function ssSeasonsMenu:onAdminPassword(password, login)
    g_client:getServerConnection():sendEvent(GetAdminEvent:new(password))
end

function ssSeasonsMenu:ingameOnAdminLoginSuccess(superFunc)
    if g_gui.currentGuiName == "SeasonsMenu" then
        g_seasons.mainMenu:updateServerSettingsVisibility()

        -- Close new password dialog. (No idea why it shows)
        g_gui:closeAllDialogs()
    else
        superFunc(self)
    end
end

------------------------------------------
-- SETTINGS PAGE
------------------------------------------

function ssSeasonsMenu:onCreatePageSettings(element)
    ssSeasonsMenu.PAGE_SETTINGS = self.pagingElement:getPageIdByElement(element)
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

function ssSeasonsMenu:hasSettingsChanged()
    return self.settingElements.seasonLength:getState() * 3 ~= g_seasons.environment.daysInSeason
        or self.settingElements.seasonIntros:getIsChecked() ~= not ssSeasonIntro.hideSeasonIntro
        or self.settingElements.controlsHelp:getIsChecked() ~= g_seasons.showControlsInHelpScreen
        or self.settingElements.controlsTemperature:getIsChecked() ~= ssWeatherForecast.degreeFahrenheit
        or self.settingElements.snowTracks:getIsChecked() ~= ssVehicle.snowTracksEnabled
        or self.settingElements.snow:getState() ~= ssSnow.mode
        or self.settingElements.moisture:getIsChecked() ~= g_seasons.weather.moistureEnabled
end

function ssSeasonsMenu:saveSettings()
    if not self:hasSettingsChanged() then return end

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

        -- Change header numbers
        if self.economy.graph then
            self.economy.graph:settingsChanged()
            self:onEconomyListSelectionChanged(self.economyList.selectedRow)
        end
        self.calendarHeader:settingsChanged()

        -- Sync new data to all the clients
        ssSettingsEvent.sendEvent()
    elseif g_currentMission.isMasterUser then
        -- Sync to the server
        ssSettingsEvent.sendEvent()
    end

    return true
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

    element:setTexts({ssLang.getText("ui_temperatureCelsius"), ssLang.getText("ui_temperatureFahrenheit")})
end

------- SEASON LENGTH -------
function ssSeasonsMenu:onCreateSeasonLength(element)
    self.settingElements.seasonLength = element
    self:replaceTexts(element)

    local texts = {}
    for i = 1, ssEnvironment.MAX_DAYS_IN_SEASON/3 do
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
