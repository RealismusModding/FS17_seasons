
ssStorage = {}

function ssStorage.getXMLFloat(xmlFile, key, defaultValue)
    if xmlFile ~= nil then
        return Utils.getNoNil(getXMLFloat(xmlFile, key), defaultValue)
    end

    return defaultValue
end

function ssStorage.getXMLString(xmlFile, key, defaultValue)
    if xmlFile ~= nil then
        return Utils.getNoNil(getXMLString(xmlFile, key), defaultValue)
    end

    return defaultValue
end

function ssStorage.getXMLBool(xmlFile, key, defaultValue)
    if xmlFile ~= nil then
        return Utils.getNoNil(getXMLBool(xmlFile, key), defaultValue)
    end

    return defaultValue
end

function ssStorage.getXMLInt(xmlFile, key, defaultValue)
    if xmlFile ~= nil then
        return Utils.getNoNil(getXMLInt(xmlFile, key), defaultValue)
    end

    return defaultValue
end

function ssStorage.setXMLFloat(xmlFile, key, value)
    setXMLFloat(xmlFile, key, value)
end

function ssStorage.setXMLString(xmlFile, key, value)
    setXMLString(xmlFile, key, value)
end

function ssStorage.setXMLBool(xmlFile, key, value)
    setXMLBool(xmlFile, key, value)
end

function ssStorage.setXMLInt(xmlFile, key, value)
    setXMLInt(xmlFile, key, value)
end
