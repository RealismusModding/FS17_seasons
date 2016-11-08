---------------------------------------------------------------------------------------------------------
-- SeasonsUtil SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  Calculate current day of the week using gametime (Mon-Sun)
-- Authors:  Akuenzi, ian898, Jarvixes, theSeb
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

-- Get the current day number
function SeasonsUtil:currentDayNumber()
    return g_currentMission.environment.currentDay;
end;

-- Get the day within the week
-- assumes that day 1 = monday
function SeasonsUtil:dayOfWeek(dayNumber)
    return (dayNumber - 1) % self.daysInWeek;
end;

-- Get the season number.
-- If no day supplied, uses current day
function SeasonsUtil:season(dayNumber)
    if (dayNumber == nil) then
        dayNumber = self:currentDayNumber();
    end;

    return math.floor(dayNumber / self.daysInSeason) % self.seasonsInYear;
end;

-- Get season name for given day number
-- If no day number supplied, uses current day
function SeasonsUtil:seasonName(dayNumber)
    return self.seasons[self:season(dayNumber)];
end;

-- Get day name for given day number
-- If no day number supplied, uses current day
function SeasonsUtil:dayName(dayNumber)
    return self.weekDays[self:dayOfWeek(dayNumber)];
end;

function SeasonsUtil:nextWeekDayNumber(currentDay)
    return (currentDay + 1) % self.daysInWeek;
end;

addModEventListener(SeasonsUtil);
