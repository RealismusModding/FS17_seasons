-- https://github.com/DeckerMMIV/FarmSim_Mod_SoilMod/blob/master/SoilManagement/soilMod/fmcSoilMod.lua

ssSeasonsMod = {}

-- Put it in the global scope so it can be recognized by other mods
getfenv(0)["modSeasonsMod"] = ssSeasonsMod

local modItem = ModsUtil.findModItemByModName(g_currentModName)
ssSeasonsMod.version = Utils.getNoNil(modItem.version ,"?.?.?.?")
ssSeasonsMod.modDir = g_currentModDirectory
ssSeasonsMod.verbose = true

function log(...)
    if not ssSeasonsMod.verbose then return end

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
local srcFiles = {
    "ssSettings.lua",
    "ssSeasonsUtil.lua",
    "ssTime.lua",
    "ssWeatherForecast.lua",
    "ssFixFruit.lua"
}

if modItem.isDirectory then
    for i = 1, #srcFiles do
        local srcFile = srcFolder .. srcFiles[i]
        local fileHash = tostring(getFileMD5(srcFile, ssSeasonsMod.modDir))

        logInfo(string.format("Loading script: %s (v%s - %s)", srcFiles[i], ssSeasonsMod.version, fileHash))

        source(srcFile)
    end
else
    for i = 1, #srcFiles do


        source(srcFolder..srcFiles[i])
    end

    ssSeasonsMod.version = ssSeasonsMod.version .. " - " .. modItem.fileHash
end

function ssSeasonsMod.loadMap(...)
    log("Loading mod...")
end

function ssSeasonsMod:deleteMap()
end

function ssSeasonsMod:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssSeasonsMod:keyEvent(unicode, sym, modifier, isDown)
end

function ssSeasonsMod:update(dt)
end

function ssSeasonsMod:draw()
end

addModEventListener(ssSeasonsMod)
