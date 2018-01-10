----------------------------------------------------------------------------------------------------
-- DEBUG SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  Debug tools
-- Authors:  Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssDebug = {}

function ssDebug:loadMap(name)
    self.enabled = false
end

function ssDebug:keyEvent(unicode, sym, modifier, isDown)
    if not isDown and sym == Input.KEY_d and modifier == Input.MOD_LALT then
        self:setEnabled(not self.enabled)
    end
end

function ssDebug:hourChanged()
    if self.minuteCount < 60 then
        -- For every minute not having a minute callback, add an extra callback
        for i = 1, 60 - self.minuteCount, 1 do
            for _, listener in pairs(g_currentMission.environment.minuteChangeListeners) do
                listener:minuteChanged()
            end
        end
    end

    self.minuteCount = 0
end

function ssDebug:minuteChanged()
    self.minuteCount = self.minuteCount + 1
end

function ssDebug:setEnabled(enabled)
    if self.enabled == enabled then return end

    self.enabled = enabled

    if self.enabled then
        self.minuteCount = g_currentMission.environment.currentMinute

        g_currentMission.environment:addMinuteChangeListener(self)
        g_currentMission.environment:addHourChangeListener(self)

        self.oldTimeScale = g_currentMission.missionInfo.timeScale
        g_currentMission:setTimeScale(6000)
    else
        g_currentMission.environment:removeMinuteChangeListener(self)
        g_currentMission.environment:removeHourChangeListener(self)

        g_currentMission:setTimeScale(self.oldTimeScale)
    end
end

function ssDebug:drawDensityParallelogram(x, z, wX, wZ, hX, hZ, offsetY, r, g, b)
    local node = g_currentMission.terrainRootNode

    drawDebugLine(  x,          getTerrainHeightAtWorldPos(node, x     ,        0, z            ) + offsetY, z          , r, g, b,
                    x + wX,     getTerrainHeightAtWorldPos(node, x + wX,        0, z + wZ       ) + offsetY, z + wZ     , r, g, b)
    drawDebugLine(  x,          getTerrainHeightAtWorldPos(node, x     ,        0, z            ) + offsetY, z          , r, g, b,
                    x + hX,     getTerrainHeightAtWorldPos(node, x + hX,        0, z + hZ       ) + offsetY, z + hZ     , r, g, b)

    drawDebugLine(  x + wX + hX,getTerrainHeightAtWorldPos(node, x + wX + hX,   0, z + wZ + hZ  ) + offsetY, z + wZ + hZ, r, g, b,
                    x + wX,     getTerrainHeightAtWorldPos(node, x + wX,        0, z + wZ       ) + offsetY, z + wZ     , r, g, b)
    drawDebugLine(  x + wX + hX,getTerrainHeightAtWorldPos(node, x + wX + hX,   0, z + wZ + hZ  ) + offsetY, z + wZ + hZ, r, g, b,
                    x + hX,     getTerrainHeightAtWorldPos(node, x + hX,        0, z + hZ       ) + offsetY, z + hZ     , r, g, b)
end
