---------------------------------------------------------------------------------------------------------
-- ssSeasonsUtil SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  Calculate current day of the week using gametime (Mon-Sun)
-- Authors:  Rahkiin, mrbear, reallogger, theSeb
--

ssSeasonsUtil = {}

function ssSeasonsUtil:loadMap(name)
end

function ssSeasonsUtil:update(dt)
    if self.isNewGame then
        self.isNewGame = false
        ssSeasonsUtil:dayChanged() -- trigger the stage change events.
    end
end

-- Get the current day number.
-- Always use this function when working with seasons, because it uses the offset
-- for keeping in the correct season when changing season length
function ssSeasonsUtil:currentDayNumber()
    return g_currentMission.environment.currentDay + self.currentDayOffset
end

-- Get the day within the week
-- assumes that day 1 = monday
-- If no day supplied, uses current day
function ssSeasonsUtil:dayOfWeek(dayNumber)
    if (dayNumber == nil) then
        dayNumber = self:currentDayNumber()
    end

    return math.fmod(dayNumber - 1, self.DAYS_IN_WEEK) + 1
end

-- Get the season number.
-- If no day supplied, uses current day
-- Starts with 0
function ssSeasonsUtil:season(dayNumber)
    if (dayNumber == nil) then
        dayNumber = self:currentDayNumber()
    end

    return math.fmod(math.floor((dayNumber - 1) / self.daysInSeason), self.SEASONS_IN_YEAR)
end

-- Starts with 0
function ssSeasonsUtil:year(dayNumber)
    if (dayNumber == nil) then
        dayNumber = self:currentDayNumber()
    end

    return math.floor((dayNumber - 1) / (self.daysInSeason * self.SEASONS_IN_YEAR))
end

-- This function calculates the real-ish daynumber from an ingame day number
-- Used by function that calculate a realistic weather / etc
-- Spring: Mar (60)  - May (151)
-- Summer: Jun (152) - Aug (243)
-- Autumn: Sep (244) - Nov (305)
-- Winter: Dec (335) - Feb (59)
-- FIXME(jos): Of course, this changes on the southern hemisphere
function ssSeasonsUtil:julianDay(dayNumber)
    local season, partInSeason, dayInSeason
    local starts = {[0] = 60, 152, 244, 335 }

    season = self:season(dayNumber)
    dayInSeason = dayNumber % self.daysInSeason
    partInSeason = dayInSeason / self.daysInSeason

    return math.fmod(math.floor(starts[season] + partInSeason * 91), 365)
end

function ssSeasonsUtil:julanDayToDayNumber(julianDay)
    local season, partInSeason, start

    if julianDay < 60 then
        season = 3 -- winter
        start = 335
    elseif julianDay < 152 then
        season = 0 -- spring
        start = 60
    elseif julianDay < 244 then
        season = 1 -- summer
        start = 152
    elseif julianDay < 335 then
        season = 2 -- autumn
        start = 224
    end

    partInSeason = (julianDay - start) / 61.5

    return season * self.daysInSeason + math.floor(partInSeason * self.daysInSeason)
end

-- Get season name for given day number
-- If no day number supplied, uses current day
function ssSeasonsUtil:seasonName(dayNumber)
    return self.seasons[self:season(dayNumber)]
end

-- Get day name for given day number
-- If no day number supplied, uses current day
function ssSeasonsUtil:dayName(dayNumber)
    return self.weekDays[self:dayOfWeek(dayNumber)]
end

-- Get short day name for given day number
-- If no day number supplied, uses current day
function ssSeasonsUtil:dayNameShort(dayNumber)
    return self.weekDaysShort[self:dayOfWeek(dayNumber)]
end

function ssSeasonsUtil:nextWeekDayNumber(currentDay)
    return (currentDay + 1) % self.DAYS_IN_WEEK
end

-- Returns 1-daysInSeason
function ssSeasonsUtil:dayInSeason(currentDay)
    if (currentDay == nil) then
        currentDay = self:currentDayNumber()
    end

    local season = self:season(currentDay) -- 0-3
    local dayInYear = math.fmod(currentDay - 1, self.daysInSeason * self.SEASONS_IN_YEAR) + 1 -- 1+
    return (dayInYear - 1 - season * self.daysInSeason) + 1 -- 1-daysInSeason
end

function ssSeasonsUtil:currentGrowthTransition(currentDay)

    local season = self:season(currentDay)
    local cGS = self:currentGrowthStage(currentDay)
    return (cGS + (season*3))
end

function ssSeasonsUtil:calcDaysPerTransition()
    local l = self.daysInSeason / 3.0
	local earlyStart = 1
	local earlyEnd = mathRound(1 * l)
	local midStart = mathRound(1 * l) + 1
	local midEnd = mathRound(2 * l)
	local lateStart = mathRound(2 * l)+1
	local lateEnd = self.daysInSeason
    return {earlyStart, earlyEnd, midStart, midEnd, lateStart, lateEnd}
end

function ssSeasonsUtil:currentGrowthStage(currentDay)
    if (currentDay == nil) then
        currentDay = self:currentDayNumber()
    end

    -- Length of a state
    local l = self.daysInSeason / 3.0
    local dayInSeason = self:dayInSeason(currentDay)

    if dayInSeason >= mathRound(2 * l) + 1 then -- Turn 3
        return 3
    elseif dayInSeason >= mathRound(1 * l) + 1 then -- Turn 2
        return 2
    else
        return 1
    end

    return nil
end


function ssSeasonsUtil:changeDaysInSeason(newSeasonLength) --15
    local oldSeasonLength = self.daysInSeason -- 6 ELIM
    local actualCurrentDay = self:currentDayNumber() -- 9

    local year = self:year(actualCurrentDay) -- 11 ELIM
    local season = self:season(actualCurrentDay) -- 12, 18
    local dayInSeason = self:dayInSeason(actualCurrentDay) -- 13 ELIM

    local seasonThatWouldBe = math.fmod(math.floor((actualCurrentDay - 1) / newSeasonLength), self.SEASONS_IN_YEAR) -- 16

    local dayThatNeedsToBe = math.floor((dayInSeason - 1) / oldSeasonLength * newSeasonLength) + 1 -- 19

    local realDifferenceInSeason = season - seasonThatWouldBe -- 21 ELIM

    local relativeYearThatNeedsTobe = realDifferenceInSeason < 0 and 1 or 0 -- 23

    local resultingDayNumber = ((year + relativeYearThatNeedsTobe) * self.SEASONS_IN_YEAR + season) * newSeasonLength + dayThatNeedsToBe -- 26
    local resultingOffset = resultingDayNumber - actualCurrentDay -- 27
    local newOffset = math.fmod(self.currentDayOffset + resultingOffset, self.SEASONS_IN_YEAR * newSeasonLength) -- 28

    self.daysInSeason = newSeasonLength
    self.currentDayOffset = newOffset

    -- Re-do time
    ssEnvironment:adaptTime()

    -- Redo weather manager
    ssWeatherManager:buildForecast()

    -- Change repair interval
    ssVehicle.repairInterval = newSeasonLength * 2
end

------------------------------------
---- Server only
------------------------------------


--Outputs a random sample from a triangular distribution
function ssSeasonsUtil:ssTriDist(m)
    local pmode = {}
    local p = {}

    --math.randomseed( g_currentMission.time )
    math.random()

    pmode = (m.mode-m.min)/(m.max-m.min)
    p = math.random()
    if p < pmode then
        return math.sqrt(p*(m.max-m.min)*(m.mode-m.min))+m.min
    else
        return m.max-math.sqrt((1-p)*(m.max-m.min)*(m.max-m.mode))
    end
end

-- Approximation of the inverse CFD of a normal distribution
-- Based on A&S formula 26.2.23 - thanks to John D. Cook
function ssSeasonsUtil:RationalApproximation(t)
    local c = {2.515517, 0.802853, 0.010328}
    local d = {1.432788, 0.189269, 0.001308}

    return t - ((c[3]*t + c[2])*t + c[1]) / (((d[3]*t + d[2])*t + d[1])*t + 1.0)
end

-- Outputs a random sample from a normal distribution with mean mu and standard deviation sigma
function ssSeasonsUtil:ssNormDist(mu,sigma)
    --math.randomseed( g_currentMission.time )
    math.random()

    local p = math.random()

    if p < 0.5 then
        return self:RationalApproximation(math.sqrt(-2.0 * math.log(p))) * -sigma + mu
    else
        return self:RationalApproximation(math.sqrt(-2.0 * math.log(1 - p))) * sigma + mu
    end
end

-- Outputs a random sample from a lognormal distribution
function ssSeasonsUtil:ssLognormDist(beta, gamma)
    --math.randomseed( g_currentMission.time )
    math.random()

    local p = math.random()
    local z

    if p < 0.5 then
        z = self:RationalApproximation( math.sqrt(-2.0*math.log(p)))*-1
    else
        z = self:RationalApproximation( math.sqrt(-2.0*math.log(1-p)))
    end

    return gamma * math.exp ( z / beta )
end

function ssSeasonsUtil:getModMapDataPath(dataFileName)
    if g_currentMission.missionInfo.map.isModMap == true then

        local path = g_currentMission.missionInfo.map.baseDirectory .. dataFileName
        if fileExists(path) then
            return path
        end
    end

    return nil
end


--
-- List implementation
-- A fast implementation of queue(actually double queue) in Lua is done by the book Programming in Lua:
-- http://www.lua.org/pil/11.4.html
-- Reworked by MrBear
--

-- ssSeasonsUtil.List = {}
function ssSeasonsUtil.listNew()
    return {first = 0, last = -1}
end

function ssSeasonsUtil.listPushLeft (list, value)
    local first = list.first - 1
    list.first = first
    list[first] = value
end

function ssSeasonsUtil.listPushRight (list, value)
    local last = list.last + 1
    list.last = last
    list[last] = value
end

function ssSeasonsUtil.listPopLeft (list)
    local first = list.first
    if first > list.last then return nil end
    local value = list[first]
    list[first] = nil        -- to allow garbage collection
    list.first = first + 1
    return value
end

function ssSeasonsUtil.listPopRight (list)
    local last = list.last
    if list.first > last then return nil end
    local value = list[last]
    list[last] = nil         -- to allow garbage collection
    list.last = last - 1
    return value
end

function Set(list)
    local set = {}

    for _, l in ipairs(list) do
        set[l] = true
    end

    return set
end

------------- Useful global functions ---------------

-- Yep, LUA does not have a math.round. It's a first.
function mathRound(value, idp)
    local mult = 10^(idp or 0)
    return math.floor(value * mult + 0.5) / mult
end

-- http://lua-users.org/wiki/CopyTable
function deepCopy(obj, seen)
    local orig_type = type(obj)

    if orig_type ~= 'table' then return obj end
    if seen and seen[obj] then return seen[obj] end

    local s = seen or {}
    local res = setmetatable({}, getmetatable(obj))
    s[obj] = res

    for k, v in pairs(obj) do
        res[deepCopy(k, s)] = deepCopy(v, s)
    end

    return res
end

-- TODO replace with table.getn()
function arrayLength(arr)
    local n = 0
    for i = 1, #arr do
        n = n + 1
    end
    return n
end

function print_r(t)
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    pos = tostring(pos)
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
end
