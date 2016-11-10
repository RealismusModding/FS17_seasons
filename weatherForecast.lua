---------------------------------------------------------------------------------------------------------
-- WEATHER FORECAST SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  to forecast the weather
-- Authors:  Authors:  Akuenzi, ian898, Jarvixes, theSeb
--

WeatherForecast = {};
WeatherForecast.debugLevel = 1;
WeatherForecast.forecast = {}; --day of week, low temp, high temp, weather condition
WeatherForecast.forecastLength = 7;
WeatherForecast.lastForecastPrediction = 0;

function WeatherForecast:loadMap(name)
    print("WeatherForecast mod loading")
    g_currentMission.WeatherForecast = self;
    self.hud = {};
    self.hud.visible = false;
    -- self.hud.overlay = createImageOverlay(Utils.getFilename("hud.png", self.modDirectory));
    -- self.hud.posX = ;
	-- self.hud.posY = ;
end;

function WeatherForecast:deleteMap()
end;

function WeatherForecast:mouseEvent(posX, posY, isDown, isUp, button)
end;

function WeatherForecast:keyEvent(unicode, sym, modifier, isDown)
    if (unicode == 107) then --TODO: this will need to be changed to use a proper inputbinding. Seb: I still
                            --want to see if it's possible to get keyEvent working properly with an inputbinding
                            --to avoid having to check for key press every frame

        -- if g_currentMission.FixFruit ~= nil then
        --     self:debugPrint("FixFruit active: " .. tostring(g_currentMission.FixFruit.active));
        --     if g_currentMission.FixFruit.active == true then
        --         g_currentMission.FixFruit.active = false;
        --     else
        --         g_currentMission.FixFruit.active = true;
        --     end;
        -- else
        --     self:debugPrint("Fixfruit not found");
        -- end;

        --looking up weather
    --     self:debugPrint("Looking up weather");
         
        --  self:debugPrint("Game Day : " .. g_currentMission.SeasonsUtil:currentDayNumber());
        --  print_r(g_currentMission.environment.weatherTemperaturesNight);
        --  print_r(g_currentMission.environment.weatherTemperaturesDay);
    --     for index, nightTemp in ipairs(g_currentMission.environment.weatherTemperaturesNight) do
    --         self:debugPrint("Night Temp: " .. nightTemp);
    --     end;

    --     for index, dayTemp in ipairs(g_currentMission.environment.weatherTemperaturesDay) do
    --         self:debugPrint("Day Temp: " .. dayTemp .. " Index: " .. tostring(index));
    --     end;

         
        --  print_r(g_currentMission.environment.rains);

    --     for index, weatherPrediction in ipairs(g_currentMission.environment.rains) do
    --         self:debugPrint("Bad weather predicted for day: " .. tostring(weatherPrediction.startDay) .. " weather type: " .. weatherPrediction.rainTypeId .. " index: " .. tostring(index));
    --     end;

    --     print_r(g_currentMission.environment.rainTypes);

        -- if (g_currentMission.SeasonsUtil == nil) then
        --     print("SeasonsUtil not found. Aborting")
        --     return;
        -- else
        --     self:buildForecast();
        -- end;

        if(self.hud.visible == false) then
            self.hud.visible = true;
        else
            self.hud.visible = false;
        end;
    end;
end;

function WeatherForecast:update(dt)
    -- Predict the weather once a day, for a whole week
    -- FIXME(jos): is this the best solution? How about weather over a long period of time, like, one season? Or a year?
    local today = g_currentMission.SeasonsUtil:currentDayNumber();
    if (self.lastForecastPrediction < today) then
        self:buildForecast();
        self.lastForecastPrediction = today;
    end;
end;

function WeatherForecast:draw()
    
    local todaysWeather;

    local tomorrowsWeather = self.forecast[1].weatherState .. " forecast tomorrow day num: " .. tostring(self.forecast[1].day);
    
    local textToDisplay = "Next day weather: " .. tomorrowsWeather ;
    renderText(0.25, 0.98, 0.01, textToDisplay);

    if (self.hud.visible == false) then
        return;
    end;
end;

function WeatherForecast:buildForecast()
    local startDayNum = g_currentMission.SeasonsUtil:currentDayNumber();
    self:debugPrint("Building forecast based on today day num: " .. startDayNum);
    -- Empty the table
    self.forecast = {};

    for n = 1, self.forecastLength do
        local oneDayForecast = {};

        oneDayForecast.day = startDayNum + n; -- To match forecast with actual game
        oneDayForecast.weekDay =  g_currentMission.SeasonsUtil.weekDays[g_currentMission.SeasonsUtil:dayOfWeek(startDayNum + n)];

        oneDayForecast.lowTemp = g_currentMission.environment.weatherTemperaturesNight[n+1];
        oneDayForecast.highTemp = g_currentMission.environment.weatherTemperaturesDay[n+1];

        oneDayForecast.weatherState = self:getWeatherStateForDay(startDayNum + n);

        table.insert(self.forecast, oneDayForecast);
    end;

    --now we check through the rains table to find bad weather
    -- for index, rain in ipairs(g_currentMission.environment.rains) do
    --     self:debugPrint("Bad weather predicted for day: " .. tostring(rain.startDay) .. " weather type: " .. rain.rainTypeId .. " index: " .. tostring(index));
    --     if rain.startDay > self.forecastLength+1 then 
    --         break;
    --     end;
    --     foreCastDayIndex = rain.startDay -1;  
    --     self.forecast[foreCastDayIndex].weatherState = rain.rainTypeId;
    -- end;

    print_r(self.forecast);
end;

-- FIXME: not the best to be iterating within another loop, but since we are only doing this once a day, not a massive issue
--perhaps rewrite so that initial forecast is generated for 7 days and then next day only remove the first element and add the next day?
function WeatherForecast:getWeatherStateForDay(dayNumber)
    local weatherState = "sun";

    for index, rain in ipairs(g_currentMission.environment.rains) do
        self:debugPrint("Bad weather predicted for day: " .. tostring(rain.startDay) .. " weather type: " .. rain.rainTypeId .. " index: " .. tostring(index));
        if rain.startDay > dayNumber then 
            break;
        end;
        if (rain.startDay == dayNumber) then
            weatherState = rain.rainTypeId;
        end;
        
    end;

    return weatherState;

end;


--use to show errors in the log file. These are there to inform the user of issues, so will stay in a release version
function WeatherForecast:errorPrint(message)
    print("--------");
    print("WeatherForecast Mod error");
    print(messsage);
    print("--------");
end;

function WeatherForecast:debugPrint(message)
    if self.debugLevel == 1 then
        print(message)
    end;
end;

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
end;

addModEventListener(WeatherForecast);
