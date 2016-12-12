---------------------------------------------------------------------------------------------------------
-- GROWTH MANAGER SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  to manage growth as the season changes
-- Authors:  theSeb
-- Credits: Inspired by upsidedown's growth manager mod

ssGrowthManager = {}

MAX_GROWTH_STATE = 99; -- needs to be set to the fruit's numGrowthStates if you are setting, or numGrowthStates-1 if you're incrementing
WITHER_STATE = 100;
FIRST_LOAD_TRANSITION = 999;

function Set (list)
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end

ssGrowthManager.defaultFruits = {};--TODO: uncomment this Set {"barley","wheat","rape","maize","soybean","sunflower","potato","sugarBeet","poplar","grass","oilseedRadish","dryGrass"};

ssGrowthManager.growthData = { 	[1]={ 				
						["barley"]			={fruitName="barley", normalGrowthState=1, normalGrowthMaxState=3},
						["wheat"]			={fruitName="wheat", normalGrowthState=1, normalGrowthMaxState=3},					
						["rape"]			={fruitName="rape", normalGrowthState=1, normalGrowthMaxState=3},
						["maize"]			={fruitName="maize", normalGrowthState=1},
						["soybean"]			={fruitName="soybean", setGrowthState=1,desiredGrowthState=WITHER_STATE},
						["sunflower"]		={fruitName="sunflower", setGrowthState=1,desiredGrowthState=WITHER_STATE},
						["potato"]			={fruitName="potato", normalGrowthState=1},
						["sugarBeet"]		={fruitName="sugarBeet", normalGrowthState=1},
						["poplar"]			={fruitName="poplar", normalGrowthState=1, normalGrowthMaxState=MAX_GROWTH_STATE},
						["grass"]			={fruitName="grass", normalGrowthState=1, normalGrowthMaxState=MAX_GROWTH_STATE},
                        ["oilseedRadish"]	={fruitName="oilseedRadish", normalGrowthState=1, normalGrowthMaxState=MAX_GROWTH_STATE},
						["default"]			={fruitName="default", normalGrowthState=1, normalGrowthMaxState=3},					
				}, 
				
				[2]={ 	["barley"]			={fruitName="barley", normalGrowthState=1, normalGrowthMaxState=3},
						["wheat"]			={fruitName="wheat", normalGrowthState=1, normalGrowthMaxState=3},
						["rape"]			={fruitName="rape", normalGrowthState=1, normalGrowthMaxState=3},
						["maize"]			={fruitName="maize", normalGrowthState=1, normalGrowthMaxState=2},
						["soybean"]			={fruitName="soybean", normalGrowthState=1},
						["sunflower"]		={fruitName="sunflower", normalGrowthState=1},
						["potato"]			={fruitName="potato", normalGrowthState=1, normalGrowthMaxState=2},
						["sugarBeet"]		={fruitName="sugarBeet", normalGrowthState=1, normalGrowthMaxState=2},
						["poplar"]			={fruitName="poplar", normalGrowthState=1, normalGrowthMaxState=MAX_GROWTH_STATE},
						["grass"]			={fruitName="grass", normalGrowthState=1, normalGrowthMaxState=MAX_GROWTH_STATE},
						["oilseedRadish"]	={fruitName="oilseedRadish", normalGrowthState=1, normalGrowthMaxState=MAX_GROWTH_STATE},
						["default"]			={fruitName="default", normalGrowthState=1, normalGrowthMaxState=3},
				},
				
				[3]={ 	["barley"]			={fruitName="barley", normalGrowthState=2, normalGrowthMaxState=4, setGrowthState=1,desiredGrowthState=WITHER_STATE},
						["wheat"]			={fruitName="wheat", normalGrowthState=2, normalGrowthMaxState=4, setGrowthState=1,desiredGrowthState=WITHER_STATE},
						["rape"]			={fruitName="rape", normalGrowthState=2, normalGrowthMaxState=4, setGrowthState=1,desiredGrowthState=WITHER_STATE},
						["maize"]			={fruitName="maize", normalGrowthState=1, normalGrowthMaxState=3},
						["soybean"]			={fruitName="soybean", normalGrowthState=1, normalGrowthMaxState=2},
						["sunflower"]		={fruitName="sunflower", normalGrowthState=1, normalGrowthMaxState=2},
						["potato"]			={fruitName="potato", normalGrowthState=2, normalGrowthMaxState=3, setGrowthState=1,desiredGrowthState=WITHER_STATE},
						["sugarBeet"]		={fruitName="sugarBeet", normalGrowthState=2, normalGrowthMaxState=3, setGrowthState=1,desiredGrowthState=WITHER_STATE},
						["grass"]			={fruitName="grass", normalGrowthState=1, normalGrowthMaxState=MAX_GROWTH_STATE},
						["oilseedRadish"]	={fruitName="oilseedRadish", normalGrowthState=1, normalGrowthMaxState=MAX_GROWTH_STATE},
						["default"]			={fruitName="default", normalGrowthState=2, normalGrowthMaxState=4, setGrowthState=1,desiredGrowthState=WITHER_STATE},
				},
				
				[4]={ 	["barley"]			={fruitName="barley",normalGrowthState=3, normalGrowthMaxState=5, setGrowthState=1,desiredGrowthState=WITHER_STATE},
						["wheat"]			={fruitName="wheat",normalGrowthState=3, normalGrowthMaxState=5, setGrowthState=1,desiredGrowthState=WITHER_STATE},
						["rape"]			={fruitName="rape", normalGrowthState=3, normalGrowthMaxState=5, setGrowthState=1,desiredGrowthState=WITHER_STATE},
						["maize"]			={fruitName="maize", normalGrowthState=2, normalGrowthMaxState=4, setGrowthState=1,desiredGrowthState=WITHER_STATE},
						["soybean"]			={fruitName="soybean", normalGrowthState=1, normalGrowthMaxState=3},
						["sunflower"]		={fruitName="sunflower", normalGrowthState=2, normalGrowthMaxState=3,setGrowthState=1,desiredGrowthState=WITHER_STATE},
						["potato"]			={fruitName="potato", normalGrowthState=3, normalGrowthMaxState=4, setGrowthState=1,desiredGrowthState=WITHER_STATE},
						["sugarBeet"]		={fruitName="sugarBeet", normalGrowthState=3, normalGrowthMaxState=4, setGrowthState=1,desiredGrowthState=WITHER_STATE},
						["poplar"]			={fruitName="poplar", normalGrowthState=1, normalGrowthMaxState=MAX_GROWTH_STATE},
						["grass"]			={fruitName="grass", normalGrowthState=1, normalGrowthMaxState=MAX_GROWTH_STATE},
						["oilseedRadish"]	={fruitName="oilseedRadish", normalGrowthState=1, normalGrowthMaxState=MAX_GROWTH_STATE},
						["default"]			={fruitName="default",normalGrowthState=3, normalGrowthMaxState=5, setGrowthState=1,desiredGrowthState=WITHER_STATE},
				},  
				
				[5]={ 	["barley"]			={fruitName="barley", normalGrowthState=6, setGrowthState=1,desiredGrowthState=WITHER_STATE, extraGrowthMinState=4, extraGrowthMaxState=5, extraGrowthFactor=2},
						["wheat"]			={fruitName="wheat", normalGrowthState=6, setGrowthState=1,desiredGrowthState=WITHER_STATE, extraGrowthMinState=4, extraGrowthMaxState=5, extraGrowthFactor=2},
						["rape"]			={fruitName="rape", normalGrowthState=6, setGrowthState=1,desiredGrowthState=WITHER_STATE, extraGrowthMinState=4, extraGrowthMaxState=5, extraGrowthFactor=2},
						["maize"]			={fruitName="maize", extraGrowthMinState=3, extraGrowthMaxState=5, extraGrowthFactor=2, setGrowthState=1,desiredGrowthState=WITHER_STATE},
						["soybean"]			={fruitName="soybean", normalGrowthState=2, normalGrowthMaxState=4,setGrowthState=1,desiredGrowthState=WITHER_STATE},
						["sunflower"]		={fruitName="sunflower", normalGrowthState=3, normalGrowthMaxState=4,setGrowthState=1,desiredGrowthState=WITHER_STATE},
						["potato"]			={fruitName="potato", normalGrowthState=4, normalGrowthMaxState=5, setGrowthState=1,desiredGrowthState=WITHER_STATE},
						["sugarBeet"]		={fruitName="sugarBeet", normalGrowthState=4, normalGrowthMaxState=5, setGrowthState=1,desiredGrowthState=WITHER_STATE},
						["grass"]			={fruitName="grass", normalGrowthState=2, normalGrowthMaxState=MAX_GROWTH_STATE},
						["oilseedRadish"]	={fruitName="oilseedRadish", normalGrowthState=2, normalGrowthMaxState=MAX_GROWTH_STATE},
						["default"]			={fruitName="default", normalGrowthState=6, setGrowthState=1,desiredGrowthState=WITHER_STATE, extraGrowthMinState=4, extraGrowthMaxState=5, extraGrowthFactor=2},
				}, 
				
				[6]={ 	["barley"]			={fruitName="barley",normalGrowthState=6, setGrowthState=1,desiredGrowthState=WITHER_STATE},
						["wheat"]			={fruitName="wheat",normalGrowthState=6, setGrowthState=1,desiredGrowthState=WITHER_STATE},
						["rape"]			={fruitName="rape", normalGrowthState=6, setGrowthState=1,desiredGrowthState=WITHER_STATE},
						["maize"]			={fruitName="maize", normalGrowthState=5, normalGrowthMaxState=6, setGrowthState=1,desiredGrowthState=WITHER_STATE},
						["soybean"]			={fruitName="soybean", extraGrowthMinState=3, extraGrowthMaxState=5, extraGrowthFactor=2, setGrowthState=1,desiredGrowthState=WITHER_STATE},
						["sunflower"]		={fruitName="sunflower", extraGrowthMinState=4, extraGrowthMaxState=5, extraGrowthFactor=2, setGrowthState=1,desiredGrowthState=WITHER_STATE},
						["potato"]			={fruitName="potato", normalGrowthState=5, normalGrowthMaxState=MAX_GROWTH_STATE, setGrowthState=1,desiredGrowthState=WITHER_STATE},
						["sugarBeet"]		={fruitName="sugarBeet", normalGrowthState=5, normalGrowthMaxState=6, setGrowthState=1,desiredGrowthState=WITHER_STATE},
						["grass"]			={fruitName="grass", normalGrowthState=2, normalGrowthMaxState=MAX_GROWTH_STATE},
						["oilseedRadish"]	={fruitName="oilseedRadish", normalGrowthState=2, normalGrowthMaxState=MAX_GROWTH_STATE},
						["default"]			={fruitName="default",normalGrowthState=6, setGrowthState=1,desiredGrowthState=WITHER_STATE},
				},
				
				[7]={ 	["barley"]			={fruitName="barley",normalGrowthState=1},
						["wheat"]			={fruitName="wheat",normalGrowthState=1},
                        ["rape"]			={fruitName="rape",normalGrowthState=1},			 	
						["maize"]			={fruitName="maize", normalGrowthState=6, setGrowthState=1,desiredGrowthState=WITHER_STATE},	
						["soybean"]			={fruitName="soybean", normalGrowthState=5, normalGrowthMaxState=6, setGrowthState=1,desiredGrowthState=WITHER_STATE},
						["sunflower"]		={fruitName="sunflower", normalGrowthState=6, setGrowthState=1,desiredGrowthState=WITHER_STATE},
						["potato"]			={fruitName="potato", normalGrowthState=MAX_GROWTH_STATE, setGrowthState=1,desiredGrowthState=WITHER_STATE},
						["sugarBeet"]		={fruitName="sugarBeet", normalGrowthState=6, setGrowthState=1,desiredGrowthState=WITHER_STATE},
						["poplar"]			={fruitName="poplar", normalGrowthState=1, normalGrowthMaxState=MAX_GROWTH_STATE},
						["grass"]			={fruitName="grass", normalGrowthState=1, normalGrowthMaxState=MAX_GROWTH_STATE},
						["oilseedRadish"]	={fruitName="oilseedRadish", normalGrowthState=1, normalGrowthMaxState=MAX_GROWTH_STATE},
						["default"]			={fruitName="default",normalGrowthState=1},
				}, 	
				
				[8]={ 	["barley"]			={fruitName="barley",normalGrowthState=1, normalGrowthMaxState=2,setGrowthState=7,desiredGrowthState=WITHER_STATE},
						["wheat"]			={fruitName="wheat",normalGrowthState=1, normalGrowthMaxState=1,setGrowthState=7,desiredGrowthState=WITHER_STATE},
						["rape"]			={fruitName="rape", normalGrowthState=1, normalGrowthMaxState=1,setGrowthState=7,desiredGrowthState=WITHER_STATE}, 
						["maize"]			={fruitName="maize", setGrowthState=1, setGrowthMaxState=MAX_GROWTH_STATE,desiredGrowthState=WITHER_STATE},
						["soybean"]			={fruitName="soybean", normalGrowthState=6, setGrowthState=1,desiredGrowthState=WITHER_STATE},
						["sunflower"]		={fruitName="sunflower", setGrowthState=1, setGrowthMaxState=MAX_GROWTH_STATE,desiredGrowthState=WITHER_STATE},
						["potato"]			={fruitName="potato", setGrowthState=1,desiredGrowthState=WITHER_STATE},
						["sugarBeet"]		={fruitName="sugarBeet", setGrowthState=1,desiredGrowthState=WITHER_STATE},
						["grass"]			={fruitName="grass", normalGrowthState=1, normalGrowthMaxState=MAX_GROWTH_STATE},
						["oilseedRadish"]	={fruitName="oilseedRadish", normalGrowthState=1, normalGrowthMaxState=MAX_GROWTH_STATE},
						["default"]			={fruitName="default",normalGrowthState=1, normalGrowthMaxState=1,setGrowthState=7,desiredGrowthState=WITHER_STATE},
 				},

				[9]={ 	["soybean"]			={fruitName="soybean", setGrowthState=1, setGrowthMaxState=MAX_GROWTH_STATE, desiredGrowthState=WITHER_STATE},
						["potato"]			={fruitName="potato", setGrowthState=1, setGrowthMaxState=MAX_GROWTH_STATE, desiredGrowthState=WITHER_STATE},
						["sugarBeet"]		={fruitName="sugarBeet", setGrowthState=1, setGrowthMaxState=MAX_GROWTH_STATE, desiredGrowthState=WITHER_STATE},
						["grass"]			={fruitName="grass", setGrowthState=1, setGrowthMaxState=MAX_GROWTH_STATE,desiredGrowthState=1},
                        ["oilseedRadish"]	={fruitName="oilseedRadish", normalGrowthState=1, normalGrowthMaxState=MAX_GROWTH_STATE},
 				},

				[10]={}; -- no growth
				[11]={}; -- no growth
				[12]={}; -- no growth
                [FIRST_LOAD_TRANSITION]={ 				
						["barley"]			={fruitName="barley", setGrowthState=1, setGrowthMaxState=MAX_GROWTH_STATE,desiredGrowthState=1},
						["wheat"]			={fruitName="wheat", setGrowthState=1, setGrowthMaxState=MAX_GROWTH_STATE,desiredGrowthState=1},					
						["rape"]			={fruitName="rape", setGrowthState=1, setGrowthMaxState=MAX_GROWTH_STATE,desiredGrowthState=1},
						["maize"]			={fruitName="maize", setGrowthState=1, setGrowthMaxState=MAX_GROWTH_STATE,desiredGrowthState=1},
						["soybean"]			={fruitName="soybean", setGrowthState=1, setGrowthMaxState=MAX_GROWTH_STATE,desiredGrowthState=1},
						["sunflower"]		={fruitName="sunflower", setGrowthState=1, setGrowthMaxState=MAX_GROWTH_STATE,desiredGrowthState=1},
						["potato"]			={fruitName="potato", setGrowthState=1, setGrowthMaxState=MAX_GROWTH_STATE,desiredGrowthState=1},
						["sugarBeet"]		={fruitName="sugarBeet", setGrowthState=1, setGrowthMaxState=MAX_GROWTH_STATE,desiredGrowthState=1},
						["poplar"]			={fruitName="poplar", setGrowthState=1, setGrowthMaxState=MAX_GROWTH_STATE,desiredGrowthState=1},
						["grass"]			={fruitName="grass", setGrowthState=1, setGrowthMaxState=MAX_GROWTH_STATE,desiredGrowthState=1},
                        ["oilseedRadish"]	={fruitName="oilseedRadish", setGrowthState=1, setGrowthMaxState=MAX_GROWTH_STATE,desiredGrowthState=1},
						
						
				}, 

};


ssGrowthManager.currentGrowthTransitionPeriod = nil
ssGrowthManager.doGrowthTransition = false


function ssGrowthManager:load(savegame, key)
    self.hasResetGrowth = ssStorage.getXMLBool(savegame, key .. ".settings.hasResetGrowth", false);
    self.growthManagerEnabled = ssStorage.getXMLBool(savegame,key .. ".settings.growthManagerEnabled", true);
end

function ssGrowthManager:save(savegame, key)
    ssStorage.setXMLBool(savegame, key .. ".settings.hasResetGrowth", self.hasResetGrowth);
    ssStorage.setXMLBool(savegame, key .. ".settings.growthManagerEnabled", self.growthManagerEnabled);
end

function ssGrowthManager:loadMap(name)

    if (self.growthManagerEnabled == false) then
        log("Growth Manager disabled");
        return
    end
    
    --if g_currentMission:getIsServer() then
        ssSeasonsMod:addGrowthStageChangeListener(self)

       --lock changing the growth speed option and set growth rate to 1 (no growth)
       g_currentMission:setPlantGrowthRate(1,nil);
       g_currentMission:setPlantGrowthRateLocked(true);
       log("Growth Manager loading. Locking growth");

       self:loadFromXML();
       --TODO: check if loaded. if not, then do not add the listener
       
        if not (self.hasResetGrowth) then 
            self.currentGrowthTransitionPeriod = FIRST_LOAD_TRANSITION;
            self.doGrowthTransition = true;
            self.hasResetGrowth = true;
            self.growthManagerEnabled = true;
            log("Growth Manager - First time growth reset - this will only happen once in a new savegame");
        end

       if g_currentMission.missionInfo.timeScale > 120 then
            self.mapSegments = 1 -- Not enought time to do it section by section since it might be called every two hour as worst case.
        else
            self.mapSegments = 16 -- Must be evenly dividable with mapsize.
        end

        self.currentX = 0 -- The row that we are currently updating
        self.currentZ = 0 -- The column that we are currently updating

    --end

end


function ssGrowthManager:loadFromXML()
    
    local elements = {"defaultFruits"};
    local defaultFruitsXML = ssGrowthManagerXML:loadFile(ssSeasonsMod.modDir .. "data/growth.xml", "growthManager", elements);

   -- print_r(data1);

    if defaultFruitsXML ~= nil then
        self.defaultFruits = Set(defaultFruitsXML)
        log("GM: setting default fruits from XML");
    else
        log("GM: XML default fruits data not found");
    end

    



    -- local elements = {
    --     ["defaultFruits"] = {}
    -- }
    -- local data1 = ssSeasonsXML:loadFile(ssSeasonsMod.modDir .. "data/growth.xml", "growthManager", elements);
    -- local data2 = ssSeasonsXML:getTypes(data1,"defaultFruits");
    -- print_r(data2);

    -- self.defaultFruits = Set(data2);
    -- print_r(self.defaultFruits);
    -- log("GM: Loading data");

    --self.data = 
    -- local mapData = ssSeasonsXML:loadFile(MAPDIR .. "Seasons.xml", "modules.animals", elements, modData, true)
    -- FIXME: find the location of the map

--     function loadFromXML()
--   self.data = {}
--   self:loadFile(ssSeasonsMod.modDir.."data/growth.xml")
--   if file exists mapFolder.."seasons_growth.xml" then
-- 	  self:loadFile(mapFolder.."seasons_growth.xml")
--   end
-- end

-- function loadFile(path)

--  for each possible stage
--    if self.data[stage] == nil then
--      self.data[stage] = {}
--    end

--    for each value thing....
--    end
--   end
-- end

end

function ssGrowthManager:deleteMap()
end

function ssGrowthManager:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssGrowthManager:keyEvent(unicode, sym, modifier, isDown)
    if (unicode == 107) then

        for index,fruit in pairs(g_currentMission.fruits) do
            local desc = FruitUtil.fruitIndexToDesc[index]
            local fruitName = desc.name
            if (self.defaultFruits[fruitName] == nil) then
                log("GM: Fruit not found in default table: " .. fruitName);
            else
                log("GM: Fruit " .. fruitName .. " found");
            end

        end

        -- self.fakeDay = self.fakeDay + ssSeasonsUtil.daysInSeason
        -- log("Season changed to " .. ssSeasonsUtil:seasonName(self.fakeDay) )
        --self:seasonChanged()

        --self.currentGrowthTransitionPeriod = self.testGrowthTransitionPeriod
        --log("Season change transition current : " .. ssGrowthManager.testGrowthTransitionPeriod)

        --self.doGrowthTransition = true


        --if self.testGrowthTransitionPeriod < 12 then
            --self.testGrowthTransitionPeriod = self.testGrowthTransitionPeriod + 1
        --else
            --self.testGrowthTransitionPeriod = 1
        --end


        -- log ("MAX_GROWTH_STATE " .. MAX_GROWTH_STATE .. " FIRST_LOAD_TRANSITION .. " .. FIRST_LOAD_TRANSITION)

        
        -- local growthTransition = ssSeasonsUtil:currentGrowthTransition(self.fakeDay)
        -- --log("Growth iteration: " .. tostring(growthTransition));

        -- self.fakeDay = self.fakeDay + 1;
        -- --local cGS = ssSeasonsUtil:currentGrowthStage(self.fakeDay);
        -- log("Current Growth Transition: " .. tostring(growthTransition));
        
        -- log("Season changed to " .. ssSeasonsUtil:seasonName(self.fakeDay) );
        --self:seasonChanged();

        --self.currentGrowthTransitionPeriod = self.testGrowthTransitionPeriod;
        --log("Season change transition current : " .. ssGrowthManager.testGrowthTransitionPeriod);
        
        -- self.doGrowthTransition = true;
        
        
        -- if self.testGrowthTransitionPeriod < 12 then
        --     self.testGrowthTransitionPeriod = self.testGrowthTransitionPeriod + 1;
        -- else
        --     self.testGrowthTransitionPeriod = 1;
        -- end
        
        
        -- log ("MAX_GROWTH_STATE " .. MAX_GROWTH_STATE .. " FIRST_LOAD_TRANSITION .. " .. FIRST_LOAD_TRANSITION);


        -- for x, line2 in pairs(self.growthData[FIRST_LOAD_TRANSITION]) do
        --     print(line2.fruitName)
        -- end


        --log("Season change transition coming up: " .. ssGrowthManager.testGrowthTransitionPeriod)

        --log("Season change transition coming up: " .. ssGrowthManager.testGrowthTransitionPeriod);    



    end
end

function ssGrowthManager:update(dt)

    if self.doGrowthTransition == true then

        local startWorldX =  self.currentX * g_currentMission.terrainSize / self.mapSegments - g_currentMission.terrainSize / 2
        local startWorldZ =  self.currentZ * g_currentMission.terrainSize / self.mapSegments - g_currentMission.terrainSize / 2
        local widthWorldX = startWorldX + g_currentMission.terrainSize / self.mapSegments - 0.1 -- -0.1 to avoid overlap.
        local widthWorldZ = startWorldZ
        local heightWorldX = startWorldX
        local heightWorldZ = startWorldZ + g_currentMission.terrainSize / self.mapSegments - 0.1 -- -0.1 to avoid overlap.

        --local detailId = g_currentMission.terrainDetailId

        for index,fruit in pairs(g_currentMission.fruits) do
            local desc = FruitUtil.fruitIndexToDesc[index]
            local fruitName = desc.name

            local x,z, widthX,widthZ, heightX,heightZ = Utils.getXZWidthAndHeight(id, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

            if (self.defaultFruits[fruitName] == nil) then
                log("Fruit not found in default table: " .. fruitName);
                fruitName = "default";
            end

            if self.growthData[self.currentGrowthTransitionPeriod][fruitName] ~= nil then 

                local fruitData = FruitUtil.fruitTypeGrowths[fruitName]

                --setGrowthState
                if self.growthData[self.currentGrowthTransitionPeriod][fruitName].setGrowthState ~= nil
                    and self.growthData[self.currentGrowthTransitionPeriod][fruitName].desiredGrowthState ~= nil then
                        --print("FruitID " .. fruit.id .. " FruitName: " .. fruitName .. " - reset growth at season transition: " .. self.currentGrowthTransitionPeriod .. " between growth states " .. self.growthData[self.currentGrowthTransitionPeriod][fruitName].setGrowthState .. " and " .. self.growthData[self.currentGrowthTransitionPeriod][fruitName].setGrowthMaxState .. " to growth state: " .. self.growthData[self.currentGrowthTransitionPeriod][fruitName].setGrowthState)

                    local minState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].setGrowthState
                    local desiredGrowthState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].desiredGrowthState

                    if desiredGrowthState == WITHER_STATE then
                         desiredGrowthState = fruitData.witheringNumGrowthStates
                    end

                    if self.growthData[self.currentGrowthTransitionPeriod][fruitName].setGrowthMaxState ~= nil then

                        local maxState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].setGrowthMaxState
                        if maxState == MAX_GROWTH_STATE then
                            maxState = fruitData.numGrowthStates
                        end
                        -- print("Fruit: " .. fruitName)
                        -- print("MinState: " .. minState)
                        -- print("Maxstate: " .. maxState)
                        setDensityMaskParams(fruit.id, "between",minState,maxState)
                    else
                        setDensityMaskParams(fruit.id, "equals",minState)
                    end

                    local sum = setDensityMaskedParallelogram(fruit.id,x,z, widthX,widthZ, heightX,heightZ,0, g_currentMission.numFruitStateChannels, fruit.id, 0, g_currentMission.numFruitStateChannels, desiredGrowthState)

                end

                --increment by 1 for crops between normalGrowthState  normalGrowthMaxState or for crops at normalGrowthState
                if self.growthData[self.currentGrowthTransitionPeriod][fruitName].normalGrowthState ~= nil then

                    local minState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].normalGrowthState

                    if self.growthData[self.currentGrowthTransitionPeriod][fruitName].normalGrowthMaxState ~= nil then

                        local maxState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].normalGrowthMaxState

                        if maxState == MAX_GROWTH_STATE then
                            maxState = fruitData.numGrowthStates-1
                        end
                        setDensityMaskParams(fruit.id, "between",minState,maxState)
                    else
                        setDensityMaskParams(fruit.id, "equals",minState)
                    end

                    local sum = addDensityMaskedParallelogram(fruit.id,x,z, widthX,widthZ, heightX,heightZ, 0, g_currentMission.numFruitStateChannels, fruit.id, 0, g_currentMission.numFruitStateChannels, 1)
                end

                --increment by extraGrowthFactor between extraGrowthMinState and extraGrowthMaxState
                if self.growthData[self.currentGrowthTransitionPeriod][fruitName].extraGrowthMinState ~= nil
                    and self.growthData[self.currentGrowthTransitionPeriod][fruitName].extraGrowthMaxState ~= nil
                    and self.growthData[self.currentGrowthTransitionPeriod][fruitName].extraGrowthFactor ~= nil then

                    local minState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].extraGrowthMinState
                    local maxState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].extraGrowthMaxState
                    local extraGrowthFactor = self.growthData[self.currentGrowthTransitionPeriod][fruitName].extraGrowthFactor

                    setDensityMaskParams(fruit.id, "between",minState,maxState)
                    local sum = addDensityMaskedParallelogram(fruit.id,x,z, widthX,widthZ, heightX,heightZ, 0, g_currentMission.numFruitStateChannels, fruit.id, 0, g_currentMission.numFruitStateChannels, extraGrowthFactor )
                end

            end  -- end of if self.growthData[self.currentGrowthTransitionPeriod][fruitName] ~= nil then

        end  -- end of for index,fruit in pairs(g_currentMission.fruits) do

        if self.currentZ < self.mapSegments - 1 then -- Starting with column 0 So index of last column is one less then the number of columns.
            -- Next column
            self.currentZ = self.currentZ + 1
        elseif  self.currentX < self.mapSegments - 1 then -- Starting with row 0
            -- Next row
            self.currentX = self.currentX + 1
            self.currentZ = 0
        else
            -- Done with the loop, set up for the next one.
            self.currentX = 0
            self.currentZ = 0
            self.doGrowthTransition = false
        end
    end -- end of if self.doGrowthTransition == true then
end

function ssGrowthManager:draw()
end

function ssGrowthManager:growthStageChanged()

    if (self.growthManagerEnabled == true) then -- redundant but heyho
        local growthTransition = ssSeasonsUtil:currentGrowthTransition();
        log("GrowthManager enabled - growthStateChanged to: " .. growthTransition);
        self.currentGrowthTransitionPeriod = growthTransition;
        self.doGrowthTransition = true;
    end
end
