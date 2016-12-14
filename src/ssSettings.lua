---------------------------------------------------------------------------------------------------------
-- SETTINGS SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  Settings GUI
-- Authors:  Rahkiin (Jarvixes)
--

ssSettings = {}

function ssSettings:load(savegame, key)
    -- self.appliedSnowDepth = ssStorage.getXMLInt(savegame, key .. ".weather.appliedSnowDepth", 0) * self.LAYER_HEIGHT
end

function ssSettings:save(savegame, key)
    -- ssStorage.setXMLInt(savegame, key .. ".weather.appliedSnowDepth", self.appliedSnowDepth / self.LAYER_HEIGHT)
end

function ssSettings:loadMap(name)
    --[[
    g_inGameMenu.alpha = 0.5
    g_inGameMenu.debugEnabled = true

    g_inGameMenu.plantWitheringElement:setDisabled(true)
    g_inGameMenu.plantGrowthRateElement:setDisabled(true)



    local xxx = InGameMenu.onCreate
    InGameMenu.onCreate = function (...)
        log("onCreate()")
        return xxx(...)
    end

    local yyy = InGameMenu.onOpen
    InGameMenu.onOpen = function (...)
        log("OnOpen()")
        return yyy(...)
    end

    InGameMenu.onCreatePlantWithering = function ()
        log("CreateW!")
    end

    InGameMenu.onCreatePlantGrowthRate = function ()
        log("CreateR!")
    end

    -- OnInGameMenuMenu(function (...)
    --     log("OnIngameMenu")
    -- end)

    log(tostring(table.getn(g_inGameMenu.elements)))
    for i, elem in pairs(g_inGameMenu.elements) do
        if elem == g_inGameMenu.plantGrowthRateElement or elem == g_inGameMenu.plantWitheringElement then
            log("Found the element")
            g_inGameMenu.elements[i] = nil
            -- table.remove(g_inGameMenu.elements, i)
            break
        end
    end
]]
--[[
InGameMenu.getAnimalData(...)
InGameMenu.loadHelpLine(...)
InGameMenu.onAdminLoginSuccess(...)
InGameMenu.onAdminPassword(...)

InGameMenu.onClickActivate(...) -- for each button

InGameMenu.onCreate(...)
InGameMenu.onCreateIsTrainTabbable(...)

InGameMenu.onCreatePageGameSettingsGame(...)
InGameMenu.onCreatePageGameSettingsGeneral(...)
InGameMenu.onCreatePageMultiplayerSettings(...)

InGameMenu.onCreatePlantGrowthRate(...)
InGameMenu.onCreatePlantWithering(...)

InGameMenu.PAGE_GAME_SETTINGS_GAME
InGameMenu.PAGE_GAME_SETTINGS_GENERAL
InGameMenu.PAGE_GAME_STATISTICS
InGameMenu.PAGE_MULTIPLAYER_LOGIN
InGameMenu.PAGE_MULTIPLAYER_SETTINGS
InGameMenu.PAGE_MULTIPLAYER_USERS

InGameMenu.saveCurrentGame(...)
InGameMenu.saveMpSettings(...)

g_inGameMenu.elements[]

 g_inGameMenu.plantGrowthRateElement[]
 g_inGameMenu.plantWitheringElement[]
]]
end

function ssSettings:deleteMap()
end

function ssSettings:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssSettings:keyEvent(unicode, sym, modifier, isDown)
end

function ssSettings:draw()
end

function ssSettings:update(dt)
end
