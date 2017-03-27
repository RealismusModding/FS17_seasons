---------------------------------------------------------------------------------------------------------
-- SCRIPT TO UPDATE DENSITY MAPS
---------------------------------------------------------------------------------------------------------
-- Purpose:  Performs updates of density maps on behalf of other modules.
-- Authors:  mrbear, Rahkiin
--

ssDensityMapScanner = {}
g_seasons.dms = ssDensityMapScanner

function ssDensityMapScanner:load(savegame, key)
    if ssStorage.hasXMLProperty(savegame, key .. ".densityMapScanner.currentJob") then
        local job = {}

        job.x = ssStorage.getXMLInt(savegame, key .. ".densityMapScanner.currentJob.x", 0)
        job.z = ssStorage.getXMLInt(savegame, key .. ".densityMapScanner.currentJob.z", 0)
        job.callbackId = ssStorage.getXMLString(savegame, key .. ".densityMapScanner.currentJob.callbackId")
        job.parameter = ssStorage.getXMLString(savegame, key .. ".densityMapScanner.currentJob.parameter")
        job.numSegments = ssStorage.getXMLInt(savegame, key .. ".densityMapScanner.currentJob.numSegments", 1)

        self.currentJob = job
    end

    -- Read queue
    self.queue = ssQueue:new()

    local i = 0
    while true do
        local ikey = string.format("%s.densityMapScanner.queue.job(%d)", key, i)
        if not ssStorage.hasXMLProperty(savegame, ikey) then break end

        local job = {}

        job.callbackId = ssStorage.getXMLString(savegame, ikey .. "#callbackId")
        job.parameter = ssStorage.getXMLString(savegame, ikey .. "#parameter")

        self.queue:push(job)

        log("[ssDensityMapScanner] Loaded job:", job.callbackId, "with parameter", job.parameter)

        i = i + 1
    end
end

function ssDensityMapScanner:save(savegame, key)
    removeXMLProperty(savegame, key .. ".densityMapScanner")

    if self.currentJob ~= nil then
        ssStorage.setXMLInt(savegame, key .. ".densityMapScanner.currentJob.x", job.x)
        ssStorage.setXMLInt(savegame, key .. ".densityMapScanner.currentJob.z", job.z)
        ssStorage.setXMLString(savegame, key .. ".densityMapScanner.currentJob.callbackId", job.callbackId)
        ssStorage.setXMLString(savegame, key .. ".densityMapScanner.currentJob.parameter", job.parameter)
        ssStorage.setXMLInt(savegame, key .. ".densityMapScanner.currentJob.numSegments", job.numSegments)
    end

    -- Save queue
    self.queue:iteratePushOrder(function (job, i)
        local ikey = string.format("%s.densityMapScanner.queue.job(%d)", key, i - 1)

        ssStorage.setXMLString(savegame, ikey .. "#callbackId", job.callbackId)

        if job.parameter ~= nil then
            ssStorage.setXMLString(savegame, ikey .. "#parameter", tostring(job.parameter))
        end
    end)
end

function ssDensityMapScanner:loadMap(name)
    if g_currentMission:getIsServer() then
        if self.queue == nil then
            self.queue = ssQueue:new()
        end
    end
end

function ssDensityMapScanner:update(dt)
    if self.currentJob == nil then
        self.currentJob = self.queue:pop()

        if self.currentJob then
            self.currentJob.x = 0
            self.currentJob.z = 0

            -- Must be evenly dividable with mapsize.
            self.currentJob.numSegments = 16

            if g_dedicatedServerInfo ~= nil or g_currentMission.missionInfo.timeScale > 120 then
                self.currentJob.numSegments = 1 -- Not enough time to do it section by section.
            end

            log("[ssDensityMapScanner] Dequed job:", self.currentJob.callbackId, "(", self.currentJob.parameter, ")")
        end
    end

    if self.currentJob ~= nil then
        if not self:run(self.currentJob) then
            self.currentJob = nil
        end
    end
end

function ssDensityMapScanner:queueJob(callbackId, parameter)
    if g_currentMission:getIsServer() then
        log("[ssDensityMapScanner] Enqued job:", callbackId, "(", parameter, ")")

        self.queue:push({
            callbackId = callbackId,
            parameter = parameter
        })
    end
end

function ssDensityMapScanner:registerCallback(callbackId, target, func, finalizer)
    log("[ssDensityMapScanner] Registering callback: " .. callbackId)

    if self.callbacks == nil then
        self.callbacks = {}
    end

    self.callbacks[callbackId] = {
        target = target,
        func = func,
        finalizer = finalizer
    }
end

-- Returns: true when new cycle needed. false when done
function ssDensityMapScanner:run(job)
    if job == nil then return end

    local size = g_currentMission.terrainSize
    local startWorldX = job.x * size / job.numSegments - size / 2
    local startWorldZ = job.z * size / job.numSegments - size / 2
    local widthWorldX = startWorldX + size / job.numSegments - 0.5 -- -0.5 to avoid overlap.
    local widthWorldZ = startWorldZ
    local heightWorldX = startWorldX
    local heightWorldZ = startWorldZ + size / job.numSegments - 0.2 -- -0.2 to avoid overlap.

    -- Run the callback
    local callback = self.callbacks[job.callbackId]
    if callback == nil then
        logInfo("[ssDensityMapScanner] Tried to run unknown callback '", job.callbackId,"'")

        return false
    end

    callback.func(callback.target, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, job.parameter)

    -- Update current job
    if job.z < job.numSegments - 1 then -- Starting with column 0 So index of last column is one less then the number of columns.
        -- Next column
        job.z = job.z + 1
    elseif job.x < job.numSegments - 1 then -- Starting with row 0
        -- Next row
        job.x = job.x + 1
        job.z = 0
    else
        -- Done with the loop, call finalizer
        if callback.callbackFinalizeFunction ~= nil then
            callback.callbackFinalizeFunction(callback.callbackSelf, self.currentParameter)
        end

        return false -- finished
    end

    return true -- not finished
end
