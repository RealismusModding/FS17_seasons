---------------------------------------------------------------------------------------------------------
-- ssFixFruit SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  To adjust fruit properties.
-- Authors:  Akuenzi, ian898, Jarvixes, theSeb
--

ssFixFruit = {};

--TODO: these values should probably be added into the ssFixFruitData table in the future, but won't bother until the animation from the back of the harvester issue is fixed
ssFixFruit.rapeWindrowLiterPerSqm = 4; -- based on the assumption that OSR produces about 0.5 of wheat which is 7 in the game and then rounded up. Not sure if this value can be a float so rounded up
ssFixFruit.soybeanWindrowLiterPerSqm = 3; -- based on the assumption that soybean produces slightly less straw than OSR
ssFixFruit.barleyWindrowLiterPerSqm = 6; -- based on the assumption that winter barley produces about 0.8 of winter wheat which is 7 in the game and then rounded up. Not sure if this value can be a float so rounded up
ssFixFruit.springBarleyWindrowLiterPerSqm = 5; -- based on the assumption that spring barley will produce a bit less straw than winter barley. TODO:implement spring barley with shorter growth cycles
ssFixFruit.springWheatWindrowLiterPerSqm = 6; -- based on the assumption that spring wheat will produce a bit less straw than winter wheat. TODO:implement spring wheat with shorter growth cycles

-- error messages
ssFixFruit.MSG_ERROR_WHEAT_WINDROW_NOT_FOUND = "Wheat windrow index could not be found. Additional swaths will not be installed."

ssFixFruit.testDay = 1;

--[[NOTE:   ssFixFruitStuff is a table bound by {}.  Within this table are additional tables, separated by a comma, for each fruit.
    Additional fruits may be added as shown by following the examples below, so long as each additional table added is separated by comma.
   The game table variables to change for each fruit are shown in each respective fruit table.]]

-- local ssFixFruitStuff =   {
--         {"sugarBeet", 1},
--         {"barley", 1},
--         {"wheat", 1},
--         {"rape", 1},
--         {"sunflower", 1},
--         {"maize", 1},
--         {"oilseedRadish", 1},
--         {"poplar", 1},
--         {"grass", 1},
--         {"dryGrass", 1},
--         {"potato", 1},
--         {"soybean", 1},
--                         }

function ssFixFruit:loadMap(name)
    --experimenting with getting mods to recognise each other
    g_currentMission.ssFixFruit = self;
    self.active = true;
    --Seb: changed variable name and appropriate camel case. variables should start with lower case letter. Changed all to 2 hours for the moment for easier debugging when checking if things are working
    local ssFixFruitData = {
        {"sugarBeet",   growthStateTime=2, minHarvestingGrowthState=9,  minForageGrowthState=9},
        {"barley",    growthStateTime=2, minHarvestingGrowthState=4,  minForageGrowthState=3},
        {"wheat",    growthStateTime=2, minHarvestingGrowthState=4,  minForageGrowthState=3},
        {"rape",    growthStateTime=2, minHarvestingGrowthState=4,  minForageGrowthState=4},
        {"sunflower",   growthStateTime=2, minHarvestingGrowthState=4,  minForageGrowthState=4},
        {"maize",    growthStateTime=2, minHarvestingGrowthState=4,  minForageGrowthState=3},
        {"oilseedRadish",  growthStateTime=2,  minHarvestingGrowthState=2,  minForageGrowthState=2},
        {"poplar",    growthStateTime=2,  minHarvestingGrowthState=4,  minForageGrowthState=4},
        {"grass",    growthStateTime=2,  minHarvestingGrowthState=2,  minForageGrowthState=2},
        {"dryGrass",   growthStateTime=2,  minHarvestingGrowthState=2,  minForageGrowthState=2},
        {"potato",    growthStateTime=2, minHarvestingGrowthState=9,  minForageGrowthState=9},
        {"soybean",   growthStateTime=2, minHarvestingGrowthState=4,  minForageGrowthState=4},
     }

    -- To update FruitUtil tables for changes to fruit growth state times.
    log("Starting to change growth")

    for _, fruitType in pairs(ssFixFruitData) do
        self:ssFixFruitTimes(fruitType[1], fruitType["growthStateTime"])
    end;

    log("ssFixFruit .. Changed growth")

    -- Seb:commeting this out for now until I understand the intentions for ssFixFruitData
    -- To update FruitUtil tables for changes to minHarvesting and minForage allowed growth states.

    --  for _, elem in pairs(ssFixFruitData) do
    --   local fruitName = "FRUITTYPE_" .. string.upper(elem[1])
    --   local fruitNumber = FruitUtil[fruitName]
    --   ModifyFruitData(elem[1], fruitNumber, elem["minHarvestingGrowthState"], "minHarvestingGrowthState")
    --   ModifyFruitData(elem[1], fruitNumber, elem["minForageGrowthState"], "minForageGrowthState")
    --  end;
    --end of new commented out code

    -- add straw to OSR and soybean
    self:AddStrawSwathsToRapeAndSoybean();

    --modify straw output for barley (winter barley)
    self:ModifyStrawSwathOutputForFruit(FruitUtil.fruitTypes["barley"].name,self.barleyWindrowLiterPerSqm)
    --Seb: is this a better (safer) way to access a fruitype name? TODO: come back to this in the future. leave commented out now
    --log("checking something: " .. FruitUtil.fruitIndexToDesc[FruitUtil.FRUITTYPE_BARLEY].name);
end;

function ssFixFruit:deleteMap()
end;

function ssFixFruit:mouseEvent(posX, posY, isDown, isUp, button)
end;

function ssFixFruit:keyEvent(unicode, sym, modifier, isDown)
    --this is to help with debugging. Pressing K will print the tables below to the log file / console.
    if (unicode == 107) then
        if(self.active == true) then
            --print_r(FruitUtil.fruitTypeGrowths);
            --print_r(FruitUtil.fruitTypes);
            --print_r(HelperUtil); just checking out this table to see if there was a way to reduce worker wages through it
            --print_r(FruitUtil);

            -- local path = getUserProfileAppPath();
            -- local file = path.."/g_currentMission2.txt";
            -- table_save(g_currentMission, file)
            -- prototyping
            -- log("Actual current day: " .. g_currentMission.environment.currentDay);
            -- local seasonNumber = self:CalculateSeasonNumberBasedOn(g_currentMission.environment.currentDay)
            -- log("Season number: " .. seasonNumber);
            -- log("Current season should be autumn. Actual: " .. self.seasons[seasonNumber]);

            -- local currentDayTest = 2;
            -- local seasonNumber = self:CalculateSeasonNumberBasedOn(currentDayTest)
            -- log("Season number: " .. seasonNumber);
            -- log("Current season should be autumn. Actual: " .. self.seasons[seasonNumber]);

            -- currentDayTest = 12;
            -- seasonNumber = self:CalculateSeasonNumberBasedOn(currentDayTest)
            -- log("Current season should be winter. Actual: " .. self.seasons[seasonNumber]);

            -- currentDayTest = 23;
            -- seasonNumber = self:CalculateSeasonNumberBasedOn(currentDayTest)
            -- log("Current season should be spring. Actual: " .. self.seasons[seasonNumber]);

            -- currentDayTest = 39;
            -- seasonNumber = self:CalculateSeasonNumberBasedOn(currentDayTest)
            -- log("Current season should be summer. Actual: " .. self.seasons[seasonNumber]);

            -- currentDayTest = 41;
            -- seasonNumber = self:CalculateSeasonNumberBasedOn(currentDayTest)

            -- log("Current season should be autumn. Actual: " .. self.seasons[seasonNumber]);

            -- currentDayTest = 51;
            -- seasonNumber = self:CalculateSeasonNumberBasedOn(currentDayTest)

            -- log("Current season should be winter. Actual: " .. self.seasons[seasonNumber]);

            --testing the display
            self.testDay = self.testDay + 1--g_currentMission.ssSeasonsUtil.daysInSeason; -- just testing the display by incrementing to the next season

            -- log("Message from weatherForecast: " .. g_currentMission.WeatherForecast.messageToOtherMod)
        end;
    end;
end;

function ssFixFruit:update(dt)
end;

function ssFixFruit:draw()
    -- TODO: absolutely awful implementation, but it's a start.
    -- Ideally this should be implemented into the hud somehow, possibly with a pretty icon to show the season. It will need to scale along with the hud scaling setting.
    setTextColor(1,1,1,1);

    if (g_currentMission.ssSeasonsUtil == nil) then
        logInfo("ssSeasonsUtil not found. Aborting")
        return;
    else
        --renderText(0.94, 0.98, 0.02, self.seasons[self:CalculateSeasonNumberBasedOn(g_currentMission.environment.currentDay)]);
        --testing (Above code works)
        local textToDisplay = "Seasons mod alpha v0.0.1 Season: " .. g_currentMission.ssSeasonsUtil:seasonName() .. " Day: " .. g_currentMission.ssSeasonsUtil:currentDayNumber() .. " (" .. g_currentMission.ssSeasonsUtil:dayName() .. ")";
        renderText(0.65, 0.98, 0.02, textToDisplay);
    end;
end;

function ssFixFruit:ssFixFruitTimes(fruitTypeName, fruitTime)
    -- Test to ensure fruit exists, and that growth time is not less than or equal to zero.

    if FruitUtil.fruitTypeGrowths[fruitTypeName] == nil or fruitTime <=0 then
        return;
    end;

    local newTime = fruitTime * 60 * 60 * 1000 -- To convert from hours to milliseconds
        FruitUtil.fruitTypeGrowths[fruitTypeName]["growthStateTime"] = newTime
         log("FruitGrowthStateTime changed for ".. fruitTypeName .. " to " .. newTime); --changed , to .. as it does not include a new line so it's easier to read in the log
end;

--Seb: Commenting this entire function out since I am not sure what the intention is here currently.
--Is there an else missing after return?

-- function ModifyFruitData(fruitName, fruitNumber, fruitData, fruitAttribute)
-- -- Test to ensure fruit exists, and that state changes are (somewhat) valid.
--     if FruitUtil.fruitIndexToDesc[fruitNumber] == nil or -- Does the fruit exist?
-- (fruitData < 1 or fruitData > FruitUtil.fruitTypeGrowths[fruitName]["numGrowthStates"]) then -- Is changed state 0 or less, or greater than the number of total fruit states?

--     return;
-- end;

-- FruitUtil.fruitIndexToDesc[fruitNumber][fruitAttribute] = fruitData
-- -- log("Fruit Attribute Changed: ", fruitAttribute, ", Hours: ", fruitData)
--     end;
-- end;

--trying to get info out of updateables but not very successfully so commented out for now
-- function printMinFieldTable()
--     local updateables = g_currentMission.updateables
--     local continue = true
--     for k, v in pairs(updateables) do
--         if type(k) == "table" and continue == true then
--             if k["minFieldGrowthStateTime"] ~= nil then
--                 --print(k["minFieldGrowthStateTime"]);
--             end;
--         end;
--     end;
-- end;

--experimenting with adding a swath to rape and soybean
--TODO: modify function to add swaths to any crop.
function ssFixFruit:AddStrawSwathsToRapeAndSoybean()
    --log("Looking up WIndrow fill type 30 expected. Actual: " .. FruitUtil.fruitTypeToWindrowFillType[FruitUtil.fruitTypes["wheat"].index]);

    --first we look up the windrow type for wheat
    local wheatWindrowFillType = FruitUtil.fruitTypeToWindrowFillType[FruitUtil.FRUITTYPE_WHEAT]
    log("Looking up windrow fill type 30 expected. Actual: " .. wheatWindrowFillType);
    --BUG: This adds straw, but animation of the straw coming out from the back of the combine is missing. The straw swaths appear on the ground. Is this as simple as the fact that there is no appropriate texture/particle emitter for this in the game?
    if wheatWindrowFillType ~= nil then
        --rape first
        -- old code FruitUtil.setFruitTypeWindrow(FruitUtil.fruitTypes["rape"].index,wheatWindrowFillType,self.rapeWindrowLiterPerSqm);
        FruitUtil.setFruitTypeWindrow(FruitUtil.FRUITTYPE_RAPE, wheatWindrowFillType, self.rapeWindrowLiterPerSqm);
        --Seb: not entirely sure if this is required or not, but I've noticed that barley uses wheat's straw type and it does have a forage conversion in a dump of FruitUtil.fruitTypes
        --FruitUtil.registerFruitTypeWindrowForageWagonConversion(FruitUtil.fruitTypes["rape"].index,FruitUtil.fruitTypes["wheat"].index);
        FruitUtil.registerFruitTypeWindrowForageWagonConversion(FruitUtil.FRUITTYPE_RAPE, FruitUtil.FRUITTYPE_WHEAT);

        --now soybean
        FruitUtil.setFruitTypeWindrow(FruitUtil.FRUITTYPE_SOYBEAN, wheatWindrowFillType, self.soybeanWindrowLiterPerSqm);
        --Seb: not entirely sure if this is required or not, but I've noticed that barley uses wheat's straw type and it does have a forage conversion in a dump of FruitUtil.fruitTypes
        FruitUtil.registerFruitTypeWindrowForageWagonConversion(FruitUtil.FRUITTYPE_SOYBEAN, FruitUtil.FRUITTYPE_WHEAT);
        log("Done adding swaths");
    else
        log(self.MSG_ERROR_WHEAT_WINDROW_NOT_FOUND);
    end;
end;

-- modify straw swath output for a given fruit to a new value. paramters fruitTypeName, newSwathouput in litres per sqm
function ssFixFruit:ModifyStrawSwathOutputForFruit(fruitTypeName,newSwathOutput)
    if FruitUtil.fruitTypes[fruitTypeName].windrowLiterPerSqm ~= nil then
        log(fruitTypeName .. "'s old swath value:  " .. FruitUtil.fruitTypes[fruitTypeName].windrowLiterPerSqm);
        FruitUtil.fruitTypes[fruitTypeName].windrowLiterPerSqm = newSwathOutput;
        log(fruitTypeName .. "'s swath value changed to: " .. newSwathOutput);
    else
        log("Trying to modify swath for a fruit that does not have a swath:" .. fruitTypeName);
    end;
end;

addModEventListener(ssFixFruit);
