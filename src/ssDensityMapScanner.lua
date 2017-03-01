---------------------------------------------------------------------------------------------------------
-- SCRIPT TO UPDATE DENSITY MAPS
---------------------------------------------------------------------------------------------------------
-- Purpose:  Performs updates of density maps on behalf of other modules.
-- Authors:  mrbear
--

ssDensityMapScanner = {}
g_seasons.dms = ssDensityMapScanner

ssDensityMapScanner.callBacks = {}

ssDensityMapScanner.currentX=0
ssDensityMapScanner.currentZ=0
ssDensityMapScanner.currentCallBackName=""
ssDensityMapScanner.currentParameter=""
ssDensityMapScanner.moreIterations=false

ssDensityMapScanner.workQ = ssUtil.listNew()

function ssDensityMapScanner:queueJob(callBackName, parameter)
    if g_currentMission:getIsServer() then
        log("DensityMapScanner, enqued job: " .. callBackName .. "(" .. parameter .. ")")

        ssUtil.listPushRight(ssDensityMapScanner.workQ, { callBackName = callBackName, parameter=parameter })
    end
end

function ssDensityMapScanner:registerCallback(callBackName, callbackSelf, callbackFunction, callbackFinalizeFunction)
    log("Registering callback: " .. callBackName)

    self.callBacks[callBackName] = {
        callbackSelf = callbackSelf,
        callbackFunction = callbackFunction,
        callbackFinalizeFunction = callbackFinalizeFunction
    }
end

function ssDensityMapScanner:save(savegame, key)
    ssStorage.setXMLInt(savegame, key .. ".densityMapScanner.currentX", self.currentX)
    ssStorage.setXMLInt(savegame, key .. ".densityMapScanner.currentZ", self.currentZ)
    ssStorage.setXMLString(savegame, key .. ".densityMapScanner.currentCallBackName", self.currentCallBackName)
    ssStorage.setXMLString(savegame, key .. ".densityMapScanner.currentParameter", tostring(self.currentParameter))
    ssStorage.setXMLBool(savegame, key .. ".densityMapScanner.moreIterations", self.moreIterations)

    local count=0
    while true do
        log("Saving job: " .. count)

        local jobb = ssUtil.listPopLeft(self.workQ)
        if jobb ~= nil then
            count = count + 1
            local namei = string.format(".densityMapScanner.workQ.jobb%d", count)
            ssStorage.setXMLString(savegame, key .. namei .. "#callBackName", jobb.callBackName)
            ssStorage.setXMLString(savegame, key .. namei .. "#parameter", tostring(jobb.parameter))
        else
            break
        end
    end
    if count > 0 then
        ssStorage.setXMLInt(savegame, key .. ".densityMapScanner.workQ#count", count)
    end
end

function ssDensityMapScanner:load(savegame, key)
    self.currentX = ssStorage.getXMLInt(savegame, key .. ".densityMapScanner.currentX", 0)
    self.currentZ = ssStorage.getXMLInt(savegame, key .. ".densityMapScanner.currentZ", 0)
    self.currentCallBackName = ssStorage.getXMLString(savegame, key .. ".densityMapScanner.currentCallBackName", "")
    self.currentParameter = ssStorage.getXMLString(savegame, key .. ".densityMapScanner.currentParameter", "")
    self.moreIterations = ssStorage.getXMLBool(savegame, key .. ".densityMapScanner.moreIterations", false)

    local items = ssStorage.getXMLInt(savegame, key .. ".densityMapScanner.workQ#count", 0)
    if items > 0 then
        for count=1, items do
            local namei = string.format(".densityMapScanner.workQ.jobb%d", count)
            local callBackName = ssStorage.getXMLString(savegame, key .. namei .. "#callBackName")
            local parameter = ssStorage.getXMLString(savegame, key .. namei .. "#parameter")
            ssUtil.listPushRight( self.workQ, { callBackName = callBackName, parameter=parameter })

            log("[Seasons] DensityMapScanner, loaded jobb: " .. callBackName .. " with parameter " .. parameter)
        end
    end
end

function ssDensityMapScanner:loadMap(name)
end

function ssDensityMapScanner:update(dt)
    if self.moreIterations == false then
        local jobb = ssUtil.listPopLeft(self.workQ)
        if jobb ~= nil then
            log("DensityMapScanner, dequed job: " .. jobb.callBackName .. "(" .. jobb.parameter .. ")")

            self.currentCallBackName = jobb.callBackName
            self.currentParameter = jobb.parameter
            self.moreIterations = true
        end
    end

    if self.moreIterations == true then
        self:ssIterateOverTerrain()
    end
end

function ssDensityMapScanner:ssIterateOverTerrain()
    -- print("- Scanning: " .. self.currentX .. ", " .. self.currentZ)
    local mapSegments = 16 -- Must be evenly dividable with mapsize.

    if g_dedicatedServerInfo ~= nil or g_currentMission.missionInfo.timeScale > 120 then
        mapSegments = 1 -- Not enough time to do it section by section.
    end

    local startWorldX = self.currentX * g_currentMission.terrainSize / mapSegments - g_currentMission.terrainSize / 2
    local startWorldZ = self.currentZ * g_currentMission.terrainSize / mapSegments - g_currentMission.terrainSize / 2
    local widthWorldX = startWorldX + g_currentMission.terrainSize / mapSegments - 0.5 -- -0.5 to avoid overlap.
    local widthWorldZ = startWorldZ
    local heightWorldX = startWorldX
    local heightWorldZ = startWorldZ + g_currentMission.terrainSize / mapSegments - 0.2 -- -0.2 to avoid overlap.

    -- Call provided function
    local callback=self.callBacks[self.currentCallBackName]
    callback.callbackFunction(callback.callbackSelf, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, self.currentParameter)

    if self.currentZ < mapSegments - 1 then -- Starting with column 0 So index of last column is one less then the number of columns.
        -- Next column
        self.currentZ = self.currentZ + 1
    elseif  self.currentX < mapSegments - 1 then -- Starting with row 0
        -- Next row
        self.currentX = self.currentX + 1
        self.currentZ = 0
    else
        -- Done with the loop, set up for the next one.
        self.currentX = 0
        self.currentZ = 0
        self.moreIterations = false

        if callback.callbackFinalizeFunction ~= nil then
            callback.callbackFinalizeFunction(callback.callbackSelf, self.currentParameter)
        end
    end
end
