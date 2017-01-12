---------------------------------------------------------------------------------------------------------
-- SEASONS XML SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  For loading season parameters from mod, map or game
-- Authors:  Rahkiin (Jarvixes),
--

ssSeasonsXML = {}

local seasonKeyToId = {
    ["spring"] = 0,
    ["summer"] = 1,
    ["autumn"] = 2,
    ["winter"] = 3
}

-- Returns raw data
function ssSeasonsXML:loadFile(path, rootKey, elements, parentData, optional)

    local file = loadXMLFile("xml", path)

    if file == nil then
        if optional == true then
            return parentData
        else
            logInfo("ssSeasonsXML: Failed to load XML Seasons file " .. path)
            return nil
        end
    end

    local data = parentData ~= nil and Utils.copyTable(parentData) or {}

    -- For each season
    for seasonName, seasonId in pairs(seasonKeyToId) do
        -- Create the season if it does not exist
        if data[seasonId] == nil then
            data[seasonId] = { ["properties"] = {} }
        end

        local seasonKey = rootKey .. ".seasons." .. seasonName
        if hasXMLProperty(file, seasonKey) then
            -- Read all season items
            if elements.seasons ~= nil then
                for _, key in pairs(elements.seasons) do
                    local xmlKey = seasonKey .. "." .. key
                    local val = getXMLString(file, xmlKey)
                    if val ~= nil then
                        data[seasonId][key] = val
                    end
                end
            end

            -- Read every properties set
            if elements.properties ~= nil then
                local i = 0
                while true do
                    local propsKey = string.format("%s.properties(%i)", seasonKey, i)
                    if not hasXMLProperty(file, propsKey) then break end

                    -- Read the type
                    local objType = getXMLString(file, propsKey .. "#type")
                    if objType == nil then
                        logInfo("Invalid XML file (1)")
                        delete(file)
                        return
                    end

                    -- If type does not yet exist, create it
                    if data[seasonId].properties[objType] == nil then
                        data[seasonId].properties[objType] = { ["_self"] = objType }
                    end

                    -- Read all properties
                    for _, key in pairs(elements.properties) do
                        local xmlKey = propsKey .. "." .. key
                        local val = getXMLString(file, xmlKey)
                        if val ~= nil then
                            data[seasonId].properties[objType][key] = val
                        end
                    end

                    i = i + 1
                end
            end
        end
    end

    delete(file)

    return data
end

-- Keys:
--  cow.birthRate -> returns the birthRate property of the cow properties type
--  cow -> returns the cow value from the season
function ssSeasonsXML:getString(data, seasonId, key, default)
    if data[seasonId] == nil then return default end

    local first, second = key:match("([^.]+).([^.]+)")

    if second ~= nil then
        if data[seasonId].properties[first] ~= nil and data[seasonId].properties[first][second] ~= nil then
            return data[seasonId].properties[first][second]
        end
    elseif data[seasonId][first] ~= nil then
        return data[seasonId][second]
    end

    return default
end

function ssSeasonsXML:getFloat(data, seasonId, key, default)
    local value = ssSeasonsXML:getString(data, seasonId, key, default)

    if value ~= nil then
        value = tonumber(value)
    end

    return value
end

function ssSeasonsXML:getBool(data, seasonId, key, default)
    local value = ssSeasonsXML:getString(data, seasonId, key, default)

    if value ~= nil then
        value = Utils.stringToBoolean(value)
    end

    return value
end

function ssSeasonsXML:getInt(data, seasonId, key, default)
    local value = ssSeasonsXML:getString(data, seasonId, key, default)

    if value ~= nil then
        value = math.floor(tonumber(value))
    end

    return value
end

-- Get types of the properties available for given season
function ssSeasonsXML:getTypes(data, seasonId)
    if data[seasonId] == nil then return nil end

    local types = {}
    for typ, _ in pairs(data[seasonId].properties) do
        table.insert(types, typ)
    end

    return types
end
