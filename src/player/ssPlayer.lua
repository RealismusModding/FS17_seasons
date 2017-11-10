ssPlayer = {}

ssPlayer.RUN_TRESHOLD = 0.4
ssPlayer.PARALLELOGRAM_SIZE = 0.01

function ssPlayer:preLoad()
    Player.updateTick = Utils.appendedFunction(Player.updateTick, ssPlayer.updateTick)
end

function ssPlayer:updateTick(dt)
    if self.isEntered and self.isClient and not g_gui:getIsGuiVisible() then
        local surfaceSound = g_currentMission.surfaceNameToSurfaceSound["snowFootsteps"]

        if surfaceSound ~= nil then
            local inSnowLayers = ssPlayer:getIsInSnowLayers(self, ssPlayer.PARALLELOGRAM_SIZE, ssPlayer.PARALLELOGRAM_SIZE)

            surfaceSound.impactCount = 1

            local moved = math.abs(self.movementX) > 0 or math.abs(self.movementZ) > 0
            local pitchOffset = 1 * self.walkingSpeed * dt * self.runningFactor

            if pitchOffset > ssPlayer.RUN_TRESHOLD then
                pitchOffset = pitchOffset * 25 -- increase pitch at running
            end

            ssEnvironment:playSurfaceSound(dt, surfaceSound, 1, pitchOffset, not inSnowLayers or not moved or self.deltaWater < 0)
        end
    end
end

function ssPlayer:getIsInSnowLayers(player, width, length)
    local trans = { localToLocal(player.graphicsRootNode, player.rootNode, 0, 0, 0) }
    local x0, _, z0 = localToWorld(player.rootNode, trans[1] + width, trans[2], trans[3] - length)
    local x1, _, z1 = localToWorld(player.rootNode, trans[1] - width, trans[2], trans[3] - length)
    local x2, _, z2 = localToWorld(player.rootNode, trans[1] + width, trans[2], trans[3] + length)

    local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(g_currentMission.terrainDetailHeightId, x0, z0, x1, z1, x2, z2)

    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "equals", TipUtil.fillTypeToHeightType[FillUtil.FILLTYPE_SNOW]["index"])
    setDensityCompareParams(g_currentMission.terrainDetailHeightId, "greater", 0)

    local density, area, _ = getDensityMaskedParallelogram(g_currentMission.terrainDetailHeightId, x, z, widthX, widthZ, heightX, heightZ, 5, 6, g_currentMission.terrainDetailHeightId, 0, 5, 0)
    local snowLayers = density / area

    setDensityMaskParams(g_currentMission.terrainDetailHeightId, "greater", -1)
    setDensityCompareParams(g_currentMission.terrainDetailHeightId, "greater", -1)

    return snowLayers > 1
end
