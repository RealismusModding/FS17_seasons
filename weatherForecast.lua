---------------------------------------------------------------------------------------------------------
-- WEATHER FORECAST SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose: to forecast the weather  
-- Authors:  theSeb, Akuenzi
--

WeatherForecast = {};
WeatherForecast.debugLevel = 1;
WeatherForecast.forecast = {}; --day of week, low temp, high temp, weather condition
WeatherForecast.forecastLength = 7;

function WeatherForecast:loadMap(name)
    print("WeatherForecast mod loading")
    g_currentMission.WeatherForecast = self;

end;

function WeatherForecast:deleteMap() 
end;

function WeatherForecast:mouseEvent(posX, posY, isDown, isUp, button)
end;

function WeatherForecast:keyEvent(unicode, sym, modifier, isDown)
    if (unicode == 107) then
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
        print_r(g_currentMission.environment.weatherTemperaturesNight);
        print_r(g_currentMission.environment.weatherTemperaturesDay);
    --     for index, nightTemp in ipairs(g_currentMission.environment.weatherTemperaturesNight) do
    --         self:debugPrint("Night Temp: " .. nightTemp);
    --     end;
        
    --     for index, dayTemp in ipairs(g_currentMission.environment.weatherTemperaturesDay) do
    --         self:debugPrint("Day Temp: " .. dayTemp .. " Index: " .. tostring(index));
    --     end;
         
         print_r(g_currentMission.environment.rains);

    --     for index, weatherPrediction in ipairs(g_currentMission.environment.rains) do
    --         self:debugPrint("Bad weather predicted for day: " .. tostring(weatherPrediction.startDay) .. " weather type: " .. weatherPrediction.rainTypeId .. " index: " .. tostring(index));
    --     end;
       
    --    -- print_r(g_currentMission.environment.rainTypes);
    
        if (g_currentMission.DayOfWeekUtil == nil) then
            print("DayOfWeekUtil not found. Aborting")
            return;
        else
            self:BuildForecast();
        end;

       

    end;
end;

function WeatherForecast:update(dt)
end;

function WeatherForecast:draw() 
end;

-- -- assumes that day 1 = monday
-- function WeatherForecast:CalculateDayofWeekBasedOnDayNumber(dayNumber)
    
--     local dayOfWeek = dayNumber; -- this will work for days 1 to 6

--     if (dayNumber % self.daysInWeek == 0) then -- if it's a perfect multiple of 7'
--         dayOfWeek = 7; -- will always be sunday 
--     elseif (dayNumber > self.daysInWeek) then
--         local weekNumber = math.floor(dayNumber/self.daysInWeek);
--         dayOfWeek = dayNumber - (weekNumber * self.daysInWeek);
--     end;

--     return dayOfWeek;

-- end;



function WeatherForecast:BuildForecast()
   
    local currentDayNum = 7; --g_currentMission.environment.currentDay 
    --local dayOfWeek = self:CalculateDayofWeekBasedOnDayNumber(currentDayNum);
    --TODO: rework the implementation so that the forecast is only built once per day

    for n=1, self.forecastLength do
        local oneDayForecast = {};
        oneDayForecast.weekDay =  g_currentMission.DayOfWeekUtil.weekDays[g_currentMission.DayOfWeekUtil:CalculateDayofWeekBasedOnDayNumber(currentDayNum+n-1)];
        oneDayForecast.lowTemp = g_currentMission.environment.weatherTemperaturesNight[n];
        oneDayForecast.highTemp = g_currentMission.environment.weatherTemperaturesDay[n];
        oneDayForecast.weatherState = "sun";
        table.insert(self.forecast,oneDayForecast);
    end;

    --now we check through the rains table to find bad weather
    for index, rain in ipairs(g_currentMission.environment.rains) do
        self:debugPrint("Bad weather predicted for day: " .. tostring(rain.startDay) .. " weather type: " .. rain.rainTypeId .. " index: " .. tostring(index));
        if rain.startDay > self.forecastLength then
            break;
        end;
        self.forecast[rain.startDay].weatherState = rain.rainTypeId;                         
    end;

    print_r(self.forecast);

    self:debugPrint("WeatherForecast:BuildForecast finished")

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

function print_r ( t )  
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

