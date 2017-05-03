----------------------------------------------------------------------------------------------------
-- CATCHING UP SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  Detects when the player has fast forwarded and shows that the game needs to catch
--           up. This waits for all density scanner jobs to complete. It will also reduce the
--           amount of jobs, if possible.
-- Authors:  Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssCatchingUp = {}
g_seasons.catchingUp = ssCatchingUp

ssCatchingUp.LIMIT = 3
ssCatchingUp.FFWD = 300

function ssCatchingUp:loadMap()
    self.showWarning = false
    self.didFfwd = false
end

function ssCatchingUp:update(dt)
    if not g_currentMission:getIsServer() or not g_currentMission:getIsClient() then return end

    if g_currentMission.missionInfo.timeScale > ssCatchingUp.FFWD then
        self.didFfwd = true
    end

    if self.didFfwd and g_currentMission.missionInfo.timeScale <= ssCatchingUp.FFWD then
        -- Did ffwd and stopped doing so
        -- if size too much, then show warning
        if g_seasons.dms.queue.size > ssCatchingUp.LIMIT and self.showWarning ~= true then
            local oldSize = g_seasons.dms.queue.size

            self:foldJobs()

            logInfo("[ssCatchingUp] Game was fast forwarded: number of jobs is reduced from", oldSize, "to", g_seasons.dms.queue.size)

            -- If after reduction the number of items is still more than the limit, show a warning
            if g_seasons.dms.queue.size > ssCatchingUp.LIMIT then
                self.showWarning = true
            end
        elseif g_seasons.dms.queue.size <= ssCatchingUp.LIMIT then
            -- Only stop when queue is empty for best effect
            self.showWarning = false
            self.didFfwd = false
        end
    else
        -- did not ffwd or still ffwding
        self.showWarning = false
    end

    if self.showWarning then
        -- g_currentMission:showBlinkingWarning("HALLO!!!!! DUURT LANG "..tostring(g_seasons.dms.queue.size))

        -- If no dialog, open it
        if self.dialog == nil then
            g_gui:closeAllDialogs()

            self.dialog = g_gui:showDialog("MessageDialog")
            if self.dialog ~= nil then
                self.dialog.target:setDialogType(DialogElement.TYPE_LOADING)
                self.dialog.target:setIsCloseAllowed(false)
                self.dialog.target:setText(ssLang.getText("dialog_timeTravel"))
            end
        end
    else
        -- Show no warning, so close it when it is open
        if self.dialog ~= nil then
            g_gui:closeDialog(self.dialog)

            self.dialog = nil
        end
    end
end

function ssCatchingUp:foldJobs()
    self:foldSnowJobs()

    self:foldReduceJob("ssReduceStrawHay")
    self:foldReduceJob("ssReduceGrass")
end

function ssCatchingUp:foldSnowJobs()
    local first = nil

    -- Go over all jobs
    g_seasons.dms.queue:iteratePushOrder(function (job)
        if job.callbackId ~= "ssSnowAddSnow" and job.callbackId ~= "ssSnowRemoveSnow" then return end

        -- Store first, we will update this one
        if first == nil then
            first = job
            first.layers = tonumber(job.parameter)

            if first.callbackId == "ssSnowRemoveSnow" then
                first.layers = -first.layers
            end
        else
            -- Remove all others
            local layers = tonumber(job.parameter)

            if job.callbackId == "ssSnowAddSnow" then
                first.layers = first.layers + layers
            elseif job.callbackId == "ssSnowRemoveSnow" then
                first.layers = first.layers - layers
            end

            g_seasons.dms.queue:remove(job, true)
        end
    end)

    -- Update first
    if first ~= nil then
        first.parameter = tostring(math.abs(first.layers))

        if first.layers == 0 then
            g_seasons.dms.queue:remove(first)
        elseif first.layers < 0 then
            first.callbackId = "ssSnowRemoveSnow"
        else
            first.callbackId = "ssSnowAddSnow"
        end
    end
end

function ssCatchingUp:foldReduceJob(name)
    local first = nil

    -- Go over all jobs
    g_seasons.dms.queue:iteratePushOrder(function (job)
        -- Only target correct jobs
        if job.callbackId ~= name then return end

        -- Store first, we will update this one
        if first == nil then
            first = job
            first.layers = tonumber(job.parameter)
        else
            -- Remove all others
            first.layers = first.layers + tonumber(job.parameter)

            g_seasons.dms.queue:remove(job, true)
        end
    end)

    if first ~= nil then
        first.parameter = tostring(first.layers)
    end
end
