---------------------------------------------------------------------------------------------------------
-- SEASON INTRO SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  A small display that shows information on the season at season start
-- Authors:  Rahkiin (Jarvixes)
--

ssSeasonIntro = {}

ssSeasonIntro.hideSeasonIntro = false
ssSeasonIntro.settingsProperties = { "hideSeasonIntro" }


function ssSeasonIntro.preSetup()
    ssSettings.add("seasons", ssSeasonIntro)
end

function ssSeasonIntro.setup()
    ssSettings.load("seasons", ssSeasonIntro)

    addModEventListener(ssSeasonIntro)
end

function ssSeasonIntro:loadMap(name)
    ssSeasonsMod:addSeasonChangeListener(self);
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
end

function ssSeasonIntro:seasonChanged(season)
    if ssSeasonIntro.hideSeasonIntro then return end

    local text = ssLang.getText(string.format("SS_SEASON_INTRO_%i", season))
    local dialog = g_gui:showDialog("YesNoDialog")

    dialog.target:setTitle(ssSeasonsUtil:seasonName())
    dialog.target:setText(text)
    dialog.target:setDialogType(DialogElement.TYPE_INFO)
    dialog.target:setIsCloseAllowed(true)
    dialog.target:setButtonTexts("OK", "Don't show again")

    dialog.target:setCallback(function(yesNo)
        if not yesNo then
            ssSeasonIntro.hideSeasonIntro = true
            ssSettings.set("seasons", "hideSeasonIntro", ssSeasonIntro.hideSeasonIntro)
        end

        g_gui:closeDialogByName("YesNoDialog")
    end)
end
