---------------------------------------------------------------------------------------------------------
-- SEASON INTRO SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  A small display that shows information on the season at season start
-- Authors:  Rahkiin (Jarvixes)
--

ssSeasonIntro = {}

function ssSeasonIntro:load(savegame, key)
    self.hideSeasonIntro = ssStorage.getXMLBool(savegame, key .. ".settings.hideSeasonIntro", false)
end

function ssSeasonIntro:save(savegame, key)
    ssStorage.setXMLBool(savegame, key .. ".settings.hideSeasonIntro", self.hideSeasonIntro)
end

function ssSeasonIntro:loadMap(name)
    ssSeasonsMod:addSeasonChangeListener(self)
    self.showSeasonChanged = false;
end

function ssSeasonIntro:deleteMap()
end

function ssSeasonIntro:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssSeasonIntro:keyEvent(unicode, sym, modifier, isDown)
end

function ssSeasonIntro:draw()
end

function ssSeasonIntro:update(dt)
    -- check befor start if other huds are active, otherwise we wait
    if self.showSeasonChanged == true and g_gui.currentGui == nil then
        self.showSeasonChanged = false
        local text = ssLang.getText(string.format("SS_SEASON_INTRO_%i", ssSeasonsUtil:season()))
        local dialog = g_gui:showDialog("YesNoDialog")

        local season,seasonDay = ssSeasonsUtil:seasonName()
        dialog.target:setTitle(season)
        dialog.target:setText(text)
        dialog.target:setDialogType(DialogElement.TYPE_INFO)
        dialog.target:setIsCloseAllowed(true)
        dialog.target:setButtonTexts(ssLang.getText("SS_BUTTON_OK"), ssLang.getText("SS_BUTTON_DONT_SHOW_AGAIN"))

        dialog.target:setCallback(function(yesNo)
            if not yesNo then
                self.hideSeasonIntro = true
            end

            g_gui:closeDialogByName("YesNoDialog")
        end)
    end
end

function ssSeasonIntro:readStream(streamId, connection)
    self.hideSeasonIntro = streamReadBool(streamId)
end

function ssSeasonIntro:writeStream(streamId, connection)
    streamWriteBool(streamId, self.hideSeasonIntro)
end

function ssSeasonIntro:seasonChanged()
    -- it's better to do it in update function
    -- other GUIs can break the functionality, courseplay as example
    if self.hideSeasonIntro then return end
    self.showSeasonChanged = true
end
