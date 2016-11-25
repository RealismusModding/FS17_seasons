---------------------------------------------------------------------------------------------------------
-- WEATHER FORECAST SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  to forecast the weather
-- Authors:  Authors:  ian898, Jarvixes, theSeb, reallogger
--

ssWeatherForecast = {};
ssWeatherForecast.forecast = {}; --day of week, low temp, high temp, weather condition
ssWeatherForecast.forecastLength = 7;
ssWeatherForecast.modDirectory = g_currentModDirectory;
ssWeatherForecast.snowDepth = 0;

function ssWeatherForecast.preSetup()
end

function ssWeatherForecast.setup()
    addModEventListener(ssWeatherForecast)
end

function ssWeatherForecast:loadMap(name)
    g_currentMission.environment:addDayChangeListener(self);
    self:buildForecast(); -- Should be read from savegame

	-- self.snowDepth = -- Enable read from savegame
	
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
    self.hud.overlays.Spring = Overlay:new("hud_spring", Utils.getFilename("huds/hud_Season_Color/hud_spring_Color.png", self.modDirectory), 0, 0, width, height);
    self.hud.overlays.Summer = Overlay:new("hud_summer", Utils.getFilename("huds/hud_Season_Color/hud_summer_Color.png", self.modDirectory), 0, 0, width, height);
    self.hud.overlays.Autumn = Overlay:new("hud_autum", Utils.getFilename("huds/hud_Season_Color/hud_autum_Color.png", self.modDirectory), 0, 0, width, height);
    self.hud.overlays.Winter = Overlay:new("hud_winter", Utils.getFilename("huds/hud_Season_Color/hud_winter_Color.png", self.modDirectory), 0, 0, width, height);

    -- Seasons Weather Icons
    self.hud.overlays.sun = g_currentMission.weatherForecastIconSunOverlay;
    self.hud.overlays.cloudy = g_currentMission.weatherForecastIconOverlays.cloudy;
    self.hud.overlays.fog = g_currentMission.weatherForecastIconOverlays.fog;
    self.hud.overlays.rain = g_currentMission.weatherForecastIconOverlays.rain;
    self.hud.overlays.hail = g_currentMission.weatherForecastIconOverlays.hail;

    -- reallogger NOT USED YET
    self.hud.overlays.weather_snow = Overlay:new("hud_snow", Utils.getFilename("huds/hud_snow.png", self.modDirectory), 0, 0, width, height);

    -- g_currentMission.environment.rainFadeDuration = 0--0.5*60000
    -- g_currentMission.environment.rainFadeDuration.minRainDuration = 60000


end

function ssWeatherForecast:deleteMap()
end

function ssWeatherForecast:mouseEvent(posX, posY, isDown, isUp, button)
end;

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
            renderText(WeatherForecastPosX + 0.068 + (daysPosOffset * (n - 1)), WeatherForecastPosY + 0.086, 0.02, ssSeasonsUtil:dayNameShort(ssSeasonsUtil:dayOfWeek()+n));

            -- Render Season Icon
            renderOverlay(self.hud.overlays[self.forecast[n].season].overlayId, WeatherForecastPosX + 0.086 + (daysPosOffset * (n - 1)), WeatherForecastPosY + 0.074, 0.0185, 0.0335);

            -- Render Weather Icon
            renderOverlay(self.hud.overlays[self.forecast[n].weatherState].overlayId, WeatherForecastPosX + 0.053 + (daysPosOffset * (n - 1)), WeatherForecastPosY + 0.026, 0.032, 0.058);

            -- Render Hi/Lo Tempratures
            renderText(WeatherForecastPosX + 0.068 + (daysPosOffset * (n - 1)), WeatherForecastPosY + 0.01, 0.018, tostring(math.floor(self.forecast[n].highTemp)) .. " / " .. tostring(math.floor(self.forecast[n].lowTemp)));
            --renderText(WeatherForecastPosX + 0.068 + (daysPosOffset * (n - 1)), WeatherForecastPosY + 0.01, 0.018, "22 / 12" );

            -- Render Season Days
            renderText(WeatherForecastPosX + 0.094 + (daysPosOffset * (n - 1)), WeatherForecastPosY + 0.045, 0.018, tostring(ssSeasonsUtil:dayInSeason(self.forecast[n].day)));

        end

        -- Clean up after us, text render after this will be affected otherwise.
        setTextColor(1, 1, 1, 1);

    end

end

function ssWeatherForecast:buildForecast()
    local startDayNum = ssSeasonsUtil:currentDayNumber();
    local ssTmax
	log("Building forecast based on today day num: " .. startDayNum);
		
	self.forecast = {};

    for n = 1, self.forecastLength do
        local oneDayForecast = {};
	    local ssTmax = {};
	    local Tmaxmean = {};

		oneDayForecast.day = startDayNum + n; -- To match forecast with actual game
        oneDayForecast.weekDay =  ssSeasonsUtil:dayName(startDayNum + n);
		oneDayForecast.season = ssSeasonsUtil:seasonName(startDayNum + n)
		
		ssTmax = self:Tmax(oneDayForecast.season)
        --log('ssTmax = ',ssTmax[2])
		oneDayForecast.highTemp = ssSeasonsUtil:ssNormDist(ssTmax[2],2.5) 
		oneDayForecast.lowTemp = ssSeasonsUtil:ssNormDist(0,2) + 0.75 * ssTmax[2]-5
		
        oneDayForecast.weatherState = self:getWeatherStateForDay(startDayNum + n);

        table.insert(self.forecast, oneDayForecast);
    end
	
	for index, rain in ipairs(g_currentMission.environment.rains) do
        for jndex, fCast in ipairs(self.forecast) do
             if (rain.startDay == fCast.day) then
                --log('fCast.day = ', fCast.day,'is equal to ', rain.startDay)
                --log('oneDayForecast = ',oneDayForecast)
                --log('rain.rainTypeId = ', rain.rainTypeId)
                if fCast.lowTemp < -1 and rain.rainTypeId == 'rain' then
				    g_currentMission.environment.rains[index].rainTypeId = 'hail'
                    self.forecast[jndex].weatherState = 'hail'
			    elseif fCast.lowTemp >= -1 and rain.rainTypeId == 'hail' then
				    g_currentMission.environment.rains[index].rainTypeId = 'rain'
                    self.forecast[jndex].weatherState = 'rain'
			    end
            end
        end
    end
	
	print_r(self.forecast)
    print_r(g_currentMission.environment.rains)

end


-- FIXME: not the best to be iterating within another loop, but since we are only doing this once a day, not a massive issue
--perhaps rewrite so that initial forecast is generated for 7 days and then next day only remove the first element and add the next day?
function ssWeatherForecast:getWeatherStateForDay(dayNumber)
    local weatherState = "sun";
    local ssTmax = {};
    local Tmaxmean = {};

    for index, rain in ipairs(g_currentMission.environment.rains) do
        log("Bad weather predicted for day: " .. tostring(rain.startDay) .. " weather type: " .. rain.rainTypeId .. " index: " .. tostring(index));
        if rain.startDay > dayNumber then
            break;
        end
        if (rain.startDay == dayNumber) then
            weatherState = rain.rainTypeId;
        end
    end

    --for k, v in pairs( g_currentMission.environment.rainFadeCurve ) do
    --    log (k, v)
    --end

    return weatherState;
end

function ssWeatherForecast:dayChanged()
    self:buildForecast();
end

function ssWeatherForecast:Tmax(ss) --sets the minimum, mode and maximum of the seasonal average maximum temperature. Simplification due to unphysical bounds.

    if ss == 'Winter' then
        -- return {5.0,8.6,10.7} --min, mode, max Temps from the data
        return {0.0,3.6,5.7} --min, mode, max

    elseif ss == "Spring" then
        return {12.1, 14.2, 17.9} --min, mode, max

    elseif ss == "Summer" then
        return {19.4, 21.7, 26.0} --min, mode, max

    elseif ss == "Autumn" then
        return {14.0, 15.6, 17.3} --min, mode, max
    end

end

-- function to output the temperature during the day and night
function ssWeatherForecast:diurnalTemp(hour,minute)
    -- need to have the high temp of the previous day    
    -- hour is hour in the day from 0 to 23
    -- minute is minutes from 0 to 59

    prevDayTemp = self.forecast[1].highTemp -- not completely correct, but instead of storing the temp of the previous day

    local currentTime = hour*60 + minute

    if currentTime < 420 then
	    currentTemp = ( math.cos(((currentTime + 540)/960)*math.pi/2) )^3 * (preDayTemp-self.forecast[1].lowTemp)+self.forecast[1].lowTemp
    elseif currentTime > 900 then
	    currentTemp = ( math.cos(((currentTime - 900)/960)*math.pi/2) )^3 * (self.forecast[1].highTemp-self.forecast[2].lowTemp)+self.forecast[1].lowTemp
    else
	    currentTemp = ( math.cos((1- (currentTime-420)/480)*math.pi/2 )^3) * (self.forecast[1].highTemp-self.forecast[1].lowTemp) + self.forecast[1].lowTemp   
    end

	return currentTemp

end

--- function to keep track of snow accumulation
--- snowDepth in meters
function ssWeatherForecast:snowAccumulation()
    currentRain = g_currentMission.environment.currentRain
    currentTemp = ssWeatherForecast.diurnalTemp(g_currentMission.environment.currentHour,g_currentMission.environment.currentMinute)

    if currentRain == "sun" then
        if currentTemp > -1  then -- snow melts at -1 if the sun is shining
            self.snowDepth = self.snowDepth - math.min(-2*currentTemp+7.5,0)/1000
        end
    elseif currentRain == "rain" then
        -- assume snow melts three times as fast if it rains
        self.snowDepth = self.snowDepth - math.min(-2*currentTemp+7.5,0) * 3/1000
    elseif currentRain == "hail" then
        -- Initial value of 10 mm/hr accumulation rate
        self.snowDepth = self.snowDepth + 10/1000
    else
        -- 75% melting (compared to clear conditions) when there is cloudy and fog
        self.snowDepth = self.snowDepth - math.min(-2*currentTemp+7.5,0)*0.75/1000
    end

    return self.snowDepth

end

--- function for predicting when soil is not workable
function ssWeatherForecast:isGroundWorkable()
	local avgSoilTemp = (self.forecast[1].highTemp + self.forecast[1].lowTemp) / 2
	if  avgSoilTemp < 5 then
		return true
	else
		return false
	end
end