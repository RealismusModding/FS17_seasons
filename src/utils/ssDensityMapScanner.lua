----------------------------------------------------------------------------------------------------
-- SCRIPT TO UPDATE DENSITY MAPS
----------------------------------------------------------------------------------------------------
-- Purpose:  Performs updates of density maps on behalf of other modules.
-- Authors:  mrbear, Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssDensityMapScanner = {}
g_seasons.dms = ssDensityMapScanner

ssDensityMapScanner.TIMESPLIT = 25 -- ms

function ssDensityMapScanner:load(savegame, key)
    if ssXMLUtil.hasProperty(savegame, key .. ".densityMapScanner.currentJob") then
        local job = {}

        job.x = ssXMLUtil.getInt(savegame, key .. ".densityMapScanner.currentJob.x", 0)
        job.z = ssXMLUtil.getInt(savegame, key .. ".densityMapScanner.currentJob.z", 0)
        job.callbackId = ssXMLUtil.getString(savegame, key .. ".densityMapScanner.currentJob.callbackId")
        job.parameter = ssXMLUtil.getString(savegame, key .. ".densityMapScanner.currentJob.parameter")
        job.numSegments = ssXMLUtil.getInt(savegame, key .. ".densityMapScanner.currentJob.numSegments", 1)

        self.currentJob = job

        log("[ssDensityMapScanner] Loaded current job:", job.callbackId, "with parameter", job.parameter)
    end

    -- Read queue
    self.queue = ssQueue:new()

    local i = 0
    while true do
        local ikey = string.format("%s.densityMapScanner.queue.job(%d)", key, i)
        if not ssXMLUtil.hasProperty(savegame, ikey) then break end

        local job = {}

        job.callbackId = ssXMLUtil.getString(savegame, ikey .. "#callbackId")
        job.parameter = ssXMLUtil.getString(savegame, ikey .. "#parameter")

        self.queue:push(job)

        log("[ssDensityMapScanner] Loaded queued job:", job.callbackId, "with parameter", job.parameter)

        i = i + 1
    end
end

function ssDensityMapScanner:save(savegame, key)
    removeXMLProperty(savegame, key .. ".densityMapScanner")

    if self.currentJob ~= nil then
        ssXMLUtil.setInt(savegame, key .. ".densityMapScanner.currentJob.x", self.currentJob.x)
        ssXMLUtil.setInt(savegame, key .. ".densityMapScanner.currentJob.z", self.currentJob.z)
        ssXMLUtil.setString(savegame, key .. ".densityMapScanner.currentJob.callbackId", self.currentJob.callbackId)
        ssXMLUtil.setString(savegame, key .. ".densityMapScanner.currentJob.parameter", tostring(self.currentJob.parameter))
        ssXMLUtil.setInt(savegame, key .. ".densityMapScanner.currentJob.numSegments", self.currentJob.numSegments)
    end

    -- Save queue
    self.queue:iteratePushOrder(function (job, i)
        local ikey = string.format("%s.densityMapScanner.queue.job(%d)", key, i - 1)

        ssXMLUtil.setString(savegame, ikey .. "#callbackId", job.callbackId)

        if job.parameter ~= nil then
            ssXMLUtil.setString(savegame, ikey .. "#parameter", tostring(job.parameter))
        end
    end)
end

function ssDensityMapScanner:loadMap(name)
    if g_currentMission:getIsServer() then
        if self.queue == nil then
            self.queue = ssQueue:new()
        end

        self.timeCounter = 0
    end
end

function ssDensityMapScanner:update(dt)
    if not g_currentMission:getIsServer() then return end

    if self.currentJob == nil then
        self.currentJob = self.queue:pop()

        -- A new job has started
        if self.currentJob then
            self.currentJob.x = 0
            self.currentJob.z = 0

            if g_dedicatedServerInfo ~= nil then
                self.currentJob.numSegments = 1 -- Not enough time to do it section by section.
            else
                -- Must be evenly dividable with mapsize.
                self.currentJob.numSegments = 16
            end

            log("[ssDensityMapScanner] Dequed job:", self.currentJob.callbackId, "(", self.currentJob.parameter, ")")
        end
    end

    if self.currentJob ~= nil then
        self.timeCounter = self.timeCounter + dt

        -- Use a timer to spread updates: only on SP, as it would only lag on MP
        -- due to density map synchronization
        if g_dedicatedServerInfo ~= nil or self.timeCounter >= ssDensityMapScanner.TIMESPLIT then
            if not self:run(self.currentJob) then
                self.currentJob = nil
            end

            -- Reset timer
            self.timeCounter = 0
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
        logInfo("[ssDensityMapScanner] Tried to run unknown callback '", job.callbackId, "'")

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
