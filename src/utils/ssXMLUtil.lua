----------------------------------------------------------------------------------------------------
-- XMLUTIL SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  For easy storage of savegame stuff and xml related utilities
-- Authors:  Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssXMLUtil = {}

function ssXMLUtil.hasProperty(xmlFile, key)
    if xmlFile ~= nil then
        return hasXMLProperty(xmlFile, key)
    end

    return false
end

function ssXMLUtil.getFloat(xmlFile, key, defaultValue)
    if xmlFile ~= nil then
        return Utils.getNoNil(getXMLFloat(xmlFile, key), defaultValue)
    end

    return defaultValue
end

function ssXMLUtil.getString(xmlFile, key, defaultValue)
    if xmlFile ~= nil then
        return Utils.getNoNil(getXMLString(xmlFile, key), defaultValue)
    end

    return defaultValue
end

function ssXMLUtil.getBool(xmlFile, key, defaultValue)
    if xmlFile ~= nil then
        return Utils.getNoNil(getXMLBool(xmlFile, key), defaultValue)
    end

    return defaultValue
end

function ssXMLUtil.getInt(xmlFile, key, defaultValue)
    if xmlFile ~= nil then
        return Utils.getNoNil(getXMLInt(xmlFile, key), defaultValue)
    end

    return defaultValue
end

function ssXMLUtil.setFloat(xmlFile, key, value)
    setXMLFloat(xmlFile, key, value)
end

function ssXMLUtil.setString(xmlFile, key, value)
    setXMLString(xmlFile, key, value)
end

function ssXMLUtil.setBool(xmlFile, key, value)
    setXMLBool(xmlFile, key, value)
end

function ssXMLUtil.setInt(xmlFile, key, value)
    setXMLInt(xmlFile, key, value)
end
