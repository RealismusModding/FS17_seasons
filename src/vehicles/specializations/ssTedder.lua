----------------------------------------------------------------------------------------------------
-- TEDDER SPECIALIZATION
----------------------------------------------------------------------------------------------------
-- Applied to every Tedder in order to change some properties
-- Authors:  Rahkiin, reallogger
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssTedder = {}

function ssTedder:prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Tedder, specializations)
end

function ssTedder:load(savegame)
    self.processTedderAreas = Utils.overwrittenFunction(self.processTedderAreas, ssTedder.processTedderAreas)
end

function ssTedder:delete()
end

function ssTedder:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssTedder:keyEvent(unicode, sym, modifier, isDown)
end

function ssTedder:update(dt)
end

function ssTedder:updateTick(dt)
end

function ssTedder:draw()
end

function ssTedder:processTedderAreas(superFunc, workAreas, accumulatedWorkAreaValues)
    local numAreas = table.getn(workAreas)

    local retWorkAreas = {}
    for i = 1, numAreas do
        local x0 = workAreas[i][1]
        local z0 = workAreas[i][2]
        local x1 = workAreas[i][3]
        local z1 = workAreas[i][4]
        local x2 = workAreas[i][5]
        local z2 = workAreas[i][6]
        local dx0 = workAreas[i][7]
        local dz0 = workAreas[i][8]
        local dx1 = workAreas[i][9]
        local dz1 = workAreas[i][10]
        local dx2 = workAreas[i][11]
        local dz2 = workAreas[i][12]

        -- pick up
        local hx = x2 - x0
        local hz = z2 - z0
        local hLength = Utils.vector2Length(hx, hz)
        local hLength_2 = 0.5 * hLength

        local wx = x1 - x0
        local wz = z1 - z0
        local wLength = Utils.vector2Length(wx, wz)

        local sx = x0 + (hx * 0.5) + ((wx / wLength) * hLength_2)
        local sz = z0 + (hz * 0.5) + ((wz / wLength) * hLength_2)

        local ex = x1 + (hx * 0.5) - ((wx / wLength) * hLength_2)
        local ez = z1 + (hz * 0.5) - ((wz / wLength) * hLength_2)

        local sy = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, sx, 0, sz)
        local ey = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, ex, 0, ez)

        local fillType1 = FruitUtil.fruitTypeToWindrowFillType[FruitUtil.FRUITTYPE_GRASS]
        local liters1 = TipUtil.tipToGroundAroundLine(self, -math.huge, fillType1, sx, sy, sz, ex, ey, ez, hLength_2, nil, nil, false, nil)


        local fillType2 = FruitUtil.fruitTypeToWindrowFillType[FruitUtil.FRUITTYPE_DRYGRASS]
        local liters2 = TipUtil.tipToGroundAroundLine(self, -math.huge, fillType2, sx, sy, sz, ex, ey, ez, hLength_2, nil, nil, false, nil)

        local liters = -liters1 - liters2

        -- drop
        local hx = dx2 - dx0
        local hz = dz2 - dz0
        local hLength = Utils.vector2Length(hx, hz)
        local hLength_2 = 0.5 * hLength

        local wx = dx1 - dx0
        local wz = dz1 - dz0
        local wLength = Utils.vector2Length(wx, wz)

        local sx = dx0 + (hx * 0.5) + ((wx / wLength) * hLength_2)
        local sz = dz0 + (hz * 0.5) + ((wz / wLength) * hLength_2)

        local ex = dx1 + (hx * 0.5) - ((wx / wLength) * hLength_2)
        local ez = dz1 + (hz * 0.5) - ((wz / wLength) * hLength_2)

        local sy = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, sx, 0, sz)
        local ey = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, ex, 0, ez)

        local toDrop = accumulatedWorkAreaValues[i] + liters

        local fillType = g_seasons.weather:isCropWet() and FruitUtil.FRUITTYPE_GRASS or FruitUtil.FRUITTYPE_DRYGRASS
        local dropped, lineOffset = TipUtil.tipToGroundAroundLine(self, toDrop, FruitUtil.fruitTypeToWindrowFillType[fillType], sx, sy, sz, ex, ey, ez, hLength_2, nil, self.tedderLineOffset, false, nil, false)

        --local dropped, lineOffset = TipUtil.tipToGroundAroundLine(self, toDrop, FruitUtil.fruitTypeToWindrowFillType[FruitUtil.FRUITTYPE_DRYGRASS], sx, sy, sz, ex, ey, ez, hLength_2, nil, self.tedderLineOffset, false, nil, false)
        self.tedderLineOffset = lineOffset
        local remain = toDrop - dropped

        accumulatedWorkAreaValues[i] = remain
        workAreas[i][13] = remain

        if liters > remain then
            table.insert(retWorkAreas, workAreas[i])
        end
    end

    return retWorkAreas
end
