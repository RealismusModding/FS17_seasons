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

function ssSeasonsMenu:new(target, custom_mt)
    if custom_mt == nil then
        custom_mt = ssSeasonsMenu_mt
    end
    local self = ScreenElement:new(target, custom_mt)

    self.currentPageId = 1
    self.currentPageMappingIndex = 1

    self.settingElements = {}


    self.overview = {}

    self.BLOCK_TYPE_PLANTABLE = 1
    self.BLOCK_TYPE_HARVESTABLE = 2

    self.overview.blockColors = {
        [self.BLOCK_TYPE_PLANTABLE] = {0.2122, 0.5271, 0.0307, 1},
        -- plantable = {0.662, 0.816, 0.557, 1},
        [self.BLOCK_TYPE_HARVESTABLE] = {0.9301, 0.6404, 0.0439, 1}
    }

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

    -- overview
    self:updateOverview()

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

    --[[
    if not g_gui:getIsDialogVisible("PasswordDialog") then
        if InputBinding.hasEvent(InputBinding.TOGGLE_GUI_SCREEN, true) or InputBinding.hasEvent(InputBinding.MENU_CANCEL, true) then
            self:exitGUI();
        end;
    end;

    if g_currentMission.missionDynamicInfo.isMultiplayer then
        -- Set the correct page if your logged in.
        if g_currentMission.isMasterUser then
            if self.clientArentLoggedIn == nil then -- delay 1 frame
                if g_gui_CurrentDialog ~= nil then
                    -- Prevent dialog to open the ingameMenu
                    g_gui_CurrentDialog.target:setCallback(GameExtensionGUI.onOK, self);
                    g_gui_CurrentDialog.target:setReturnScreen(nil, nil);
                    g_gui_CurrentDialog = nil;
                end;
            end;

            if self.clientArentLoggedIn ~= nil then
                self.clientArentLoggedIn = nil;
                self:setPage();
            end;
        end;
    end;
    --]]
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

ssRectOverlay = {}
local ssRectOverlay_mt = Class(ssRectOverlay)

function ssRectOverlay:new(parentElement)
    local self = {}
    setmetatable(self, ssRectOverlay_mt)

    self.parent = parentElement

    if ssRectOverlay.g_overlay == nil then
        local width, height = getNormalizedScreenValues(1, 1)
        ssRectOverlay.g_overlay = Overlay:new("pixel", Utils.getFilename("resources/gui/pixel.png", g_seasons.modDir), 0, 0, width, height)
    end

    return self
end

function ssRectOverlay:render(x, y, width, height, color)
    if color ~= nil then
        ssRectOverlay.g_overlay:setColor(unpack(color))
    else
        ssRectOverlay.g_overlay:setColor(1, 1, 1, 1)
    end

    -- Change the origin from bottom-left to top-left because we draw from left to right, top to bottom
    x = x + self.parent.absPosition[1]
    y = self.parent.absPosition[2] + self.parent.size[2] - height - y

    renderOverlay(ssRectOverlay.g_overlay.overlayId, x, y, width, height)
end

function ssRectOverlay:renderText(x, y, fontSize, text, boxHeight)
    local height = getTextHeight(fontSize, text)

    if boxHeight ~= nil then
        y = y + (boxHeight - height) / 2
    end

    -- Change the origin from bottom-left to top-left because we draw from left to right, top to bottom
    x = x + self.parent.absPosition[1]
    y = self.parent.absPosition[2] + self.parent.size[2] - height - y

    renderText(x, y, fontSize, text)
end

function ssRectOverlay:renderOverlay(overlay, x, y, width, height, boxHeight, boxWidth)
    if boxHeight ~= nil then
        y = y + (boxHeight - height) / 2
    end

    if boxWidth ~= nil then
        x = x + (boxWidth - width) / 2
    end

    -- Change the origin from bottom-left to top-left because we draw from left to right, top to bottom
    x = x + self.parent.absPosition[1]
    y = self.parent.absPosition[2] + self.parent.size[2] - height - y

    renderOverlay(overlay.overlayId, x, y, width, height)
end

------------------------------------------

function ssSeasonsMenu:onCreatePageOverview(element)
    ssSeasonsMenu.PAGE_OVERVIEW = self.pagingElement:getPageIdByElement(element)

    local o = self.overview
    local _ = nil

    -- Pre-compute a lot of values
    o.rect = ssRectOverlay:new(element)

    local fruitHeightPixels = 32

    o.transitionWidth, o.transitionHeight = getNormalizedScreenValues(45, fruitHeightPixels / 2)
    _, o.fruitHeight = getNormalizedScreenValues(0, fruitHeightPixels)
    o.fruitSpacerWidth, o.fruitSpacerHeight = getNormalizedScreenValues(5, 5)
    o.fruitNameWidth, _ = getNormalizedScreenValues(230, 0)
    o.germinationWidth, _ = getNormalizedScreenValues(70, 0)

    _, o.headerHeight = getNormalizedScreenValues(0, 50)

    _, o.textSize = getNormalizedScreenValues(0, 14)
    o.textSpacingWidth, o.textSpacingHeight = getNormalizedScreenValues(5, 5)

    o.fruitIconWidth, o.fruitIconHeight = getNormalizedScreenValues(fruitHeightPixels - 8, fruitHeightPixels - 8)

    o.guideWidth, _ = getNormalizedScreenValues(1, 0)
    o.headerSeparatorWidth, _ = getNormalizedScreenValues(1, 0)

    o.seasonIconWidth, o.seasonIconHeight = getNormalizedScreenValues(30, 30)

    o.topLeftX, o.topLeftY = getNormalizedScreenValues(50, 20)
    o.totalWidth = o.fruitNameWidth + o.germinationWidth + 2 * o.fruitSpacerWidth + 12 * o.transitionWidth

    o.seasons = {}
    o.seasons[ssEnvironment.SEASON_SPRING] = Overlay:new("hud_spring", Utils.getFilename("resources/huds/hud_spring.dds", g_seasons.modDir), 0, 0, o.seasonIconWidth, o.seasonIconHeight)
    o.seasons[ssEnvironment.SEASON_SUMMER] = Overlay:new("hud_summer", Utils.getFilename("resources/huds/hud_summer.dds", g_seasons.modDir), 0, 0, o.seasonIconWidth, o.seasonIconHeight)
    o.seasons[ssEnvironment.SEASON_AUTUMN] = Overlay:new("hud_autumn", Utils.getFilename("resources/huds/hud_autumn.dds", g_seasons.modDir), 0, 0, o.seasonIconWidth, o.seasonIconHeight)
    o.seasons[ssEnvironment.SEASON_WINTER] = Overlay:new("hud_winter", Utils.getFilename("resources/huds/hud_winter.dds", g_seasons.modDir), 0, 0, o.seasonIconWidth, o.seasonIconHeight)

    -- Cache of icons, against leaking when rebuilding
    o.iconCache = {}
end

function ssSeasonsMenu:updateOverview()
    self.overviewData = {}

    local canPlant = g_seasons.growthManager:getCanPlantData()
    local canHarvest = g_seasons.growthManager:getCanHarvestData()

    function generateBlocks(blocks, fruitName, data, type)
        if data == nil or data[fruitName] == nil then return end

        local currentBlock = nil

        -- Go over the data
        -- When you find a true
            -- If no block open, make new block
            -- If block open, set end of block to new true
        -- When find false
            -- Add block, reset current block

        for i = 1, 12 do
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
    end

    for index, fruitDesc in ipairs(FruitUtil.fruitIndexToDesc) do
        if fruitDesc.allowsSeeding then -- must be in list
            local item = {}
            local fillTypeDesc = FillUtil.fillTypeIndexToDesc[FruitUtil.fruitTypeToFillType[index]]

            item.name = fruitDesc.name
            item.i18Name = fillTypeDesc.nameI18N

            item.temperature = g_seasons.weather:germinationTemperature(fruitDesc.name)

            if self.overview.iconCache[index] == nil then
                self.overview.iconCache[index] = Overlay:new("fruitIcon", fillTypeDesc.hudOverlayFilename, 0, 0, 40, 40)
            end
            item.icon = self.overview.iconCache[index]

            item.blocks = {}
            generateBlocks(item.blocks, fruitDesc.name, canPlant, self.BLOCK_TYPE_PLANTABLE)
            generateBlocks(item.blocks, fruitDesc.name, canHarvest, self.BLOCK_TYPE_HARVESTABLE)

            table.insert(self.overviewData, item)
        end
    end
end

function ssSeasonsMenu:drawOverview(element)
    local o = self.overview
    local topLeftX = (element.size[1] - o.totalWidth) / 2
    local headerLeft = topLeftX + o.fruitNameWidth + o.germinationWidth + 2 * o.fruitSpacerWidth

    -- Print header
    setTextColor(1, 1, 1, 1)

    -- Background
    o.rect:render(
        headerLeft,
        o.topLeftY,
        o.transitionWidth * 12,
        o.headerHeight - o.fruitSpacerHeight,
        {0.013, 0.013, 0.013, 1}
    )

    -- Season icons
    for s = 0, 3 do
        o.rect:renderOverlay(
            self.overview.seasons[s],
            headerLeft + s * o.transitionWidth * 3,
            o.topLeftY,
            o.seasonIconWidth,
            o.seasonIconHeight,
            nil, --headerHeight - fruitSpacerHeight,
            o.transitionWidth * 3
        )
    end

    -- Draw separator blocks in the header
    for i = 1, 12 do
        if i ~= 1 then
            if i == 4 or i == 7 or i == 10 then
                o.rect:render(
                    headerLeft + (i - 1) * o.transitionWidth,
                    o.topLeftY,
                    o.headerSeparatorWidth,
                    o.headerHeight - o.fruitSpacerHeight,
                    {0.0284, 0.0284, 0.0284, 1} -- ????
                )
            else
                o.rect:render(
                    headerLeft + (i - 1) * o.transitionWidth,
                    o.topLeftY + o.seasonIconHeight,
                    o.headerSeparatorWidth,
                    o.headerHeight - o.seasonIconHeight - o.fruitSpacerHeight,
                    {0.0284, 0.0284, 0.0284, 1}
                )
            end
        end
    end

    -- Transition names

    -- Print all fruits' data
    local iFruit = 0
    for _, fruitData in ipairs(self.overviewData) do
        local fruitY = o.topLeftY + o.headerHeight + iFruit * (o.fruitHeight + o.fruitSpacerHeight)
        local fruitX = topLeftX

        -- Print name of the fruit
        setTextAlignment(RenderText.ALIGN_LEFT)
        o.rect:render(
            fruitX,
            fruitY,
            o.fruitNameWidth,
            o.fruitHeight,
            {0.013, 0.013, 0.013, 1}
        )
        o.rect:renderOverlay(fruitData.icon, fruitX + o.textSpacingWidth, fruitY, o.fruitIconWidth, o.fruitIconHeight, o.fruitHeight)
        o.rect:renderText(fruitX + 2 * o.textSpacingWidth + o.fruitIconWidth, fruitY, o.textSize, fruitData.i18Name, o.fruitHeight)

        -- Print germination temperature
        fruitX = fruitX + o.fruitNameWidth + o.fruitSpacerWidth
        o.rect:render(
            fruitX,
            fruitY,
            o.germinationWidth,
            o.fruitHeight,
            {0.013, 0.013, 0.013, 1}
        )
        setTextAlignment(RenderText.ALIGN_CENTER)

        if math.floor(ssWeatherManager.soilTemp, 0) < fruitData.temperature then
            setTextColor(0.0742, 0.4341, 0.6939, 1)
        end
        o.rect:renderText(fruitX + o.germinationWidth / 2, fruitY, o.textSize, ssLang.formatTemperature(fruitData.temperature), o.fruitHeight)
        setTextColor(1, 1, 1, 1)

        fruitX = fruitX + o.germinationWidth + o.fruitSpacerWidth

        -- Draw all blocks
        for _, block in pairs(fruitData.blocks) do
            local blockInY = block.type == self.BLOCK_TYPE_HARVESTABLE and o.transitionHeight or 0

            o.rect:render(
                fruitX + (block.s - 1) * o.transitionWidth,
                fruitY + blockInY,
                o.transitionWidth * (block.e - block.s + 1),
                o.transitionHeight,
                self.overview.blockColors[block.type]
            )
        end

        iFruit = iFruit + 1
    end

    -- Print vertical line for our current day
    local fruitsLeft = topLeftX + o.fruitNameWidth + o.fruitSpacerWidth + o.germinationWidth + o.fruitSpacerWidth
    local fruitsRight = fruitsLeft + 12 * o.transitionWidth
    local dayInYear = g_seasons.environment:dayInSeason() + g_seasons.environment:currentSeason() * g_seasons.environment.daysInSeason

    o.rect:render(
        fruitsLeft + (fruitsRight - fruitsLeft) / (g_seasons.environment.daysInSeason * 4) * (dayInYear - 1),
        o.topLeftY + o.headerHeight,
        o.guideWidth,
        table.getn(self.overviewData) * (o.fruitHeight + o.fruitSpacerHeight) - o.fruitSpacerHeight,
        {0.0742, 0.4341, 0.6939, 1}
    )

    setTextColor(1, 1, 1, 1)
    setTextAlignment(RenderText.ALIGN_LEFT)
end

function ssSeasonsMenu:deleteOverview()
    self.overview.testOverlay:delete()
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
        local dialog = g_gui:showDialog("PasswordDialog")
        dialog.target:setCallback(self.onAdminPassword, self)
    end
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
