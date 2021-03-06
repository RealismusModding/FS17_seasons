----------------------------------------------------------------------------------------------------
-- HELP LINES FOR HELP IN INGAMEMENU
----------------------------------------------------------------------------------------------------
-- Authors:  Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssHelpLines = {}

function ssHelpLines:preLoad()
    g_seasons.help = self
end

function ssHelpLines:loadMap()
    self:loadFromXML(g_seasons.modDir .. "resources/gui/helpLine.xml")
end

function ssHelpLines:deleteMap()
    local selector = g_inGameMenu.helpLineCategorySelectorElement

    for _, cat in ipairs(self.categories) do
        for index, category in ipairs(g_inGameMenu.helpLineCategories) do
            if category == cat then
                table.remove(g_inGameMenu.helpLineCategories, index)
                table.remove(selector.texts, index)

                selector:updateTextElement();
                break
            end
        end
    end

    selector:setState(selector.state, true)
end

function ssHelpLines:loadI18NIntoGlobal(key)
    g_i18n.globalI18N:setText(key, ssLang.getText(key))
end

function ssHelpLines:loadFromXML(path)
    local xmlFile = loadXMLFile("helpLine", path)

    self.categories = {}

    local categoryIndex = 0
    while true do
        local categoryKey = string.format("helpLines.helpLineCategory(%d)", categoryIndex)
        if not hasXMLProperty(xmlFile, categoryKey) then break end

        local category = {}
        category.title = getXMLString(xmlFile, categoryKey .. "#title")
        category.helpLines = {}

        self:loadI18NIntoGlobal(category.title)

        g_inGameMenu.helpLineCategorySelectorElement:addText(ssLang.getText(category.title))

        local lineIndex = 0
        while true do
            local lineKey = string.format("%s.helpLine(%d)", categoryKey, lineIndex)
            if not hasXMLProperty(xmlFile, lineKey) then break end

            local helpLine = {}
            helpLine.title = getXMLString(xmlFile, lineKey .. "#title")
            helpLine.items = {}

            self:loadI18NIntoGlobal(helpLine.title)

            local itemIndex = 0
            while true do
                local itemKey = string.format("%s.item(%d)", lineKey, itemIndex)
                if not hasXMLProperty(xmlFile, itemKey) then break end

                local type = getXMLString(xmlFile, itemKey .. "#type")
                local value = getXMLString(xmlFile, itemKey .. "#value")

                if type == "text" then
                    self:loadI18NIntoGlobal(value)
                end

                if type == "image" then
                    value = g_seasons.modDir .. value
                end

                if value ~= nil and (type == "text" or type == "image") then
                    local item = {
                        type = type,
                        value = value,
                        heightScale = Utils.getNoNil(getXMLFloat(xmlFile, itemKey .. "#heightScale"), 1)
                    }

                    table.insert(helpLine.items, item)
                end

                itemIndex = itemIndex + 1
            end

            table.insert(category.helpLines, helpLine)
            lineIndex = lineIndex + 1
        end

        table.insert(g_inGameMenu.helpLineCategories, category)
        table.insert(self.categories, category)
        categoryIndex = categoryIndex + 1
    end

    delete(xmlFile)
end
