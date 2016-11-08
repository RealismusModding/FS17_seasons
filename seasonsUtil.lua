---------------------------------------------------------------------------------------------------------
-- SeasonsUtil SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  Calculate current day of the week using gametime (Mon-Sun)
-- Authors:  theSeb, Akuenzi
--

SeasonsUtil = {};

SeasonsUtil.weekDays = {"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"};
SeasonsUtil.daysInWeek = 7;
SeasonsUtil.seasons = {[0]="Autumn", "Winter", "Spring", "Summer"};
SeasonsUtil.seasonsInYear = 4;

SeasonsUtil.daysInSeason = 10;

function SeasonsUtil:loadMap(name)
     print("Loading SeasonsUtil");
     g_currentMission.SeasonsUtil = self;
end;

function SeasonsUtil:deleteMap()
end;

function SeasonsUtil:mouseEvent(posX, posY, isDown, isUp, button)
end;

function SeasonsUtil:keyEvent(unicode, sym, modifier, isDown)
end;

function SeasonsUtil:update(dt)
end;

function SeasonsUtil:draw()
end;

--assumes that day 1 = monday
function SeasonsUtil:CalculateDayofWeekBasedOnDayNumber(dayNumber)
    local dayOfWeek = dayNumber; -- this will work for days 1 to 6

    if (dayNumber % self.daysInWeek == 0) then -- if it's a perfect multiple of 7'
        dayOfWeek = 7; -- will always be sunday
    elseif (dayNumber > self.daysInWeek) then
        local weekNumber = math.floor(dayNumber/self.daysInWeek);
        dayOfWeek = dayNumber - (weekNumber * self.daysInWeek);
    end;

    return dayOfWeek;
end;

function SeasonsUtil:seasonOfDayNumber(dayNumber)
    return math.floor(dayNumber / self.daysInSeason) % self.seasonsInYear;
end;

function SeasonsUtil:seasonNameOfDayNumber(dayNumber)
    return self.seasons[self:seasonOfDayNumber(dayNumber)];
end;

function SeasonsUtil:dayNameOfDayNumber(dayNumber)
    return self.weekDays[self:CalculateDayofWeekBasedOnDayNumber(dayNumber)];
end;

--might end up not using this function
function SeasonsUtil:ReturnNextDayNumber(currentDay)
    return (currentDay + 1) % self.daysInWeek;
end;

addModEventListener(SeasonsUtil);
