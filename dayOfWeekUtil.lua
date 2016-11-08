
---------------------------------------------------------------------------------------------------------
-- DAYOFWEEKUTIL SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  Calculate current day of the week using gametime (Mon-Sun)
-- Authors:  theSeb, Akuenzi
--

--Seb:might end up renaming this as SeasonsCommonUtil or something along those lines because we can then use it for more common functions that are needed across the mod
DayOfWeekUtil = {};

DayOfWeekUtil.weekDays = {"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"};
DayOfWeekUtil.daysInWeek = 7;

function DayOfWeekUtil:loadMap(name)
     print("Loading DayOfWeekUtil");
     g_currentMission.DayOfWeekUtil = self;
end;

function DayOfWeekUtil:deleteMap()
end;

function DayOfWeekUtil:mouseEvent(posX, posY, isDown, isUp, button)
end;

function DayOfWeekUtil:keyEvent(unicode, sym, modifier, isDown)
end;

function DayOfWeekUtil:update(dt)
end;

function DayOfWeekUtil:draw()
end;

--assumes that day 1 = monday
function DayOfWeekUtil:CalculateDayofWeekBasedOnDayNumber(dayNumber)
    local dayOfWeek = dayNumber; -- this will work for days 1 to 6

    if (dayNumber % self.daysInWeek == 0) then -- if it's a perfect multiple of 7'
        dayOfWeek = 7; -- will always be sunday
    elseif (dayNumber > self.daysInWeek) then
        local weekNumber = math.floor(dayNumber/self.daysInWeek);
        dayOfWeek = dayNumber - (weekNumber * self.daysInWeek);
    end;

    return dayOfWeek;
end;

--might end up not using this function
function DayOfWeekUtil:ReturnNextDayNumber(currentDay)
    return (currentDay + 1) % self.daysInWeek;
end;

addModEventListener(DayOfWeekUtil);
