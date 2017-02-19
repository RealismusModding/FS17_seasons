---------------------------------------------------------------------------------------------------------
-- SCRIPT TO ADD PHYSICAL SNOW LAYERS
---------------------------------------------------------------------------------------------------------
-- Purpose:  to create plowable snow on the ground
-- Authors:  mrbear
--

ssReplaceVisual = {}
g_seasons.replaceVisual = ssReplaceVisual

function ssReplaceVisual:preLoad()
    Placeable.finalizePlacement = Utils.appendedFunction(Placeable.finalizePlacement, ssReplaceVisual.placeableUpdatePlacableOnCreation)
end

function ssReplaceVisual:loadMap(name)
    if g_currentMission:getIsClient() then
        g_seasons.environment:addSeasonChangeListener(self)

        local modReplacements = loadI3DFile(g_seasons.modDir .. "resources/replacementTexturesMaterialHolder.i3d") -- Loading materialHolder

        self:loadFromXML()

        self:loadTextureIdTable(getRootNode()) -- Built into map
        self:loadTextureIdTable(modReplacements)

        -- Only if this game does not need to wait for other modules to receive data,
        -- update the textures. (singleplayer)
        if g_currentMission:getIsServer() then
            self:updateTextures(getRootNode())
        end
    end
end

function ssReplaceVisual:readStream(streamId, connection)
    -- Load after data for seaonUtils is loaded
    self:updateTextures(getRootNode())
end

function ssReplaceVisual:loadFromXML()
    self.textureReplacements = {}
    self.textureReplacements.default = {}

    self:loadTextureReplacementsFromXMLFile(g_seasons.modDir .. "data/textures.xml")
end

function ssReplaceVisual:loadTextureReplacementsFromXMLFile(path)
    local file = loadXMLFile("xml", path)
    if file == nil then
        logInfo("Failed to load texture replacements configuration form " .. path)
        return
    end

    local seasonKeyToId = {
        ["spring"] = 0,
        ["summer"] = 1,
        ["autumn"] = 2,
        ["winter"] = 3
    }

    for seasonName, seasonId in pairs(seasonKeyToId) do
        -- Create the season if it does not exist
        if self.textureReplacements[seasonId] == nil then
            self.textureReplacements[seasonId] = {}
        end

        local seasonKey = "textures.seasons." .. seasonName
        if hasXMLProperty(file, seasonKey) then
            local season = self.textureReplacements[seasonId]

            -- Read each texture replacement
            local i = 0
            while true do
                local textureKey = string.format("%s.texture(%i)", seasonKey, i)
                if not hasXMLProperty(file, textureKey) then break end

                local shapeName = getXMLString(file, textureKey .. "#shapeName")
                local secondaryNodeName = getXMLString(file, textureKey .. "#secondaryNodeName")
                local toTexture = getXMLString(file, textureKey .. "#to")

                if shapeName == nil or secondaryNodeName == nil or toTexture == nil then
                    logInfo("Failed to load texture replacements configuration from " .. path .. ": invalid format")
                    return
                end

                if season[shapeName] == nil then
                    season[shapeName] = {}
                end

                season[shapeName][secondaryNodeName] = {
                    ["replacementName"] = toTexture
                }

                i = i + 1
            end

        end
    end

    delete(file)
end

function ssReplaceVisual:seasonChanged()
    if g_currentMission:getIsClient() then
        self:updateTextures(getRootNode())
    end
end

function ssReplaceVisual.placeableUpdatePlacableOnCreation(self)
    if g_currentMission:getIsClient() then
        ssReplaceVisual:updateTextures(self.nodeId)
    end
end

-- Stefan Geiger - GIANTS Software (https://gdn.giants-software.com/thread.php?categoryId=16&threadId=664)
function findNodeByName(nodeId, name)
    if getName(nodeId) == name then
        return nodeId
    end
    for i=0, getNumOfChildren(nodeId)-1 do
        local tmp = findNodeByName(getChildAt(nodeId, i), name)
        if tmp ~= nil then
            return tmp
        end
    end
    return nil
end

--
-- Texture replacement
--

-- Finds the Id for the replacement materials and adds it to self.textureReplacements.
-- Searchbase is the root node of a loaded I3D file.
function ssReplaceVisual:loadTextureIdTable(searchBase)
    for seasonId, seasonTable in pairs(self.textureReplacements) do
        for shapeName, shapeNameTable in pairs(seasonTable) do
            for secondaryNodeName, secondaryNodeTable in pairs(shapeNameTable) do
                local materialSrcId = findNodeByName(searchBase, secondaryNodeTable.replacementName)

                if materialSrcId ~= nil then -- Can be defined in an other I3D file.
                    -- print("Loading mapping for texture replacement: Shapename: " .. shapeName .. " secondaryNodeName: " .. secondaryNodeName .. " searchBase: " .. searchBase .. " season: " .. seasonName .. " Value: " .. secondaryNodeTable["replacementName"] .. " materialID: " .. materialSrcId )
                    self.textureReplacements[seasonId][shapeName][secondaryNodeName].materialId = getMaterial(materialSrcId, 0)
                    if self.textureReplacements.default[shapeName] == nil then
                        self.textureReplacements.default[shapeName] = {}
                    end

                    if self.textureReplacements.default[shapeName][secondaryNodeName] == nil then
                        self.textureReplacements.default[shapeName][secondaryNodeName] = {}
                    end

                    self.textureReplacements.default[shapeName][secondaryNodeName].materialId = ssReplaceVisual:findOriginalMaterial(getRootNode(), shapeName, secondaryNodeName)
                end
            end
        end
    end
end

-- Finds the material of the original Shape object
function ssReplaceVisual:findOriginalMaterial(searchBase, shapeName, secondaryNodeName)
    -- print("Searching for object: " .. shapeName .. "/" .. secondaryNodeName .. " under " .. searchBase )
    local parentShapeId = findNodeByName(searchBase, shapeName)
    local childShapeId
    local materialId

    -- print("DEBUG: " .. parentShapeId )
    if parentShapeId ~= nil then
        childShapeId = (findNodeByName(parentShapeId, secondaryNodeName))
        if childShapeId ~= nil then
            materialId = getMaterial(childShapeId, 0)
            -- print("Found materialID: " .. materialId .. " for childobject " ..  childShapeId .. ".")
        end
    end

    return materialId
end

-- Walks the node tree and replaces materials according to season as specified in self.textureReplacements
function ssReplaceVisual:updateTextures(nodeId)
    local currentSeason = g_seasons.environment:currentSeason()

    if self.textureReplacements[currentSeason][getName(nodeId)] ~= nil then
        for secondaryNodeName, secondaryNodeTable in pairs(self.textureReplacements[currentSeason][getName(nodeId)]) do
            -- print("Asking for texture change: " .. getName(nodeId) .. " (" .. nodeId .. ")/" .. secondaryNodeName .. " to " .. secondaryNodeTable["materialId"] .. ".")
            self:updateTexturesSubNode(nodeId, secondaryNodeName, secondaryNodeTable.materialId)
        end
    elseif self.textureReplacements.default[getName(nodeId)] ~= nil then
        for secondaryNodeName, secondaryNodeTable in pairs(self.textureReplacements.default[getName(nodeId)]) do
            -- print("Asking for texture change: " .. getName(nodeId) .. " (" .. nodeId .. ")/" .. secondaryNodeName .. " to " .. secondaryNodeTable["materialId"] .. ".")
            self:updateTexturesSubNode(nodeId, secondaryNodeName, secondaryNodeTable.materialId)
        end
    end

    for i = 0, getNumOfChildren(nodeId) - 1 do
        local tmp = self:updateTextures(getChildAt(nodeId, i), name)

        if tmp ~= nil then
            return tmp
        end
    end

    return nil
end

-- Does a specified replacement on subnodes of nodeId.
function ssReplaceVisual:updateTexturesSubNode(nodeId, shapeName, materialSrcId)
    if getName(nodeId) == shapeName then
        -- print("Setting texture for " .. getName(nodeId) .. " (" .. nodeId .. ") to " .. materialSrcId .. ".")
        setMaterial(nodeId, materialSrcId, 0)
    end

    for i = 0, getNumOfChildren(nodeId) - 1 do
        local tmp = self:updateTexturesSubNode(getChildAt(nodeId, i), shapeName, materialSrcId)

        if tmp ~= nil then
            return tmp
        end
    end

    return nil
end
