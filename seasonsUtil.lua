---------------------------------------------------------------------------------------------------------
-- SeasonsUtil SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  Calculate current day of the week using gametime (Mon-Sun)
-- Authors:  Akuenzi, ian898, Jarvixes, theSeb
--

SeasonsUtil = {};

SeasonsUtil.weekDays = {"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"};
SeasonsUtil.weekDaysShort = {"Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"};
SeasonsUtil.daysInWeek = 7;
SeasonsUtil.seasons = {[0]="Spring", "Summer", "Autumn", "Winter"};
SeasonsUtil.seasonsInYear = 4;

SeasonsUtil.daysInSeason = 10;

function SeasonsUtil:loadMap(name)
     print("Loading SeasonsUtil");
     g_currentMission.SeasonsUtil = self;

     -- FIXME(jos): load daysInSeason from savegame
     -- FIXME(jos): load weekdays, weekdayshsort and seasons from i18n
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
    return ((dayNumber - 1) % self.daysInWeek) + 1;
end;

-- Get the season number.
-- If no day supplied, uses current day
function SeasonsUtil:season(dayNumber)
    if (dayNumber == nil) then
        dayNumber = self:currentDayNumber();
    end;

    return math.floor(dayNumber / self.daysInSeason) % self.seasonsInYear;
end;

-- This function calculates the real-ish daynumber from an ingame day number
-- Used by function that calculate a realistic weather / etc
-- Spring: Mar (60)  - May (151)
-- Summer: Jun (152) - Aug (243)
-- Autumn: Sep (244) - Nov (305)
-- Winter: Dec (335) - Feb (59)
-- FIXME(jos): Of course, this changes on the southern hemisphere
function SeasonsUtil:julianDay(dayNumber)
    local season, partInSeason, dayInSeason;
    local starts = {[0] = 60, 152, 244, 335 };

    season = self:season(dayNumber);
    dayInSeason = dayNumber % self.daysInSeason;
    partInSeason = dayInSeason / self.daysInSeason;

    return math.floor(starts[season] + partInSeason * 30);
end;

function SeasonsUtil:julanDayToDayNumber(julianDay)
    local season, partInSeason, start;

    if julianDay < 60 then
        season = 3; -- winter
        start = 335;
    elseif julianDay < 152 then
        season = 0; -- spring
        start = 60;
    elseif julianDay < 244 then
        season = 1; -- summer
        start = 152;
    elseif julianDay < 335 then
        season = 2; -- autumn
        start = 224;
    end;

    partInSeason = (julianDay - start) / 61.5;

    return season * self.daysInSeason + math.floor(partInSeason * self.daysInSeason);
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

-- Get short day name for given day number
-- If no day number supplied, uses current day
function SeasonsUtil:dayNameShort(dayNumber)
    return self.weekDaysShort[self:dayOfWeek(dayNumber)];
end;

function SeasonsUtil:nextWeekDayNumber(currentDay)
    return (currentDay + 1) % self.daysInWeek;
end;

addModEventListener(SeasonsUtil);
