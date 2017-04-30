----------------------------------------------------------------------------------------------------
-- ssEnvironment
----------------------------------------------------------------------------------------------------
-- Purpose:  Adjust day/night system and implement seasons
--           Definition of a season and  transitions
-- Authors:  Rahkiin, reallogger, theSeb
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssEnvironment = {}
g_seasons.environment = ssEnvironment

----------------------------
-- Constants
----------------------------

ssEnvironment.DAYS_IN_WEEK = 7
ssEnvironment.SEASONS_IN_YEAR = 4
ssEnvironment.MONTHS_IN_YEAR = 12
ssEnvironment.TRANSITIONS_IN_YEAR = 12

ssEnvironment.SEASON_SPRING = 0 -- important to start at 0, not 1
ssEnvironment.SEASON_SUMMER = 1
ssEnvironment.SEASON_AUTUMN = 2
ssEnvironment.SEASON_WINTER = 3

ssEnvironment.TRANSITION_EARLY_SPRING = 1
ssEnvironment.TRANSITION_MID_SPRING = 2
ssEnvironment.TRANSITION_LATE_SPRING = 3

ssEnvironment.TRANSITION_EARLY_SUMMER = 4
ssEnvironment.TRANSITION_MID_SUMMER = 5
ssEnvironment.TRANSITION_LATE_SUMMER = 6

ssEnvironment.TRANSITION_EARLY_AUTUMN = 7
ssEnvironment.TRANSITION_MID_AUTUMN = 8
ssEnvironment.TRANSITION_LATE_AUTUMN = 9

ssEnvironment.TRANSITION_EARLY_WINTER = 10
ssEnvironment.TRANSITION_MID_WINTER = 11
ssEnvironment.TRANSITION_LATE_WINTER = 12

function ssEnvironment:preLoad()
    -- Install the snow raintype. This needs to be just after the vanilla
    -- environment did it, because in here (preLoad) it is too early, and
    -- in loadMap it is too late. (both crash)
    Environment.new = Utils.overwrittenFunction(Environment.new, function (self, superFunc, xmlFilename)
        local self = superFunc(self, xmlFilename)

        Environment.RAINTYPE_SNOW = "snow"
        self:loadRainType(Environment.RAINTYPE_SNOW, 1, g_seasons.modDir .. "resources/environment/snow.i3d", false, 0, 0)
        self.rainFogColor[Environment.RAINTYPE_SNOW] = {0.07074, 0.07074, 0.07074, 0.01}

        return self
    end)
end

function ssEnvironment:load(savegame, key)
    self.daysInSeason = Utils.clamp(ssXMLUtil.getInt(savegame, key .. ".settings.daysInSeason", 9), 3, 12)
    self.latestSeason = ssXMLUtil.getInt(savegame, key .. ".environment.latestSeason", -1)
    self.latestTransition = ssXMLUtil.getInt(savegame, key .. ".environment.latestGrowthStage", 0) --todo: fix this ... leaving this as stage in the xml file until release
                                                                                                            --to not break existing test save games
    self.currentDayOffset = ssXMLUtil.getInt(savegame, key .. ".environment.currentDayOffset_DO_NOT_CHANGE", 0)

    self._doInitalDayEvent = savegame == nil
end

function ssEnvironment:save(savegame, key)
    ssXMLUtil.setInt(savegame, key .. ".settings.daysInSeason", self.daysInSeason)
    ssXMLUtil.setInt(savegame, key .. ".environment.latestSeason", self.latestSeason)
    ssXMLUtil.setInt(savegame, key .. ".environment.latestGrowthStage", self.latestTransition) --TODO: fix this before release
    ssXMLUtil.setInt(savegame, key .. ".environment.currentDayOffset_DO_NOT_CHANGE", self.currentDayOffset)
end

function ssEnvironment:loadMap(name)
    self.seasonChangeListeners = {}
    self.transitionChangeListeners = {}
    self.seasonLengthChangeListeners = {}

    -- Add day change listener to handle new dayNight system and new events
    g_currentMission.environment:addDayChangeListener(self)
end

function ssEnvironment:readStream(streamId, connection)
    g_currentMission.environment.currentDay = streamReadInt16(streamId)
    self.daysInSeason = streamReadInt16(streamId)
    self.latestSeason = streamReadInt16(streamId)
    self.latestTransition = streamReadInt16(streamId)
    self.currentDayOffset = streamReadInt16(streamId)
end

function ssEnvironment:writeStream(streamId, connection)
    streamWriteInt16(streamId, g_currentMission.environment.currentDay)
    streamWriteInt16(streamId, self.daysInSeason)
    streamWriteInt16(streamId, self.latestSeason)
    streamWriteInt16(streamId, self.latestTransition)
    streamWriteInt16(streamId, self.currentDayOffset)
end

function ssEnvironment:update(dt)
    -- The first day has already started with a new savegame
    -- Call all the event handlers to update growth, time and anything else
     if self._doInitalDayEvent then
        self:callListeners()
        self._doInitalDayEvent = false
    end
end

----------------------------
-- Seasons events
----------------------------

function ssEnvironment:callListeners()
    if not g_seasons.enabled then return end

    local currentSeason = self:currentSeason()
    local currentTransition = self:transitionAtDay()

    -- Call season change events
    if currentSeason ~= self.latestSeason then
        self.latestSeason = currentSeason

        for _, listener in pairs(self.seasonChangeListeners) do
            listener:seasonChanged()
        end
    end

    -- Call  transition events
    if currentTransition ~= self.latestTransition then
        self.latestTransition = currentTransition

        for _, listener in pairs(self.transitionChangeListeners) do
            listener:transitionChanged()
        end
    end
end

-- Listeners for a change of season
function ssEnvironment:addSeasonChangeListener(listener)
    if listener ~= nil then
        self.seasonChangeListeners[listener] = listener
    end
end

function ssEnvironment:removeSeasonChangeListener(listener)
    if listener ~= nil then
        self.seasonChangeListeners[listener] = nil
    end
end

-- Listeners for a change of transition
function ssEnvironment:addTransitionChangeListener(listener)
    if listener ~= nil then
        self.transitionChangeListeners[listener] = listener
    end
end

function ssEnvironment:removeTransitionChangeListener(listener)
    if listener ~= nil then
        self.transitionChangeListeners[listener] = nil
    end
end

-- Listeners for a change of season length
function ssEnvironment:addSeasonLengthChangeListener(listener)
    if listener ~= nil then
        self.seasonLengthChangeListeners[listener] = listener
    end
end

function ssEnvironment:removeSeasonLengthChangeListener(listener)
    if listener ~= nil then
        self.seasonLengthChangeListeners[listener] = nil
    end
end

----------------------------
-- Events
----------------------------

function ssEnvironment:dayChanged()
    self:callListeners()
end

----------------------------
-- Tools
----------------------------

-- Get the current day number.
-- Always use this function when working with seasons, because it uses the offset
-- for keeping in the correct season when changing season length
function ssEnvironment:currentDay()
    return g_currentMission.environment.currentDay + self.currentDayOffset
end

-- Starts with 0
function ssEnvironment:currentSeason()
    return self:seasonAtDay(self:currentDay())
end

-- Starts with 0
function ssEnvironment:seasonAtDay(dayNumber)
    return math.fmod(math.floor((dayNumber - 1) / self.daysInSeason), self.SEASONS_IN_YEAR)
end

-- Retuns month number based on dayNumber
function ssEnvironment:monthAtDay(dayNumber)
    return self:monthAtTransitionNumber(self:transitionAtDay(dayNumber))
end

function ssEnvironment:monthAtTransitionNumber(transitionNumber)
    local monthNumber = math.fmod(transitionNumber, self.MONTHS_IN_YEAR) + 2
    if monthNumber > self.MONTHS_IN_YEAR then --because 11 becomes 13 TODO: brain gone  need to improve
        monthNumber = 1
    end

    return monthNumber
end

-- Returns 1-daysInSeason
function ssEnvironment:dayInSeason(currentDay)
    if (currentDay == nil) then
        currentDay = self:currentDay()
    end

    local season = self:seasonAtDay(currentDay) -- 0-3
    local dayInYear = math.fmod(currentDay - 1, self.daysInSeason * self.SEASONS_IN_YEAR) + 1 -- 1+
    return (dayInYear - 1 - season * self.daysInSeason) + 1 -- 1 - daysInSeason
end

-- Starts with 0
function ssEnvironment:currentYear()
    return self:yearAtDay(self:currentDay())
end

-- Starts with 0
function ssEnvironment:yearAtDay(dayNumber)
    return math.floor((dayNumber - 1) / (self.daysInSeason * self.SEASONS_IN_YEAR))
end

function ssEnvironment:nextTransition()
    local cGT = self:transitionAtDay()
    if cGT == self.TRANSITIONS_IN_YEAR then
        return 1
    else
        return cGT + 1
    end
end

--uses currentDay if dayNumber not passed in
function ssEnvironment:transitionAtDay(dayNumber)
    if (dayNumber == nil) then
        dayNumber = self:currentDay()
    end

    local season = self:seasonAtDay(dayNumber)
    local seasonTransition = self:getTransitionInSeason(dayNumber)
    return (seasonTransition + (season * 3))
end

--this funtion returns the transition within a season (1, 2, 3)
--most functions should not call this directly. use transitionAtDay instead to get the current transition
function ssEnvironment:getTransitionInSeason(currentDay)
    if (currentDay == nil) then
        currentDay = self:currentDay()
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

-- Called when the number of days in a season needs to be changed.
-- A complex algorithm
function ssEnvironment:changeDaysInSeason(newSeasonLength) --15
    local oldSeasonLength = self.daysInSeason -- 6 ELIM
    local actualCurrentDay = self:currentDay() -- 9

    local year = self:currentYear(actualCurrentDay) -- 11 ELIM
    local season = self:currentSeason(actualCurrentDay) -- 12, 18
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
    g_seasons.daylight:adaptTime()

    -- Call season length changed listeners
    for _, listener in pairs(self.seasonLengthChangeListeners) do
        listener:seasonLengthChanged()
    end
end
