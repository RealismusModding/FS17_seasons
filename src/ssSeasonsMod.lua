-- https://github.com/DeckerMMIV/FarmSim_Mod_SoilMod/blob/master/SoilManagement/soilMod/fmcSoilMod.lua

ssSeasonsMod = {}

-- Put it in the global scope so it can be recognized by other mods
getfenv(0)["modSeasonsMod"] = ssSeasonsMod

local modItem = ModsUtil.findModItemByModName(g_currentModName)
ssSeasonsMod.version = Utils.getNoNil(modItem.version, "?.?.?.?")
ssSeasonsMod.modDir = g_currentModDirectory
ssSeasonsMod.verbose = true

ssSeasonsMod.seasonListeners = {}
ssSeasonsMod.growthStageListeners = {}

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
    "ssLang.lua",
    "ssSettings.lua",
    "ssSeasonsUtil.lua",
    "ssTime.lua",
    "ssWeatherForecast.lua",
    "ssFixFruit.lua",
    "ssEconomy.lua",
    "ssVehicle.lua",
    "ssGrowthManager.lua",
    "ssSnow.lua",
    "ssBank.lua",
    "ssSeasonIntro.lua",
    "ssReplaceVisual.lua"
}

-- Load all scripts
if modItem.isDirectory then
    for i = 1, #srcFiles do
        local srcFile = srcFolder .. srcFiles[i]
        local fileHash = tostring(getFileMD5(srcFile, ssSeasonsMod.modDir))

        logInfo(string.format("Loading script: %s (v%s - %s)", srcFiles[i], ssSeasonsMod.version, fileHash))

        source(srcFile)
    end
else
    for i = 1, #srcFiles do

        logInfo(string.format("Loading script: %s (v%s)", srcFiles[i], ssSeasonsMod.version))

        source(srcFolder..srcFiles[i])
    end

    ssSeasonsMod.version = ssSeasonsMod.version .. " - " .. modItem.fileHash
end

function ssSeasonsMod.loadMap(...)
    log("ssSeasonsMod.loadMap()")

    return ssSeasonsMod.origLoadMap(...)
end

function ssSeasonsMod.loadMapFinished(...)
    log("ssSeasonsMod.loadMapFinished()")

    -- Before loading the savegame, allow classes to set their default values
    -- and let the settings system know that they need values
    ssSeasonsUtil.preSetup()
    ssTime.preSetup()
    ssEconomy.preSetup()
    ssWeatherForecast.preSetup()
    ssFixFruit.preSetup()
    ssVehicle.preSetup()
    ssGrowthManager.preSetup()
    ssSnow.preSetup()
    ssBank.preSetup()
    ssSeasonIntro.preSetup()
    ssReplaceVisual.preSetup()

    -- Load all requested values
    ssSettings.loadFromSavegame()

    -- Now read those values and set up the classes
    ssSeasonsUtil.setup()
    ssTime.setup()
    ssEconomy.setup()
    ssWeatherForecast.setup()
    ssFixFruit.setup()
    ssVehicle.setup()
    ssGrowthManager.setup()
    ssSnow.setup()
    ssBank.setup()
    ssSeasonIntro.setup()
    ssReplaceVisual.setup()

    ssSeasonsMod.latestSeason = ssSeasonsUtil:season()

    ssSeasonsMod.enabled = true

    return ssSeasonsMod.origLoadMapFinished(...)
end

function ssSeasonsMod.delete(...)
    log("ssSeasonsMod.delete()")

    return ssSeasonsMod.origDelete(...)
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

function mathRound(value, idp)
    local mult = 10^(idp or 0)
    return math.floor(value * mult + 0.5) / mult
end

------------- Useful global functions ---------------

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

-- returns: isArray, size (if size is 0 can also be object)
local function isArray(table)
    local max = 0
    local count = 0

    for k, v in pairs(table) do
        if type(k) == "number" then
            if k > max then max = k end
            count = count + 1
        else
            return false, nil
        end
    end

    if max > count * 2 then
        return false, nil
    end

    return true, max
end

function jsonEncode(t, indent, cache)
    if indent == nil then indent = ""; end
    local newIndent = indent .. "  ";

    if cache == nil then cache = {}; end


    if (type(t) == "table") then
        -- Assume everything is an object (will change later, see if it is an arrya)

        for _, value in pairs(cache) do
            if value == t then
                return "\"[Cyclic]\"";
            end
        end
        table.insert(cache, 1, t);

        if isArray(t) then
            local str = "[";
            local first = true;

            for pos, val in pairs(t) do
                if not first then
                    str = str .. ",";
                end
                first = false;

                str = str .. "\n" .. newIndent .. jsonEncode(val, newIndent, cache);
            end

            return str .. "\n" .. indent .. "]";
        else
            local str = "{";
            local first = true;

            for pos, val in pairs(t) do
                if not first then
                    str = str .. ",";
                end
                first = false;

                str = str .. "\n" .. newIndent .. jsonEncode(pos, newIndent, cache) .. ": " .. jsonEncode(val, newIndent, cache);
            end

            return str .. "\n" .. indent .. "}";
        end
    elseif type(t) == "string" then
        return "\"" .. t .. "\"";
    elseif type(t) == "function" then
        return "\"Function(){}\"";
    else
        return tostring(t);
    end

    return nil;
end

function tprint(tbl, indent)
    if not indent then indent = 0 end
    for k, v in pairs(tbl) do
        if k ~= nil then
            formatting = string.rep("  ", indent) .. tostring(k) .. ": "
        end;
        if type(v) == "table" then
            print(formatting)
            tprint(v, indent+1)
        elseif type(v) == 'boolean' then
            print(formatting .. tostring(v))
        else
            print(formatting .. tostring(v))
        end
    end
end

function exportstring(s)
    s = string.format( "%q",s )
    -- to replace
    s = string.gsub( s,"\\\n","\\n" )
    s = string.gsub( s,"\r","\\r" )
    s = string.gsub( s,string.char(26),"\"..string.char(26)..\"" )
    return s
end

function table_save(tbl, filename)
    local charS,charE = "   ","\n"
    local file,err

    -- create a pseudo file that writes to a string and return the string
    if not filename then
        file =  { write = function( self,newstr ) self.str = self.str..newstr end, str = "" }
        charS,charE = "",""
    -- write table to tmpfile
    elseif filename == true or filename == 1 then
        charS,charE,file = "","",io.tmpfile()
    -- write table to file
    -- use io.open here rather than io.output, since in windows when clicking on a file opened with io.output will create an error
    else
        file,err = io.open( filename, "w" )
        if err then return _,err end
    end

    -- initiate variables for save procedure
    local tables,lookup = { tbl },{ [tbl] = 1 }
    file:write( "return {"..charE )
    for idx,t in ipairs( tables ) do
        if filename and filename ~= true and filename ~= 1 then
            file:write( "-- Table: {"..idx.."}"..charE .. tostring(tables) )
        end
        file:write( "{"..charE )
        local thandled = {}
        for i,v in ipairs( t ) do
            thandled[i] = true
            -- escape functions and userdata
            if type( v ) ~= "userdata" then
                -- only handle value
                if type( v ) == "table" then
                    if not lookup[v] then
                        table.insert( tables, v )
                        lookup[v] = #tables
                    end
                    file:write( charS.."{"..lookup[v].."},"..charE )
                elseif type( v ) == "function" then
                    file:write( charS.."loadstring("..exportstring(string.dump( v )).."),"..charE )
                else
                    local value =  ( type( v ) == "string" and exportstring( v ) ) or tostring( v )
                    file:write(  charS..value..","..charE )
                end
            end
        end
        for i,v in pairs( t ) do
            -- escape functions and userdata
            if (not thandled[i]) and type( v ) ~= "userdata" then
                -- handle index
                if type( i ) == "table" then
                    if not lookup[i] then
                        table.insert( tables,i )
                        lookup[i] = #tables
                    end
                    file:write( charS.."[{"..lookup[i].."}]=" )
                else
                    local index = ( type( i ) == "string" and "["..exportstring( i ).."]" ) or string.format( "[%d]",i )
                    file:write( charS..index.."=" )
                end
                -- handle value
                if type( v ) == "table" then
                    if not lookup[v] then
                        table.insert( tables,v )
                        lookup[v] = #tables
                    end
                    file:write( "{"..lookup[v].."},"..charE )
                elseif type( v ) == "function" then
                    file:write( "loadstring("..exportstring(string.dump( v )).."),"..charE )
                else
                    local value =  ( type( v ) == "string" and exportstring( v ) ) or tostring( v )
                    file:write( value..","..charE )
                end
            end
        end
        file:write( "},"..charE )
    end
    file:write( "}" )

    -- Return Values
    -- return stringtable from string
    if not filename then
        -- set marker for stringtable
        return file.str.."--|"
    -- return stringttable from file
    elseif filename == true or filename == 1 then
        file:seek ( "set" )
        -- no need to close file, it gets closed and removed automatically
        -- set marker for stringtable
        return file:read( "*a" ).."--|"
    -- close file and return 1
    else
        file:close()
        return 1
    end
end

