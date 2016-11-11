---------------------------------------------------------------------------------------------------------
-- WEATHER FORECAST SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  to forecast the weather
-- Authors:  Authors:  Akuenzi, ian898, Jarvixes, theSeb
--

ssWeatherForecast = {};
ssWeatherForecast.forecast = {}; --day of week, low temp, high temp, weather condition
ssWeatherForecast.forecastLength = 7;
ssWeatherForecast.lastForecastPrediction = 0;
ssWeatherForecast.modDirectory = g_currentModDirectory;

function ssWeatherForecast:loadMap(name)
    print("ssWeatherForecast mod loading");
    g_currentMission.ssWeatherForecast = self;
    
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
	
end;

function ssWeatherForecast:deleteMap()
end;

function ssWeatherForecast:mouseEvent(posX, posY, isDown, isUp, button)
end;

function ssWeatherForecast:keyEvent(unicode, sym, modifier, isDown)
    if (unicode == 107) then --TODO: this will need to be changed to use a proper inputbinding. Seb: I still
                            --want to see if it's possible to get keyEvent working properly with an inputbinding
                            --to avoid having to check for key press every frame

        -- if g_currentMission.FixFruit ~= nil then
        --     log("FixFruit active: " .. tostring(g_currentMission.FixFruit.active))
        --     if g_currentMission.FixFruit.active == true then
        --         g_currentMission.FixFruit.active = false
        --     else
        --         g_currentMission.FixFruit.active = true
        --     end
        -- else
        --     log("Fixfruit not found")
        -- end

        --looking up weather
    --     log("Looking up weather")

        --  log("Game Day : " .. g_currentMission.SeasonsUtil:currentDayNumber())
        --  print_r(g_currentMission.environment.weatherTemperaturesNight)
        --  print_r(g_currentMission.environment.weatherTemperaturesDay)
    --     for index, nightTemp in ipairs(g_currentMission.environment.weatherTemperaturesNight) do
    --         log("Night Temp: " .. nightTemp)
    --     end

    --     for index, dayTemp in ipairs(g_currentMission.environment.weatherTemperaturesDay) do
    --         log("Day Temp: " .. dayTemp .. " Index: " .. tostring(index))
    --     end

    --  print_r(g_currentMission.environment.rains)
    -- log("Game Day : " .. g_currentMission.ssSeasonsUtil:currentDayNumber())
    -- print_r(g_currentMission.environment.rains)

    --     for index, weatherPrediction in ipairs(g_currentMission.environment.rains) do
    --         log("Bad weather predicted for day: " .. tostring(weatherPrediction.startDay) .. " weather type: " .. weatherPrediction.rainTypeId .. " index: " .. tostring(index))
    --     end

    --     print_r(g_currentMission.environment.rainTypes)

        -- if (g_currentMission.ssSeasonsUtil == nil) then
        --     print("ssSeasonsUtil not found. Aborting")
        --     return
        -- else
        --     self:buildForecast()
        -- end

        if(self.hud.visible == false) then
            self.hud.visible = true;
        else
            self.hud.visible = false;
        end
    end
end

function ssWeatherForecast:update(dt)
    -- Predict the weather once a day, for a whole week
    -- FIXME(jos): is this the best solution? How about weather over a long period of time, like, one season? Or a year?
    local today = g_currentMission.ssSeasonsUtil:currentDayNumber();
    if (self.lastForecastPrediction < today) then
        self:buildForecast();
        self.lastForecastPrediction = today;
    end
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
		
		end;
		
		-- Clean up after us, text render after this will be affected otherwise.
		setTextColor(1, 1, 1, 1);
		
    end;
	
end;

function ssWeatherForecast:buildForecast()
    local startDayNum = g_currentMission.ssSeasonsUtil:currentDayNumber();
    log("Building forecast based on today day num: " .. startDayNum);

    -- Empty the table
    self.forecast = {};

    for n = 1, self.forecastLength do
        local oneDayForecast = {};

        oneDayForecast.day = startDayNum + n; -- To match forecast with actual game
        oneDayForecast.weekDay =  g_currentMission.ssSeasonsUtil.weekDays[g_currentMission.ssSeasonsUtil:dayOfWeek(startDayNum + n)];

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

    print_r(self.forecast)
end

-- FIXME: not the best to be iterating within another loop, but since we are only doing this once a day, not a massive issue
--perhaps rewrite so that initial forecast is generated for 7 days and then next day only remove the first element and add the next day?
function ssWeatherForecast:getWeatherStateForDay(dayNumber)
    local weatherState = "sun"

    for index, rain in ipairs(g_currentMission.environment.rains) do
        log("Bad weather predicted for day: " .. tostring(rain.startDay) .. " weather type: " .. rain.rainTypeId .. " index: " .. tostring(index))
        if rain.startDay > dayNumber then
            break
        end
        if (rain.startDay == dayNumber) then
            weatherState = rain.rainTypeId
        end

    end

    return weatherState

end

function print_r(t)
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
    print()
end

addModEventListener(ssWeatherForecast)
