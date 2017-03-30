----------------------------------------------------------------------------------------------------
-- MULTIPLAYER JOIN EVENT
----------------------------------------------------------------------------------------------------
-- Purpose:  Event when a player joins: calls all classes for readUpdate and writeUpdate
-- Authors:  Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssMultiplayerJoinEvent = {}
ssMultiplayerJoinEvent_mt = Class(ssMultiplayerJoinEvent, Event)
InitEventClass(ssMultiplayerJoinEvent, "ssMultiplayerJoinEvent")

function ssMultiplayerJoinEvent:emptyNew()
    local self = Event:new(ssMultiplayerJoinEvent_mt)
    self.className = "ssMultiplayerJoinEvent"
    return self
end

function ssMultiplayerJoinEvent:new()
    local self = ssMultiplayerJoinEvent:emptyNew()
    -- set properties
    return self
end

-- Send data from the server to the client
function ssMultiplayerJoinEvent:writeStream(streamId, connection)
    if not connection:getIsServer() then
        -- Write number of classes, for fun really
        streamWriteInt32(streamId, table.getn(ssMultiplayer.classes))

        for _, className in pairs(ssMultiplayer.classes) do
            -- For each class, write the classname
            streamWriteString(streamId, className)

            -- Let the class write as well
            if _G[className].writeStream ~= nil then
                _G[className]:writeStream(streamId, connection)
            end
        end
    end
end

-- Read fromt he server
function ssMultiplayerJoinEvent:readStream(streamId, connection)
    if connection:getIsServer() then
        -- Read number of classes, for fun really. But match it

        local num = streamReadInt32(streamId)
        if num ~= table.getn(ssMultiplayer.classes) then
            logInfo("ssMultiplayerJoinEvent:", "Something totally wrong happened: client and server mod are different (1)")
            return
        end

        for _, className in pairs(ssMultiplayer.classes) do
            local className2 = streamReadString(streamId)
            if className ~= className2 then
                logInfo("ssMultiplayerJoinEvent:", "Something totally wrong happened: client and server mod are different (2)")
                return
            end

            if _G[className].readStream ~= nil then
                _G[className]:readStream(streamId, connection)
            end
        end
    end
end

function ssMultiplayerJoinEvent:sendObjects(superFunc, connection, x, y, z, viewDistanceCoeff)
    connection:sendEvent(ssMultiplayerJoinEvent:new())

    return superFunc(self, connection, x, y, z, viewDistanceCoeff)
end
