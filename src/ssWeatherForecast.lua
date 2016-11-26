---------------------------------------------------------------------------------------------------------
-- WEATHER FORECAST SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  to forecast and display the weather
-- Authors:  Authors:  ian898, Jarvixes, theSeb, reallogger
--

ssWeatherForecast = {}

function ssWeatherForecast:loadMap(name)
    -- g_currentMission.environment:addDayChangeListener(self)

    self.hud = {}
    self.hud.visible = true

    self.hud.posY = -0.14
    self.hud.posX = 0.504

    self.hud.overlays = {}

    -- Forecast hud
    local width, height = getNormalizedScreenValues(1024, 128)
    self.hud.overlays.forecast_hud = Overlay:new("hud_forecast", Utils.getFilename("huds/hud_forecast.png", ssSeasonsMod.modDir), 0, 0, width, height)

    -- Seasons "White" Icons
    local width, height = getNormalizedScreenValues(128, 128)
    --self.hud.overlays.season_spring = Overlay:new("hud_spring", Utils.getFilename("huds/hud_spring.png", self.modDirectory), 0, 0, width, height)
    --self.hud.overlays.season_summer = Overlay:new("hud_summer", Utils.getFilename("huds/hud_summer.png", self.modDirectory), 0, 0, width, height)
    --self.hud.overlays.season_autum = Overlay:new("hud_autum", Utils.getFilename("huds/hud_autum.png", self.modDirectory), 0, 0, width, height)
    --self.hud.overlays.season_winter = Overlay:new("hud_winter", Utils.getFilename("huds/hud_winter.png", self.modDirectory), 0, 0, width, height)

    -- Seasons "Color" Icons
    self.hud.overlays.Spring = Overlay:new("hud_spring", Utils.getFilename("huds/hud_Season_Color/hud_spring_Color.png", ssSeasonsMod.modDir), 0, 0, width, height)
    self.hud.overlays.Summer = Overlay:new("hud_summer", Utils.getFilename("huds/hud_Season_Color/hud_summer_Color.png", ssSeasonsMod.modDir), 0, 0, width, height)
    self.hud.overlays.Autumn = Overlay:new("hud_autum", Utils.getFilename("huds/hud_Season_Color/hud_autum_Color.png", ssSeasonsMod.modDir), 0, 0, width, height)
    self.hud.overlays.Winter = Overlay:new("hud_winter", Utils.getFilename("huds/hud_Season_Color/hud_winter_Color.png", ssSeasonsMod.modDir), 0, 0, width, height)

    -- Seasons Weather Icons
    self.hud.overlays.sun = g_currentMission.weatherForecastIconSunOverlay
    self.hud.overlays.cloudy = g_currentMission.weatherForecastIconOverlays.cloudy
    self.hud.overlays.fog = g_currentMission.weatherForecastIconOverlays.fog
    self.hud.overlays.rain = g_currentMission.weatherForecastIconOverlays.rain
    self.hud.overlays.hail = g_currentMission.weatherForecastIconOverlays.hail
    self.hud.overlays.snow = Overlay:new("hud_snow", Utils.getFilename("huds/hud_snow.png", ssSeasonsMod.modDir), 0, 0, width, height)

    -- g_currentMission.environment.rainFadeDuration = 0--0.5*60000
    -- g_currentMission.environment.rainFadeDuration.minRainDuration = 60000
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
    local forecastLength = ssWeatherManager.forecastLength

    local todaysWeather
    local tomorrowsWeather = forecast[1].weatherState .. " forecast tomorrow day num: " .. tostring(forecast[1].day)
    local textToDisplay = "Next day weather: " .. tomorrowsWeather

    renderText(0.25, 0.98, 0.01, textToDisplay)

    if self.hud.visible then
        -- Set position WeatherForecast overlay.
        local WeatherForecastPosX = self.hud.posX
        local WeatherForecastPosY = g_currentMission.moneyIconOverlay.y + self.hud.posY

        -- Render Background
        renderOverlay(self.hud.overlays.forecast_hud.overlayId, WeatherForecastPosX,  WeatherForecastPosY, 0.52, 0.114)

        -- Set text color and alignment
        setTextColor(1,1,1,.9)
        setTextAlignment(RenderText.ALIGN_CENTER)

        -- Set firstDayPos
        local daysPosOffset = 0.0615

        for n = 1, forecastLength do
            -- Render Day of The Week
            renderText(WeatherForecastPosX + 0.068 + (daysPosOffset * (n - 1)), WeatherForecastPosY + 0.086, 0.02, ssSeasonsUtil:dayNameShort(ssSeasonsUtil:dayOfWeek()+n))

            -- Render Season Icon
            renderOverlay(self.hud.overlays[forecast[n].season].overlayId, WeatherForecastPosX + 0.086 + (daysPosOffset * (n - 1)), WeatherForecastPosY + 0.074, 0.0185, 0.0335)

            -- Render Weather Icon
            renderOverlay(self.hud.overlays[forecast[n].weatherState].overlayId, WeatherForecastPosX + 0.053 + (daysPosOffset * (n - 1)), WeatherForecastPosY + 0.026, 0.032, 0.058)

            -- Render Hi/Lo Tempratures
            renderText(WeatherForecastPosX + 0.068 + (daysPosOffset * (n - 1)), WeatherForecastPosY + 0.01, 0.018, tostring(math.floor(forecast[n].highTemp)) .. " / " .. tostring(math.floor(forecast[n].lowTemp)))
            --renderText(WeatherForecastPosX + 0.068 + (daysPosOffset * (n - 1)), WeatherForecastPosY + 0.01, 0.018, "22 / 12" )

            -- Render Season Days
            renderText(WeatherForecastPosX + 0.094 + (daysPosOffset * (n - 1)), WeatherForecastPosY + 0.045, 0.018, tostring(ssSeasonsUtil:dayInSeason(forecast[n].day)))
        end

        -- Clean up after us, text render after this will be affected otherwise.
        setTextColor(1, 1, 1, 1)
    end
end
