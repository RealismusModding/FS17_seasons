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

    
    -- To update FruitUtil tables for changes to fruit growth state times.
    for i = 1, table.getn(FixFruitStuff) do
        self:FixFruitTimes(FixFruitStuff[i][1], FixFruitStuff[i][2])
    end;
     
    
end;

function FixFruit:deleteMap() 
end

function FixFruit:mouseEvent(posX, posY, isDown, isUp, button)
end;

function FixFruit:keyEvent(unicode, sym, modifier, isDown)
end;

function FixFruit:update(dt)
        
end;

function FixFruit:draw() 
end;

function FixFruit:FixFruitTimes(fruitType, fruitTime)
    local name = fruitType
    local newTime = fruitTime * 60 * 60 * 1000 -- To convert from hours to milliseconds
    --print("Old time for " .. name .. " : " .. FruitUtil.fruitTypeGrowths[name]["growthStateTime"]);
    FruitUtil.fruitTypeGrowths[name]["growthStateTime"] = newTime
    --print("FruitGrowthStateTime changed for " .. name .. " to " .. newTime);
end;