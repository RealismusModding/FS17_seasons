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

            if g_dedicatedServerInfo ~= nil then
                self.currentJob.numSegments = 1 -- Not enough time to do it section by section.
            else
                -- Must be evenly dividable with mapsize.
                self.currentJob.numSegments = math.min(g_currentMission.terrainSize,16*16)
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

        local job = {
            callbackId = callbackId,
            parameter = parameter
        }

        if not self:foldNewJob(job) then
            self.queue:push(job)
        end
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
    local pixelSize = size / getDensityMapSize(g_currentMission.terrainDetailHeightId)
    local startWorldX = job.x * size / job.numSegments - size / 2 + (pixelSize / 2)
    local startWorldZ = -size / 2
    local widthWorldX = startWorldX + size / job.numSegments - pixelSize
    local widthWorldZ = startWorldZ
    local heightWorldX = startWorldX
    local heightWorldZ = startWorldZ + size

    -- Run the callback
    local callback = self.callbacks[job.callbackId]
    if callback == nil then
        logInfo("[ssDensityMapScanner] Tried to run unknown callback '", job.callbackId, "'")

        return false
    end

    callback.func(callback.target, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, job.parameter)

    -- Update current job
    if job.x < job.numSegments - 1 then -- Starting with row 0
        -- Next row
        job.x = job.x + 1
    else
        -- Done with the loop, call finalizer
        if callback.finalizer ~= nil then
            callback.finalizer(callback.target, job.parameter)
        end

        return false -- finished
    end

    return true -- not finished
end

----------------------------
-- Folding
-- NOTE(Rahkiin): What I dislike about this is the coupling.
-- Now the DMS code contains stuff of classes that call the
-- DMS. Is a bit nasty. Solution is to move these fold actions
-- into the actual class that creates them.
----------------------------

--- Attempt to fold a job into the queue
-- @param job job to fold
-- @return true when folded, false when enqueueing is needed
function ssDensityMapScanner:foldNewJob(job)
    local folded = false

    if job.callbackId == "ssSnowAddSnow" or job.callbackId == "ssSnowRemoveSnow" then
        folded = self:foldSnow(job)
    elseif job.callbackId == "ssReduceStrawHay" or job.callbackId == "ssReduceGrass" then
        folded = self:foldSwath(job)
    end

    return folded
end

--- Fold a new snow job
-- @param newJob new job to fold
-- @return true when successfully folded, false otherwise
function ssDensityMapScanner:foldSnow(newJob)
    local folded = false

    local newDiff = tonumber(newJob.parameter)
    if newJob.callbackId == "ssSnowRemoveSnow" then
        newDiff = -newDiff
    end

    -- Find first snow command and adjust it
    self.queue:iteratePopOrder(function (job)
        local layers = 0

        if job.callbackId == "ssSnowAddSnow" then
            layers = tonumber(job.parameter)
        elseif job.callbackId == "ssSnowRemoveSnow" then
            layers = -1 * tonumber(job.parameter)
        end

        if layers ~= 0 then
            local newLayers = layers + newDiff

            if newLayers == 0 then
                self.queue:remove(job)
            elseif newLayers < 0 then
                job.parameter = tostring(-newLayers)
                job.callbackId = "ssSnowRemoveSnow"
            else
                job.parameter = tostring(newLayers)
                job.callbackId = "ssSnowAddSnow"
            end

            folded = true
            return true -- break
        end
    end)

    return folded
end

--- Attempt to fold a swath job
-- @param newJob new job to fold
-- @return true when successfully folded, false otherwise
function ssDensityMapScanner:foldSwath(newJob)
    local folded = false

    self.queue:iteratePopOrder(function (job)
        if job.callbackId == newJob.callbackId then
            job.parameter = tostring(tonumber(job.parameter) + tonumber(newJob.parameter))

            folded = true
            return true -- break
        end
    end)

    return folded
end
