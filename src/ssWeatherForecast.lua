---------------------------------------------------------------------------------------------------------
-- WEATHER FORECAST SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  to forecast the weather
-- Authors:  ian898, Jarvixes, theSeb
--

ssWeatherForecast = {};
ssWeatherForecast.forecast = {}; --day of week, low temp, high temp, weather condition
ssWeatherForecast.forecastLength = 7;
ssWeatherForecast.modDirectory = g_currentModDirectory;

function ssWeatherForecast.preSetup()
end

function ssWeatherForecast.setup()
    addModEventListener(ssWeatherForecast)
end

function ssWeatherForecast:loadMap(name)
    g_currentMission.environment:addDayChangeListener(self);
    self:buildForecast();

    self.hud = {};
    self.hud.visible = true;

    self.hud.posY = -0.14;
    self.hud.posX = 0.504;

    self.hud.overlays = {};

    -- Forecast hud
    local width, height = getNormalizedScreenValues(1024, 128);
    self.hud.overlays.forecast_hud = Overlay:new("hud_forecast", Utils.getFilename("huds/hud_forecast.png", self.modDirectory), 0, 0, width, height);

    -- Seasons "White" Icons
    local width, height = getNormalizedScreenValues(128, 128);
    --self.hud.overlays.season_spring = Overlay:new("hud_spring", Utils.getFilename("huds/hud_spring.png", self.modDirectory), 0, 0, width, height);
    --self.hud.overlays.season_summer = Overlay:new("hud_summer", Utils.getFilename("huds/hud_summer.png", self.modDirectory), 0, 0, width, height);
    --self.hud.overlays.season_autum = Overlay:new("hud_autum", Utils.getFilename("huds/hud_autum.png", self.modDirectory), 0, 0, width, height);
    --self.hud.overlays.season_winter = Overlay:new("hud_winter", Utils.getFilename("huds/hud_winter.png", self.modDirectory), 0, 0, width, height);

    -- Seasons "Color" Icons
    self.hud.overlays.season_spring = Overlay:new("hud_spring", Utils.getFilename("huds/hud_Season_Color/hud_spring_Color.png", self.modDirectory), 0, 0, width, height);
    self.hud.overlays.season_summer = Overlay:new("hud_summer", Utils.getFilename("huds/hud_Season_Color/hud_summer_Color.png", self.modDirectory), 0, 0, width, height);
    self.hud.overlays.season_autum = Overlay:new("hud_autum", Utils.getFilename("huds/hud_Season_Color/hud_autum_Color.png", self.modDirectory), 0, 0, width, height);
    self.hud.overlays.season_winter = Overlay:new("hud_winter", Utils.getFilename("huds/hud_Season_Color/hud_winter_Color.png", self.modDirectory), 0, 0, width, height);

    -- Seasons Weather Icons
    self.hud.overlays.weather_sun = g_currentMission.weatherForecastIconSunOverlay;
    self.hud.overlays.weather_cloudy = g_currentMission.weatherForecastIconOverlays.cloudy;
    self.hud.overlays.weather_fog = g_currentMission.weatherForecastIconOverlays.fog;
    self.hud.overlays.weather_rain = g_currentMission.weatherForecastIconOverlays.rain;
    self.hud.overlays.weather_hail = g_currentMission.weatherForecastIconOverlays.hail;
    self.hud.overlays.weather_snow = Overlay:new("hud_snow", Utils.getFilename("huds/hud_snow.png", self.modDirectory), 0, 0, width, height);

end

function ssWeatherForecast:deleteMap()
end

function ssWeatherForecast:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssWeatherForecast:keyEvent(unicode, sym, modifier, isDown)
    if (unicode == 107) then
        self.hud.visible = not self.hud.visible;
    end
end

function ssWeatherForecast:update(dt)
end

function ssWeatherForecast:draw()
    local todaysWeather;
    local tomorrowsWeather = self.forecast[1].weatherState .. " forecast tomorrow day num: " .. tostring(self.forecast[1].day);
    local textToDisplay = "Next day weather: " .. tomorrowsWeather;

    renderText(0.25, 0.98, 0.01, textToDisplay);

    if self.hud.visible then

        -- Set position WeatherForecast overlay.
        local WeatherForecastPosX = self.hud.posX;
        local WeatherForecastPosY = g_currentMission.moneyIconOverlay.y + self.hud.posY;

        -- Render Background
        renderOverlay(self.hud.overlays.forecast_hud.overlayId, WeatherForecastPosX,  WeatherForecastPosY, 0.52, 0.114);

        -- Set text color and alignment
        setTextColor(1,1,1,.9);
        setTextAlignment(RenderText.ALIGN_CENTER);

        -- Set firstDayPos
        local daysPosOffset = 0.0615;

        for n = 1, self.forecastLength do

            -- Render Day of The Week
            renderText(WeatherForecastPosX + 0.068 + (daysPosOffset * (n - 1)), WeatherForecastPosY + 0.086, 0.02, "MON");

            -- Render Season Icon
            renderOverlay(self.hud.overlays["season_summer"].overlayId, WeatherForecastPosX + 0.086 + (daysPosOffset * (n - 1)), WeatherForecastPosY + 0.074, 0.0185, 0.0335);

            -- Render Weather Icon
            renderOverlay(self.hud.overlays["weather_cloudy"].overlayId, WeatherForecastPosX + 0.053 + (daysPosOffset * (n - 1)), WeatherForecastPosY + 0.026, 0.032, 0.058);

            -- Render Hi/Lo Tempratures
            renderText(WeatherForecastPosX + 0.068 + (daysPosOffset * (n - 1)), WeatherForecastPosY + 0.01, 0.018, "22 / 12");

            -- Render Season Days
            renderText(WeatherForecastPosX + 0.094 + (daysPosOffset * (n - 1)), WeatherForecastPosY + 0.045, 0.018, tostring(n));

        end

        -- Clean up after us, text render after this will be affected otherwise.
        setTextColor(1, 1, 1, 1);

    end

end

function ssWeatherForecast:buildForecast()
    local startDayNum = ssSeasonsUtil:currentDayNumber();
    log("Building forecast based on today day num: " .. startDayNum);

    -- Empty the table
    self.forecast = {};

    for n = 1, self.forecastLength do
        local oneDayForecast = {};

        oneDayForecast.day = startDayNum + n; -- To match forecast with actual game
        oneDayForecast.weekDay =  ssSeasonsUtil:dayName(startDayNum + n);

        oneDayForecast.lowTemp = g_currentMission.environment.weatherTemperaturesNight[n+1];
        oneDayForecast.highTemp = g_currentMission.environment.weatherTemperaturesDay[n+1];

        oneDayForecast.weatherState = self:getWeatherStateForDay(startDayNum + n);

        table.insert(self.forecast, oneDayForecast);
    end

    --now we check through the rains table to find bad weather
    -- for index, rain in ipairs(g_currentMission.environment.rains) do
    --     log("Bad weather predicted for day: " .. tostring(rain.startDay) .. " weather type: " .. rain.rainTypeId .. " index: " .. tostring(index))
    --     if rain.startDay > self.forecastLength+1 then
    --         break
    --     end
    --     foreCastDayIndex = rain.startDay -1
    --     self.forecast[foreCastDayIndex].weatherState = rain.rainTypeId
    -- end

    print_r(self.forecast);
end

-- FIXME: not the best to be iterating within another loop, but since we are only doing this once a day, not a massive issue
--perhaps rewrite so that initial forecast is generated for 7 days and then next day only remove the first element and add the next day?
function ssWeatherForecast:getWeatherStateForDay(dayNumber)
    local weatherState = "sun";

    for index, rain in ipairs(g_currentMission.environment.rains) do
        log("Bad weather predicted for day: " .. tostring(rain.startDay) .. " weather type: " .. rain.rainTypeId .. " index: " .. tostring(index));
        if rain.startDay > dayNumber then
            break;
        end
        if (rain.startDay == dayNumber) then
            weatherState = rain.rainTypeId;
        end

    end

    return weatherState;
end

function ssWeatherForecast:dayChanged()
    self:buildForecast();
end
