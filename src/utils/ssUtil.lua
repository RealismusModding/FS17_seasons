----------------------------------------------------------------------------------------------------
-- ssUtil SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  Calculate current day of the week using gametime (Mon-Sun)
-- Authors:  Rahkiin, mrbear, reallogger, theSeb
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssUtil = {}
g_seasons.util = ssUtil

ssUtil.seasonKeyToId = {
    ["spring"] = 0,
    ["summer"] = 1,
    ["autumn"] = 2,
    ["winter"] = 3
}

-- Get the day within the week
-- assumes that day 1 = monday
function ssUtil.dayOfWeek(dayNumber)
    return math.fmod(dayNumber - 1, g_seasons.environment.DAYS_IN_WEEK) + 1
end

-- This function calculates the real-ish daynumber from an ingame day number
-- Used by function that calculate a realistic weather / etc
-- Spring: Mar (60)  - May (151)
-- Summer: Jun (152) - Aug (243)
-- Autumn: Sep (244) - Nov (305)
-- Winter: Dec (335) - Feb (59)
-- FIXME(jos): This changes on the southern hemisphere
function ssUtil.julianDay(dayNumber)
    local season, partInSeason, dayInSeason
    local starts = {[0] = 60, 152, 244, 335 }

    season = g_seasons.environment:seasonAtDay(dayNumber)
    dayInSeason = (dayNumber - 1) % g_seasons.environment.daysInSeason
    partInSeason = dayInSeason / g_seasons.environment.daysInSeason

    return math.fmod(math.floor(starts[season] + partInSeason * 91), 365)
end

function ssUtil.julianDayToDayNumber(julianDay)
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

    return season * g_seasons.environment.daysInSeason + math.floor(partInSeason * g_seasons.environment.daysInSeason)
end

-- Get season name for given day number
-- If no day number supplied, uses current day
function ssUtil.seasonName(season)
    return ssLang.getText("SS_SEASON_" .. tostring(season), "???")
end

-- Get day name for given day number
-- If no day number supplied, uses current day
function ssUtil.dayName(dayOfWeek)
    return ssLang.getText("SS_WEEKDAY_" .. tostring(dayOfWeek), "???")
end

-- Get short day name for given day number
-- If no day number supplied, uses current day
function ssUtil.dayNameShort(dayOfWeek)
    return ssLang.getText("SS_WEEKDAY_SHORT_" .. tostring(dayOfWeek), "???")
end

-- Get short name of month for given month number
function ssUtil.monthNameShort(monthNumber)
    return ssLang.getText("SS_MONTH_SHORT_" .. tostring(monthNumber), "???")
end

function ssUtil.fullSeasonName(transition)
    return ssLang.getText("SS_SEASON_FULL_NAME_" .. tostring(transition), "???")
end

function ssUtil.nextWeekDayNumber(currentDay)
    return (currentDay + 1) % g_seasons.environment.DAYS_IN_WEEK
end

-- Calculate the split of days into ealy, mid and late season
function ssUtil.calcDaysPerTransition()
    local l = g_seasons.environment.daysInSeason / 3.0
    local earlyStart = 1
    local earlyEnd = mathRound(1 * l)
    local midStart = earlyEnd + 1
    local midEnd = mathRound(2 * l)
    local lateStart = midEnd + 1
    local lateEnd = g_seasons.environment.daysInSeason

    return {earlyStart, earlyEnd, midStart, midEnd, lateStart, lateEnd}
end

--Outputs a random sample from a triangular distribution
function ssUtil.triDist(m)
    local pmode = {}
    local p = {}

    --math.randomseed( g_currentMission.time )
    math.random()

    pmode = (m.mode - m.min) / (m.max - m.min)
    p = math.random()
    if p < pmode then
        return math.sqrt(p * (m.max - m.min) * (m.mode - m.min)) + m.min
    else
        return m.max - math.sqrt((1 - p) * (m.max - m.min) * (m.max - m.mode))
    end
end

-- Approximation of the inverse CFD of a normal distribution
-- Based on A&S formula 26.2.23 - thanks to John D. Cook
function ssUtil.rationalApproximation(t)
    local c = {2.515517, 0.802853, 0.010328}
    local d = {1.432788, 0.189269, 0.001308}

    return t - ((c[3] * t + c[2]) * t + c[1]) / (((d[3] * t + d[2]) * t + d[1]) * t + 1.0)
end

-- Outputs a random sample from a normal distribution with mean mu and standard deviation sigma
function ssUtil.normDist(mu, sigma)
    --math.randomseed( g_currentMission.time )
    math.random()

    local p = math.random()

    if p < 0.5 then
        return ssUtil.rationalApproximation(math.sqrt(-2.0 * math.log(p))) * -sigma + mu
    else
        return ssUtil.rationalApproximation(math.sqrt(-2.0 * math.log(1 - p))) * sigma + mu
    end
end

-- Outputs a random sample from a lognormal distribution
function ssUtil.lognormDist(beta, gamma)
    --math.randomseed( g_currentMission.time )
    math.random()

    local p = math.random()
    local z

    if p < 0.5 then
        z = ssUtil.rationalApproximation( math.sqrt(-2.0 * math.log(p))) * -1
    else
        z = ssUtil.rationalApproximation( math.sqrt(-2.0 * math.log(1 - p)))
    end

    return gamma * math.exp ( z / beta )
end

function ssUtil.getModMapDataPath(dataFileName)
    if g_currentMission.missionInfo.map.isModMap == true then
        local path = g_currentMission.missionInfo.map.baseDirectory .. dataFileName
        if fileExists(path) then
            return path
        end
    end

    return nil
end

function ssUtil.basedir(path)
    local dir, _ = string.match(path, "(.*/)(.*)")

    return dir
end

function ssUtil.normalizedPath(path)
    return path:gsub("/[^/]+/%.%./", "/")
end

function ssUtil.isWorkHours()
    local hour = g_currentMission.environment.currentHour
    local dow = ssUtil.dayOfWeek(g_seasons.environment:currentDay())

    return hour >= ssEconomy.aiDayStart and hour <= ssEconomy.aiDayEnd and dow <= 5
end

function ssUtil.getSnowMaskId()
    local id = getTerrainDetailByName(g_currentMission.terrainRootNode, "ssSnowMask")

    if id == 0 then
        id = getTerrainDetailByName(g_currentMission.terrainRootNode, "SeasonsSnowMask")
    end

    if id == 0 then
        return nil
    end

    return id
end

function ssUtil.getTempMaskId()
    local id = getTerrainDetailByName(g_currentMission.terrainRootNode, "ssTempMask")

    if id == 0 then
        return nil
    end

    return id
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
    local mult = 10 ^ (idp or 0)
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
    local print_r_cache = {}
    local function sub_print_r(t, indent)
        if (print_r_cache[tostring(t)]) then
            print(indent .. "*" .. tostring(t))
        else
            print_r_cache[tostring(t)] = true
            if (type(t) == "table") then
                for pos, val in pairs(t) do
                    pos = tostring(pos)
                    if (type(val) == "table") then
                        print(indent .. "[" .. pos .. "] => " .. tostring(t) .. " {")
                        sub_print_r(val, indent .. string.rep(" ", string.len(pos) + 8))
                        print(indent .. string.rep(" ", string.len(pos) + 6) .. "}")
                    elseif (type(val) == "string") then
                        print(indent .. "[" .. pos .. '] => "' .. val .. '"')
                    else
                        print(indent .. "[" .. pos .. "] => " .. tostring(val))
                    end
                end
            else
                print(indent .. tostring(t))
            end
        end
    end
    if (type(t) == "table") then
        print(tostring(t) .. " {")
        sub_print_r(t, "  ")
        print("}")
    else
        sub_print_r(t, "  ")
    end
    print()
end
