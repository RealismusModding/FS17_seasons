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
            self.showWarning = true
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
