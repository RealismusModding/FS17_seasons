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
ssEnvironment.MAX_DAYS_IN_SEASON = 24

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

source(g_seasons.modDir .. "src/events/ssVisualSeasonChangedEvent.lua")

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
    self.daysInSeason = Utils.clamp(ssXMLUtil.getInt(savegame, key .. ".settings.daysInSeason", 9), 3, self.MAX_DAYS_IN_SEASON)
    self.latestSeason = ssXMLUtil.getInt(savegame, key .. ".environment.latestSeason", 0)
    self.latestTransition = ssXMLUtil.getInt(savegame, key .. ".environment.latestTransition", 1)
    self.currentDayOffset = ssXMLUtil.getInt(savegame, key .. ".environment.currentDayOffset_DO_NOT_CHANGE", -(g_currentMission.environment.currentDay - 1))
    self.latestVisualSeason = ssXMLUtil.getInt(savegame, key .. ".environment.latestVisualSeason", self.latestSeason)

    self._doInitalDayEvent = savegame == nil
end

function ssEnvironment:save(savegame, key)
    ssXMLUtil.setInt(savegame, key .. ".settings.daysInSeason", self.daysInSeason)
    ssXMLUtil.setInt(savegame, key .. ".environment.latestSeason", self.latestSeason)
    ssXMLUtil.setInt(savegame, key .. ".environment.latestVisualSeason", self.latestVisualSeason)
    ssXMLUtil.setInt(savegame, key .. ".environment.latestTransition", self.latestTransition)
    ssXMLUtil.setInt(savegame, key .. ".environment.currentDayOffset_DO_NOT_CHANGE", self.currentDayOffset)
end

function ssEnvironment:loadMap(name)
    self.seasonChangeListeners = {}
    self.transitionChangeListeners = {}
    self.seasonLengthChangeListeners = {}
    self.visualSeasonChangeListeners = {}

    self.latitudeCategories = {}
    self:loadLatitudeCategoriesFromXML(g_seasons.modDir .. "data/visualSeason.xml")

    -- Modded
    for _, path in ipairs(g_seasons:getModPaths("visualSeason")) do
        self:loadLatitudeCategoriesFromXML(path)
    end

    print_r(self.latitudeCategories)

    -- Add day change listener to handle new dayNight system and new events
    g_currentMission.environment:addDayChangeListener(self)

    addConsoleCommand("ssSetVisualSeason", "Set visual season", "consoleCommandSetVisualSeason", self)
end

function ssEnvironment:readStream(streamId, connection)
    g_currentMission.environment.currentDay = streamReadInt16(streamId)
    self.daysInSeason = streamReadInt16(streamId)
    self.latestSeason = streamReadInt16(streamId)
    self.latestTransition = streamReadInt16(streamId)
    self.latestVisualSeason = streamReadInt16(streamId)
    self.currentDayOffset = streamReadInt16(streamId)
end

function ssEnvironment:writeStream(streamId, connection)
    streamWriteInt16(streamId, g_currentMission.environment.currentDay)
    streamWriteInt16(streamId, self.daysInSeason)
    streamWriteInt16(streamId, self.latestSeason)
    streamWriteInt16(streamId, self.latestTransition)
    streamWriteInt16(streamId, self.latestVisualSeason)
    streamWriteInt16(streamId, self.currentDayOffset)
end

function ssEnvironment:loadLatitudeCategoriesFromXML(path)
    local file = loadXMLFile("season", path)

    local i = 0
    while true do
        local key = string.format("visualSeason.latitudeCategory(%i)", i)
        if not ssXMLUtil.hasProperty(file, key) then break end

        local type = ssXMLUtil.getInt(file, key .. "#type")
        if type == nil then
            logInfo("ssEnvironment: type of latitude category invalid")
            break
        end

        if self.latitudeCategories[type] == nil then
            self.latitudeCategories[type] = {}
        end

        local j = 0
        while true do
            local vkey = string.format("%s.visual(%i)", key, j)
            if not ssXMLUtil.hasProperty(file, vkey) then break end

            local gt = ssXMLUtil.getInt(file, vkey .. "#transition")
            if gt == nil then
                logInfo("ssEnvironment: invalid transition in latitude categories")
                break
            end

            self.latitudeCategories[type][gt] = ssXMLUtil.getString(file, vkey)

            j = j + 1
        end

        i = i + 1
    end

    delete(file)
end

function ssEnvironment:update(dt)
    -- The first day has already started with a new savegame
    -- Call all the event handlers to update growth, time and anything else

    if self._doInitalDayEvent then
        self.latestTransition = 0
        self.latestSeason = -1
        self:callListeners()
        self._doInitalDayEvent = false

        g_currentMission.inGameMessage:showMessage("Seasons", ssLang.getText("msg_welcome"), 30000)
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

        for _, listener in ipairs(self.seasonChangeListeners) do
            listener:seasonChanged()
        end
    end

    -- Call  transition events
    if currentTransition ~= self.latestTransition then
        self.latestTransition = currentTransition

        for _, listener in ipairs(self.transitionChangeListeners) do
            listener:transitionChanged()
        end
    end

    -- Let MP do the calling on the client
    if g_currentMission:getIsServer() then
        local newVisuals = self:calculateVisualSeason()

        if newVisuals ~= self.latestVisualSeason then
            self.latestVisualSeason = newVisuals

            for _, listener in ipairs(self.visualSeasonChangeListeners) do
                listener:visualSeasonChanged(newVisuals)
            end

            ssVisualSeasonChangedEvent.sendEvent(newVisuals)
        end
    end
end

local function removeItemFromTable(tbl, item)
    local i

    for j, v in ipairs(tbl) do
        if v == item then
            i = j
        end
    end

    if i ~= nil then
        table.remove(tbl, i)
    end
end

-- Listeners for a change of season
function ssEnvironment:addSeasonChangeListener(listener)
    if listener ~= nil then
        table.insert(self.seasonChangeListeners, listener)
    end
end

function ssEnvironment:removeSeasonChangeListener(listener)
    if listener ~= nil then
        removeItemFromTable(self.seasonChangeListeners, listener)
    end
end

-- Listeners for a change of transition
function ssEnvironment:addTransitionChangeListener(listener)
    if listener ~= nil then
        table.insert(self.transitionChangeListeners, listener)
    end
end

function ssEnvironment:removeTransitionChangeListener(listener)
    if listener ~= nil then
        removeItemFromTable(self.transitionChangeListeners, listener)
    end
end

-- Listeners for a change of season length
function ssEnvironment:addSeasonLengthChangeListener(listener)
    if listener ~= nil then
        table.insert(self.seasonLengthChangeListeners, listener)
    end
end

function ssEnvironment:removeSeasonLengthChangeListener(listener)
    if listener ~= nil then
        removeItemFromTable(self.seasonLengthChangeListeners, listener)
    end
end

-- Listeners for the change of the visual season (not aligned with actual seasons)
function ssEnvironment:addVisualSeasonChangeListener(listener)
    if listener ~= nil then
        table.insert(self.visualSeasonChangeListeners, listener)
    end
end

function ssEnvironment:removeVisualSeasonChangeListener(listener)
    if listener ~= nil then
        removeItemFromTable(self.visualSeasonChangeListeners, listener)
    end
end

----------------------------
-- Visual season calc
----------------------------

function ssEnvironment:latitudeCategory()
    local lat = g_seasons.daylight.latitude

    if lat <= 45 then
        return 1
    elseif lat <= 50 then
        return 2
    elseif lat <= 60 then
        return 3
    end

    return 4
end

-- Only run once per day
function ssEnvironment:calculateVisualSeason()
    local curSeason = self:currentSeason()
    local avgAirTemp = (ssWeatherManager.forecast[2].highTemp * 8 + ssWeatherManager.forecast[2].lowTemp * 16) / 24
    local lowAirTemp = ssWeatherManager.forecast[2].lowTemp
    local springLeavesTemp = 5
    local dropLeavesTemp = 0

    local dataVisual = self.latitudeCategories[self:latitudeCategory()][self:transitionAtDay()]
    local dataSeason = ssUtil.seasonKeyToId[dataVisual]

    -- Spring
    -- Keeping bare winter textures if the daily average temperature is below a treshold
    if dataVisual == "springTemp" and self.latestVisualSeason == self.SEASON_WINTER
        and (avgAirTemp <= springLeavesTemp or g_seasons.snow.appliedSnowDepth > 0) then
        return self.SEASON_WINTER

    -- Winter
    -- Keeping autumn textures until the daily average temperature is below a treshold
    elseif dataVisual == "winterTemp" and self.latestVisualSeason == self.SEASON_AUTUMN and avgAirTemp >= dropLeavesTemp then
        return self.SEASON_AUTUMN

    -- Get value from the data if available
    elseif dataSeason ~= nil then
        return dataSeason

    else
        return curSeason
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

function ssEnvironment:currentVisualSeason()
    return self.latestVisualSeason
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
    if oldSeasonLength == newSeasonLength then return end

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
    for _, listener in ipairs(self.seasonLengthChangeListeners) do
        listener:seasonLengthChanged()
    end
end

--
-- Console command for debugging and map makers
--

function ssEnvironment:consoleCommandSetVisualSeason(seasonName)
    local season = g_seasons.util.seasonKeyToId[ssUtil.trim(seasonName)]

    if season == nil then
        logInfo("The supplied visual season does not exist")
        return
    end

    -- Overwrite getter
    -- local oldCurrentSeason = self.currentSeason
    -- self.currentSeason = function (self)
    --     return season
    -- end
    local oldVSeason = self.currentVisualSeason
    self.currentVisualSeason = function (self)
        return season
    end

    -- Update
    for _, listener in pairs(self.visualSeasonChangeListeners) do
        listener:visualSeasonChanged(season)
    end

    -- Fix getter
    -- self.currentSeason = oldCurrentSeason
    self.currentVisualSeason = oldVSeason

    self.debug = false

    return "Updated textures to " .. tostring(season)
end
