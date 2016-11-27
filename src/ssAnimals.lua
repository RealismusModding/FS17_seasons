---------------------------------------------------------------------------------------------------------
-- ANIMALS SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  To adjust the animals
-- Authors:  Rahkiin (Jarvixes)
--

ssAnimals = {}

function ssAnimals:load(savegame, key)
    -- self.appliedSnowDepth = ssStorage.getXMLFloat(savegame, key .. ".animals.appliedSnowDepth", 0)
end

function ssAnimals:save(savegame, key)
    -- ssStorage.setXMLFloat(savegame, key .. ".animals.appliedSnowDepth", self.appliedSnowDepth)
end

function ssAnimals:loadMap(name)
    ssSeasonsMod:addSeasonChangeListener(self);

    --[[
    log("FILLLEVELS")
    print_r(g_currentMission.husbandries.cow.tipTriggersFillLevels)
    log("FILLTYPES")
    -- g_currentMission.husbandries.cow.tipTriggersFillLevels[FILLTYPE_DRYGRASS_WINDROW][n].tipTrigger.acceptedFillTypes
    log("POWERRR" ..tostring(g_currentMission.husbandries.cow.tipTriggersFillLevels[FillUtil.FILLTYPE_POWERFOOD][1].tipTrigger))
    print_r(g_currentMission.husbandries.sheep.tipTriggersFillLevels[FillUtil.FILLTYPE_DRYGRASS_WINDROW])
    log("POWERRR" ..tostring(g_currentMission.husbandries.cow.tipTriggersFillLevels[FillUtil.FILLTYPE_POWERFOOD][1].tipTrigger.acceptedFillTypes))
    -- print_r(g_currentMission.husbandries.cow.fillTypes)
    -- print_r(g_currentMission.husbandries.chicken.fillTypes)
    -- print_r(g_currentMission.husbandries.pig.fillTypes)
    -- print_r(g_currentMission.husbandries.sheep.fillTypes)
    log("TUPTRIGGERS")
    print_r(g_currentMission.husbandries.cow.tipTriggers)
    --]]

    -- self:disableFillType("sheep", FillUtil.FILLTYPE_DRYGRASS_WINDROW)
    -- self:disableFillType("cow", FillUtil.FILLTYPE_DRYGRASS_WINDROW)

    -- log(ssSeasonsXML:getFloat(y, ssSeasonsUtil.SEASON_SUMMER, "cow.birthRate", 1))
    -- log(ssSeasonsXML:getInt(y, ssSeasonsUtil.SEASON_SPRING, "cow.liquidManure", 1))
    -- print_r(ssSeasonsXML:getTypes(y, ssSeasonsUtil.SEASON_SUMMER))


    self:loadFromXML()
end

function ssAnimals:loadFromXML()
    local elements = {
        ["seasons"] = {},
        ["properties"] = { "straw", "food", "water", "birthRate", "milk", "manure", "liquidManure", "wool"}
    }

    self.data = ssSeasonsXML:loadFile(ssSeasonsMod.modDir .. "data/animals.xml", "animals", elements)
    -- local mapData = ssSeasonsXML:loadFile(MAPDIR .. "Seasons.xml", "modules.animals", elements, modData, true)
    -- FIXME: find the location of the map
end

function ssAnimals:deleteMap()
end

function ssAnimals:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssAnimals:keyEvent(unicode, sym, modifier, isDown)
end

function ssAnimals:draw()
end

function ssAnimals:update(dt)
end

function ssAnimals:seasonChanged()
end

-- animal: string, filltype: int
function ssAnimals:disableFillType(animal, fillType)
    local trough = g_currentMission.husbandries[animal].tipTriggersFillLevels[fillType]

    for _, p in pairs(trough) do -- Jos: not sure what p actually is.
        if p.tipTrigger.acceptedFillTypes[fillType] ~= nil then
            p.tipTrigger.acceptedFillTypes[fillType] = false
        end
    end
end

-- animal: string, filltype: int
-- Fill must be installed
function ssAnimals:enableFillType(animal, fillType)
    local trough = g_currentMission.husbandries[animal].tipTriggersFillLevels[fillType]

    for _, p in pairs(trough) do -- Jos: not sure what p actually is.
        if p.tipTrigger.acceptedFillTypes[fillType] ~= nil then
            p.tipTrigger.acceptedFillTypes[fillType] = true
        end
    end
end
