---------------------------------------------------------------------------------------------------------
-- ANIMALS SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  To adjust the animals
-- Authors:  Rahkiin, theSeb (added mapDir loading)
--

ssAnimals = {}
g_seasons.animals = ssAnimals

function ssAnimals:loadMap(name)
    g_seasons.environment:addSeasonChangeListener(self)
    g_seasons.environment:addSeasonLengthChangeListener(self)

    -- Load parameters
    self:loadFromXML()

    if g_currentMission:getIsServer() then
        -- Initial setuo (it changed from nothing)
        self:seasonChanged()
    end
end

function ssAnimals:loadFromXML()
    local elements = {
        ["seasons"] = {},
        ["properties"] = { "straw", "food", "water", "birthRate", "milk", "manure", "liquidManure", "wool"}
    }

    self.data = ssSeasonsXML:loadFile(g_seasons.modDir .. "data/animals.xml", "animals", elements)

    local modPath = ssUtil.getModMapDataPath("seasons_animals.xml")
    if modPath ~= nil then
  	    self.data = ssSeasonsXML:loadFile(modPath, "animals", elements, self.data, true)
    end
end

function ssAnimals:readStream(streamId, connection)
    -- Load after data for seasonUtils is loaded
    self:seasonChanged()
end

function ssAnimals:seasonChanged()
    local season = g_seasons.environment:currentSeason()
    local types = ssSeasonsXML:getTypes(self.data, season)

    for _, typ in pairs(types) do
        if g_currentMission.husbandries[typ] ~= nil then
            local desc = g_currentMission.husbandries[typ].animalDesc

            local birthRatePerDay = ssSeasonsXML:getFloat(self.data, season, typ .. ".birthRate", 0) / g_seasons.environment.daysInSeason
            if birthRatePerDay ~= 0 then
                desc.birthRatePerDay = math.max(birthRatePerDay,1/(2*g_seasons.environment.daysInSeason))
            else
                desc.birthRatePerDay = 0
            end

            desc.foodPerDay = ssSeasonsXML:getFloat(self.data, season, typ .. ".food", 0)
            desc.liquidManurePerDay = ssSeasonsXML:getFloat(self.data, season, typ .. ".liquidManure", 0)
            desc.manurePerDay = ssSeasonsXML:getFloat(self.data, season, typ .. ".manure", 0)
            desc.milkPerDay = ssSeasonsXML:getFloat(self.data, season, typ .. ".milk", 0)
            desc.palletFillLevelPerDay = ssSeasonsXML:getFloat(self.data, season, typ .. ".wool", 0)
            desc.strawPerDay = ssSeasonsXML:getFloat(self.data, season, typ .. ".straw", 0)
            desc.waterPerDay = ssSeasonsXML:getFloat(self.data, season, typ .. ".water", 0)
        end
    end

    if season == g_seasons.environment.SEASON_WINTER then
        self:toggleFillType("sheep", FillUtil.FILLTYPE_GRASS_WINDROW, false)
        self:toggleFillType("cow", FillUtil.FILLTYPE_GRASS_WINDROW, false)
    else
        self:toggleFillType("sheep", FillUtil.FILLTYPE_GRASS_WINDROW, true)
        self:toggleFillType("cow", FillUtil.FILLTYPE_GRASS_WINDROW, true)
    end

    -- FIXME send event to clients that stuff has changed
    -- broadcast event
end

function ssAnimals:seasonLengthChanged()
    -- Recalculate all values
    self:seasonChanged()
end

-- animal: string, filltype: int, enabled: bool
-- Fill must be installed
function ssAnimals:toggleFillType(animal, fillType, enabled)
    local trough = g_currentMission.husbandries[animal].tipTriggersFillLevels[fillType]

    for _, p in pairs(trough) do -- Jos: not sure what p actually is.
        if p.tipTrigger.acceptedFillTypes[fillType] ~= nil then
            p.tipTrigger.acceptedFillTypes[fillType] = enabled
        end
    end
end
