---------------------------------------------------------------------------------------------------------
-- WEATHER FORECAST SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  to forecast and display the weather
-- Authors:  Authors:  ian898, Jarvixes, theSeb, reallogger
--

-- HUD changed to fit other resolution settings with scaling the hud and add user friendly information | Blacky_BPG

ssWeatherForecast = {}
local screenAspectRatio = g_screenAspectRatio / (16 / 9)

function ssWeatherForecast:load(savegame, key)
	self.hud.visible = ssStorage.getXMLBool(savegame, key .. ".settings.forecastHudVisible", true)
end

function ssWeatherForecast:save(savegame, key)
	ssStorage.setXMLBool(savegame, key .. ".settings.forecastHudVisible", self.hud.visible)
end

function ssWeatherForecast:loadMap(name)
    if g_currentMission:getIsClient() then
        self.hud = {}
        self.hud.visible = true

        self.guiScale = Utils.getNoNil(g_gameSettings:getValue("uiScale"),1)
        self.hud.heigth = 0.0694 * self.guiScale * screenAspectRatio
        self.hud.width = (self.hud.heigth * 7) / g_screenAspectRatio
        self.hud.widthSmall = (self.hud.heigth * 4) / g_screenAspectRatio
        self.hud.posX = 0.9807 - self.hud.width
        self.hud.posXSmall = 0.9807 - self.hud.widthSmall
        self.hud.posY = g_currentMission.infoBarBgOverlay.y - self.hud.heigth
        self.hud.posYSmall = g_currentMission.infoBarBgOverlay.y
        self.hud.iconHeigth = 0.0444 * self.guiScale * screenAspectRatio
        self.hud.iconWidth = self.hud.iconHeigth / g_screenAspectRatio
        self.hud.iconHeigthSmall = 0.0222 * self.guiScale * screenAspectRatio
        self.hud.iconWidthSmall = self.hud.iconHeigthSmall / g_screenAspectRatio
        self.hud.iconWidthCurrent = g_currentMission.weatherForecastIconSunOverlay.width
        self.hud.iconHeigthCurrent = g_currentMission.weatherForecastIconSunOverlay.height
        self.hud.textSize = g_currentMission.timeScaleTextSize * 1.25
        self.hud.overlays = {}

        -- Forecast hud
        local width, height = getNormalizedScreenValues(1024, 128)
        self.hud.overlays.forecast_hud = Overlay:new("hud_forecast", Utils.getFilename("resources/huds/hud_forecast.dds", ssSeasonsMod.modDir), 0, 0, width, height)
        self.hud.overlays.forecast_hud_sml = Overlay:new("hud_forecast_sml", Utils.getFilename("resources/huds/hud_forecast_sml.dds", ssSeasonsMod.modDir), 0, 0, width, height)

        -- Seasons "White" Icons
        local width, height = getNormalizedScreenValues(128, 128)

        -- Seasons "Color" Icons
        self.hud.overlays[0] = Overlay:new("hud_spring", Utils.getFilename("resources/huds/hud_Season_Color/hud_spring_Color.dds", ssSeasonsMod.modDir), 0, 0, width, height)
        self.hud.overlays[1] = Overlay:new("hud_summer", Utils.getFilename("resources/huds/hud_Season_Color/hud_summer_Color.dds", ssSeasonsMod.modDir), 0, 0, width, height)
        self.hud.overlays[2] = Overlay:new("hud_autumn", Utils.getFilename("resources/huds/hud_Season_Color/hud_autumn_Color.dds", ssSeasonsMod.modDir), 0, 0, width, height)
        self.hud.overlays[3] = Overlay:new("hud_winter", Utils.getFilename("resources/huds/hud_Season_Color/hud_winter_Color.dds", ssSeasonsMod.modDir), 0, 0, width, height)

        -- Seasons Weather Icons
        self.hud.overlays.sun = g_currentMission.weatherForecastIconSunOverlay
        self.hud.overlays.cloudy = g_currentMission.weatherForecastIconOverlays.cloudy
        self.hud.overlays.fog = g_currentMission.weatherForecastIconOverlays.fog
        self.hud.overlays.rain = g_currentMission.weatherForecastIconOverlays.rain
        self.hud.overlays.snow = Overlay:new("hud_snow", Utils.getFilename("resources/huds/hud_snow.dds", ssSeasonsMod.modDir), 0, 0, width, height)

        -- we need the hail icon for other seasons, only in winter we need the snow icon
        self.hud.overlays.hail = g_currentMission.weatherForecastIconOverlays.hail
        -- g_currentMission.weatherForecastIconOverlays.hail = self.hud.overlays.snow
        -- self.hud.overlays.hail = self.hud.overlays.snow
    end
end

function ssWeatherForecast:deleteMap()
end

function ssWeatherForecast:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssWeatherForecast:keyEvent(unicode, sym, modifier, isDown)
-- we have a key assigned in moddesc, so this is obsolete
--    if (unicode == 107) then
--        self.hud.visible = not self.hud.visible
--    end
end

function ssWeatherForecast:update(dt)
    if InputBinding.hasEvent(InputBinding.SEASONS_SHOW_WF) then
        self.hud.visible = not self.hud.visible
    end
end

function ssWeatherForecast:draw()
    local forecast = ssWeatherManager.forecast

    if self.hud.visible then
        -- Render Background
        renderOverlay(self.hud.overlays.forecast_hud.overlayId, self.hud.posX, self.hud.posY, self.hud.width, self.hud.heigth)

        -- Set text color and alignment
        setTextColor(1, 1, 1, 1)
        setTextAlignment(RenderText.ALIGN_CENTER)

        -- Set firstDayPos
        local daysPosOffset = (self.hud.width - 0.006 / g_screenAspectRatio) / 7 -- self.hud.heigth / g_screenAspectRatio

        for n = 2, ssWeatherManager.forecastLength do
            -- Render Weather Icon
            local dayOffset = (daysPosOffset * (n - 2))
            local posXOffset = (0.005*self.guiScale*screenAspectRatio)/g_screenAspectRatio
            local posYOffset = 0.005*self.guiScale*screenAspectRatio
            local weatherIcon = forecast[n].weatherState
            if forecast[n].season == ssSeasonsUtil.SEASON_WINTER and forecast[n].weatherState == "hail" then
                weatherIcon = "snow"
            end
            renderOverlay(self.hud.overlays[weatherIcon].overlayId, self.hud.posX + posXOffset + dayOffset, self.hud.posY + self.hud.heigth - posYOffset - self.hud.iconHeigth, self.hud.iconWidth, self.hud.iconHeigth)

            -- Render Season Icon
            renderOverlay(self.hud.overlays[forecast[n].season].overlayId, self.hud.posX + posXOffset + self.hud.iconWidth + dayOffset, self.hud.posY + self.hud.heigth - posYOffset - self.hud.iconHeigthSmall, self.hud.iconWidthSmall, self.hud.iconHeigthSmall)

            -- Render Day of The Season
            setTextAlignment(RenderText.ALIGN_CENTER)
            renderText(self.hud.posX + self.hud.iconWidth + posXOffset + self.hud.iconWidthSmall/2 + dayOffset, self.hud.posY + self.hud.heigth - self.hud.iconHeigthSmall * 2, self.hud.textSize, tostring(ssSeasonsUtil:dayInSeason(forecast[n].day)))

            -- Render Hi/Lo Tempratures
            setTextAlignment(RenderText.ALIGN_RIGHT)
            local tempString = tostring(math.floor(forecast[n].highTemp)) .. " / " .. tostring(math.floor(forecast[n].lowTemp))
            renderText(self.hud.posX + self.hud.iconWidth + self.hud.iconWidthSmall + dayOffset, self.hud.posY + posYOffset, self.hud.textSize*0.9, tempString)

            -- Render day of week
            setTextAlignment(RenderText.ALIGN_LEFT)
            renderText(self.hud.posX + posXOffset + dayOffset, self.hud.posY + posYOffset, self.hud.textSize, ssSeasonsUtil:dayNameShort(ssSeasonsUtil:dayOfWeek()+n))
        end

    end


    -- current day hud
    local xPos = 0.9807 - g_currentMission.infoBarBgOverlay.width - self.hud.widthSmall + g_currentMission.weatherForecastBgOverlay.width + 0.009 / g_screenAspectRatio
    local xPosIcon = xPos + self.hud.widthSmall - self.hud.iconWidthCurrent * 1.1
    local yPosIcon = self.hud.posYSmall + (self.hud.heigth - self.hud.iconHeigthCurrent) / 2

    -- current day hud background
    renderOverlay(self.hud.overlays.forecast_hud_sml.overlayId, xPos,  self.hud.posYSmall, self.hud.widthSmall, self.hud.heigth)

    local season = ssSeasonsUtil:season()
    local currentWeather = ssWeatherManager:getWeatherStateForHour(ssSeasonsUtil:currentDayNumber(),g_currentMission.environment.currentHour)
    local nextWeather = ssWeatherManager:getWeatherStateForHour(ssSeasonsUtil:currentDayNumber(),g_currentMission.environment.currentHour+1)
    local currentWeatherIcon = currentWeather
    if season == ssSeasonsUtil.SEASON_WINTER and currentWeather == "hail" then
        currentWeatherIcon = "snow"
    end
    local nextWeatherIcon = nextWeather
    if season == ssSeasonsUtil.SEASON_WINTER and nextWeather == "hail" then
        nextWeatherIcon = "snow"
    end

    -- current, and if changes in next hour, next weather
    if currentWeather == nextWeather then
        renderOverlay(self.hud.overlays[currentWeatherIcon].overlayId, xPosIcon, yPosIcon, self.hud.iconWidthCurrent, self.hud.iconHeigthCurrent)
    else
        renderOverlay(self.hud.overlays[currentWeatherIcon].overlayId, xPosIcon, yPosIcon + self.hud.iconHeigthCurrent*0.2, self.hud.iconWidthCurrent*0.8, self.hud.iconHeigthCurrent*0.8)
        renderOverlay(self.hud.overlays[nextWeatherIcon].overlayId, xPosIcon + self.hud.iconWidthCurrent*0.6, yPosIcon, self.hud.iconWidthCurrent*0.4, self.hud.iconHeigthCurrent*0.4)
    end

    -- current season
    renderOverlay(self.hud.overlays[season].overlayId, xPosIcon - self.hud.iconWidthCurrent - self.hud.iconWidthCurrent*0.2, yPosIcon + self.hud.iconHeigthCurrent*0.2, self.hud.iconWidthCurrent*0.8, self.hud.iconHeigthCurrent*0.8)

    -- current season day
    setTextAlignment(RenderText.ALIGN_CENTER)
    renderText(xPosIcon - self.hud.iconWidthCurrent - self.hud.iconWidthCurrent*0.2 + self.hud.iconWidthCurrent*0.5, yPosIcon + 0.005*self.guiScale*screenAspectRatio, self.hud.textSize * 0.9, " ("..ssSeasonsUtil:dayInSeason(ssSeasonsUtil:currentDayNumber()).." / "..tostring(ssSeasonsUtil.daysInSeason)..")");

    -- this function we need in the utils script so we can show the "real" ingame date
    local y,m,d = ssSeasonsUtil:getInGameDate()
    local dateText = tostring(d).."."..tostring(m).."."..tostring(y)
    setTextAlignment(RenderText.ALIGN_LEFT)
    renderText(xPos + (0.008*self.guiScale*screenAspectRatio)/g_screenAspectRatio, yPosIcon + 0.005*self.guiScale*screenAspectRatio + self.hud.textSize*2.8, self.hud.textSize*0.9, ssSeasonsUtil:dayName().."   |   "..dateText);
    renderText(xPos + (0.008*self.guiScale*screenAspectRatio)/g_screenAspectRatio, yPosIcon + 0.005*self.guiScale*screenAspectRatio + self.hud.textSize*1.4, self.hud.textSize*0.9, ssLang.getText("SS_DAY", "Playday: ")..ssSeasonsUtil:currentDayNumber());
    renderText(xPos + (0.008*self.guiScale*screenAspectRatio)/g_screenAspectRatio, yPosIcon + 0.005*self.guiScale*screenAspectRatio, self.hud.textSize*0.9, ssLang.getText("SS_TEMPERATURE_NAME", "Temp: ")..tostring(math.floor(ssWeatherManager:diurnalTemp(g_currentMission.environment.currentHour, g_currentMission.environment.currentMinute)*10)/10).." C");

    -- Clean up after us, text render after this will be affected otherwise.
    setTextColor(1, 1, 1, 1)
end
