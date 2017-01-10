---------------------------------------------------------------------------------------------------------
-- ssSeasonsUtil SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  Calculate current day of the week using gametime (Mon-Sun)
-- Authors:  Jarvixes, mrbear, reallogger, theSeb
--

ssSeasonsUtil = {}

ssSeasonsUtil.weekDays = {}
ssSeasonsUtil.weekDaysShort = {}
ssSeasonsUtil.seasons = {}

ssSeasonsUtil.DAYS_IN_WEEK = 7
ssSeasonsUtil.SEASONS_IN_YEAR = 4

ssSeasonsUtil.SEASON_SPRING = 0
ssSeasonsUtil.SEASON_SUMMER = 1
ssSeasonsUtil.SEASON_AUTUMN = 2
ssSeasonsUtil.SEASON_WINTER = 3

ssSeasonsUtil.weekDays = {
    ssLang.getText("SS_WEEKDAY_MONDAY", "Monday"),
    ssLang.getText("SS_WEEKDAY_TUESDAY", "Tuesday"),
    ssLang.getText("SS_WEEKDAY_WEDNESDAY", "Wednesday"),
    ssLang.getText("SS_WEEKDAY_THURSDAY", "Thursday"),
    ssLang.getText("SS_WEEKDAY_FRIDAY", "Friday"),
    ssLang.getText("SS_WEEKDAY_SATURDAY", "Saturday"),
    ssLang.getText("SS_WEEKDAY_SUNDAY", "Sunday"),
}

ssSeasonsUtil.weekDaysShort = {
    ssLang.getText("SS_WEEKDAY_MON", "Mon"),
    ssLang.getText("SS_WEEKDAY_TUE", "Tue"),
    ssLang.getText("SS_WEEKDAY_WED", "Wed"),
    ssLang.getText("SS_WEEKDAY_THU", "Thu"),
    ssLang.getText("SS_WEEKDAY_FRI", "Fri"),
    ssLang.getText("SS_WEEKDAY_SAT", "Sat"),
    ssLang.getText("SS_WEEKDAY_SUN", "Sun"),
}

ssSeasonsUtil.seasons = {
    [0] = ssLang.getText("SS_SEASON_SPRING", "Spring"),
    ssLang.getText("SS_SEASON_SUMMER", "Summer"),
    ssLang.getText("SS_SEASON_AUTUMN", "Autumn"),
    ssLang.getText("SS_SEASON_WINTER", "Winter"),
}

function ssSeasonsUtil:load(savegame, key)
    self.daysInSeason = Utils.clamp(ssStorage.getXMLInt(savegame, key .. ".settings.daysInSeason", 9), 3, 12)
    self.latestSeason = ssStorage.getXMLInt(savegame, key .. ".settings.latestSeason", -1)
    self.latestGrowthStage = ssStorage.getXMLInt(savegame, key .. ".settings.latestGrowthStage", 0)
    self.currentDayOffset = ssStorage.getXMLInt(savegame, key .. ".settings.currentDayOffset_DO_NOT_CHANGE", 0)

    self.isNewGame = savegame == nil
end

function ssSeasonsUtil:save(savegame, key)
    ssStorage.setXMLInt(savegame, key .. ".settings.daysInSeason", self.daysInSeason)
    ssStorage.setXMLInt(savegame, key .. ".settings.latestSeason", self.latestSeason)
    ssStorage.setXMLInt(savegame, key .. ".settings.latestGrowthStage", self.latestGrowthStage)
    ssStorage.setXMLInt(savegame, key .. ".settings.currentDayOffset_DO_NOT_CHANGE", self.currentDayOffset)
end

function ssSeasonsUtil:loadMap(name)
    g_currentMission.environment:addDayChangeListener(self)
end

function ssSeasonsUtil:deleteMap()
end

function ssSeasonsUtil:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssSeasonsUtil:keyEvent(unicode, sym, modifier, isDown)
end

function ssSeasonsUtil:update(dt)
    if self.isNewGame then
        self.isNewGame = false
        ssSeasonsUtil:dayChanged() -- trigger the stage change events.
    end

    -- TODO: This does not belong here, but in the main seasons class (g_seasons ?)
    if InputBinding.hasEvent(InputBinding.SEASONS_SHOW_MENU) then
        g_gui:showGui("SeasonsMenu")
    end
end

function ssSeasonsUtil:readStream(streamId, connection)
    self.daysInSeason = streamReadFloat32(streamId)
    self.latestSeason = streamReadFloat32(streamId)
    self.latestGrowthStage = streamReadFloat32(streamId)
end

function ssSeasonsUtil:writeStream(streamId, connection)
    streamWriteFloat32(streamId, self.daysInSeason)
    streamWriteFloat32(streamId, self.latestSeason)
    streamWriteFloat32(streamId, self.latestGrowthStage)
end

function ssSeasonsUtil:draw()
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

-- 0 = spring, 3 = winter
function ssSeasonsUtil:isSeason(seasonNumber)
    return self:season() == seasonNumber
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

-- This is here, because ssSeasonsMod is never really loaded as a mod class..
-- It is complicated, but installing a day change listener on it wont work
function ssSeasonsUtil:dayChanged()
    if ssSeasonsMod.enabled then
        local currentSeason = self:season()

        local currentGrowthStage = self:currentGrowthStage()

        -- Call season change events
        if currentSeason ~= ssSeasonsUtil.latestSeason then
            ssSeasonsUtil.latestSeason = currentSeason

            for _, target in pairs(ssSeasonsMod.seasonListeners) do
                -- No check here, let it crash if the function is missing
                target.seasonChanged(target)
            end
        end

        -- Call growth stage events
        if currentGrowthStage ~= ssSeasonsUtil.latestGrowthStage then
            ssSeasonsUtil.latestGrowthStage = currentGrowthStage

            for _, target in pairs(ssSeasonsMod.growthStageListeners) do
                -- No check here, let it crash if the function is missing
                target.growthStageChanged(target)
            end
        end
    end
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
    ssTime:adaptTime()

    -- Redo weather manager
    ssWeatherManager:buildForecast()
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
