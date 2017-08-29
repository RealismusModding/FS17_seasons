----------------------------------------------------------------------------------------------------
-- ANIMALS SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  To adjust the animals
-- Authors:  baron, Rahkiin, reallogger, theSeb
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssAnimals = {}
g_seasons.animals = ssAnimals

function ssAnimals:loadMap(name)
    g_seasons.environment:addSeasonChangeListener(self)
    g_seasons.environment:addSeasonLengthChangeListener(self)

    AnimalHusbandry.getCapacity = Utils.overwrittenFunction(AnimalHusbandry.getCapacity, ssAnimals.husbandryCapacityWrapper)
    AnimalHusbandry.getHasSpaceForTipping = Utils.overwrittenFunction(AnimalHusbandry.getHasSpaceForTipping, ssAnimals.husbandryCapacityWrapper)
    AnimalHusbandry.addAnimals = Utils.appendedFunction(AnimalHusbandry.addAnimals, ssAnimals.AddAnimalsAddition)

    -- Override the i18n for threshing during rain, as it is now not allowed when moisture is too high
    -- Show the same warning when the moisture system is disabled.
    getfenv(0)["g_i18n"].texts["warning_inAdvanceFeedingLimitReached"] = ssLang.getText("warning_inAdvanceFeedingLimitReached3")

    -- Load parameters
    self:loadFromXML()

    if g_currentMission:getIsServer() then
        g_currentMission.environment:addDayChangeListener(self)
        g_currentMission.environment:addHourChangeListener(self)
    end
end

function ssAnimals:loadGameFinished()
    self.seasonLengthfactor = 6 / g_seasons.environment.daysInSeason

    self:adjustAnimals()
end

function ssAnimals:loadFromXML()
    local elements = {
        ["seasons"] = {},
        ["properties"] = { "straw", "food", "water", "birthRate", "milk", "manure", "liquidManure", "wool", "dailyUpkeep"}
    }

    self.data = ssSeasonsXML:loadFile(g_seasons.modDir .. "data/animals.xml", "animals", elements)

    -- Modded
    for _, path in ipairs(g_seasons:getModPaths("animals")) do
        self.data = ssSeasonsXML:loadFile(path, "animals", elements, self.data, true)
    end
end

function ssAnimals:load(savegame, key)
    -- Load or set default values
    self.averageProduction = {}

    for  _, husbandry in pairs(g_currentMission.husbandries) do
        local animal = husbandry.typeName
        self.averageProduction[animal] = ssXMLUtil.getFloat(savegame, key .. "." .. animal .. ".averageProduction", 0.8)
    end

end

function ssAnimals:save(savegame, key)

    for  _, husbandry in pairs(g_currentMission.husbandries) do
        local animal = husbandry.typeName
        ssXMLUtil.setFloat(savegame, key .. "." .. animal .. ".averageProduction", self.averageProduction[animal])
    end

end

function ssAnimals:seasonChanged()
    self:updateTroughs()

    self:adjustAnimals()
end

function ssAnimals:seasonLengthChanged()
    self.seasonLengthfactor = 6 / g_seasons.environment.daysInSeason

    self:adjustAnimals()
end

function ssAnimals:dayChanged()
    if g_currentMission:getIsServer() and g_currentMission.missionInfo.difficulty ~= 0 then
        local numKilled = 0
        -- percentages for base season length = 6 days
        -- kill 15% of cows if they are not fed (can live approx 4 weeks without food)
        numKilled = numKilled + self:killAnimals("cow", 0.15 * self.seasonLengthfactor * 0.5 * g_currentMission.missionInfo.difficulty)

        -- kill 10% of sheep if they are not fed (can probably live longer than cows without food)
        numKilled = numKilled + self:killAnimals("sheep", 0.1 * self.seasonLengthfactor * 0.5 * g_currentMission.missionInfo.difficulty)

        -- kill 25% of pigs if they are not fed (can live approx 2 weeks without food)
        numKilled = numKilled + self:killAnimals("pig", 0.25 * self.seasonLengthfactor * 0.5 * g_currentMission.missionInfo.difficulty)

        if numKilled > 0 then
            g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format(ssLang.getText("warning_animalsKilled"), numKilled))
        end
    end
end

function ssAnimals:hourChanged()

    AnimalHusbandry:addAnimals()
    for  _, husbandry in pairs(g_currentMission.husbandries) do
        local animal = husbandry.typeName
        local avgProd = self.averageProduction[animal]
        local currentProd = self.averageProduction[animal].productivity

        self.averageProduction[animal] = self:getAverageProductivity(avgProd, currentProd, animal)
    end
end

function ssAnimals:adjustAnimals()
    local season = g_seasons.environment:currentSeason()
    local types = ssSeasonsXML:getTypes(self.data, season)

    for _, typ in pairs(types) do
        if g_currentMission.husbandries[typ] ~= nil then
            local desc = g_currentMission.husbandries[typ].animalDesc

            desc.birthRatePerDay = ssSeasonsXML:getFloat(self.data, season, typ .. ".birthRate", 0) * self.seasonLengthfactor
            desc.foodPerDay = ssSeasonsXML:getFloat(self.data, season, typ .. ".food", 0) * self.seasonLengthfactor
            desc.liquidManurePerDay = ssSeasonsXML:getFloat(self.data, season, typ .. ".liquidManure", 0) * self.seasonLengthfactor
            desc.manurePerDay = ssSeasonsXML:getFloat(self.data, season, typ .. ".manure", 0) * self.seasonLengthfactor
            desc.milkPerDay = ssSeasonsXML:getFloat(self.data, season, typ .. ".milk", 0) * self.seasonLengthfactor
            desc.palletFillLevelPerDay = ssSeasonsXML:getFloat(self.data, season, typ .. ".wool", 0) * self.seasonLengthfactor
            desc.strawPerDay = ssSeasonsXML:getFloat(self.data, season, typ .. ".straw", 0) * self.seasonLengthfactor
            desc.waterPerDay = ssSeasonsXML:getFloat(self.data, season, typ .. ".water", 0) * self.seasonLengthfactor
            desc.dailyUpkeep = ssSeasonsXML:getFloat(self.data, season, typ .. ".dailyUpkeep", 0) * self.seasonLengthfactor
            g_currentMission.husbandries[typ].dailyUpkeep = desc.dailyUpkeep
        end
    end

    self:updateTroughs()

    -- g_server:broadcastEvent(ssAnimalsDataEvent:new(g_currentMission.husbandries))
end

function ssAnimals:updateTroughs()
    local season = g_seasons.environment:currentSeason()

    -- Load vanilla dirtification types at latest possible time
    -- to allow other mods to override them
    if self.oldSheepDirt == nil then
        self.oldSheepDirt = self:getDirtType("sheep")
        self.oldCowDirt = self:getDirtType("cow")
    end

    if season == g_seasons.environment.SEASON_WINTER then
        self:toggleFillType("sheep", FillUtil.FILLTYPE_GRASS_WINDROW, false)
        self:toggleFillType("cow", FillUtil.FILLTYPE_GRASS_WINDROW, false)

        if self.oldSheepDirt == FillUtil.FILLTYPE_GRASS_WINDROW then
            self:setDirtType("sheep", FillUtil.FILLTYPE_DRYGRASS_WINDROW)
        end

        if self.oldCowDirt == FillUtil.FILLTYPE_GRASS_WINDROW then
            self:setDirtType("cow", FillUtil.FILLTYPE_DRYGRASS_WINDROW)
        end
    else
        self:toggleFillType("sheep", FillUtil.FILLTYPE_GRASS_WINDROW, true)
        self:toggleFillType("cow", FillUtil.FILLTYPE_GRASS_WINDROW, true)

        self:setDirtType("sheep", self.oldSheepDirt)
        self:setDirtType("cow", self.oldCowDirt)
    end
end

function ssAnimals:getDirtType(animal)
    local husbandry = g_currentMission.husbandries[animal]

    if husbandry ~= nil then
        return husbandry.dirtificationFillType
    end

    return nil
end

function ssAnimals:setDirtType(animal, fillType)
    local husbandry = g_currentMission.husbandries[animal]

    if husbandry ~= nil then
        husbandry.dirtificationFillType = fillType
    end
end

-- animal: string, filltype: int, enabled: bool
-- Fill must be installed
function ssAnimals:toggleFillType(animal, fillType, enabled)
    if g_currentMission.husbandries[animal] == nil then return end

    local trough = g_currentMission.husbandries[animal].tipTriggersFillLevels[fillType]

    for _, p in pairs(trough) do -- Jos: not sure what p actually is.
        if p.tipTrigger.acceptedFillTypes[fillType] ~= nil then
            p.tipTrigger.acceptedFillTypes[fillType] = enabled
        end
    end
end

-- animal health inspection
function ssAnimals:animalIsCaredFor(animal)
    local husbandry = g_currentMission.husbandries[animal]
    local season = g_seasons.environment:currentSeason()
    local hasWater, hasFood, hasStraw = false, false, false

    for fillType, trigger in pairs(husbandry.tipTriggersFillLevels) do
        for _, trough in pairs(trigger) do
            if trough.fillLevel > 0 then
                if fillType == FillUtil.FILLTYPE_WATER then
                    hasWater = true
                elseif fillType == FillUtil.FILLTYPE_STRAW then
                    hasStraw = true
                else -- not water nor straw, assume food
                    hasFood = true
                end
            end
        end
    end

    if hasFood and hasWater then
        return true
    end

    return false
end

function ssAnimals:killAnimals(animal, p)
    local husbandry = g_currentMission.husbandries[animal]
    if husbandry == nil then return 0 end

    if not self:animalIsCaredFor(animal) then
        local killedAnimals = math.ceil(p * husbandry.totalNumAnimals)
        local tmpNumAnimals = husbandry.totalNumAnimals

        if killedAnimals > 0 then
            g_currentMission.husbandries[animal]:removeAnimals(killedAnimals, 0)

            return killedAnimals
        end
    end

    return 0
end

-- In vanilla, the trough can contain 6 days of food.
-- This is calculated using the number of animals (min of 15) and the amount of food needed per day
-- We want it to be 3 days only so we halve the food consumption, and the i18n text
function ssAnimals:husbandryCapacityWrapper(superFunc, fillType, _)
    local oldWater = self.animalDesc.waterPerDay
    local oldFood = self.animalDesc.foodPerDay
    local oldStraw = self.animalDesc.strawPerDay

    self.animalDesc.waterPerDay = oldWater / 2
    self.animalDesc.foodPerDay = oldFood / 2
    self.animalDesc.strawPerDay = oldStraw / 2

    local ret = superFunc(self, fillType, _)

    self.animalDesc.waterPerDay = oldWater
    self.animalDesc.foodPerDay = oldFood
    self.animalDesc.strawPerDay = oldStraw

    return ret
end

function ssAnimals:getAverageProductivity(avgProd, currentProd, animal)
    local seasonFac = g_seasons.environment.daysInSeason * 24 * 3
    local reductionFac = 0.1

    if currentProd < 0.75 and currentProd < avgProd then
        seasonFac = seasonFac * reductionFac
    end

    return avgProd / (seasonFac - 1) + currentProd / seasonFac
end

function ssAnimals:addAnimalProductivity(currentAnimals, addedAnimals, avgProd)
    if currentAnimals == 0 then
        return 0.8
    else
        return (avgProd * currentAnimals + 0.8 * addedAnimals) / (currentAnimals + addedAnimals)
    end
end

function ssAnimals:AddAnimalsAddition(num, subType)
    local currentAnimals = g_currentMission.husbandries[subType].totalNumAnimals

    ssAnimals.averageProduction[animal] = ssAnimals:addAnimalProductivity(currentAnimals, num, ssAnimals.averageProduction[animal])

end