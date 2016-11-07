---------------------------------------------------------------------------------------------------------
-- WEATHER FORECAST SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose: to forecast the weather  
-- Authors:  theSeb, Akuenzi
--

WeatherForecast = {};
WeatherForecast.debugLevel = 1;
WeatherForecast.daysInWeek = 7;
WeatherForecast.weekDays = {"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"};


function WeatherForecast:loadMap(name)
    self:debugPrint("WeatherForecast mod loading")
    -- g_currentMission.Seasons = Seasons;
    -- g_currentMission.Seasons.WeatherForecast = self;
    g_currentMission.WeatherForecast = self;
    self.messageToOtherMod = "hello";
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
        self:debugPrint("Looking up weather");
        print_r(g_currentMission.environment.weatherTemperaturesNight);
        print_r(g_currentMission.environment.weatherTemperaturesDay);
        for index, nightTemp in pairs(g_currentMission.environment.weatherTemperaturesNight) do
            self:debugPrint("Night Temp: " .. nightTemp);
        end;
        
        for index, dayTemp in pairs(g_currentMission.environment.weatherTemperaturesDay) do
            self:debugPrint("Day Temp: " .. dayTemp .. " Index: " .. tostring(index));
        end;
         
         print_r(g_currentMission.environment.rains);

        for index, weatherPrediction in pairs(g_currentMission.environment.rains) do
            self:debugPrint("Bad weather predicted for day: " .. tostring(weatherPrediction.startDay) .. " weather type: " .. weatherPrediction.rainTypeId .. " index: " .. tostring(index));
        end;
       
       -- print_r(g_currentMission.environment.rainTypes);
       local dayNumToCheck = 1;
       self:debugPrint("Day " .. dayNumToCheck .. "Weekday: " .. self:CalculateDayofWeekBasedOnDayNumber(dayNumToCheck));

       dayNumToCheck = 2;
       self:debugPrint("Day " .. dayNumToCheck .. "Weekday: " .. self:CalculateDayofWeekBasedOnDayNumber(dayNumToCheck));

       dayNumToCheck = 3;
       self:debugPrint("Day " .. dayNumToCheck .. "Weekday: " .. self:CalculateDayofWeekBasedOnDayNumber(dayNumToCheck));

       dayNumToCheck = 4;
       self:debugPrint("Day " .. dayNumToCheck .. "Weekday: " .. self:CalculateDayofWeekBasedOnDayNumber(dayNumToCheck));

       dayNumToCheck = 5;
       self:debugPrint("Day " .. dayNumToCheck .. "Weekday: " .. self:CalculateDayofWeekBasedOnDayNumber(dayNumToCheck));

       dayNumToCheck = 6;
       self:debugPrint("Day " .. dayNumToCheck .. "Weekday: " .. self:CalculateDayofWeekBasedOnDayNumber(dayNumToCheck));

       dayNumToCheck = 7;
       self:debugPrint("Day " .. dayNumToCheck .. "Weekday: " .. self:CalculateDayofWeekBasedOnDayNumber(dayNumToCheck));

       dayNumToCheck = 8;
       self:debugPrint("Day " .. dayNumToCheck .. "Weekday: " .. self:CalculateDayofWeekBasedOnDayNumber(dayNumToCheck));

       dayNumToCheck = 9;
       self:debugPrint("Day " .. dayNumToCheck .. "Weekday: " .. self:CalculateDayofWeekBasedOnDayNumber(dayNumToCheck));

       dayNumToCheck = 10;
       self:debugPrint("Day " .. dayNumToCheck .. "Weekday: " .. self:CalculateDayofWeekBasedOnDayNumber(dayNumToCheck));

       dayNumToCheck = 11;
       self:debugPrint("Day " .. dayNumToCheck .. "Weekday: " .. self:CalculateDayofWeekBasedOnDayNumber(dayNumToCheck));

       dayNumToCheck = 12;
       self:debugPrint("Day " .. dayNumToCheck .. "Weekday: " .. self:CalculateDayofWeekBasedOnDayNumber(dayNumToCheck));

       dayNumToCheck = 13;
       self:debugPrint("Day " .. dayNumToCheck .. "Weekday: " .. self:CalculateDayofWeekBasedOnDayNumber(dayNumToCheck));

       dayNumToCheck = 14;
       self:debugPrint("Day " .. dayNumToCheck .. "Weekday: " .. self:CalculateDayofWeekBasedOnDayNumber(dayNumToCheck));

       dayNumToCheck = 15;
       self:debugPrint("Day " .. dayNumToCheck .. "Weekday: " .. self:CalculateDayofWeekBasedOnDayNumber(dayNumToCheck));

       dayNumToCheck = 21;
       self:debugPrint("Day " .. dayNumToCheck .. "Weekday: " .. self:CalculateDayofWeekBasedOnDayNumber(dayNumToCheck));

       dayNumToCheck = 22;
       self:debugPrint("Day " .. dayNumToCheck .. "Weekday: " .. self:CalculateDayofWeekBasedOnDayNumber(dayNumToCheck));
    end;
end;

function WeatherForecast:update(dt)
end;

function WeatherForecast:draw() 
end;

-- assumes that day 1 = monday
function WeatherForecast:CalculateDayofWeekBasedOnDayNumber(dayNumber)
    
    local returnedDay = dayNumber; -- this will work for days 1 to 6

    if (dayNumber % self.daysInWeek == 0) then -- if it's a perfect multiple of 7'
        returnedDay = 7; -- will always be sunday 
    elseif (dayNumber > self.daysInWeek) then
        local weekNumber = math.floor(dayNumber/self.daysInWeek);
        returnedDay = dayNumber - (weekNumber * self.daysInWeek);
    end;

    return self.weekDays[returnedDay];

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

