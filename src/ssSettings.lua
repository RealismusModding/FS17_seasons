-- Inspired by https://github.com/DeckerMMIV/FarmSim_Mod_SoilMod/blob/master/SoilManagement/soilMod/fmcSettings.lua

ssSettings = {}
ssSettings.keys = {}

function ssSettings.add(key, class)
    if class.settingsProperties ~= nil then
        for k, v in pairs(class.settingsProperties) do
            ssSettings.set(key, v, class[v])
        end
    end
end

function ssSettings.load(key, class)
    if class.settingsProperties ~= nil then
        for k, v in pairs(class.settingsProperties) do
            class[v] = ssSettings.get(key, v, class[v])
        end
    end
end

function ssSettings.set(key, attr, value)
    if not ssSettings.keys[key] then
        ssSettings.keys[key] = {}
    end
    ssSettings.keys[key][attr] = value
end

function ssSettings.get(key, attr, defaulValue)
    if not ssSettings.keys[key] then
        return defaultValue
    end
    return Utils.getNoNil(ssSettings.keys[key][attr], defaultValue)
end

function ssSettings.onLoadCareerSavegame(xmlFile, rootXmlKey)
    for key, attrs in pairs(ssSettings.keys) do
        local xmlKey = rootXmlKey .. "." .. key

        for attr, value in pairs(attrs) do
            local xmlKeyAttr = xmlKey .. "#" .. attr

            if type(value) == "boolean" then
                value = Utils.getNoNil(getXMLBool(xmlFile, xmlKeyAttr), value)
            elseif type(value) == "number" then
                value = Utils.getNoNil(getXMLFloat(xmlFile, xmlKeyAttr), value)
            else
                value = Utils.getNoNil(getXMLString(xmlFile, xmlKeyAttr), value)
            end

            ssSettings.set(key, attr, value)
        end
    end
end

function ssSettings.onSaveCareerSavegame(xmlFile, rootXmlKey)
    for key, attrs in pairs(ssSettings.keys) do
        local xmlKey = rootXmlKey .. "." .. key

        for attr, value in pairs(attrs) do
            local xmlKeyAttr = xmlKey .. "#" .. attr

            if type(value) == "boolean" then
                setXMLBool(xmlFile, xmlKeyAttr, value)
            elseif type(value) == "number" then
                if math.floor(value) == math.ceil(value) then
                    setXMLInt(xmlFile, xmlKeyAttr, value)
                else
                    setXMLFloat(xmlFile, xmlKeyAttr, value)
                end
            else
                setXMLString(xmlFile, xmlKeyAttr, value)
            end
        end
    end
end

function ssSettings.loadFromSavegame()
    if g_currentMission == nil or not g_currentMission:getIsServer() then return end
    if not g_currentMission.missionInfo.isValid then return end

    local filename = g_currentMission.missionInfo.savegameDirectory .. "/careerSavegame.xml"
    local xmlFile = loadXMLFile("xml", filename)

    if xmlFile then
        ssSettings.onLoadCareerSavegame(xmlFile, "careerSavegame.modsSettings.ssSeasonsMod")
        delete(xmlFile)
    end
end

-- Injection to save at the right moment
local function saveInjectedFunction(self)
    if ssSeasonsMod.enabled and self.isValid and self.xmlKey ~= nil then
        if self.xmlFile ~= nil then
            ssSettings.onSaveCareerSavegame(self.xmlFile, self.xmlKey .. ".modsSettings.ssSeasonsMod")
        else
            g_currentMission.inGameMessage:showMessage("SeasonsMod", g_i18n:getText("SaveFailed"), 10000);
        end
    end
end

FSCareerMissionInfo.saveToXML = Utils.prependedFunction(FSCareerMissionInfo.saveToXML, saveInjectedFunction);
