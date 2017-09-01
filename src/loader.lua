----------------------------------------------------------------------------------------------------
-- LOADER SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  Loads the mod
-- Authors:  Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

local ssSeasonsMod = {}

------------------------------------------
-- quickly needed utility functions
------------------------------------------

function log(...)
    if not g_seasons.verbose then return end

    local str = "[Seasons]"
    for i = 1, select("#", ...) do
        str = str .. " " .. tostring(select(i, ...))
    end
    print(str)
end

function logInfo(...)
    local str = "[Seasons]"
    for i = 1, select("#", ...) do
        str = str .. " " .. tostring(select(i, ...))
    end
    print(str)
end

function logStack()
    if not g_seasons.debug then return end

    print(debug.traceback())
end

-- http://lua-users.org/wiki/SplitJoin
local function split(str, pat)
    local t = {}  -- NOTE: use {n = 0} in Lua-5.0
    local fpat = "(.-)" .. pat
    local last_end = 1
    local s, e, cap = str:find(fpat, 1)

    while s do
        if s ~= 1 or cap ~= "" then
            table.insert(t, cap)
        end

        last_end = e + 1
        s, e, cap = str:find(fpat, last_end)
    end

    if last_end <= #str then
        cap = str:sub(last_end)
        table.insert(t, cap)
    end

    return t
end

------------------------------------------
-- file loading
------------------------------------------

local srcFolder = g_currentModDirectory .. "src/"
local files = {
    -- Utilities
    "utils/ssLang",
    "utils/ssXMLUtil",
    "utils/ssSeasonsXML",
    "utils/ssQueue",

    -- Main system
    "ssMultiplayer",
    "ssMain",

    "utils/ssUtil",
    "environment/ssEnvironment",

    "environment/ssDaylight",
    "misc/ssEconomy",
    "environment/ssWeatherManager",
    "environment/ssWeatherForecast",
    "vehicles/ssVehicle",
    "misc/ssFieldJobManager",
    "growth/ssFruitManager",
    "growth/ssGrowthManagerData",
    "growth/ssGrowthGUI",
    "growth/ssGrowthDebug",
    "growth/ssGrowthManager",
    "environment/ssSnow",
    "gui/ssSeasonIntro",
    "environment/ssReplaceVisual",
    "utils/ssDensityMapScanner",

    -- Adjustments to the game
    "misc/ssPedestrianSystem",
    "misc/ssTrafficSystem",
    "misc/ssTreeManager",
    "misc/ssSwathManager",
    "misc/ssBaleManager",
    "misc/ssAnimals",
    "misc/ssSkipNight",

    -- Adjusted objects
    "objects/ssBunkerSilo",
    "placeables/ssPlaceable",
    "placeables/ssStorage",

    -- New objects
    "objects/ssSnowAdmirer",
    "objects/ssSeasonAdmirer",
    "objects/ssIcePlane",

    "misc/ssEconomyHistory",

    -- GUI
    "gui/ssHelpLines",
    "gui/ssRectOverlay",
    "gui/ssGraph",
    "gui/ssSeasonsMenu",
    "gui/ssCatchingUp",

    "handtools/ssMeasureTool"
}

local isDebug = false --<%=debug %>
if isDebug then
    table.insert(files, "utils/ssDebug")
end

-- Classes used for automation of loading and multiplayer
g_modClasses = {}
for _, path in pairs(files) do
    local theSplit = split(path, "[\\/]+")

    table.insert(g_modClasses, theSplit[table.getn(theSplit)])
end

-- Load all scripts
for i, path in pairs(files) do
    source(srcFolder .. path .. ".lua")

    local class = g_modClasses[i]

    if _G[class] ~= nil and _G[class].preLoad ~= nil then
        _G[class]:preLoad()
    end
end

------------------------------------------
-- base mission encapsulation functions
------------------------------------------

local function noopFunction() end

function ssSeasonsMod.loadMapFinished(...)
    local requiredMethods = { "deleteMap", "mouseEvent", "keyEvent", "draw", "update" }

    -- Before loading the savegame, allow classes to set their default values
    -- and let the settings system know that they need values
    for _, k in pairs(g_modClasses) do
        if _G[k] ~= nil and _G[k].loadMap ~= nil then
            -- Set any missing functions with dummies. This is because it makes code in classes cleaner
            for _, method in pairs(requiredMethods) do
                if _G[k][method] == nil then
                    _G[k][method] = noopFunction
                end
            end

            addModEventListener(_G[k])
        end
    end

    ssSeasonsMod:loadFromXML()

    -- Enable the mod
    g_seasons.enabled = true
end

function ssSeasonsMod.loadFromXML(...)
    if g_currentMission == nil or not g_currentMission:getIsServer() then return end

    local xmlFile = nil
    if g_currentMission.missionInfo.isValid then
        local filename = g_currentMission.missionInfo.savegameDirectory .. "/careerSavegame.xml"
        xmlFile = loadXMLFile("xml", filename)
    end
    -- Empty, is solved by ssXMLUtil. Useful for loading defaults

    for _, k in pairs(g_modClasses) do
        if _G[k] ~= nil and _G[k].loadMap ~= nil and _G[k].load ~= nil then
            _G[k].load(_G[k], xmlFile, "careerSavegame.ssSeasons")
        end
    end

    if xmlFile ~= nil then
        delete(xmlFile)
    end
end

function ssSeasonsMod.saveToXML(self)
    if g_seasons.enabled and self.isValid and self.xmlKey ~= nil then
        if self.xmlFile ~= nil then
            local ssKey = self.xmlKey .. ".ssSeasons"
            removeXMLProperty(self.xmlFile, ssKey)

            for _, k in pairs(g_modClasses) do
                if _G[k] ~= nil and _G[k].loadMap ~= nil and _G[k].save ~= nil then
                    _G[k].save(_G[k], self.xmlFile, ssKey)
                end
            end
        else
            g_currentMission.inGameMessage:showMessage("Seasons", ssLang.getText("SS_SAVE_FAILED"), 10000)
        end
    end
end

-- Add a new mod event: loadMapFinished.
function ssSeasonsMod.nullFinished(...)
    local isServer = g_currentMission:getIsServer()

    for _, k in pairs(g_modClasses) do
        if _G[k] ~= nil and _G[k].loadMapFinished ~= nil then
            _G[k]:loadMapFinished()
        end
    end

    if g_currentMission:getIsServer() then
        for _, k in pairs(g_modClasses) do
            if _G[k] ~= nil and _G[k].loadGameFinished ~= nil then
                _G[k]:loadGameFinished()
            end
        end
    end
end

FSBaseMission.loadMapFinished = Utils.prependedFunction(FSBaseMission.loadMapFinished, ssSeasonsMod.loadMapFinished)
FSCareerMissionInfo.saveToXML = Utils.appendedFunction(FSCareerMissionInfo.saveToXML, ssSeasonsMod.saveToXML)
Mission00.loadMission00Finished = Utils.prependedFunction(Mission00.loadMission00Finished, ssSeasonsMod.nullFinished)

------------------------------------------
-- Fixes for Giants Vanilla game
------------------------------------------

-- Giants engine does not copy this unit to the mod g_i18n version
g_i18n.moneyUnit = getfenv(0)["g_i18n"].moneyUnit

-- Make sure not both the contest and normal seasons mod is loaded
local path = g_modsDirectory .. "FS17Contest_Seasons.zip"
if fileExists(path) then
    -- Act as if the contest mod is already loaded
    g_modIsLoaded["FS17Contest_Seasons"] = true

    -- GameExtension overrides this function and tries to read from g_currentMission
    -- which does not exist at this point.
    local old = getfenv(0)["g_currentMission"]
    getfenv(0)["g_currentMission"] = {}

    g_gui:showInfoDialog({
        text = ssLang.getText("SS_REMOVE_CONTEST_TEXT"),
        dialogType = DialogElement.TYPE_INFO
    })

    getfenv(0)["g_currentMission"] = old
end
