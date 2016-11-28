---------------------------------------------------------------------------------------------------------
-- SEASON INTRO SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  A small display that shows information on the season at season start
-- Authors:  Rahkiin (Jarvixes)
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

function ssMultiplayer:deleteMap()
end

function ssMultiplayer:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssMultiplayer:keyEvent(unicode, sym, modifier, isDown)
end

function ssMultiplayer:draw()
end

function ssMultiplayer:update(dt)
    if not g_currentMission:getIsServer() then return end

    if g_currentMission.missionDynamicInfo.isMultiplayer then
        local numPlayers = table.getn(g_currentMission.users)

        if numPlayers ~= self.numPlayers then
            self.numPlayers = numPlayers

            -- Figure out what player is missing
            print_r(g_currentMission.users)

            -- SEND EVENT
            log("New Player Joined!")
        end
    end
end

function ssMultiplayer:readStream(streamId, connection)
end

function ssMultiplayer:writeStream(streamId, connection)
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
            _G[className].writeStream(_G[className], streamId, connection)
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

            _G[className].readStream(_G[className], streamId, connection)
        end
    end
end

function ssMultiplayerJoinEvent:sendObjects(superFunc, connection, x, y, z, viewDistanceCoeff)
    log("Send Objects!")

    connection:sendEvent(ssMultiplayerJoinEvent:new());

    return superFunc(self, connection, x, y, z, viewDistanceCoeff);
end
Server.sendObjects = Utils.overwrittenFunction(Server.sendObjects, ssMultiplayerJoinEvent.sendObjects)
