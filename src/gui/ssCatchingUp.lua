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
ssCatchingUp.FFWD = 120

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
        if g_seasons.dms.queue.size > ssCatchingUp.LIMIT then
            self.showWarning = true

            self:foldJobs()
        else
            -- Already below limit, reset the catchUp
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
                self.dialog.target:setText("The game is catching up " .. tostring(g_seasons.dms.queue.size))
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
    -- Go over all jobs

    -- If job has name with snow
        -- if first == nil
            -- first = job
            -- first.layers = tonumber(job.param)
            -- if name == remove then first.layers = -first.layers
        -- else
            -- layers = tonumber(job.param)
            -- if name == add then first.layers = first.layers + layers
            -- if name == remove then first.layers = first.layers - layers
            -- remove(job)

    -- if first.layers < 0 then first.name = remove else first.name = add
end

function ssCatchingUp:foldReduceJob(name)
    -- Go over all jobs

    -- If job has name = name
        -- if first == nil
            -- first = job
            -- first.layers = tonumber(job.param)
        -- else
            -- first.layers = first.layers + tonumber(job.param)
            -- remove(job)
    -- end
end
