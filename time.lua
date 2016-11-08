---------------------------------------------------------------------------------------------------------
-- FIXFRUIT SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  To adjust fruit properties.
-- Authors:  Akuenzi, ian898, Jarvixes, theSeb
--

Time = {};
self.lastUpdate = 0;

function Time:loadMap(name)
    g_currentMission.Time = self;
end;

function Time:deleteMap()
end;

function Time:mouseEvent(posX, posY, isDown, isUp, button)
end;

function Time:keyEvent(unicode, sym, modifier, isDown)
end;

function WeatherForecast:update(dt)
end;

function WeatherForecast:updateTick(dt)
    -- Predict the weather once a day, for a whole week
    -- FIXME(jos): is this the best solution? How about weather over a long period of time, like, one season? Or a year?
    local today = g_currentMission.SeasonsUtil:currentDayNumber();
    if (self.lastUpdate < today) then
        -- FIXME: do something
        self.lastUpdate = today;
    end;
end;

function Time:draw()
end;

addModEventListener(Time);
