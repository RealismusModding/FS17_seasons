---------------------------------------------------------------------------------------------------------
-- WEATHER FORECAST SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose: to forecast the weather  
-- Authors:  theSeb, Akuenzi
--

WeatherForecast = {};
WeatherForecast.debugLevel = 1

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
        if g_currentMission.FixFruit ~= nil then
            self:debugPrint("FixFruit active: " .. tostring(g_currentMission.FixFruit.active));
            if g_currentMission.FixFruit.active == true then
                g_currentMission.FixFruit.active = false
            else
                g_currentMission.FixFruit.active = true
            end;
        end;
    end;
end;

function WeatherForecast:update(dt)
end;

function WeatherForecast:draw() 
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

addModEventListener(WeatherForecast);

