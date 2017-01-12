---------------------------------------------------------------------------------------------------------
-- LOADER SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  Loads the mod
-- Authors:  Rahkiin (Jarvixes)

ssSeasonsMod = {}

ssSeasonsMod.seasonListeners = {}
ssSeasonsMod.growthStageListeners = {}

function log(...)
    if not g_seasons.verbose then return end

    local str = "[Seasons] "
    for i = 1, select("#", ...) do
        str = str .. tostring(select(i, ...))
    end
    print(str)
end

function logInfo(...)
    local str = "[Seasons] "
    for i = 1, select("#", ...) do
        str = str .. tostring(select(i, ...))
    end
    print(str)
end

local srcFolder = g_currentModDirectory .. "src/"
g_modClasses = {
    "ssMain",
    "ssLang",
    "ssStorage",
    "ssSeasonsXML",
    "ssMultiplayer",
    "ssSeasonsUtil",
    "ssTime",
    "ssEconomy",
    "ssWeatherManager",
    "ssWeatherForecast",
    "ssVehicle",
    "ssGrowthManagerData",
    "ssGrowthManager",
    "ssSnow",
    "ssSeasonIntro",
    "ssReplaceVisual",
    "ssAnimals",
    "ssDensityMapScanner",
    "ssViewController",
    "ssPedestrianSystem"
}

if g_seasons.debug then
    table.insert(g_modClasses, "ssDebug")
end

logInfo("Loading Seasons...")

-- Load all scripts
for _, class in pairs(g_modClasses) do
    source(srcFolder .. class .. ".lua")

    if _G[class].preLoad ~= nil then
        _G[class]:preLoad()
    end
end

-- The menu is not a proper class.
source(srcFolder .. "ssSeasonsMenu.lua")


------------------------------------------
-- base mission encapsulation functions
------------------------------------------

function ssSeasonsMod.loadMap(...)
    return ssSeasonsMod.origLoadMap(...)
end

function noopFunction() end

function ssSeasonsMod.loadMapFinished(...)
    local requiredMethods = { "deleteMap", "mouseEvent", "keyEvent", "draw", "update" }

    -- Before loading the savegame, allow classes to set their default values
    -- and let the settings system know that they need values
    for _, k in pairs(g_modClasses) do
        if _G[k].loadMap ~= nil then
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

    return ssSeasonsMod.origLoadMapFinished(...)
end

function ssSeasonsMod.delete(...)
    return ssSeasonsMod.origDelete(...)
end

function ssSeasonsMod:loadFromXML(...)
    if g_currentMission == nil or not g_currentMission:getIsServer() then return end

    local xmlFile = nil
    if g_currentMission.missionInfo.isValid then
        local filename = g_currentMission.missionInfo.savegameDirectory .. "/careerSavegame.xml"
        xmlFile = loadXMLFile("xml", filename)
    end
    -- Empty, is solved by ssStorage. Useful for loading defaults

    for _, k in pairs(g_modClasses) do
        if _G[k].load ~= nil then
            _G[k].load(_G[k], xmlFile, "careerSavegame.ssSeasons")
        end
    end

    if xmlFile ~= nil then
        delete(xmlFile)
    end
end

local function ssSeasonsModSaveToXML(self)
    if ssSeasonsMod.enabled and self.isValid and self.xmlKey ~= nil then
        if self.xmlFile ~= nil then
            for _, k in pairs(g_modClasses) do
                if _G[k].save ~= nil then
                    _G[k].save(_G[k], self.xmlFile, self.xmlKey .. ".ssSeasons")
                end
            end
        else
            g_currentMission.inGameMessage:showMessage("Seasons", ssLang.getText("SS_SAVE_FAILED"), 10000)
        end
    end
end

-- Listeners for a change of season
function ssSeasonsMod:addSeasonChangeListener(target)
    if target ~= nil then
        table.insert(ssSeasonsMod.seasonListeners, target)
    end
end

function ssSeasonsMod:removeSeasonChangeListener(target)
    if target ~= nil then
        for i = 1, #ssSeasonsMod.seasonListeners do
            if ssSeasonsMod.seasonListeners[i] == target then
                table.remove(ssSeasonsMod.seasonListeners, i)
                break
            end
        end
    end
end

-- Listeners for a change of growth stage
function ssSeasonsMod:addGrowthStageChangeListener(target)
    if target ~= nil then
        table.insert(ssSeasonsMod.growthStageListeners, target)
    end
end

function ssSeasonsMod:removeGrowthStageChangeListener(target)
    if target ~= nil then
        for i = 1, #ssSeasonsMod.growthStageListeners do
            if ssSeasonsMod.growthStageListeners[i] == target then
                table.remove(ssSeasonsMod.growthStageListeners, i)
                break
            end
        end
    end
end

ssSeasonsMod.origLoadMap = FSBaseMission.loadMap
ssSeasonsMod.origLoadMapFinished = FSBaseMission.loadMapFinished
ssSeasonsMod.origDelete = FSBaseMission.delete

FSBaseMission.loadMap = ssSeasonsMod.loadMap
FSBaseMission.loadMapFinished = ssSeasonsMod.loadMapFinished
FSBaseMission.delete = ssSeasonsMod.delete

FSCareerMissionInfo.saveToXML = Utils.appendedFunction(FSCareerMissionInfo.saveToXML, ssSeasonsModSaveToXML)
