---------------------------------------------------------------------------------------------------------
-- WEATHER FORECAST SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  to forecast and display the weather
-- Authors:  Authors:  ian898, Jarvixes, theSeb, reallogger
--
-- Forecast hud does not currently scale and does not work on all screen resolutions - TO BE FIXED

ssWeatherForecast = {}

function ssWeatherForecast:loadMap(name)
    if g_currentMission:getIsClient() then
        self.hud = {}
        self.hud.visible = true

        self.hud.posY = -0.14
        self.hud.posX = 0.504

        self.hud.overlays = {}

        -- Forecast hud
        local width, height = getNormalizedScreenValues(1024, 128)
        self.hud.overlays.forecast_hud = Overlay:new("hud_forecast", Utils.getFilename("resources/huds/hud_forecast.png", ssSeasonsMod.modDir), 0, 0, width, height)

        -- Current day hud
        local width, height = getNormalizedScreenValues(128, 128)
        self.hud.overlays.day_hud = Overlay:new("hud_day",  Utils.getFilename("resources/huds/hud_day.png", ssSeasonsMod.modDir), 0, 0, height, height)

        -- clock overlay
        local width, height = getNormalizedScreenValues(64, 64)
        self.hud.overlays.clock_overlay = Overlay:new("clock_overlay",  Utils.getFilename("resources/huds/clock_overlay.png", ssSeasonsMod.modDir), 0, 0, height, height)
        self.hud.overlays.clock_symbol = Overlay:new("clock_symbol",  Utils.getFilename("resources/huds/clock_symbol.png", ssSeasonsMod.modDir), 0, 0, height, height)

        -- Seasons "White" Icons
        local width, height = getNormalizedScreenValues(128, 128)

        -- Seasons "Color" Icons
        self.hud.overlays.Spring = Overlay:new("hud_spring", Utils.getFilename("resources/huds/hud_Season_Color/hud_spring_Color.png", ssSeasonsMod.modDir), 0, 0, width, height)
        self.hud.overlays.Summer = Overlay:new("hud_summer", Utils.getFilename("resources/huds/hud_Season_Color/hud_summer_Color.png", ssSeasonsMod.modDir), 0, 0, width, height)
        self.hud.overlays.Autumn = Overlay:new("hud_autumn", Utils.getFilename("resources/huds/hud_Season_Color/hud_autumn_Color.png", ssSeasonsMod.modDir), 0, 0, width, height)
        self.hud.overlays.Winter = Overlay:new("hud_winter", Utils.getFilename("resources/huds/hud_Season_Color/hud_winter_Color.png", ssSeasonsMod.modDir), 0, 0, width, height)

        -- Seasons Weather Icons
        self.hud.overlays.sun = g_currentMission.weatherForecastIconSunOverlay
        self.hud.overlays.cloudy = g_currentMission.weatherForecastIconOverlays.cloudy
        self.hud.overlays.fog = g_currentMission.weatherForecastIconOverlays.fog
        self.hud.overlays.rain = g_currentMission.weatherForecastIconOverlays.rain
        self.hud.overlays.snow = Overlay:new("hud_snow", Utils.getFilename("resources/huds/hud_snow.png", ssSeasonsMod.modDir), 0, 0, width, height)

        g_currentMission.weatherForecastIconOverlays.hail = self.hud.overlays.snow
        self.hud.overlays.hail = self.hud.overlays.snow

    end

    uiScale = g_gameSettings:getValue("uiScale")
end

function ssWeatherForecast:deleteMap()
end

function ssWeatherForecast:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssWeatherForecast:keyEvent(unicode, sym, modifier, isDown)
    if (unicode == 107) then
        self.hud.visible = not self.hud.visible
    end
end

function ssWeatherForecast:update(dt)
end

function ssWeatherForecast:draw()
    local forecast = ssWeatherManager.forecast

    -- Set text color and alignment
    setTextColor(1, 1, 1, .9)
    setTextAlignment(RenderText.ALIGN_CENTER)

    if self.hud.visible then
        -- Set position WeatherForecast overlay.
        local WeatherForecastPosX = self.hud.posX
        local WeatherForecastPosY = g_currentMission.moneyIconOverlay.y + self.hud.posY

        -- Render Background
        renderOverlay(self.hud.overlays.forecast_hud.overlayId, WeatherForecastPosX,  WeatherForecastPosY, 0.52, 0.114)

        -- Set firstDayPos
        local daysPosOffset = 0.0615

        for n = 2, ssWeatherManager.forecastLength do
            -- Render Day of The Week
            renderText(WeatherForecastPosX + 0.068 + (daysPosOffset * (n - 2)), WeatherForecastPosY + 0.086, 0.02, ssSeasonsUtil:dayNameShort(ssSeasonsUtil:dayOfWeek()+n-1))

            -- Render Season Icon
            renderOverlay(self.hud.overlays[ssSeasonsUtil.seasons[forecast[n].season]].overlayId, WeatherForecastPosX + 0.086 + (daysPosOffset * (n - 2)), WeatherForecastPosY + 0.074, 0.0185, 0.0335)

            -- Render Weather Icon
            renderOverlay(self.hud.overlays[forecast[n].weatherState].overlayId, WeatherForecastPosX + 0.053 + (daysPosOffset * (n - 2)), WeatherForecastPosY + 0.026, 0.032, 0.058)

            -- Render Hi/Lo Temperatures
            local tempString = tostring(math.floor(forecast[n].highTemp)) .. " / " .. tostring(math.floor(forecast[n].lowTemp))
            renderText(WeatherForecastPosX + 0.068 + (daysPosOffset * (n - 2)), WeatherForecastPosY + 0.01, 0.018, tempString)
            --renderText(WeatherForecastPosX + 0.068 + (daysPosOffset * (n - 1)), WeatherForecastPosY + 0.01, 0.018, "22 / 12" )

            -- Render Season Days
            renderText(WeatherForecastPosX + 0.094 + (daysPosOffset * (n - 2)), WeatherForecastPosY + 0.045, 0.018, tostring(ssSeasonsUtil:dayInSeason(forecast[n].day)))
        end

        -- Clean up after us, text render after this will be affected otherwise.
        setTextColor(1, 1, 1, 1)
    end

    -- Set position clock overlay    
    local clockPosX = g_currentMission.timeBgOverlay.x + 0.01*uiScale
    local clockPosY = g_currentMission.timeBgOverlay.y + 0.01*uiScale

    -- Render Background
    renderOverlay(self.hud.overlays.clock_overlay.overlayId, clockPosX , clockPosY, 0.07*uiScale, 0.04*uiScale)

    -- Render clock
    renderText(clockPosX+0.03*uiScale,clockPosY+0.024*uiScale,0.018*uiScale,string.format("%02d:%02d",g_currentMission.environment.currentHour,g_currentMission.environment.currentMinute))
    renderOverlay(self.hud.overlays.clock_symbol.overlayId, clockPosX + 0.002*uiScale, clockPosY + 0.021*uiScale, 0.01125*uiScale, 0.02*uiScale)
    renderText(clockPosX+0.03*uiScale,clockPosY,0.018*uiScale,string.format("%02d/%s/%d",ssSeasonsUtil:dayInSeason(forecast[1].day),ssSeasonsUtil.seasons[forecast[1].season],ssSeasonsUtil:year()+2017))

    -- Set position day overlay    
    local dayPosX = g_currentMission.infoBarBgOverlay.x - 0.037*uiScale
    local dayPosY = g_currentMission.infoBarBgOverlay.y
 
    -- Render Background
    renderOverlay(self.hud.overlays.day_hud.overlayId, dayPosX , dayPosY, g_currentMission.infoBarBgOverlay.height/2, g_currentMission.infoBarBgOverlay.height)

    -- Render Season Icon
    renderOverlay(self.hud.overlays[ssSeasonsUtil.seasons[forecast[1].season]].overlayId, dayPosX + 0.009*uiScale, dayPosY + 0.033*uiScale, 0.0185*uiScale, 0.0335*uiScale)

    -- Render current Temperatures
    local currentTemp = mathRound(ssWeatherManager:diurnalTemp(g_currentMission.environment.currentHour, g_currentMission.environment.currentMinute),0)
    setTextAlignment(RenderText.ALIGN_RIGHT)
    renderText(dayPosX + 0.03*uiScale, dayPosY + 0.01*uiScale, 0.018*uiScale, tostring(currentTemp ..' C'))
    renderText(dayPosX + 0.024*uiScale, dayPosY + 0.018*uiScale, 0.01*uiScale, 'o')
end
