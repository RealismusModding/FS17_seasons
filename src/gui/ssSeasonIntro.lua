----------------------------------------------------------------------------------------------------
-- SEASON INTRO SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  A small display that shows information on the season at season start
-- Authors:  Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssSeasonIntro = {}
g_seasons.seasonIntro = ssSeasonIntro

function ssSeasonIntro:load(savegame, key)
    self.hideSeasonIntro = ssXMLUtil.getBool(savegame, key .. ".settings.hideSeasonIntro", false)
end

function ssSeasonIntro:save(savegame, key)
    ssXMLUtil.setBool(savegame, key .. ".settings.hideSeasonIntro", self.hideSeasonIntro)
end

function ssSeasonIntro:loadMap(name)
    g_seasons.environment:addSeasonChangeListener(self)

    self.showSeasonChanged = false
end

function ssSeasonIntro:update(dt)
    if self.showSeasonChanged == true and g_gui.currentGui == nil then
        self.showSeasonChanged = false

        self:showIntro(g_seasons.environment:currentSeason())
    end
end

function ssSeasonIntro:showIntro(season)
    function cb(self, yesNo)
        if not yesNo then
            self.hideSeasonIntro = true
        end

        g_gui:showGui("")
    end

    g_gui:showYesNoDialog({
        text = ssLang.getText(string.format("SS_SEASON_INTRO_%i", season)),
        title = ssUtil.seasonName(g_seasons.environment:currentSeason()),
        dialogType = DialogElement.TYPE_INFO,
        callback = cb,
        target = self,
        yesText = ssLang.getText("SS_BUTTON_OK"),
        noText = ssLang.getText("SS_BUTTON_DONT_SHOW_AGAIN")
    })
end

function ssSeasonIntro:readStream(streamId, connection)
    self.hideSeasonIntro = streamReadBool(streamId)
end

function ssSeasonIntro:writeStream(streamId, connection)
    streamWriteBool(streamId, self.hideSeasonIntro)
end

function ssSeasonIntro:seasonChanged()
    if self.hideSeasonIntro then return end

    self.showSeasonChanged = true
end
