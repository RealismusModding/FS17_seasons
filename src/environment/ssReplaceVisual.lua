----------------------------------------------------------------------------------------------------
-- SCRIPT TO ADD PHYSICAL SNOW LAYERS
----------------------------------------------------------------------------------------------------
-- Purpose:  to create plowable snow on the ground
-- Authors:  mrbear
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssReplaceVisual = {}
g_seasons.replaceVisual = ssReplaceVisual

function ssReplaceVisual:preLoad()
    Placeable.finalizePlacement = Utils.appendedFunction(Placeable.finalizePlacement, ssReplaceVisual.placeableUpdatePlacableOnCreation)
end

function ssReplaceVisual:loadMap(name)
    if g_currentMission:getIsClient() then
        g_seasons.environment:addSeasonChangeListener(self)

        self:loadFromXML()

        self:loadTextureIdTable(getRootNode()) -- Built into map
        for _, replacements in ipairs(self.modReplacements) do
            self:loadTextureIdTable(replacements)
        end

        -- Only if this game does not need to wait for other modules to receive data,
        -- update the textures. (singleplayer)
        if g_currentMission:getIsServer() then
            self:updateTextures()
        end

        addConsoleCommand("ssSetVisuals", "Set visuals", "consoleCommandSetVisuals", self)
    end
end

function ssReplaceVisual:readStream(streamId, connection)
    -- Load after environment is loaded
    self:updateTextures()
end

function ssReplaceVisual:loadFromXML()
    self.textureReplacements = {}
    self.textureReplacements.default = {}
    self.modReplacements = {}

    -- Default
    self:loadTextureReplacementsFromXMLFile(g_seasons.modDir .. "data/textures.xml")

    -- Modded
    for _, path in ipairs(g_seasons:getModPaths("textures")) do
        self:loadTextureReplacementsFromXMLFile(path)
    end
end

function ssReplaceVisual:loadTextureReplacementsFromXMLFile(path)
    local file = loadXMLFile("xml", path)
    if file == nil then
        logInfo("ssReplaceVisual:", "Failed to load texture replacements configuration from " .. path)
        return
    end

    local seasonKeyToId = {
        ["spring"] = 0,
        ["summer"] = 1,
        ["autumn"] = 2,
        ["winter"] = 3
    }

    -- Load properties
    if Utils.getNoNil(getXMLBool(file, "textures#overwrite"), false) then
        self.textureReplacements = {}
        self.textureReplacements.default = {}
    end

    -- If there is a material holder, load that first
    local matHolder = getXMLString(file, "textures#materialHolder")
    if matHolder ~= nil then
        local normPath = ssUtil.normalizedPath(ssUtil.basedir(path) .. matHolder)

        local replacements = loadI3DFile(normPath)

        table.insert(self.modReplacements, replacements)

        if self.tmpMaterialHolderNodeId == nil then
            self.tmpMaterialHolderNodeId = self:findNodeByName(replacements, "summer_material_holder")
        end
    end

    -- Load seasons replacements
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

                if secondaryNodeName == nil then
                    secondaryNodeName = ""
                end

                if shapeName == nil or toTexture == nil then
                    logInfo("ssReplaceVisual:", "Failed to load texture replacements configuration from " .. path .. ": invalid format")
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

            i = 0
            if season._foliageLayers == nil then
                season._foliageLayers = {}
            end

            while true do
                local foliageKey = string.format("%s.foliageLayer(%i)", seasonKey, i)
                if not hasXMLProperty(file, foliageKey) then break end

                local layerName = getXMLString(file, foliageKey .. "#name")
                local toShape = getXMLString(file, foliageKey .. "#to")
                local visible = Utils.getNoNil(getXMLBool(file, foliageKey .. "#visible"), true)

                if layerName == nil or (toShape == nil and visible == true) then
                    logInfo("ssReplaceVisual:", "Failed to load foliage layer replacements configuration from " .. path .. ": invalid format")
                    return
                end

                season._foliageLayers[layerName] = {
                    ["to"] = toShape,
                    ["visible"] = visible
                }

                i = i + 1
            end
        end
    end

    delete(file)
end

function ssReplaceVisual:update(dt)
    if self.once ~= true and g_currentMission:getIsClient() then
        self:updateFoliageLayers()
        self.once = true
    end
end

function ssReplaceVisual:seasonChanged()
    if g_currentMission:getIsClient() then
        self:updateTextures()
        self:updateFoliageLayers()
    end
end

function ssReplaceVisual.placeableUpdatePlacableOnCreation(self)
    if g_currentMission:getIsClient() then
        ssReplaceVisual:updateTextures(self.nodeId)
    end
end

-- Stefan Geiger - GIANTS Software (https://gdn.giants-software.com/thread.php?categoryId=16&threadId=664)
function ssReplaceVisual:findNodeByName(nodeId, name)
    if getName(nodeId) == name then
        return nodeId
    end

    for i = 0, getNumOfChildren(nodeId) - 1 do
        local tmp = self:findNodeByName(getChildAt(nodeId, i), name)

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
-- Also used to reset to the defaults
function ssReplaceVisual:loadTextureIdTable(searchBase)
    -- Go over each texture (season, shape, secShape), find the material in the game
    -- and store its ID

    if self.textureReplacements.default._foliageLayers == nil then
        self.textureReplacements.default._foliageLayers = {}
    end

    for seasonId, seasonTable in pairs(self.textureReplacements) do
        if seasonId ~= "default" then

        for shapeName, shapeNameTable in pairs(seasonTable) do
            for secondaryNodeName, secondaryNodeTable in pairs(shapeNameTable) do
                local materialSrcId = self:findNodeByName(searchBase, secondaryNodeTable.replacementName)

                if materialSrcId ~= nil then -- Can be defined in an other I3D file.
                    -- log("Loading mapping for texture replacement: Shapename: " .. shapeName .. " secondaryNodeName: " .. secondaryNodeName .. " searchBase: " .. searchBase .. " season: " .. seasonId .. " Value: " .. secondaryNodeTable["replacementName"] .. " materialID: " .. materialSrcId )
                    self.textureReplacements[seasonId][shapeName][secondaryNodeName].materialId = getMaterial(materialSrcId, 0)

                    -- Load the current material
                    if self.textureReplacements.default[shapeName] == nil then
                        self.textureReplacements.default[shapeName] = {}
                    end

                    if self.textureReplacements.default[shapeName][secondaryNodeName] == nil then
                        self.textureReplacements.default[shapeName][secondaryNodeName] = {}
                    end

                    if self.textureReplacements.default[shapeName][secondaryNodeName].materialId == nil then
                        local materialId = ssReplaceVisual:findOriginalMaterial(getRootNode(), shapeName, secondaryNodeName)
                        self.textureReplacements.default[shapeName][secondaryNodeName].materialId = materialId

                        -- Load an object to hold it as well to prevent garbage collect
                        if materialId ~= nil and self.tmpMaterialHolderNodeId ~= nil then
                            local nodeId = clone(self.tmpMaterialHolderNodeId, false, false, false)

                            link(getRootNode(), nodeId)
                            setMaterial(nodeId, materialId, 0)
                        end
                    end
                end
            end
        end

        if self.textureReplacements[seasonId]._foliageLayers ~= nil then
            local layers = self.textureReplacements[seasonId]._foliageLayers

            for layerName, data in pairs(layers) do
                if data.to ~= nil then
                    local node = self:findNodeByName(searchBase, data.to)

                    if node ~= nil then
                        data.materialId = getMaterial(node, 0)
                    end
                end

                -- To be able to iterate over it
                self.textureReplacements.default._foliageLayers[layerName] = 0
            end
        end

        end
    end
end

-- Finds the material of the original Shape object
function ssReplaceVisual:findOriginalMaterial(searchBase, shapeName, secondaryNodeName)
    -- print("Searching for object: " .. shapeName .. "/" .. secondaryNodeName .. " under " .. searchBase )
    local parentShapeId = self:findNodeByName(searchBase, shapeName)
    local childShapeId
    local materialId

    -- print("DEBUG: " .. parentShapeId )
    if parentShapeId ~= nil then
        if secondaryNodeName == "" then
            return getMaterial(parentShapeId, 0)
        end

        childShapeId = (self:findNodeByName(parentShapeId, secondaryNodeName))
        if childShapeId ~= nil then
            materialId = getMaterial(childShapeId, 0)
        end
    end

    return materialId
end

-- Walks the node tree and replaces materials according to season as specified in self.textureReplacements
function ssReplaceVisual:updateTextures(nodeId)
    if nodeId == nil then
        nodeId = getRootNode()
    end

    local season = g_seasons.environment:currentSeason()
    local nodeName = getName(nodeId)

    if self.textureReplacements[season][nodeName] ~= nil then
        -- If there is a texture for this season and node, set it
        for secondaryNodeName, secondaryNodeTable in pairs(self.textureReplacements[season][getName(nodeId)]) do
            if secondaryNodeName == "" then
                secondaryNodeName = nodeName
            end

            if secondaryNodeTable.materialId ~= nil then
                -- log("Asking for texture change: " .. getName(nodeId) .. " (" .. nodeId .. ")/" .. secondaryNodeName .. " to " .. secondaryNodeTable["materialId"])
                self:updateTexturesSubNode(nodeId, secondaryNodeName, secondaryNodeTable.materialId)
            end
        end
    elseif self.textureReplacements.default[nodeName] ~= nil then
        -- Otherwise, set the default
        for secondaryNodeName, secondaryNodeTable in pairs(self.textureReplacements.default[getName(nodeId)]) do
            if secondaryNodeName == "" then
                secondaryNodeName = nodeName
            end

            -- MATERIALID is NULL for birch
            if secondaryNodeTable.materialId ~= nil then
                -- log("Asking for texture change: " .. getName(nodeId) .. " (" .. nodeId .. ")/" .. secondaryNodeName .. " to " .. secondaryNodeTable["materialId"])
                self:updateTexturesSubNode(nodeId, secondaryNodeName, secondaryNodeTable.materialId)
            end
        end
    end

    -- Replace for all children recursivly
    for i = 0, getNumOfChildren(nodeId) - 1 do
        local childId = getChildAt(nodeId, i)

        if childId ~= nil then
            self:updateTextures(childId, name)
        end
    end
end

-- Does a specified replacement on subnodes of nodeId.
function ssReplaceVisual:updateTexturesSubNode(nodeId, shapeName, materialSrcId)
    if getName(nodeId) == shapeName then
        -- log("Setting texture for " .. getName(nodeId) .. " (" .. tostring(nodeId) .. ") to " .. tostring(materialSrcId))
        setMaterial(nodeId, materialSrcId, 0)
    end

    for i = 0, getNumOfChildren(nodeId) - 1 do
        local childId = getChildAt(nodeId, i)

        if childId ~= nil then
            local tmp = self:updateTexturesSubNode(childId, shapeName, materialSrcId)

            if tmp ~= nil then
                return tmp
            end
        end
    end

    return nil
end

function ssReplaceVisual:consoleCommandSetVisuals(seasonName)
    local season = g_seasons.environment.SEASON_SPRING
    if seasonName == "summer" then
        season = g_seasons.environment.SEASON_SUMMER
    elseif seasonName == "autumn" then
        season = g_seasons.environment.SEASON_AUTUMN
    elseif seasonName == "winter" then
        season = g_seasons.environment.SEASON_WINTER
    end

    -- Overwrite getter
    local oldCurrentSeason = g_seasons.environment.currentSeason
    g_seasons.environment.currentSeason = function (self)
        return season
    end

    -- Update
    self:updateTextures()
    self:updateFoliageLayers()

    -- Fix getter
    g_seasons.environment.currentSeason = oldCurrentSeason

    self.debug = false

    return "Updated textures to " .. tostring(season)
end

function ssReplaceVisual:updateFoliageLayers()
    local layers = self.textureReplacements[g_seasons.environment:currentSeason()]._foliageLayers

    for layerName, defaultMaterial in pairs(self.textureReplacements.default._foliageLayers) do
        local layerId = getChild(g_currentMission.terrainRootNode, layerName)
        local seasonLayer = layers[layerName]

        if layerId ~= 0 then
            -- Load default
            if defaultMaterial == 0 then
                defaultMaterial = getMaterial(getChildAt(layerId, 0), 0)

                self.textureReplacements.default._foliageLayers[layerName] = defaultMaterial

                -- Store in a shape against GC
                if defaultMaterial ~= nil and self.tmpMaterialHolderNodeId ~= nil then
                    local nodeId = clone(self.tmpMaterialHolderNodeId, false, false, false)

                    link(getRootNode(), nodeId)
                    setMaterial(nodeId, defaultMaterial, 0)
                end
            end

            if layers[layerName] ~= nil then
                -- Set updated material. Use default if not supplied (visibility toggle only)
                if seasonLayer.materialId ~= nil then
                    self:setFoliageMaterial(layerId, seasonLayer.materialId)
                else
                    self:setFoliageMaterial(layerId, defaultMaterial)
                end

                setVisibility(layerId, seasonLayer.visible)
            else
                -- Set default material
                self:setFoliageMaterial(layerId, defaultMaterial)
                setVisibility(layerId, true)
            end
        end
    end
end

function ssReplaceVisual:setFoliageMaterial(layerId, material)
    for i = 0, getNumOfChildren(layerId) - 1 do
        setMaterial(getChildAt(layerId, i), material, 0)
    end
end
