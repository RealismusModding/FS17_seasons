---------------------------------------------------------------------------------------------------------
-- WEATHER FORECAST SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  to forecast and display the weather
-- Authors:  Authors:  ian898, Jarvixes, theSeb, reallogger
-- 
-- Credits: Blacky_BPG for scaling the hud

ssWeatherForecast = {}
local screenAspectRatio = g_screenAspectRatio / (16 / 9)
ssWeatherForecast.hud = {}

function ssWeatherForecast:loadMap(name)
    if g_currentMission:getIsClient() then
        self.guiScale = Utils.getNoNil(g_gameSettings:getValue("uiScale"),1)
        self.hud.heigth = 0.1 * self.guiScale * screenAspectRatio
        self.hud.width = (0.1 * self.guiScale * 7) / g_screenAspectRatio * screenAspectRatio
        self.hud.widthSmall = (0.1 * self.guiScale * 4) / g_screenAspectRatio*screenAspectRatio
        self.hud.posX = g_currentMission.infoBarBgOverlay.x - self.hud.width*(0.915)
        self.hud.posXSmall = 1 - self.hud.widthSmall
        self.hud.posY = g_currentMission.infoBarBgOverlay.y - self.hud.heigth*1.1
        self.hud.posYSmall = g_currentMission.infoBarBgOverlay.y
        self.hud.iconHeigth = 0.0444 * self.guiScale * screenAspectRatio
        self.hud.iconWidth = self.hud.iconHeigth / g_screenAspectRatio 
        self.hud.iconHeigthSmall = 0.0222 * self.guiScale * screenAspectRatio
        self.hud.iconWidthSmall = self.hud.iconHeigthSmall / g_screenAspectRatio
        self.hud.textSize = g_currentMission.timeScaleTextSize * 1.5

        -- Set position clock overlay
        self.hud.clockPosX = g_currentMission.timeBgOverlay.x - 0.36 * self.guiScale / g_screenAspectRatio * screenAspectRatio
        self.hud.clockPosY = g_currentMission.timeBgOverlay.y + 0.005 * self.guiScale * screenAspectRatio
        self.hud.clockHeight = 0.04 * self.guiScale * screenAspectRatio
        self.hud.clockWidth = 0.12 * self.guiScale / g_screenAspectRatio * screenAspectRatio

        -- Set position day overlay
        self.hud.dayPosY = g_currentMission.infoBarBgOverlay.y
        self.hud.dayHeight = g_currentMission.infoBarBgOverlay.height
        self.hud.dayWidth = g_currentMission.infoBarBgOverlay.height / g_screenAspectRatio * screenAspectRatio

        self.hud.overlays = {}

        -- Forecast hud
        local width, height = getNormalizedScreenValues(1024, 128)
        self.hud.overlays.forecast_hud = Overlay:new("hud_forecast", Utils.getFilename("resources/huds/hud_forecast.dds", ssSeasonsMod.modDir), 0, 0, width, height)

        -- Current day hud
        local width, height = getNormalizedScreenValues(128, 128)
        self.hud.overlays.day_hud = Overlay:new("hud_day",  Utils.getFilename("resources/huds/hud_day.dds", ssSeasonsMod.modDir), 0, 0, height, height)

        -- clock overlay
        local width, height = getNormalizedScreenValues(64, 64)
        self.hud.overlays.clock_overlay = Overlay:new("clock_overlay",  Utils.getFilename("resources/huds/clock_overlay.dds", ssSeasonsMod.modDir), 0, 0, height, height)
        self.hud.overlays.clock_symbol = Overlay:new("clock_symbol",  Utils.getFilename("resources/huds/clock_symbol.dds", ssSeasonsMod.modDir), 0, 0, height, height)

        -- Seasons "White" Icons
        local width, height = getNormalizedScreenValues(128, 128)

        -- Seasons "Color" Icons
        self.hud.overlays.seasons = {}
        self.hud.overlays.seasons[ssSeasonsUtil.SEASON_SPRING] = Overlay:new("hud_spring", Utils.getFilename("resources/huds/hud_Season_Color/hud_spring_Color.dds", ssSeasonsMod.modDir), 0, 0, width, height)
        self.hud.overlays.seasons[ssSeasonsUtil.SEASON_SUMMER] = Overlay:new("hud_summer", Utils.getFilename("resources/huds/hud_Season_Color/hud_summer_Color.dds", ssSeasonsMod.modDir), 0, 0, width, height)
        self.hud.overlays.seasons[ssSeasonsUtil.SEASON_AUTUMN] = Overlay:new("hud_autumn", Utils.getFilename("resources/huds/hud_Season_Color/hud_autumn_Color.dds", ssSeasonsMod.modDir), 0, 0, width, height)
        self.hud.overlays.seasons[ssSeasonsUtil.SEASON_WINTER] = Overlay:new("hud_winter", Utils.getFilename("resources/huds/hud_Season_Color/hud_winter_Color.dds", ssSeasonsMod.modDir), 0, 0, width, height)

        self.hud.overlays.frozen_hud = Overlay:new("hud_frozen", Utils.getFilename("resources/huds/frozenground.dds", ssSeasonsMod.modDir), 0, 0, width, height)

        -- Seasons Weather Icons
        self.hud.overlays.sun = g_currentMission.weatherForecastIconSunOverlay
        self.hud.overlays.cloudy = g_currentMission.weatherForecastIconOverlays.cloudy
        self.hud.overlays.fog = g_currentMission.weatherForecastIconOverlays.fog
        self.hud.overlays.rain = g_currentMission.weatherForecastIconOverlays.rain
        self.hud.overlays.snow = Overlay:new("hud_snow", Utils.getFilename("resources/huds/hud_snow.dds", ssSeasonsMod.modDir), 0, 0, width, height)

        g_currentMission.weatherForecastIconOverlays.hail = self.hud.overlays.snow
        self.hud.overlays.hail = self.hud.overlays.snow

    end

end

function ssWeatherForecast:load(savegame, key)
    self.hud.visible = ssStorage.getXMLBool(savegame, key .. ".settings.WeatherForecastHudVisible", true)
end

function ssWeatherForecast:save(savegame, key)
    if g_currentMission:getIsServer() == true then
        ssStorage.setXMLBool(savegame, key .. ".settings.WeatherForecastHudVisible", self.hud.visible)
    end
end

function ssWeatherForecast:deleteMap()
end

function ssWeatherForecast:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssWeatherForecast:keyEvent(unicode, sym, modifier, isDown)
end

function ssWeatherForecast:update(dt)
    g_currentMission:addHelpButtonText(g_i18n:getText("input_SEASONS_SHOW_WF"), InputBinding.SEASONS_SHOW_WF)
    if InputBinding.hasEvent(InputBinding.SEASONS_SHOW_WF) then
        self.hud.visible = not self.hud.visible
    end
end

function ssWeatherForecast:draw()
    local forecast = ssWeatherManager.forecast

    if not g_currentMission.fieldJobManager:isFieldJobActive() then 
        -- Set text color and alignment
        setTextColor(1, 1, 1, .9)
        setTextAlignment(RenderText.ALIGN_CENTER)

        if self.hud.visible then
            -- Render Background
            renderOverlay(self.hud.overlays.forecast_hud.overlayId, self.hud.posX, self.hud.posY, self.hud.width, self.hud.heigth)

            -- Set firstDayPos

            local daysPosOffset = (self.hud.width - 0.125 * self.guiScale / g_screenAspectRatio * screenAspectRatio) / 7 

            for n = 2, ssWeatherManager.forecastLength do
                local dayOffset = (daysPosOffset * (n - 2))
                local posXOffset = (0.068*self.guiScale)/g_screenAspectRatio*screenAspectRatio
                local posYOffset = 0.01*self.guiScale*screenAspectRatio
                local weatherIcon = forecast[n].weatherState

                -- Render Season Icon
                renderOverlay(self.hud.overlays.seasons[forecast[n].season].overlayId, self.hud.posX + posXOffset + self.hud.iconWidth + self.hud.iconWidthSmall/4 + dayOffset, self.hud.posY + self.hud.heigth - posYOffset - self.hud.iconHeigthSmall*0.8, self.hud.iconWidthSmall, self.hud.iconHeigthSmall)

                -- Render Weather Icon
                renderOverlay(self.hud.overlays[weatherIcon].overlayId, self.hud.posX + posXOffset + dayOffset, self.hud.posY + self.hud.heigth - posYOffset - self.hud.iconHeigth*1.4, self.hud.iconWidth, self.hud.iconHeigth)

                -- Render Season Days
                setTextAlignment(RenderText.ALIGN_CENTER)
                renderText(self.hud.posX + posXOffset + self.hud.iconWidth + self.hud.iconWidthSmall*3/4 + dayOffset, self.hud.posY + self.hud.heigth - posYOffset - self.hud.iconHeigth, self.hud.textSize, tostring(ssSeasonsUtil:dayInSeason(forecast[n].day)))

                -- Render Hi/Lo Temperatures
                local tempString = tostring(math.floor(forecast[n].highTemp)) .. " / " .. tostring(math.floor(forecast[n].lowTemp))
                setTextAlignment(RenderText.ALIGN_LEFT)
                renderText(self.hud.posX + posXOffset + dayOffset, self.hud.posY + posYOffset, self.hud.textSize, tempString)

                -- Render Day of The Week
                renderText(self.hud.posX + posXOffset + dayOffset, self.hud.posY + self.hud.heigth - posYOffset - self.hud.iconHeigthSmall/2, self.hud.textSize, ssSeasonsUtil:dayNameShort(ssSeasonsUtil:dayOfWeek()+n-1))
            end

        end

        self.hud.dayPosX = g_currentMission.infoBarBgOverlay.x - 0.08 * self.guiScale / g_screenAspectRatio * screenAspectRatio
        -- Render clock background
        renderOverlay(self.hud.overlays.clock_overlay.overlayId, self.hud.clockPosX , self.hud.clockPosY, self.hud.clockWidth, self.hud.clockHeight)

        -- Render clock
        setTextAlignment(RenderText.ALIGN_CENTER)
        renderText(self.hud.clockPosX + self.hud.clockWidth/2 + self.hud.iconWidthSmall/2,self.hud.clockPosY + self.hud.clockHeight - self.hud.textSize, self.hud.textSize*1.5, string.format("%02d:%02d", g_currentMission.environment.currentHour, g_currentMission.environment.currentMinute))
        renderOverlay(self.hud.overlays.clock_symbol.overlayId, self.hud.clockPosX, self.hud.clockPosY + self.hud.clockHeight - self.hud.textSize*1.3, self.hud.iconWidthSmall*1.2, self.hud.iconHeigthSmall*1.2)
        renderText(self.hud.clockPosX + self.hud.clockWidth/2,self.hud.clockPosY, self.hud.textSize, string.format("%02d/%s/%d", ssSeasonsUtil:dayInSeason(forecast[1].day), ssSeasonsUtil.seasons[forecast[1].season], ssSeasonsUtil:year() + 2017))

        -- Render Background
        renderOverlay(self.hud.overlays.day_hud.overlayId, self.hud.dayPosX , self.hud.dayPosY, self.hud.dayWidth, self.hud.dayHeight)
    
        if ssWeatherManager:isGroundWorkable() == false then
            renderOverlay(self.hud.overlays.frozen_hud.overlayId, self.hud.dayPosX - self.hud.dayHeight*0.8, self.hud.dayPosY + self.hud.dayHeight*0.1, self.hud.dayHeight/g_screenAspectRatio*0.8, self.hud.dayHeight*0.8)
        end

        -- Render Season Icon
        renderOverlay(self.hud.overlays.seasons[forecast[1].season].overlayId, self.hud.dayPosX + self.hud.dayWidth/2 - self.hud.iconWidthSmall*0.75, self.hud.dayPosY + self.hud.dayHeight - self.hud.iconHeigthSmall*1.7, self.hud.iconWidthSmall*1.5, self.hud.iconHeigthSmall*1.5)

        -- Render current Temperatures
        local currentTemp = mathRound(ssWeatherManager:diurnalTemp(g_currentMission.environment.currentHour, g_currentMission.environment.currentMinute), 0)
        setTextAlignment(RenderText.ALIGN_RIGHT)
        renderText(self.hud.dayPosX + self.hud.dayWidth - self.hud.iconWidthSmall*0.5, self.hud.dayPosY + self.hud.iconHeigthSmall*0.5, self.hud.textSize, tostring(currentTemp .. "ºC"))

        -- Clean up after us, text render after this will be affected otherwise.
        setTextColor(1, 1, 1, 1)
    end

end