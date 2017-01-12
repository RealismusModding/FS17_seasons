---------------------------------------------------------------------------------------------------------
-- ssGrowthManagerData
---------------------------------------------------------------------------------------------------------
-- Purpose:  For loading growth data
-- Authors:  theSeb, based on ssSeasonsXML by Rahkiin (Jarvixes)
--

ssGrowthManagerData = {}

 ssGrowthManagerData.DEFAULT_FILE_PATH = "data/growth.xml"

function ssGrowthManagerData:loadAllData()
    local growthData = {}
    local path = g_seasons.modDir .. self.DEFAULT_FILE_PATH
    local rootKey = "growthManager"

    local file = loadXMLFile("xml", path)
    if file == nil then
        logInfo("ssGrowthManagerData: Failed to load XML growth data file " .. path)
        return nil,nil
    end

    local defaultFruits = self:getDefaultFruitsData(rootKey, file)
    if defaultFruits == nil then
        logInfo("ssGrowthManagerData: Failed to load XML growth data file (defaultFruits) " .. path)
        return nil,nil
    end

    local growthData = self:getGrowthData(rootKey, file)
    if growthData == nil then
        logInfo("ssGrowthManagerData: Failed to load XML growth data file (growthTransitions) " .. path)
        return nil,nil
    end

    --additional modmap growthData
    local modMapDataPath = ssSeasonsUtil:getModMapDataPath("seasons_growth.xml")
    --modMapDataPath = g_seasons.modDir .. "data/seasons_growth.xml" --for testing

    if  modMapDataPath ~= nil then
        logInfo("ssGrowthManagerData: Additional growth data found - loading")
        file = loadXMLFile("xml", modMapDataPath)
        if file ~= nil then
            local optionalDefaultFruits = self:getDefaultFruitsData(rootKey, file, defaultFruits)
            if optionalDefaultFruits == nil then
                logInfo("ssGrowthManagerData: Failed to load additional XML growth data file (defaultFruits) " .. path)
            else
                local optionalGrowthData = self:getGrowthData(rootKey, file, growthData, true)
                if optionalGrowthData == nil then
                    logInfo("ssGrowthManagerData: Failed to load additional XML growth data file (growthTransitions) " .. path)
                else
                    defaultFruits = optionalDefaultFruits
                    growthData = optionalGrowthData
                end
            end
        else
            logInfo("ssGrowthManagerData: Failed to load additional XML growth data file " .. modMapDataPath)
        end
    end

    return defaultFruits, growthData
end

function ssGrowthManagerData:getGrowthData(rootKey, file, parentData, additionalData)
    local growthData = parentData ~= nil and Utils.copyTable(parentData) or {}--{}

    local growthTransitionsKey = rootKey .. ".growthTransitions"

    if hasXMLProperty(file,growthTransitionsKey) then

        --load each transition
        local i = 0
        while true do
            local growthTransitionKey = string.format("%s.gt(%i)", growthTransitionsKey, i)
            if not hasXMLProperty(file, growthTransitionKey) then
                break
            end

            local growthTransitionNumKey = growthTransitionKey .. "#growthTransitionNum"
            local growthTransitionNum = getXMLString(file,growthTransitionNumKey)
            if growthTransitionNum == nil then
                logInfo("ssGrowthManagerData: getGrowthData: XML loading failed growthTransitionNumKey:" .. growthTransitionNumKey)
                return nil
            elseif growthTransitionNum == "FIRST_LOAD_TRANSITION" then
                growthTransitionNum = ssGrowthManager.FIRST_LOAD_TRANSITION
            else
                growthTransitionNum = tonumber(growthTransitionNum)
            end

            --insert growth transition into datatable
            if additionalData ~= true then
                table.insert( growthData, growthTransitionNum, {})
            end

            growthData = self:getFruitsTransitionStates(growthTransitionKey, file, growthTransitionNum, growthData,additionalData)
            i = i + 1
        end
    else
        logInfo("ssGrowthManagerData: getGrowthData: XML loading failed growthTransitionsKey" .. growthTransitionsKey .. " not found")
        return nil
    end

    return growthData
end

function ssGrowthManagerData:getFruitsTransitionStates(growthTransitionKey, file, growthTransitionNum, parentData, additionalData)
    local growthData = parentData
    --load each fruit

    local i = 0
    while true do
        local fruitKey = string.format("%s.fruit(%i)", growthTransitionKey, i)
        if not hasXMLProperty(file, fruitKey) then
            break
        end

        local fruitName = getXMLString(file,fruitKey .. "#fruitName")
        if fruitName == nil then
            logInfo("ssGrowthManagerData: getFruitsTransitionStates: XML loading failed fruitKey" .. fruitKey .. " not found")
        end

        --if additionalData ~= true then TODO: check if fruit exists, overwrite, or create new table or leave it like this - it overwrites
            growthData[growthTransitionNum][fruitName] = {}
        --end
        growthData[growthTransitionNum][fruitName].fruitName = fruitName

        local normalGrowthState = getXMLInt(file,fruitKey .. "#normalGrowthState")
        if normalGrowthState ~= nil then
            growthData[growthTransitionNum][fruitName].normalGrowthState = normalGrowthState
        end

        local normalGrowthMaxState =  getXMLString(file,fruitKey .. "#normalGrowthMaxState")
        if normalGrowthMaxState ~= nil then
            if normalGrowthMaxState == "MAX_STATE" then
                growthData[growthTransitionNum][fruitName].normalGrowthMaxState = ssGrowthManager.MAX_STATE
            else
                growthData[growthTransitionNum][fruitName].normalGrowthMaxState = tonumber(normalGrowthMaxState)
            end
        end

        local setGrowthState =  getXMLInt(file,fruitKey .. "#setGrowthState")
        if setGrowthState ~= nil then
            growthData[growthTransitionNum][fruitName].setGrowthState = setGrowthState
        end

        local setGrowthMaxState =  getXMLString(file,fruitKey .. "#setGrowthMaxState")
        if setGrowthMaxState ~= nil then
            --growthData[growthTransitionNum][fruitName].setGrowthMaxState = setGrowthMaxState
            if setGrowthMaxState == "MAX_STATE" then
                growthData[growthTransitionNum][fruitName].setGrowthMaxState = ssGrowthManager.MAX_STATE
            else
                growthData[growthTransitionNum][fruitName].setGrowthMaxState = tonumber(setGrowthMaxState)
            end
        end

        local desiredGrowthState =  getXMLString(file,fruitKey .. "#desiredGrowthState")
        if desiredGrowthState ~= nil then
            if desiredGrowthState == "CUT" then
                growthData[growthTransitionNum][fruitName].desiredGrowthState = ssGrowthManager.CUT
            elseif desiredGrowthState == "WITHERED" then
                growthData[growthTransitionNum][fruitName].desiredGrowthState = ssGrowthManager.WITHERED
            else
                growthData[growthTransitionNum][fruitName].desiredGrowthState = tonumber(desiredGrowthState)
            end
        end

        local extraGrowthMinState = getXMLInt(file,fruitKey .. "#extraGrowthMinState")
        if extraGrowthMinState ~= nil then
            growthData[growthTransitionNum][fruitName].extraGrowthMinState = extraGrowthMinState
        end

        local extraGrowthMaxState = getXMLInt(file,fruitKey .. "#extraGrowthMaxState")
        if extraGrowthMaxState ~= nil then
            growthData[growthTransitionNum][fruitName].extraGrowthMaxState = extraGrowthMaxState
        end

        local extraGrowthFactor = getXMLInt(file,fruitKey .. "#extraGrowthFactor")
        if extraGrowthFactor ~= nil then
            growthData[growthTransitionNum][fruitName].extraGrowthFactor = extraGrowthFactor
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
            local defaultFruitKey = string.format("%s.defaultFruit(%i)#name", defaultFruitsKey, i)
            if not hasXMLProperty(file, defaultFruitKey) then
                break
            end

            local fruitName = getXMLString(file, defaultFruitKey)
            if fruitName ~= nil then
                table.insert(defaultFruits,fruitName)
            else
                logInfo("ssGrowthManagerData: getDefaultFruitsData: XML loading failed " .. defaultFruitKey )
                return nil
            end
            i = i + 1
        end
    else
        log("ssGrowthManagerData: getDefaultFruitsData: XML loading failed " .. defaultFruitsKey .. " not found")
        return nil
    end

    return defaultFruits
end
