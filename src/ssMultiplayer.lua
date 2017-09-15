----------------------------------------------------------------------------------------------------
-- SEASON INTRO SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  A small display that shows information on the season at season start
-- Authors:  Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssMultiplayer = {}

source(g_currentModDirectory .. "src/events/ssMultiplayerJoinEvent.lua")

function ssMultiplayer:preLoad()
    Server.sendObjects = Utils.prependedFunction(Server.sendObjects, ssMultiplayerJoinEvent.sendObjects)
end

function ssMultiplayer:loadMap(name)
    self.players = {}

    self.classes = {}
    for _, className in ipairs(g_modClasses) do
        local class = _G[className]

        if class.loadMap ~= nil and (class.readStream ~= nil or class.writeStream ~= nil or class.loadGameFinished ~= nil) then
            table.insert(self.classes, className)
        end
    end
end
