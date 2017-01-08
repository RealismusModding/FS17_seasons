---------------------------------------------------------------------------------------------------------
-- ANIMALS SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  To adjust the animals
-- Authors:  Rahkiin (Jarvixes), theSeb (added mapDir loading)
--

ssPedestrianSystem = {}

function ssPedestrianSystem:loadMap(name)
    ssSeasonsMod:addSeasonChangeListener(self)

    if g_currentMission:getIsServer() then
        -- Initial setuo (it changed from nothing)
        self:seasonChanged()
    end
end

function ssPedestrianSystem:readStream(streamId, connection)
    -- Load after data for seasonUtils is loaded
    self:seasonChanged()
end

function ssPedestrianSystem:deleteMap()
end

function ssPedestrianSystem:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssPedestrianSystem:keyEvent(unicode, sym, modifier, isDown)
end

function ssPedestrianSystem:draw()
end

function ssPedestrianSystem:update(dt)
end

function ssPedestrianSystem:seasonChanged()
    local season = ssSeasonsUtil:season()

    if season == ssSeasonsUtil.SEASON_WINTER then
        g_currentMission.pedestrianSystem:setEnabled(false)
    else
        g_currentMission.pedestrianSystem:setEnabled(true)
    end
end
