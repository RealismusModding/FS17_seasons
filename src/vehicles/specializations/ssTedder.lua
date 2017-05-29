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

        local hx, hz, hLength, hLength_2
        local wx, wz, wLength
        local sx, sz, ex, ez, sy, ey

        -- pick up
        hx = x2 - x0
        hz = z2 - z0
        hLength = Utils.vector2Length(hx, hz)
        hLength_2 = 0.5 * hLength

        wx = x1 - x0
        wz = z1 - z0
        wLength = Utils.vector2Length(wx, wz)

        sx = x0 + (hx * 0.5) + ((wx / wLength) * hLength_2)
        sz = z0 + (hz * 0.5) + ((wz / wLength) * hLength_2)

        ex = x1 + (hx * 0.5) - ((wx / wLength) * hLength_2)
        ez = z1 + (hz * 0.5) - ((wz / wLength) * hLength_2)

        sy = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, sx, 0, sz)
        ey = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, ex, 0, ez)

        local fillType1 = FruitUtil.fruitTypeToWindrowFillType[FruitUtil.FRUITTYPE_GRASS]
        local liters1 = TipUtil.tipToGroundAroundLine(self, -math.huge, fillType1, sx, sy, sz, ex, ey, ez, hLength_2, nil, nil, false, nil)

        local fillType2 = FruitUtil.fruitTypeToWindrowFillType[FruitUtil.FRUITTYPE_DRYGRASS]
        local liters2 = TipUtil.tipToGroundAroundLine(self, -math.huge, fillType2, sx, sy, sz, ex, ey, ez, hLength_2, nil, nil, false, nil)

        local liters = -liters1 - liters2

        -- drop
        hx = dx2 - dx0
        hz = dz2 - dz0
        hLength = Utils.vector2Length(hx, hz)
        hLength_2 = 0.5 * hLength

        wx = dx1 - dx0
        wz = dz1 - dz0
        wLength = Utils.vector2Length(wx, wz)

        sx = dx0 + (hx * 0.5) + ((wx / wLength) * hLength_2)
        sz = dz0 + (hz * 0.5) + ((wz / wLength) * hLength_2)

        ex = dx1 + (hx * 0.5) - ((wx / wLength) * hLength_2)
        ez = dz1 + (hz * 0.5) - ((wz / wLength) * hLength_2)

        sy = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, sx, 0, sz)
        ey = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, ex, 0, ez)

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
