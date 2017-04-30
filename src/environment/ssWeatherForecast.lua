----------------------------------------------------------------------------------------------------
-- WEATHER FORECAST SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  to forecast and display the weather
-- Authors:  ian898, Rahkiin, theSeb, reallogger
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssWeatherForecast = {}
g_seasons.forecast = ssWeatherForecast

local screenAspectRatio = g_screenAspectRatio / (16 / 9)
ssWeatherForecast.hud = {}

function ssWeatherForecast:loadMap(name)
    if g_currentMission:getIsClient() then
        self.guiScale = Utils.getNoNil(g_gameSettings:getValue("uiScale"), 1)
        self.hud.width, self.hud.height = getNormalizedScreenValues(60 * 7 * self.guiScale, 60 * self.guiScale)
        self.hud.widthSmall, _ = getNormalizedScreenValues(60 * 4 * self.guiScale, 0)
        --self.hud.widthSmall = (0.1 * self.guiScale * 4) / g_screenAspectRatio * screenAspectRatio
        self.hud.posX = g_currentMission.infoBarBgOverlay.x - self.hud.width * (0.915)
        self.hud.posXSmall = 1 - self.hud.widthSmall
        self.hud.posY = g_currentMission.infoBarBgOverlay.y - self.hud.height * 1.1
        self.hud.posYSmall = g_currentMission.infoBarBgOverlay.y
        self.hud.iconWidth, self.hud.iconHeight = getNormalizedScreenValues(28 * self.guiScale, 28 * self.guiScale)
        self.hud.iconWidthSmall, self.hud.iconHeightSmall = getNormalizedScreenValues(14 * self.guiScale, 14 * self.guiScale)
        self.hud.textSize = g_currentMission.timeScaleTextSize

        -- Set position clock overlay
        _, self.hud.clockPosY = getNormalizedScreenValues(0, 2 * self.guiScale)
        self.hud.clockPosY = self.hud.clockPosY + g_currentMission.timeBgOverlay.y
        self.hud.clockWidth, self.hud.clockHeight = getNormalizedScreenValues(100 * self.guiScale, 35* self.guiScale)

        -- Set position day overlay
        --self.hud.dayPosX = self.hud.posX + self.hud.width * (1 - 0.915)
        self.hud.dayPosY = g_currentMission.infoBarBgOverlay.y
        self.hud.dayHeight = g_currentMission.infoBarBgOverlay.height
        --self.hud.dayWidth = g_currentMission.infoBarBgOverlay.height / g_screenAspectRatio * screenAspectRatio
        self.hud.dayWidth = self.hud.width / 6.5

        self.hud.overlays = {}

        -- Forecast hud
        local width, height = getNormalizedScreenValues(1024, 128)
        self.hud.overlays.forecast_hud = Overlay:new("hud_forecast", Utils.getFilename("resources/huds/hud_forecast.dds", g_seasons.modDir), 0, 0, width, height)

        -- Current day hud
        local width, height = getNormalizedScreenValues(256, 128)
        self.hud.overlays.day_hud = Overlay:new("hud_day",  Utils.getFilename("resources/huds/hud_day.dds", g_seasons.modDir), 0, 0, height, height)

        -- clock overlay and cloud and ground for day hud
        local width, height = getNormalizedScreenValues(64, 64)
        local _, y = getNormalizedScreenValues(0, 5)
        g_currentMission.timeOffsetY = g_currentMission.timeOffsetY + y
        g_currentMission.timeIconOverlay.y = g_currentMission.timeIconOverlay.y + y

        self.hud.overlays.ground_symbol = Overlay:new("ground_symbol",  Utils.getFilename("resources/huds/ground_symbol.dds", g_seasons.modDir), 0, 0, height, height)
        self.hud.overlays.cloud_symbol = Overlay:new("cloud_symbol",  Utils.getFilename("resources/huds/cloud_symbol.dds", g_seasons.modDir), 0, 0, height, height)

        -- Seasons "White" Icons
        local width, height = getNormalizedScreenValues(128, 128)

        -- Seasons "Color" Icons
        self.hud.overlays.seasons = {}
        self.hud.overlays.seasons[ssEnvironment.SEASON_SPRING] = Overlay:new("hud_spring", Utils.getFilename("resources/huds/hud_Season_Color/hud_spring_Color.dds", g_seasons.modDir), 0, 0, width, height)
        self.hud.overlays.seasons[ssEnvironment.SEASON_SUMMER] = Overlay:new("hud_summer", Utils.getFilename("resources/huds/hud_Season_Color/hud_summer_Color.dds", g_seasons.modDir), 0, 0, width, height)
        self.hud.overlays.seasons[ssEnvironment.SEASON_AUTUMN] = Overlay:new("hud_autumn", Utils.getFilename("resources/huds/hud_Season_Color/hud_autumn_Color.dds", g_seasons.modDir), 0, 0, width, height)
        self.hud.overlays.seasons[ssEnvironment.SEASON_WINTER] = Overlay:new("hud_winter", Utils.getFilename("resources/huds/hud_Season_Color/hud_winter_Color.dds", g_seasons.modDir), 0, 0, width, height)

        self.hud.overlays.frozen_hud = Overlay:new("hud_frozen", Utils.getFilename("resources/huds/frozenground.dds", g_seasons.modDir), 0, 0, width, height)
        self.hud.overlays.wetcrop_hud = Overlay:new("hud_wetcrop", Utils.getFilename("resources/huds/wetcrop.dds", g_seasons.modDir), 0, 0, width, height)

        -- Seasons Weather Icons
        self.hud.overlays.sun = g_currentMission.weatherForecastIconSunOverlay
        self.hud.overlays.cloudy = g_currentMission.weatherForecastIconOverlays.cloudy
        self.hud.overlays.fog = g_currentMission.weatherForecastIconOverlays.fog
        self.hud.overlays.rain = g_currentMission.weatherForecastIconOverlays.rain
        self.hud.overlays.snow = Overlay:new("hud_snow", Utils.getFilename("resources/huds/hud_snow.dds", g_seasons.modDir), 0, 0, width, height)

        g_currentMission.weatherForecastIconOverlays.snow = self.hud.overlays.snow
        self.hud.overlays.hail = self.hud.overlays.snow
    end
end

function ssWeatherForecast:load(savegame, key)
    self.hud.visible = ssXMLUtil.getBool(savegame, key .. ".settings.weatherForecastHudVisible", false)
    self.degreeFahrenheit = ssXMLUtil.getBool(savegame, key .. ".weather.fahrenheit", false)
end

function ssWeatherForecast:save(savegame, key)
    if g_currentMission:getIsServer() == true then
        ssXMLUtil.setBool(savegame, key .. ".settings.weatherForecastHudVisible", self.hud.visible)
        ssXMLUtil.setBool(savegame, key .. ".weather.fahrenheit", self.degreeFahrenheit)
    end
end

function ssWeatherForecast:update(dt)
    if g_seasons.showControlsInHelpScreen then
        if not self.hud.visible then
            g_currentMission:addHelpButtonText(g_i18n:getText("input_SEASONS_SHOW_WF"), InputBinding.SEASONS_SHOW_WF, nil, GS_PRIO_VERY_LOW)
        else
            g_currentMission:addHelpButtonText(g_i18n:getText("SEASONS_HIDE_WF"), InputBinding.SEASONS_SHOW_WF, nil, GS_PRIO_VERY_LOW)
        end
    end

    if InputBinding.hasEvent(InputBinding.SEASONS_SHOW_WF) then
        self.hud.visible = not self.hud.visible
    end
end

function ssWeatherForecast:draw()
    if (g_currentMission.fieldJobManager == nil or not g_currentMission.fieldJobManager:isFieldJobActive())
        and g_currentMission.showHudEnv then

        -- Set text color and alignment
        setTextColor(1, 1, 1, .9)
        setTextAlignment(RenderText.ALIGN_CENTER)

        if self.hud.visible then
            self:drawForecast(ssWeatherManager.forecast)
        end

        self:drawToday(ssWeatherManager.forecast)

        -- Clean up after us, text render after this will be affected otherwise.
        setTextColor(1, 1, 1, 1)
        setTextAlignment(RenderText.ALIGN_LEFT)
    end
end

function ssWeatherForecast:drawForecast(forecast)
    -- Render Background
    renderOverlay(self.hud.overlays.forecast_hud.overlayId, self.hud.posX, self.hud.posY, self.hud.width, self.hud.height)

    -- Set firstDayPos
    local daysPosOffset = self.hud.width / 8.5

    for n = 2, ssWeatherManager.forecastLength do
        local dayOffset = (daysPosOffset * (n - 2))
        local posXOffset, posYOffset = getNormalizedScreenValues(40 * self.guiScale, 6 * self.guiScale)
        local weatherIcon = forecast[n].weatherState

        -- Render Season Icon
        renderOverlay(self.hud.overlays.seasons[forecast[n].season].overlayId, self.hud.posX + posXOffset + self.hud.iconWidth + self.hud.iconWidthSmall / 4 + dayOffset, self.hud.posY + self.hud.height - posYOffset - self.hud.iconHeightSmall * 0.8, self.hud.iconWidthSmall, self.hud.iconHeightSmall)

        -- Render Weather Icon
        renderOverlay(self.hud.overlays[weatherIcon].overlayId, self.hud.posX + posXOffset + dayOffset, self.hud.posY + self.hud.height - posYOffset - self.hud.iconHeight * 1.4, self.hud.iconWidth, self.hud.iconHeight)

        -- Render Season Days
        setTextAlignment(RenderText.ALIGN_CENTER)
        renderText(self.hud.posX + posXOffset + self.hud.iconWidth + self.hud.iconWidthSmall * 3 / 4 + dayOffset, self.hud.posY + self.hud.height - posYOffset - self.hud.iconHeight, self.hud.textSize * 1.2, tostring(g_seasons.environment:dayInSeason(forecast[n].day)))

        -- Render Hi/Lo Temperatures
        local tempString = self:getTemperatureHighLowString(forecast[n])

        setTextAlignment(RenderText.ALIGN_LEFT)
        renderText(self.hud.posX + posXOffset + dayOffset, self.hud.posY + posYOffset, self.hud.textSize * 1.2, tempString)

        -- Render Day of The Week
        renderText(self.hud.posX + posXOffset + dayOffset, self.hud.posY + self.hud.height - posYOffset - self.hud.iconHeightSmall / 2, self.hud.textSize * 1.2, ssUtil.dayNameShort(ssUtil.dayOfWeek(g_seasons.environment:currentDay() + n - 1)))
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
    -- x-position of overlays has to be dynamically defined
    self.hud.dayPosX = g_currentMission.infoBarBgOverlay.x - 0.10 * self.guiScale / g_screenAspectRatio * screenAspectRatio
    self.hud.clockPosX = g_currentMission.moneyIconOverlay.x - self.hud.clockWidth * 1.42 -- 1.45

    -- Render clock
    setTextAlignment(RenderText.ALIGN_CENTER)

    -- Render day and season
    renderText(self.hud.clockPosX + self.hud.clockWidth / 2, self.hud.clockPosY, self.hud.textSize * 1.5, string.format("%02d/%s", g_seasons.environment:dayInSeason(forecast[1].day), ssUtil.fullSeasonName(g_seasons.environment:transitionAtDay(forecast[1].day))))

    -- Render Background
    renderOverlay(self.hud.overlays.day_hud.overlayId, self.hud.dayPosX , self.hud.dayPosY, self.hud.dayWidth, self.hud.dayHeight)
    -- TODO: Render gray overlay (pixel)
    -- TODO: Render black overlay (pixel)

    if ssWeatherManager:isGroundFrozen() then
        renderOverlay(self.hud.overlays.frozen_hud.overlayId, self.hud.dayPosX - self.hud.dayHeight * 0.6, self.hud.dayPosY + self.hud.dayHeight * 0.1, self.hud.dayHeight / g_screenAspectRatio * 0.8, self.hud.dayHeight * 0.8)
    end

    if g_seasons.weather.moistureEnabled and not ssWeatherManager:isGroundFrozen() and ssWeatherManager:isCropWet() then
        renderOverlay(self.hud.overlays.wetcrop_hud.overlayId, self.hud.dayPosX - self.hud.dayHeight * 0.6, self.hud.dayPosY + self.hud.dayHeight * 0.1, self.hud.dayHeight / g_screenAspectRatio * 0.8, self.hud.dayHeight * 0.8)
    end

    -- Render Season, cloud and ground icon
    renderOverlay(self.hud.overlays.seasons[forecast[1].season].overlayId, self.hud.dayPosX + self.hud.iconWidthSmall * 0.3, self.hud.dayPosY + self.hud.dayHeight / 2 - self.hud.iconHeightSmall / 2 * 1.5, self.hud.iconWidthSmall * 1.5, self.hud.iconHeightSmall * 1.5)
    renderOverlay(self.hud.overlays.cloud_symbol.overlayId, self.hud.dayPosX + self.hud.dayWidth / 2 - self.hud.iconWidthSmall * 0.6, self.hud.dayPosY + self.hud.dayHeight - self.hud.iconHeightSmall * 1.7, self.hud.iconWidthSmall, self.hud.iconHeightSmall)
    renderOverlay(self.hud.overlays.ground_symbol.overlayId, self.hud.dayPosX + self.hud.dayWidth / 2 - self.hud.iconWidthSmall * 0.6, self.hud.dayPosY + self.hud.iconHeightSmall * 0.7, self.hud.iconWidthSmall, self.hud.iconHeightSmall)

    -- Render current air temperature
    setTextAlignment(RenderText.ALIGN_RIGHT)
    local airTemp = mathRound(ssWeatherManager:currentTemperature(), 0)
    renderText(self.hud.dayPosX + self.hud.dayWidth - self.hud.iconWidthSmall * 0.4, self.hud.dayPosY + self.hud.dayHeight * 0.65, self.hud.textSize * 1.1, ssLang.formatTemperature(airTemp))

    -- Render current soil temperature
    setTextAlignment(RenderText.ALIGN_RIGHT)
    local soilTemp = math.floor(ssWeatherManager.soilTemp, 0)
    renderText(self.hud.dayPosX + self.hud.dayWidth - self.hud.iconWidthSmall * 0.4, self.hud.dayPosY + self.hud.dayHeight * 0.25, self.hud.textSize * 1.1, ssLang.formatTemperature(soilTemp))
end
