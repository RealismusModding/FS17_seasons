----------------------------------------------------------------------------------------------------
-- WEATHER FORECAST SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  to forecast and display the weather
-- Authors:  Rahkiin, reallogger, theSeb
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssWeatherForecast = {}

function ssWeatherForecast:preLoad()
    g_seasons.forecast = self
end

function ssWeatherForecast:load(savegame, key)
    self.visible = ssXMLUtil.getBool(savegame, key .. ".settings.weatherForecastHudVisible", GS_IS_CONSOLE_VERSION)
    self.degreeFahrenheit = ssXMLUtil.getBool(savegame, key .. ".weather.fahrenheit", g_gameSettings.useMiles)
end

function ssWeatherForecast:save(savegame, key)
    if g_currentMission:getIsServer() == true then
        ssXMLUtil.setBool(savegame, key .. ".settings.weatherForecastHudVisible", self.visible)
        ssXMLUtil.setBool(savegame, key .. ".weather.fahrenheit", self.degreeFahrenheit)
    end
end

function ssWeatherForecast:loadMap(name)
    if not g_currentMission:getIsClient() then return end

    local uiScale = Utils.getNoNil(g_gameSettings:getValue("uiScale"), 1)
    self.guiScale = uiScale

    self.borderWidth, self.borderHeight = getNormalizedScreenValues(4 * uiScale, 4 * uiScale)

    -- Forecast basics
    self.forecastDayWidth, self.forecastDayHeight = getNormalizedScreenValues(50 * uiScale, 50 * uiScale)
    self.forecastSpacingWidth, self.forecastSpacingHeight = self.borderWidth, self.borderHeight
    self.forecastWidth = 7 * self.forecastDayWidth + 8 * self.forecastSpacingWidth
    self.forecastHeight = self.forecastDayHeight + 2 * self.forecastSpacingHeight

    self.marginX, self.marginY = getNormalizedScreenValues(2 * uiScale, 2 * uiScale)

    self.forecastY = g_currentMission.infoBarBgOverlay.y - self.forecastHeight - self.forecastSpacingHeight
    self.forecastX = g_currentMission.infoBarBgOverlay.x - self.forecastWidth

    -- Weather icon
    self.iconWidth, self.iconHeight = getNormalizedScreenValues(28 * uiScale, 28 * uiScale)

    -- Season icons, air/soil icon
    self.iconWidthSmall, self.iconHeightSmall = getNormalizedScreenValues(16 * uiScale, 16 * uiScale)

    self.textSize = g_currentMission.timeScaleTextSize

    -- Set position day overlay
    self.todayPosY = g_currentMission.infoBarBgOverlay.y
    self.todayHeight = g_currentMission.infoBarBgOverlay.height
    self.separatorWidth, self.separatorHeight = getNormalizedScreenValues(1 * uiScale, 1 * uiScale)

    self.todayTextWidth, _ = getNormalizedScreenValues(24 * uiScale, 0)
    self.todayWidth = self.borderWidth * 2 + self.marginX * 4 + self.separatorWidth + self.iconWidth + self.iconWidthSmall + self.todayTextWidth

    self.todayIconOffsetX = self.borderWidth + self.marginX * 3 + self.iconWidth + self.separatorWidth
    self.todayTempOffsetX = self.todayIconOffsetX + self.iconWidthSmall + self.separatorWidth

    self.todayAirOffsetY = (self.todayHeight - 2 * self.borderHeight) * 3 / 4 - self.iconHeightSmall / 2 + self.borderHeight
    self.todaySoilOffsetY = (self.todayHeight - 2 * self.borderHeight) / 4 - self.iconHeightSmall / 2 + self.borderHeight

    self.todaySeasonOffsetY = self.todayHeight / 2 - self.iconHeight / 2
    self.todayVerticalSeparatorOffsetX = self.borderWidth + 2 * self.marginX + self.iconWidth

    self.todayHorizontalSeparatorY = self.todayPosY + (self.todayHeight - self.separatorHeight) / 2
    self.todayHorizontalSeparatorWidth = self.iconWidthSmall + self.todayTextWidth

    self.todayTextOffset = self.todayWidth - self.borderWidth - self.marginX
    self.todayAirTextY = self.todayPosY + (self.todayHeight - 2 * self.borderHeight) * 3 / 4 - self.textSize * 1.1 / 2 + self.borderHeight
    self.todaySoilTextY = self.todayPosY + (self.todayHeight - 2 * self.borderHeight) / 4 - self.textSize * 1.1 / 2 + self.borderHeight


    -- Rect for drawing the backgrounds
    width, height = getNormalizedScreenValues(1, 1)
    self.rect = Overlay:new("pixel", g_baseUIFilename, 0, 0, width, height)
    self.rect:setUVs(g_colorBgUVs)

    -- Season
    local _, y = getNormalizedScreenValues(0, 5)
    g_currentMission.timeOffsetY = g_currentMission.timeOffsetY + y
    g_currentMission.timeIconOverlay.y = g_currentMission.timeIconOverlay.y + y

    self.overlays = {}

    self.overlays.soilSymbol = Overlay:new("soilSymbol",  g_seasons.baseUIFilename, 0, 0, self.iconWidthSmall, self.iconHeightSmall)
    self.overlays.soilSymbol:setUVs(getNormalizedUVs({80, 8, 64, 64}))
    self.overlays.airSymbol = Overlay:new("airSymbol",  g_seasons.baseUIFilename, 0, 0, self.iconWidthSmall, self.iconHeightSmall)
    self.overlays.airSymbol:setUVs(getNormalizedUVs({8, 8, 64, 64}))

    -- Seasons Icons
    self.overlays.seasons = {}
    self.overlays.seasons[ssEnvironment.SEASON_SPRING] = Overlay:new("hud_spring", g_seasons.baseUIFilename, 0, 0, 0, 0)
    self.overlays.seasons[ssEnvironment.SEASON_SPRING]:setUVs(getNormalizedUVs({8, 216, 128, 128}))
    self.overlays.seasons[ssEnvironment.SEASON_SUMMER] = Overlay:new("hud_summer", g_seasons.baseUIFilename, 0, 0, 0, 0)
    self.overlays.seasons[ssEnvironment.SEASON_SUMMER]:setUVs(getNormalizedUVs({144, 216, 128, 128}))
    self.overlays.seasons[ssEnvironment.SEASON_AUTUMN] = Overlay:new("hud_autumn", g_seasons.baseUIFilename, 0, 0, 0, 0)
    self.overlays.seasons[ssEnvironment.SEASON_AUTUMN]:setUVs(getNormalizedUVs({280, 216, 128, 128}))
    self.overlays.seasons[ssEnvironment.SEASON_WINTER] = Overlay:new("hud_winter", g_seasons.baseUIFilename, 0, 0, 0, 0)
    self.overlays.seasons[ssEnvironment.SEASON_WINTER]:setUVs(getNormalizedUVs({416, 216, 128, 128}))

    -- State icons
    self.stateWidth, self.stateHeight = getNormalizedScreenValues(50 * uiScale, 50 * uiScale)
    self.stateIconWidth, self.stateIconHeight = self.stateWidth - 2 * self.borderWidth, self.stateHeight - 2 * self.borderHeight
    self.statePosY = self.todayPosY

    self.overlays.frozen = Overlay:new("hud_frozen", g_seasons.baseUIFilename, 0, 0, self.stateIconWidth, self.stateIconHeight)
    self.overlays.frozen:setUVs(getNormalizedUVs({8, 352, 204, 204}))
    self.overlays.wetcrop = Overlay:new("hud_wetcrop", g_seasons.baseUIFilename, 0, 0, self.stateIconWidth, self.stateIconHeight)
    self.overlays.wetcrop:setUVs(getNormalizedUVs({220, 352, 204, 204}))

    -- New snow icon
    g_currentMission.weatherForecastIconOverlays.snow = Overlay:new("hud_snow", g_seasons.baseUIFilename, 0, 0, 0, 0)
    g_currentMission.weatherForecastIconOverlays.snow:setUVs(getNormalizedUVs({552, 80, 128, 128}))

    -- Seasons Weather Icons
    self.overlays.sun = g_currentMission.weatherForecastIconSunOverlay
    self.overlays.cloudy = g_currentMission.weatherForecastIconOverlays.cloudy
    self.overlays.fog = g_currentMission.weatherForecastIconOverlays.fog
    self.overlays.rain = g_currentMission.weatherForecastIconOverlays.rain
    self.overlays.snow = g_currentMission.weatherForecastIconOverlays.snow
    self.overlays.hail = self.overlays.snow

    self.vanillaNotificationOffset = g_currentMission.ingameNotificationOffsetY

    self:setForecastVisible(self.visible)
end

function ssWeatherForecast:deleteMap()
    self.rect:delete()

    self.overlays.soilSymbol:delete()
    self.overlays.airSymbol:delete()

    for _, overlay in pairs(self.overlays.seasons) do
        overlay:delete()
    end

    self.overlays.frozen:delete()
    self.overlays.wetcrop:delete()

    -- Do not delete: it is automatically done by the game
    -- g_currentMission.weatherForecastIconOverlays.snow:delete()
end

function ssWeatherForecast:update(dt)
    if g_currentMission.controlledVehicle == nil or not GS_IS_CONSOLE_VERSION then
        if g_seasons.showControlsInHelpScreen then
            if not self.visible then
                g_currentMission:addHelpButtonText(g_i18n:getText("input_SEASONS_SHOW_WF"), InputBinding.SEASONS_SHOW_WF, nil, GS_PRIO_VERY_LOW)
            else
                g_currentMission:addHelpButtonText(g_i18n:getText("SEASONS_HIDE_WF"), InputBinding.SEASONS_SHOW_WF, nil, GS_PRIO_VERY_LOW)
            end
        end

        if InputBinding.hasEvent(InputBinding.SEASONS_SHOW_WF) then
            self:setForecastVisible(not self.visible)
        end
    end
end

function ssWeatherForecast:setForecastVisible(visible)
    self.visible = visible

    if visible then
        g_currentMission.ingameNotificationOffsetY = self.vanillaNotificationOffset - self.forecastHeight
    else
        g_currentMission.ingameNotificationOffsetY = self.vanillaNotificationOffset
    end
end

function ssWeatherForecast:draw()
    if (g_currentMission.fieldJobManager == nil or not g_currentMission.fieldJobManager:isFieldJobActive())
        and g_currentMission.showHudEnv then

        -- Set text color and alignment
        setTextColor(1, 1, 1, .9)
        setTextAlignment(RenderText.ALIGN_CENTER)

        if self.visible then
            self:drawForecast(ssWeatherManager.forecast)
        end

        self:drawToday(ssWeatherManager.forecast)

        -- Clean up after us, text render after this will be affected otherwise.
        setTextColor(1, 1, 1, 1)
        setTextAlignment(RenderText.ALIGN_LEFT)
    end
end

function ssWeatherForecast:drawForecast(forecast)
    -- Draw grey border background
    self.rect:setPosition(self.forecastX, self.forecastY)
    self.rect:setDimension(self.forecastWidth, self.forecastHeight)
    self.rect:setColor(unpack(g_colorBg))
    self.rect:render()

    -- Draw square background
    self.rect:setColor(0.0075, 0.0075, 0.0075, 1)
    self.rect:setDimension(self.forecastDayWidth, self.forecastDayHeight)
    for i = 1, 7 do
        self.rect:setPosition(self.forecastX + i * self.forecastSpacingWidth + (i - 1) * self.forecastDayWidth, self.forecastY + self.forecastSpacingHeight)
        self.rect:render()
    end

    local dayOffsetY = self.forecastY + self.forecastSpacingHeight

    for n = 2, ssWeatherManager.forecastLength do
        -- X of the day
        local dayOffsetX = self.forecastX + self.forecastSpacingWidth + (n - 2) * (self.forecastDayWidth + self.forecastSpacingWidth)

        local weatherIcon = forecast[n].weatherState

        -- Render Season Icon
        local seasonIcon = self.overlays.seasons[forecast[n].season]
        seasonIcon:setDimension(self.iconWidthSmall, self.iconHeightSmall)
        -- Top right corner
        seasonIcon:setPosition(dayOffsetX + self.forecastDayWidth - self.iconWidthSmall - self.marginX, dayOffsetY + self.forecastDayHeight - self.iconHeightSmall - self.marginY)
        seasonIcon:render()

        -- Render Weather Icon
        local weatherIcon = self.overlays[weatherIcon]
        weatherIcon:setDimension(self.iconWidth, self.iconHeight)
        weatherIcon:setPosition(dayOffsetX + self.marginX, dayOffsetY + (self.forecastDayHeight - self.iconHeight) / 2)
        weatherIcon:render()

        -- Render Season Days
        setTextAlignment(RenderText.ALIGN_CENTER)
        renderText(dayOffsetX + self.forecastDayWidth - self.marginX - self.iconWidthSmall / 2, dayOffsetY + (self.forecastDayHeight - self.textSize * 1.2) / 2, self.textSize * 1.2, tostring(g_seasons.environment:dayInSeason(forecast[n].day)))

        -- Render Hi/Lo Temperatures
        local hiLoTemp = self:getTemperatureHighLowString(forecast[n])

        setTextAlignment(RenderText.ALIGN_LEFT)
        renderText(dayOffsetX + self.marginX, dayOffsetY + self.marginY, self.textSize * 1.2, hiLoTemp)

        -- Render Day of The Week
        -- renderText(self.forecastX + posXOffset + dayOffset, self.forecastY + self.height - posYOffset - self.iconHeightSmall / 2, self.textSize * 1.2, ssUtil.dayNameShort(ssUtil.dayOfWeek(g_seasons.environment:currentDay() + n - 1)))
        local dayName = ssUtil.dayNameShort(ssUtil.dayOfWeek(g_currentMission.environment.currentDay + n - 1))
        renderText(dayOffsetX + self.marginX, dayOffsetY + self.forecastDayHeight - self.textSize * 1.2 - self.marginY, self.textSize * 1.2, dayName)
    end
end

function ssWeatherForecast:getTemperatureHighLowString(data)
    local highTemp = math.floor(data.highTemp)
    local lowTemp = math.floor(data.lowTemp)

    if self.degreeFahrenheit then
        highTemp = math.floor(ssLang.convertTempToFahrenheit(data.highTemp))
        lowTemp = math.floor(ssLang.convertTempToFahrenheit(data.lowTemp))
    end

    return tostring(highTemp) .. " / " .. tostring(lowTemp)
end

function ssWeatherForecast:drawToday(forecast)
    -- Render day and season below the clock
    local clockText = string.format("%02d/%s", g_seasons.environment:dayInSeason(forecast[1].day), ssUtil.fullSeasonName(g_seasons.environment:transitionAtDay(forecast[1].day)))
    local clockX = g_currentMission.timeBgOverlay.x + g_currentMission.timeSeparatorOffsetX / 2
    setTextAlignment(RenderText.ALIGN_CENTER)
    renderText(clockX, g_currentMission.timeBgOverlay.y + 2 * self.marginY, self.textSize * 1.5, clockText)

    -- Create the today backdrop
    self.todayPosX = g_currentMission.infoBarBgOverlay.x - self.borderWidth - self.todayWidth

    -- Render border
    self.rect:setPosition(self.todayPosX, self.todayPosY)
    self.rect:setDimension(self.todayWidth, self.todayHeight)
    self.rect:setColor(unpack(g_colorBg))
    self.rect:render()

    -- Render black-ish background
    self.rect:setPosition(self.todayPosX + self.borderWidth, self.todayPosY + self.borderHeight)
    self.rect:setDimension(self.todayWidth - 2 * self.borderWidth, self.todayHeight - 2 * self.borderHeight)
    self.rect:setColor(0.0075, 0.0075, 0.0075, 1)
    self.rect:render()

    -- Draw line between air and soil temp
    self.rect:setColor(unpack(g_colorBg))

    self.rect:setPosition(self.todayPosX + self.todayVerticalSeparatorOffsetX, g_currentMission.infoBarSeparatorOverlay.y)
    self.rect:setDimension(g_currentMission.infoBarSeparatorOverlay.width, g_currentMission.infoBarSeparatorOverlay.height)
    self.rect:render()

    self.rect:setPosition(self.todayPosX + self.todayIconOffsetX, self.todayHorizontalSeparatorY)
    self.rect:setDimension(self.todayHorizontalSeparatorWidth, self.separatorHeight)
    self.rect:render()

    -- Render Season, cloud and ground icon
    local seasonIcon = self.overlays.seasons[forecast[1].season]
    seasonIcon:setDimension(self.iconWidth, self.iconHeight)
    seasonIcon:setPosition(self.todayPosX + self.borderWidth + self.marginX, self.todayPosY + self.todaySeasonOffsetY)
    seasonIcon:render()

    self.overlays.airSymbol:setPosition(self.todayPosX + self.todayIconOffsetX, self.todayPosY + self.todayAirOffsetY)
    self.overlays.airSymbol:render()

    self.overlays.soilSymbol:setPosition(self.todayPosX + self.todayIconOffsetX, self.todayPosY + self.todaySoilOffsetY)
    self.overlays.soilSymbol:render()

    -- Render current air temperature
    local airTemp = mathRound(ssWeatherManager:currentTemperature(), 0)
    local soilTemp = math.floor(ssWeatherManager.soilTemp, 0)

    setTextAlignment(RenderText.ALIGN_RIGHT)
    renderText(self.todayPosX + self.todayTextOffset, self.todayAirTextY, self.textSize * 1.1, ssLang.formatTemperature(airTemp))
    renderText(self.todayPosX + self.todayTextOffset, self.todaySoilTextY, self.textSize * 1.1, ssLang.formatTemperature(soilTemp))

    -- Render any states
    if ssWeatherManager:isGroundFrozen() then
        self:renderState(self.overlays.frozen)
    elseif g_seasons.weather.moistureEnabled and ssWeatherManager:isCropWet() then
        self:renderState(self.overlays.wetcrop)
    end
end

function ssWeatherForecast:renderState(stateIcon)
    local posX = self.todayPosX - self.borderWidth - self.stateWidth

    -- Render border
    self.rect:setPosition(posX, self.statePosY)
    self.rect:setDimension(self.stateWidth, self.stateHeight)
    self.rect:setColor(unpack(g_colorBg))
    self.rect:render()

    -- Render black-ish background
    local innerWidth, innerHeight = self.stateWidth - 2 * self.borderWidth, self.stateHeight - 2 * self.borderHeight
    local innerX, innerY = posX + self.borderWidth, self.statePosY + self.borderHeight

    self.rect:setPosition(innerX, innerY)
    self.rect:setDimension(innerWidth, innerHeight)
    self.rect:setColor(0.0075, 0.0075, 0.0075, 1)
    self.rect:render()

    -- Render icon
    stateIcon:setPosition(innerX, innerY)
    stateIcon:setDimension(innerWidth, innerHeight)
    stateIcon:render()
end
