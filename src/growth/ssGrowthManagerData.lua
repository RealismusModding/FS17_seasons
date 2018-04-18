----------------------------------------------------------------------------------------------------
-- ssGrowthManagerData
----------------------------------------------------------------------------------------------------
-- Purpose:  For loading growth data
-- Authors:  theSeb, based on ssSeasonsXML by Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssGrowthManagerData = {}

-- constans
ssGrowthManagerData.LEGACY_GROWTH_FORMAT = 1

function ssGrowthManagerData:loadAllData()
    local growthData = {}
    local path = g_seasons:getDataPath("growth")
    local rootKey = "growth"

    local file = loadXMLFile("xml", path)
    if file == nil then
        logInfo("ssGrowthManagerData:", "Failed to load XML growth data file " .. path)
        return nil, nil
    end

    local defaultFruits = self:getDefaultFruitsData(rootKey, file)
    if defaultFruits == nil then
        logInfo("ssGrowthManagerData:", "Failed to load XML growth data file (defaultFruits) " .. path)
        return nil, nil
    end

    local growthData = self:getGrowthData(rootKey, file)
    if growthData == nil then
        logInfo("ssGrowthManagerData:", "Failed to load XML growth data file (transitions) " .. path)
        return nil, nil
    end
    delete(file)

    --additional modmap growthData
    for _, path in ipairs(g_seasons:getModPaths("growth")) do
        local optionalDefaultFruits, optionalGrowthData = self:loadAdditionalData(rootKey, path, defaultFruits, growthData)
        if optionalDefaultFruits == nil or optionalGrowthData == nil then
            logInfo("ssGrowthManagerData:", "Failed to process additional XML growth data file: " .. path)
        else
            defaultFruits = optionalDefaultFruits
            growthData = optionalGrowthData
        end
    end

    return defaultFruits, growthData
end

function ssGrowthManagerData:loadAdditionalData(rootKey, modMapDataPath, defaultFruits, growthData)
    logInfo("ssGrowthManagerData:", "Additional growth data found - loading: " .. modMapDataPath)
    local optionalDefaultFruits = nil
    local optionalGrowthData = nil

    local file = loadXMLFile("xml", modMapDataPath)
    if file ~= nil then
        local overWriteData = getXMLBool(file, rootKey .. "#overwrite")
        if overWriteData == true then
            optionalDefaultFruits = self:getDefaultFruitsData(rootKey, file)
            if optionalDefaultFruits ~= nil then
                optionalGrowthData = self:getGrowthData(rootKey, file)
            end
        else
            optionalDefaultFruits = self:getDefaultFruitsData(rootKey, file, defaultFruits)
            if optionalDefaultFruits ~= nil then
                optionalGrowthData = self:getGrowthData(rootKey, file, growthData, true)
            end
        end

        delete(file)
    else
        logInfo("ssGrowthManagerData:", "Failed to load additional XML growth data file: " .. modMapDataPath)
    end

    return optionalDefaultFruits, optionalGrowthData
end

function ssGrowthManagerData:getGrowthData(rootKey, file, parentData, additionalData)
    local growthData = parentData ~= nil and Utils.copyTable(parentData) or {}

    local transitionsKey = rootKey .. ".growthTransitions"

    local fileVersion = self:getGrowthFileVersion(rootKey, file)

    if hasXMLProperty(file, transitionsKey) then
        --load each transition
        local i = 0
        while true do
            local transitionKey = string.format("%s.gt(%i)", transitionsKey, i)
            if not hasXMLProperty(file, transitionKey) then
                break
            end

            local transitionNumKey = transitionKey .. "#growthTransitionNum"
            local transitionNum = getXMLString(file, transitionNumKey)
            if transitionNum == nil then
                logInfo("ssGrowthManagerData:", "getGrowthData: XML loading failed transitionNumKey:" .. transitionNumKey)
                return nil
            elseif transitionNum == "FIRST_LOAD_TRANSITION" then
                transitionNum = ssGrowthManager.FIRST_LOAD_TRANSITION
            else
                transitionNum = tonumber(transitionNum)
            end

            --insert growth transition into datatable
            if additionalData ~= true then
                table.insert(growthData, transitionNum, {})
            end

            if fileVersion == SELF.LEGACY_GROWTH_FORMAT then
                growthData = self:getFruitsTransitionStatesLegacyFormat(transitionKey, file, transitionNum, growthData)
            else
                growthData = self:getFruitsTransitionStates(transitionKey, file, transitionNum, growthData)
            end

            i = i + 1
        end
    else
        logInfo("ssGrowthManagerData:", "getGrowthData: XML loading failed transitionsKey" .. transitionsKey .. " not found")
        return nil
    end

    return growthData
end

function ssGrowthManagerData:getFruitsTransitionStates(transitionKey, file, transitionNum, parentData)
    local growthData = parentData

    --load each fruit
    local i = 0
    while true do
        local fruitKey = string.format("%s.fruit(%i)", transitionKey, i)
        if not hasXMLProperty(file, fruitKey) then
            break
        end

        local fruitName = getXMLString(file, fruitKey .. "#fruitName")
        if fruitName == nil then
            logInfo("ssGrowthManagerData:", "getFruitsTransitionStates: XML loading failed fruitKey" .. fruitKey .. " not found")
        end

        growthData[transitionNum][fruitName] = {}
        growthData[transitionNum][fruitName].fruitName = fruitName

        local incrementByOneMin = getXMLInt(file, fruitKey .. "#normalGrowthState")
        if incrementByOneMin ~= nil then
            growthData[transitionNum][fruitName].incrementByOneMin = incrementByOneMin
        end

        local incrementByOneMax =  getXMLString(file, fruitKey .. "#normalGrowthMaxState")
        if incrementByOneMax ~= nil then
            if incrementByOneMax == "MAX_STATE" then
                growthData[transitionNum][fruitName].incrementByOneMax = ssGrowthManager.MAX_STATE
            else
                growthData[transitionNum][fruitName].incrementByOneMax = tonumber(incrementByOneMax)
            end
        end

        local setFromMin =  getXMLInt(file, fruitKey .. "#setGrowthState")
        if setFromMin ~= nil then
            growthData[transitionNum][fruitName].setFromMin = setFromMin
        end

        local setFromMax =  getXMLString(file, fruitKey .. "#setGrowthMaxState")
        if setFromMax ~= nil then
            if setFromMax == "MAX_STATE" then
                growthData[transitionNum][fruitName].setFromMax = ssGrowthManager.MAX_STATE
            else
                growthData[transitionNum][fruitName].setFromMax = tonumber(setFromMax)
            end
        end

        local setTo =  getXMLString(file, fruitKey .. "#desiredGrowthState")
        if setTo ~= nil then
            if setTo == "CUT" then
                growthData[transitionNum][fruitName].setTo = ssGrowthManager.CUT
            elseif setTo == "WITHERED" then
                growthData[transitionNum][fruitName].setTo = ssGrowthManager.WITHERED
            else
                growthData[transitionNum][fruitName].setTo = tonumber(setTo)
            end
        end

        local incrementByMin = getXMLInt(file, fruitKey .. "#extraGrowthMinState")
        if incrementByMin ~= nil then
            growthData[transitionNum][fruitName].incrementByMin = incrementByMin
        end

        local incrementByMax = getXMLInt(file, fruitKey .. "#extraGrowthMaxState")
        if incrementByMax ~= nil then
            growthData[transitionNum][fruitName].incrementByMax = incrementByMax
        end

        local incrementBy = getXMLInt(file, fruitKey .. "#extraGrowthFactor")
        if incrementBy ~= nil then
            growthData[transitionNum][fruitName].incrementBy = incrementBy
        end

        local removeTransition = getXMLBool(file, fruitKey .. "#removeTransition")
        if removeTransition == true then
            growthData[transitionNum][fruitName] = nil
        end

        i = i + 1
    end

    return growthData
end

function ssGrowthManagerData:getDefaultFruitsData(rootKey, file, parentData)
    local defaultFruits = parentData ~= nil and Utils.copyTable(parentData) or {}--{}
    local defaultFruitsKey =  rootKey .. ".defaultFruits"

    if hasXMLProperty(file, defaultFruitsKey) then

        local i = 0
        while true do
            local defaultFruitKey = string.format("%s.defaultFruit(%i)#fruitName", defaultFruitsKey, i)
            if not hasXMLProperty(file, defaultFruitKey) then
                break
            end

            local fruitName = getXMLString(file, defaultFruitKey)
            local maxSprayGrowthState = getXMLInt(file, string.format("%s.defaultFruit(%i)#maxSprayGrowthState", defaultFruitsKey, i))
            if fruitName ~= nil then
                defaultFruits[fruitName] = {}
                if maxSprayGrowthState ~= nil then
                    defaultFruits[fruitName].maxSprayGrowthState = maxSprayGrowthState
                else
                    defaultFruits[fruitName].maxSprayGrowthState = 4
                end
            else
                logInfo("ssGrowthManagerData:", "getDefaultFruitsData: XML loading failed " .. defaultFruitKey )
                return nil
            end
            i = i + 1
        end
    else
        logInfo("ssGrowthManagerData:", "getDefaultFruitsData: XML loading failed " .. defaultFruitsKey .. " not found")
        return nil
    end

    return defaultFruits
end

function ssGrowthManagerData:getGrowthFileVersion(rootKey, file)
    local version = getXMLInt(file, rootKey .. ".version")
    if version ~= nil then
        return version
    else 
        return self.LEGACY_GROWTH_FORMAT
    end
end
