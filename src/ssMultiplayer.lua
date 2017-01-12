---------------------------------------------------------------------------------------------------------
-- SEASON INTRO SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  A small display that shows information on the season at season start
-- Authors:  Rahkiin
--

ssMultiplayer = {}

function ssMultiplayer:loadMap(name)
    self.players = {}
    self.numPlayers = 0

    self.classes = {}
    for _, className in pairs(g_modClasses) do
        local class = _G[className]
        -- if (class.readStream ~= nil or class.writeStream ~= nil) and class.eventId ~= nil then
        if class.readStream ~= nil or class.writeStream ~= nil then
            table.insert(self.classes, className)
        end
    end
end

-- connection:sendEvent(ssMultiplayerJoinEvent:new())

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
                _G[className].writeStream(_G[className], streamId, connection)
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
            logInfo("Something totally wrong happened: client and server mod are different (1)")
            return
        end

        for _, className in pairs(ssMultiplayer.classes) do
            local className2 = streamReadString(streamId)
            if className ~= className2 then
                logInfo("Something totally wrong happened: client and server mod are different (2)")
                return
            end

            if _G[className].readStream ~= nil then
                _G[className].readStream(_G[className], streamId, connection)
            end
        end
    end
end

function ssMultiplayerJoinEvent:sendObjects(superFunc, connection, x, y, z, viewDistanceCoeff)
    connection:sendEvent(ssMultiplayerJoinEvent:new())

    return superFunc(self, connection, x, y, z, viewDistanceCoeff)
end
Server.sendObjects = Utils.overwrittenFunction(Server.sendObjects, ssMultiplayerJoinEvent.sendObjects)
