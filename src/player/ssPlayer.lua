----------------------------------------------------------------------------------------------------
-- ssPlayer
----------------------------------------------------------------------------------------------------
-- Purpose:  Interaction with player
-- Authors:  Wopster
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssPlayer = {}

ssPlayer.RUN_TRESHOLD = 0.4
ssPlayer.PARALLELOGRAM_SIZE = 0.01

local PARAM_GREATER = "greater"
local PARAM_EQUAL = "equal"

function ssPlayer:preLoad()
    g_seasons.player = self

    ssUtil.appendedFunction(Player, "updateTick", ssPlayer.playerUpdateTick)

    if TipUtil.getCollisionHeightAtWorldPos == nil then
        TipUtil.getCollisionHeightAtWorldPos = function (x,y,z)
            return getDensityHeightAtWorldPos(g_currentMission.terrainDetailHeightId, x, y, z)
        end
    end
end

function ssPlayer:playerUpdateTick(dt)
    local snowDepth = g_seasons.weather.snowDepth
    if self.isServer then
        snowDepth = ssSnow.appliedSnowDepth
    end

    if not g_gui:getIsGuiVisible()
            and self.isEntered
            and self.isClient
            and snowDepth >= ssSnow.LAYER_HEIGHT then
        local surfaceSound = g_currentMission.surfaceNameToSurfaceSound["snowFootsteps"]

        if surfaceSound ~= nil then
            local inSnowLayers = ssPlayer:getIsInSnowLayers(self, ssPlayer.PARALLELOGRAM_SIZE, ssPlayer.PARALLELOGRAM_SIZE)

            if inSnowLayers then
                surfaceSound.impactCount = 1

                -- delay the solid ground sounds
                local distanceDelay = math.random() * 0.2
                self.walkStepDistance = -distanceDelay
            end

            local moved = math.abs(self.movementX) > 0 or math.abs(self.movementZ) > 0
            local pitchOffset = 1 * self.walkingSpeed * dt * self.runningFactor

            if pitchOffset > ssPlayer.RUN_TRESHOLD then
                pitchOffset = pitchOffset * 25 -- increase pitch at running
            end

            ssEnvironment:playSurfaceSound(dt, surfaceSound, surfaceSound.impactCount, pitchOffset, not inSnowLayers or not moved or self.deltaWater < 0)
        end
    end

    -- Prevent player from getting stuck in a high level of snow
    if self.isControlled then
        local px, py, pz = getTranslation(self.rootNode)
        local dy, delta = TipUtil.getCollisionHeightAtWorldPos(px, py, pz)
        local heightOffset =  0.5 * self.height -- for root node origin to terrain
        if py < dy + heightOffset - 0.1 then
            py = dy + heightOffset
            setTranslation(self.rootNode, px, py, pz)
        end
    end
end

function ssPlayer:getIsInSnowLayers(player, width, length)
    local trans = { localToLocal(player.graphicsRootNode, player.rootNode, 0, 0, 0) }
    local x0, _, z0 = localToWorld(player.rootNode, trans[1] + width, trans[2], trans[3] - length)
    local x1, _, z1 = localToWorld(player.rootNode, trans[1] - width, trans[2], trans[3] - length)
    local x2, _, z2 = localToWorld(player.rootNode, trans[1] + width, trans[2], trans[3] + length)

    local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, x0, z0, x1, z1, x2, z2)

    setDensityMaskParams(g_currentMission.terrainDetailHeightId, PARAM_EQUAL, TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_SNOW]["index"])
    setDensityCompareParams(g_currentMission.terrainDetailHeightId, PARAM_GREATER, 0)

    local density, area, _ = getDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 5, 6, g_currentMission.terrainDetailHeightId, 0, 5, 0)
    local snowLayers = density / area

    setDensityMaskParams(g_currentMission.terrainDetailHeightId, PARAM_GREATER, -1)
    setDensityCompareParams(g_currentMission.terrainDetailHeightId, PARAM_GREATER, -1)

    return isNumeric(snowLayers) and snowLayers >= 1
end
