---------------------------------------------------------------------------------------------------------
-- WEATHER MANAGER SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  to create and manage the weather
-- Authors:  Authors:  ian898, Jarvixes, theSeb, reallogger
--

ssWeatherManager = {}
ssWeatherManager.forecast = {} --day of week, low temp, high temp, weather condition
ssWeatherManager.forecastLength = 7
ssWeatherManager.snowDepth = 0

function ssWeatherManager:loadMap(name)
    g_currentMission.environment:addDayChangeListener(self)
    g_currentMission.environment:addHourChangeListener(self)

    self:buildForecast() -- Should be read from savegame
    -- self.snowDepth = -- Enable read from savegame
end

function ssWeatherManager:deleteMap()
end

function ssWeatherManager:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssWeatherManager:keyEvent(unicode, sym, modifier, isDown)
end

function ssWeatherManager:update(dt)
end

function ssWeatherManager:draw()
end

function ssWeatherManager:buildForecast()
    local startDayNum = ssSeasonsUtil:currentDayNumber()
    local ssTmax
    log("Building forecast based on today day num: " .. startDayNum)

    self.forecast = {}

    for n = 1, self.forecastLength do
        local oneDayForecast = {}
        local ssTmax = {}
        local Tmaxmean = {}

        oneDayForecast.day = startDayNum + n -- To match forecast with actual game
        oneDayForecast.weekDay =  ssSeasonsUtil:dayName(startDayNum + n)
        oneDayForecast.season = ssSeasonsUtil:seasonName(startDayNum + n)

        ssTmax = self:Tmax(oneDayForecast.season)
        oneDayForecast.highTemp = ssSeasonsUtil:ssNormDist(ssTmax[2],2.5)
        oneDayForecast.lowTemp = ssSeasonsUtil:ssNormDist(0,2) + 0.75 * ssTmax[2]-5

        oneDayForecast.weatherState = self:getWeatherStateForDay(startDayNum + n)

        table.insert(self.forecast, oneDayForecast)
    end

    for index, rain in ipairs(g_currentMission.environment.rains) do
        for jndex, fCast in ipairs(self.forecast) do
             if (rain.startDay == fCast.day) then
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

function ssWeatherManager:updateForecast()
    local dayNum = ssSeasonsUtil:currentDayNumber() + self.forecastLength;
    log("Updating forecast based on today day num: " .. dayNum);

    table.remove(self.forecast,1)

    local oneDayForecast = {};
    local ssTmax = {};

    oneDayForecast.day = dayNum; -- To match forecast with actual game
    oneDayForecast.weekDay =  ssSeasonsUtil:dayName(dayNum);
    oneDayForecast.season = ssSeasonsUtil:seasonName(dayNum)

	if self.forecast[self.forecastLength-1].season == oneDayForecast.season then
		--Seasonal average for a day in the season
		ssTmax = self:Tmax(oneDayForecast.season)
        oneDayForecast.Tmaxmean = self.forecast[self.forecastLength-1].Tmaxmean
			
	elseif self.forecast[self.forecastLength-1].season ~= oneDayForecast.season then
		--Seasonal average for a day in the next season
        ssTmax = self:Tmax(oneDayForecast.season)
        oneDayForecast.Tmaxmean = ssSeasonsUtil:ssTriDist(ssTmax) 
		
    end

    oneDayForecast.highTemp = ssSeasonsUtil:ssNormDist(ssTmax[2],2.5)
    oneDayForecast.lowTemp = ssSeasonsUtil:ssNormDist(0,2) + 0.75 * ssTmax[2]-5

    oneDayForecast.weatherState = self:getWeatherStateForDay(dayNum);

    table.insert(self.forecast, oneDayForecast);

    for index, rain in ipairs(g_currentMission.environment.rains) do
        for jndex, fCast in ipairs(self.forecast) do
             if (rain.startDay == fCast.day) then
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
function ssWeatherManager:getWeatherStateForDay(dayNumber)
    local weatherState = "sun"
    local ssTmax = {}
    local Tmaxmean = {}

    for index, rain in ipairs(g_currentMission.environment.rains) do
        log("Bad weather predicted for day: " .. tostring(rain.startDay) .. " weather type: " .. rain.rainTypeId .. " index: " .. tostring(index))
        if rain.startDay > dayNumber then
            break
        end
        if (rain.startDay == dayNumber) then
            weatherState = rain.rainTypeId
        end
    end

    --for k, v in pairs( g_currentMission.environment.rainFadeCurve ) do
    --    log (k, v)
    --end

    return weatherState
end

function ssWeatherManager:dayChanged()
    self:updateForecast()
end

function ssWeatherManager:hourChanged()
    self:calculateSnowAccumulation()
end

function ssWeatherManager:Tmax(ss) --sets the minimum, mode and maximum of the seasonal average maximum temperature. Simplification due to unphysical bounds.
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
function ssWeatherManager:diurnalTemp(hour, minute)
    -- need to have the high temp of the previous day
    -- hour is hour in the day from 0 to 23
    -- minute is minutes from 0 to 59

    prevDayTemp = self.forecast[1].highTemp -- not completely correct, but instead of storing the temp of the previous day

    local currentTime = hour*60 + minute

    if currentTime < 420 then
        currentTemp = (math.cos(((currentTime + 540) / 960) * math.pi / 2)) ^ 3 * (prevDayTemp - self.forecast[1].lowTemp) + self.forecast[1].lowTemp
    elseif currentTime > 900 then
        currentTemp = (math.cos(((currentTime - 900) / 960) * math.pi / 2)) ^ 3 * (self.forecast[1].highTemp - self.forecast[2].lowTemp) + self.forecast[1].lowTemp
    else
        currentTemp = (math.cos((1 - (currentTime -  420) / 480) * math.pi / 2) ^ 3) * (self.forecast[1].highTemp - self.forecast[1].lowTemp) + self.forecast[1].lowTemp
    end

    return currentTemp
end

--- function to keep track of snow accumulation
--- snowDepth in meters
function ssWeatherManager:calculateSnowAccumulation()
    currentRain = g_currentMission.environment.currentRain
    currentTemp = ssWeatherManager:diurnalTemp(g_currentMission.environment.currentHour, g_currentMission.environment.currentMinute)

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
function ssWeatherManager:isGroundWorkable()
    local avgSoilTemp = (self.forecast[1].highTemp + self.forecast[1].lowTemp) / 2
    if  avgSoilTemp < 5 then
        return true
    else
        return false
    end
end

function ssWeatherManager:getSnowHeight()
    return self.snowDepth
end
