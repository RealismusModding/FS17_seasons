----------------------------------------------------------------------------------------------------
-- XMLUTIL SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  For easy storage of savegame stuff and xml related utilities
-- Authors:  Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssXMLUtil = {}

function ssXMLUtil.hasXMLProperty(xmlFile, key)
    if xmlFile ~= nil then
        return hasXMLProperty(xmlFile, key)
    end

    return false
end

function ssXMLUtil.getXMLFloat(xmlFile, key, defaultValue)
    if xmlFile ~= nil then
        return Utils.getNoNil(getXMLFloat(xmlFile, key), defaultValue)
    end

    return defaultValue
end

function ssXMLUtil.getXMLString(xmlFile, key, defaultValue)
    if xmlFile ~= nil then
        return Utils.getNoNil(getXMLString(xmlFile, key), defaultValue)
    end

    return defaultValue
end

function ssXMLUtil.getXMLBool(xmlFile, key, defaultValue)
    if xmlFile ~= nil then
        return Utils.getNoNil(getXMLBool(xmlFile, key), defaultValue)
    end

    return defaultValue
end

function ssXMLUtil.getXMLInt(xmlFile, key, defaultValue)
    if xmlFile ~= nil then
        return Utils.getNoNil(getXMLInt(xmlFile, key), defaultValue)
    end

    return defaultValue
end

function ssXMLUtil.setXMLFloat(xmlFile, key, value)
    setXMLFloat(xmlFile, key, value)
end

function ssXMLUtil.setXMLString(xmlFile, key, value)
    setXMLString(xmlFile, key, value)
end

function ssXMLUtil.setXMLBool(xmlFile, key, value)
    setXMLBool(xmlFile, key, value)
end

function ssXMLUtil.setXMLInt(xmlFile, key, value)
    setXMLInt(xmlFile, key, value)
end
