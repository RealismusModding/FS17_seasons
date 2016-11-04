---------------------------------------------------------------------------------------------------------
-- FIXFRUIT SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose: To adjust fruit properties.  
-- Authors:  Akuenzi, theSeb
--

FixFruit = {};

--do not use print. use self:debugPrint() instead, unless we want the message to be displayed in a release version
FixFruit.debugLevel = 1 -- 0 if you don't want to see debugging messages in the log file / console. 1 to switch on debug statements


--[[NOTE:   FixFruitStuff is a table bound by {}.  Within this table are additional tables, separated by a comma, for each fruit.
    Additional fruits may be added as shown by following the examples below, so long as each additional table added is separated by comma.
   The game table variables to change for each fruit are shown in each respective fruit table.]]
   
-- local FixFruitStuff =   {
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

function FixFruit:loadMap(name) 

    --Seb: changed variable name and appropriate camel case. variables should start with lower case letter
    local fixFruitData = {
   {"sugarBeet",   growthStateTime=6.7, minHarvestingGrowthState=9,  minForageGrowthState=9},
   {"barley",    growthStateTime=6.7, minHarvestingGrowthState=4,  minForageGrowthState=3},
   {"wheat",    growthStateTime=6.7, minHarvestingGrowthState=4,  minForageGrowthState=3},
   {"rape",    growthStateTime=6.7, minHarvestingGrowthState=4,  minForageGrowthState=4},
   {"sunflower",   growthStateTime=6.7, minHarvestingGrowthState=4,  minForageGrowthState=4},
   {"maize",    growthStateTime=6.7, minHarvestingGrowthState=4,  minForageGrowthState=3},
   {"oilseedRadish",  growthStateTime=10,  minHarvestingGrowthState=2,  minForageGrowthState=2},
   {"poplar",    growthStateTime=20,  minHarvestingGrowthState=4,  minForageGrowthState=4},
   {"grass",    growthStateTime=10,  minHarvestingGrowthState=2,  minForageGrowthState=2},
   {"dryGrass",   growthStateTime=10,  minHarvestingGrowthState=2,  minForageGrowthState=2},
   {"potato",    growthStateTime=6.7, minHarvestingGrowthState=9,  minForageGrowthState=9},
   {"soybean",   growthStateTime=6.7, minHarvestingGrowthState=4,  minForageGrowthState=4},
     }

    -- To update FruitUtil tables for changes to fruit growth state times.
    self:debugPrint("Starting to change growth")
    
    for _, fruitType in pairs(fixFruitData) do
        self:FixFruitTimes(fruitType[1], fruitType["growthStateTime"])
    end;
 
    self:debugPrint("Changed growth")

    -- Seb:commeting this out for now until I understand the intentions for FixFruitData
    -- To update FruitUtil tables for changes to minHarvesting and minForage allowed growth states.
    
    --  for _, elem in pairs(fixFruitData) do
    --   local fruitName = "FRUITTYPE_" .. string.upper(elem[1])
    --   local fruitNumber = FruitUtil[fruitName]
    --   ModifyFruitData(elem[1], fruitNumber, elem["minHarvestingGrowthState"], "minHarvestingGrowthState")
    --   ModifyFruitData(elem[1], fruitNumber, elem["minForageGrowthState"], "minForageGrowthState")
    --  end;
    --end of new commented out code

    --Old code to be removed later
    -- To update FruitUtil tables for changes to fruit growth state times.
    -- for i = 1, table.getn(FixFruitStuff) do
    --     self:FixFruitTimes(FixFruitStuff[i][1], FixFruitStuff[i][2])
    -- end;
    
    -- print("Fruittype",FruitUtil.fruitTypes["barley"].fruitType);
    -- print("FruitType Index",FruitUtil.fruitTypes["barley"].index);
    -- end of old code

    --experimenting with adding a swath to rape
    --TODO: fix magic values. 30 is the swath type for wheat. Need to get that out properly from FruitUtil. 6 is the ouput of swath 
    -- or windrowLiterPerSqm as the game defines it. 7 is the default number for wheat and barley in the base game. I have set canola to 6
    -- because it makes sense to have less, but will need to check these values with someone that knows more about farming
    FruitUtil.setFruitTypeWindrow(FruitUtil.fruitTypes["rape"].index,30,6);
    --Seb: not entirely sure if this is required or not, but I've noticed that barley uses wheat's straw type and it does have a forage conversion in a dump of FruitUtil.fruitTypes  
    FruitUtil.registerFruitTypeWindrowForageWagonConversion(FruitUtil.fruitTypes["rape"].index,FruitUtil.fruitTypes["wheat"].index);
end;

function FixFruit:deleteMap() 
end

function FixFruit:mouseEvent(posX, posY, isDown, isUp, button)
end;

function FixFruit:keyEvent(unicode, sym, modifier, isDown)
    --this is to help with debugging. Pressing K will print the tables below to the log file / console. 
    if (unicode == 107) then
        print_r(FruitUtil.fruitTypeGrowths); 
        print_r(FruitUtil.fruitTypes);
        --print_r(FruitUtil);
    end;
end;

function FixFruit:update(dt)
end;

function FixFruit:draw() 
end;

-- Seb:I have modified this to be a member of the FixFruit class hence FixFruit: in front. To call self:FixFruitTimes(). global functions are bad. not that it makes a huge difference in FS, but hey ho, let's stick to good practices. 
function FixFruit:FixFruitTimes(fruitType, fruitTime)
    
    -- old code
    -- local name = fruitType
    -- local newTime = fruitTime * 60 * 60 * 1000 -- To convert from hours to milliseconds
    -- print("Old time for " .. name .. " : " .. FruitUtil.fruitTypeGrowths[name]["growthStateTime"]);
    -- FruitUtil.fruitTypeGrowths[name]["growthStateTime"] = newTime
    -- print("FruitGrowthStateTime changed for " .. name .. " to " .. newTime);
    -- end of old code
    
    -- Test to ensure fruit exists, and that growth time is not less than or equal to zero.
    
    if FruitUtil.fruitTypeGrowths[fruitType] == nil or fruitTime <=0 then
        return;
    end;
 
    local newTime = fruitTime * 60 * 60 * 1000 -- To convert from hours to milliseconds
        FruitUtil.fruitTypeGrowths[fruitType]["growthStateTime"] = newTime
         self:debugPrint("FruitGrowthStateTime changed for ".. fruitType .. " to " .. newTime); --changed , to .. as it does not include a new line so it's easier to read in the log
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
    -- -- self:debugPrint("Fruit Attribute Changed: ", fruitAttribute, ", Hours: ", fruitData)
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


function FixFruit:debugPrint(message)
    if self.debugLevel == 1 then
        print(message)
    end;
end;

--debug print table function. will be removed later
function print_r ( t )  
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
    print()
end;

addModEventListener(FixFruit);