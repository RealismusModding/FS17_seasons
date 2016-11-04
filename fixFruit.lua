---------------------------------------------------------------------------------------------------------
-- FIXFRUIT SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose: To adjust fruit properties.  Currently this only modifies game time per fruit growth state.
-- Author:  Akuenzi
--

FixFruit = {};

--[[NOTE:   FixFruitStuff is a table bound by {}.  Within this table are additional tables, separated by a comma, for each fruit.
            Additional fruits may be added as shown by following the examples below, so long as each additional table added is separated by comma.
            The number following each fruit denotes the desired time in hours per growth state.]]
   
local FixFruitStuff =   {
        {"sugarBeet", 1},
        {"barley", 1},
        {"wheat", 1},
        {"rape", 1},
        {"sunflower", 1},
        {"maize", 1},
        {"oilseedRadish", 1},
        {"poplar", 1},
        {"grass", 1},
        {"dryGrass", 1},
        {"potato", 1},
        {"soybean", 1},
                        }

function FixFruit:loadMap(name) 

    -- -- To find the shortest desired fruit growth state in the table above.
    -- local min = math.huge
    -- for i = 1, table.getn(FixFruitStuff) do
    --    for k, v in pairs(FixFruitStuff[i]) do
    --        print("k: " .. k);
    --        if k == 2 then
    --            min = math.min(min, v)
    --         end;
    --     end;
    -- end;

    -- print("Now we are here")
    -- --To adjust game table's allowed minimum fruit growth state time.
    -- local updateables = g_currentMission.updateables
    -- local continue = true
    -- for k, v in pairs(updateables) do
    --    if type(k) == "table" and continue == true then
    --        if k["minFieldGrowthStateTime"] ~= nil then
    --            if (min * 60 * 60 * 1000) < k["minFieldGrowthStateTime"] then
    --                print("less than?")
    --                print("minFieldGrowthStateTime before:" .. k["minFieldGrowthStateTime"] )
    --                k["minFieldGrowthStateTime"] = min * 60 * 60 * 1000 -- To convert from hours to milliseconds
    --                print("minFieldGrowthStateTime after:" .. k["minFieldGrowthStateTime"] )
    --             end;
    --             continue = false
    --         end;
    --     end;
    -- end;
    -- print("done iterating")

    -- To update FruitUtil tables for changes to fruit growth state times.
    -- for i = 1, table.getn(FixFruitStuff) do
    --     self:FixFruitTimes(FixFruitStuff[i][1], FixFruitStuff[i][2])
    -- end;
    
   -- print("Fruittype",FruitUtil.fruitTypes["barley"].fruitType);
   -- print("FruitType Index",FruitUtil.fruitTypes["barley"].index);
    FruitUtil.setFruitTypeWindrow(FruitUtil.fruitTypes["rape"].index,30,6);
    FruitUtil.registerFruitTypeWindrowForageWagonConversion(FruitUtil.fruitTypes["rape"].index,FruitUtil.fruitTypes["wheat"].index);
    
end;

function FixFruit:deleteMap() 
end

function FixFruit:mouseEvent(posX, posY, isDown, isUp, button)
end;

function FixFruit:keyEvent(unicode, sym, modifier, isDown)
    --print(unicode);
    if (unicode == 107) then
        print_r(FruitUtil.fruitTypeGrowths); 
        print_r(FruitUtil.fruitTypes);
        print_r(FruitUtil);
        --printMinFieldTable();

    end;

end;

function FixFruit:update(dt)
        
end;

function FixFruit:draw() 
end;

function FixFruit:FixFruitTimes(fruitType, fruitTime)
    local name = fruitType
    local newTime = fruitTime * 60 * 60 * 1000 -- To convert from hours to milliseconds
    print("Old time for " .. name .. " : " .. FruitUtil.fruitTypeGrowths[name]["growthStateTime"]);
    FruitUtil.fruitTypeGrowths[name]["growthStateTime"] = newTime
    print("FruitGrowthStateTime changed for " .. name .. " to " .. newTime);
end;

--
function printMinFieldTable()
    local updateables = g_currentMission.updateables
    local continue = true
    for k, v in pairs(updateables) do
        if type(k) == "table" and continue == true then
            if k["minFieldGrowthStateTime"] ~= nil then
                --print(k["minFieldGrowthStateTime"]);
            end;
        end;
    end;
end;

--debug print table function
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