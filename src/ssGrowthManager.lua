---------------------------------------------------------------------------------------------------------
-- GROWTH MANAGER SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  to manage growth as the season changes
-- Authors:  theSeb
-- Credits: Inspired by upsidedown's growth manager mod

ssGrowthManager = {}


LAST_GROWTH_STATE = 99; -- needs to be set to the fruit's numGrowthStates if you are setting, or -1 if you're incrementing
FIRST_LOAD_TRANSITION = 999;



ssGrowthManager.growthData = { 	[1]={ 				
						["barley"]			={fruitName="barley", normalGrowthState=1, normalGrowthMaxState=3},
						["wheat"]			={fruitName="wheat", normalGrowthState=1, normalGrowthMaxState=3},					
						["rape"]			={fruitName="rape", normalGrowthState=1},
						["maize"]			={fruitName="maize", normalGrowthState=1},
						["soybean"]			={fruitName="soybean", witherState=1},
						["sunflower"]		={fruitName="sunflower", witherState=1},
						["potato"]			={fruitName="potato", normalGrowthState=1},
						["sugarBeet"]		={fruitName="sugarBeet", normalGrowthState=1},
						["poplar"]			={fruitName="poplar", normalGrowthState=1, normalGrowthMaxState=LAST_GROWTH_STATE},
						["grass"]			={fruitName="grass", normalGrowthState=1, normalGrowthMaxState=LAST_GROWTH_STATE},
						
						
				}, 
				
				[2]={ 	["barley"]			={fruitName="barley", normalGrowthState=1, normalGrowthMaxState=3},
						["wheat"]			={fruitName="wheat", normalGrowthState=1, normalGrowthMaxState=3},
						["rape"]			={fruitName="rape", normalGrowthState=1, normalGrowthMaxState=2},
						["maize"]			={fruitName="maize", normalGrowthState=1, normalGrowthMaxState=2},
						["soybean"]			={fruitName="soybean", normalGrowthState=1},
						["sunflower"]		={fruitName="sunflower", normalGrowthState=1},
						["potato"]			={fruitName="potato", normalGrowthState=1, normalGrowthMaxState=2},
						["sugarBeet"]		={fruitName="sugarBeet", normalGrowthState=1, normalGrowthMaxState=2},
						["poplar"]			={fruitName="poplar", normalGrowthState=1, normalGrowthMaxState=LAST_GROWTH_STATE},
						["grass"]			={fruitName="grass", normalGrowthState=1, normalGrowthMaxState=LAST_GROWTH_STATE},

				},
				
				[3]={ 	["barley"]			={fruitName="barley", normalGrowthState=2, normalGrowthMaxState=4, witherState=1},
						["wheat"]			={fruitName="wheat", normalGrowthState=2, normalGrowthMaxState=4, witherState=1},
						["rape"]			={fruitName="rape", normalGrowthState=2, normalGrowthMaxState=3, witherState=1},
						["maize"]			={fruitName="maize", normalGrowthState=1, normalGrowthMaxState=3},
						["soybean"]			={fruitName="soybean", normalGrowthState=1, normalGrowthMaxState=2},
						["sunflower"]		={fruitName="sunflower", normalGrowthState=1, normalGrowthMaxState=2},
						["potato"]			={fruitName="potato", normalGrowthState=2, normalGrowthMaxState=3, witherState=1},
						["sugarBeet"]		={fruitName="sugarBeet", normalGrowthState=2, normalGrowthMaxState=3, witherState=1},
						["grass"]			={fruitName="grass", normalGrowthState=1, normalGrowthMaxState=LAST_GROWTH_STATE},
				},
				
				[4]={ 	["barley"]			={fruitName="barley",normalGrowthState=3, normalGrowthMaxState=5, witherState=1},
						["wheat"]			={fruitName="wheat",normalGrowthState=3, normalGrowthMaxState=5, witherState=1},
						["rape"]			={fruitName="rape", normalGrowthState=3, normalGrowthMaxState=4, witherState=1},
						["maize"]			={fruitName="maize", normalGrowthState=2, normalGrowthMaxState=4, witherState=1},
						["soybean"]			={fruitName="soybean", normalGrowthState=1, normalGrowthMaxState=3},
						["sunflower"]		={fruitName="sunflower", normalGrowthState=2, normalGrowthMaxState=3,witherState=1},
						["potato"]			={fruitName="potato", normalGrowthState=3, normalGrowthMaxState=4, witherState=1},
						["sugarBeet"]		={fruitName="sugarBeet", normalGrowthState=3, normalGrowthMaxState=4, witherState=1},
						["poplar"]			={fruitName="poplar", normalGrowthState=1, normalGrowthMaxState=LAST_GROWTH_STATE},
						["grass"]			={fruitName="grass", normalGrowthState=1, normalGrowthMaxState=LAST_GROWTH_STATE},

				},  
				
				[5]={ 	["barley"]			={fruitName="barley", normalGrowthState=6, witherState=1, extraGrowthMinState=4, extraGrowthMaxState=5, extraGrowthFactor=2},
						["wheat"]			={fruitName="wheat", normalGrowthState=6, witherState=1, extraGrowthMinState=4, extraGrowthMaxState=5, extraGrowthFactor=2},
						["rape"]			={fruitName="rape", extraGrowthMinState=4, extraGrowthMaxState=5, extraGrowthFactor=2, witherState=1},
						["maize"]			={fruitName="maize", extraGrowthMinState=3, extraGrowthMaxState=5, extraGrowthFactor=2, witherState=1},
						["soybean"]			={fruitName="soybean", normalGrowthState=2, normalGrowthMaxState=4,witherState=1},
						["sunflower"]		={fruitName="sunflower", normalGrowthState=3, normalGrowthMaxState=4,witherState=1},
						["potato"]			={fruitName="potato", normalGrowthState=4, normalGrowthMaxState=5, witherState=1},
						["sugarBeet"]			={fruitName="sugarBeet", normalGrowthState=4, normalGrowthMaxState=5, witherState=1},
						["grass"]			={fruitName="grass", normalGrowthState=2, normalGrowthMaxState=LAST_GROWTH_STATE},
				}, 
				
				[6]={ 	["barley"]			={fruitName="barley",normalGrowthState=6, witherState=1},
						["wheat"]			={fruitName="wheat",normalGrowthState=6, witherState=1},
						["rape"]			={fruitName="rape", normalGrowthState=6, witherState=1},
						["maize"]			={fruitName="maize", normalGrowthState=5, normalGrowthMaxState=6, witherState=1},
						["soybean"]			={fruitName="soybean", extraGrowthMinState=3, extraGrowthMaxState=5, extraGrowthFactor=2, witherState=1},
						["sunflower"]		={fruitName="sunflower", extraGrowthMinState=4, extraGrowthMaxState=5, extraGrowthFactor=2, witherState=1},
						["potato"]			={fruitName="potato", normalGrowthState=5, normalGrowthMaxState=LAST_GROWTH_STATE, witherState=1},
						["sugarBeet"]		={fruitName="sugarBeet", normalGrowthState=5, normalGrowthMaxState=6, witherState=1},
						["grass"]			={fruitName="grass", normalGrowthState=2, normalGrowthMaxState=LAST_GROWTH_STATE},
				},
				
				[7]={ 	["barley"]			={fruitName="barley",normalGrowthState=1},
						["wheat"]			={fruitName="wheat",normalGrowthState=1},			 	
						["maize"]			={fruitName="maize", normalGrowthState=6, witherState=1},	
						["soybean"]			={fruitName="soybean", normalGrowthState=5, normalGrowthMaxState=6, witherState=1},
						["sunflower"]		={fruitName="sunflower", normalGrowthState=6, witherState=1},
						["potato"]			={fruitName="potato", normalGrowthState=LAST_GROWTH_STATE, witherState=1},
						["sugarBeet"]		={fruitName="sugarBeet", normalGrowthState=6, witherState=1},
						["poplar"]			={fruitName="poplar", normalGrowthState=1, normalGrowthMaxState=LAST_GROWTH_STATE},
						["grass"]			={fruitName="grass", normalGrowthState=1, normalGrowthMaxState=LAST_GROWTH_STATE},
				}, 	
				
				[8]={ 	["barley"]			={fruitName="barley",normalGrowthState=1, normalGrowthMaxState=2,witherState=7},
						["wheat"]			={fruitName="wheat",normalGrowthState=1, normalGrowthMaxState=1,witherState=7},
						["rape"]			={fruitName="rape", witherMinState=1, witherMaxState=7}, 
						["maize"]			={fruitName="maize", witherMinState=1, witherMaxState=7},
						["soybean"]			={fruitName="soybean", normalGrowthState=6, witherState=1},
						["sunflower"]		={fruitName="sunflower", witherMinState=1, witherMaxState=7},
						["potato"]			={fruitName="potato", witherState=1},
						["sugarBeet"]		={fruitName="sugarBeet", witherState=1},
						["grass"]			={fruitName="grass", normalGrowthState=1, normalGrowthMaxState=LAST_GROWTH_STATE},
						
							
 				}, 	
				[9]={ 	["soybean"]			={fruitName="soybean", witherMinState=1, witherMaxState=7},
						["potato"]			={fruitName="potato", witherMinState=1, witherMaxState=7},
						["sugarBeet"]		={fruitName="sugarBeet", witherMinState=1, witherMaxState=7},
						["grass"]			={fruitName="grass", setGrowthMinState=1, setGrowthMaxState=LAST_GROWTH_STATE,setGrowthState=1},
						
 				},
				[10]={}; -- no growth
				[11]={}; -- no growth
				[12]={}; -- no growth
                [FIRST_LOAD_TRANSITION]={ 				
						["barley"]			={fruitName="barley", setGrowthMinState=1, setGrowthMaxState=LAST_GROWTH_STATE,setGrowthState=1},
						["wheat"]			={fruitName="wheat", setGrowthMinState=1, setGrowthMaxState=LAST_GROWTH_STATE,setGrowthState=1},					
						["rape"]			={fruitName="rape", setGrowthMinState=1, setGrowthMaxState=LAST_GROWTH_STATE,setGrowthState=1},
						["maize"]			={fruitName="maize", setGrowthMinState=1, setGrowthMaxState=LAST_GROWTH_STATE,setGrowthState=1},
						["soybean"]			={fruitName="soybean", setGrowthMinState=1, setGrowthMaxState=LAST_GROWTH_STATE,setGrowthState=1},
						["sunflower"]		={fruitName="sunflower", setGrowthMinState=1, setGrowthMaxState=LAST_GROWTH_STATE,setGrowthState=1},
						["potato"]			={fruitName="potato", setGrowthMinState=1, setGrowthMaxState=LAST_GROWTH_STATE,setGrowthState=1},
						["sugarBeet"]		={fruitName="sugarBeet", setGrowthMinState=1, setGrowthMaxState=LAST_GROWTH_STATE,setGrowthState=1},
						["poplar"]			={fruitName="poplar", setGrowthMinState=1, setGrowthMaxState=LAST_GROWTH_STATE,setGrowthState=1},
						["grass"]			={fruitName="grass", setGrowthMinState=1, setGrowthMaxState=LAST_GROWTH_STATE,setGrowthState=1},
						
						
				}, 

};


--test stuff
ssGrowthManager.fakeDay = 1;
ssGrowthManager.testGrowthTransitionPeriod = 1;
--end of test stuff

ssGrowthManager.firstTimeload = false; -- set this to true if you want to play around
ssGrowthManager.currentGrowthTransitionPeriod = nil;
ssGrowthManager.doGrowthTransition = false;

function ssGrowthManager.preSetup()
end

function ssGrowthManager.setup()
    addModEventListener(ssGrowthManager);
end

function ssGrowthManager:loadMap(name)
    --g_currentMission.environment:addDayChangeListener(self);
    --g_currentMission.environment:addHourChangeListener(self);

    --ssSeasonsMod:addSeasonChangeListener(self);
    log("Growth Manager loading");
    --ssSeasonsMod.addGrowthStageChangeListener(self);

   
   --lock changing the growth speed option and set growth rate to 1 (no growth)
   g_currentMission:setPlantGrowthRate(1,nil);
   g_currentMission:setPlantGrowthRateLocked(true);

    

    -- TODO: handle first time map loading
    --load firstTimeload from config then

    if self.firstTimeload == true then -- only if it does not exist in the config
        self.currentGrowthTransitionPeriod = FIRST_LOAD_TRANSITION;
        self.doGrowthTransition = true;
        self.firstTimeload = false;
        log("Growth Manager - First time load growth reset");
        
        --store firstTimeload in config
    end

    log("Growth Manager - current growth from seasonUtil: " .. ssSeasonsUtil:currentGrowthStage());


    -- end of first time map loading


   --self:handleSeasonChange(); 

   if g_currentMission.missionInfo.timeScale > 120 then
        self.mapSegments = 1; -- Not enought time to do it section by section since it might be called every two hour as worst case.
    else
        self.mapSegments = 16; -- Must be evenly dividable with mapsize.
    end

     
    self.currentX = 0; -- The row that we are currently updating
    self.currentZ = 0; -- The column that we are currently updating

    
    print("Loading finished ...");

end

function ssGrowthManager:deleteMap()
end

function ssGrowthManager:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssGrowthManager:keyEvent(unicode, sym, modifier, isDown)
    if (unicode == 107) then
        
        --self:handleSeasonChange();
        -- if (self. == true) then
        --     self. = false;
        -- else
        --     self. = true;
        -- end

        -- self.fakeDay = self.fakeDay + ssSeasonsUtil.daysInSeason;
        -- log("Season changed to " .. ssSeasonsUtil:seasonName(self.fakeDay) );
        --self:seasonChanged();

        log("Season change transition current : " .. ssGrowthManager.testGrowthTransitionPeriod);
        self.doGrowthTransition = true;
        self.currentGrowthTransitionPeriod = self.testGrowthTransitionPeriod;
        
        if self.testGrowthTransitionPeriod < 12 then
            self.testGrowthTransitionPeriod = self.testGrowthTransitionPeriod + 1;
        else
            self.testGrowthTransitionPeriod = 1;
        end

        
        -- log ("LAST_GROWTH_STATE " .. LAST_GROWTH_STATE .. " FIRST_LOAD_TRANSITION .. " .. FIRST_LOAD_TRANSITION);

        -- for x, line2 in pairs(self.growthData[FIRST_LOAD_TRANSITION]) do
		-- 	print(line2.fruitName);
		-- end

        log("Season change transition coming up: " .. ssGrowthManager.testGrowthTransitionPeriod);    

       
    end
end

function ssGrowthManager:readStream(streamId, connection)
    --self:seasonChanged()
end

function ssGrowthManager:update(dt)

if self.doGrowthTransition == true then

        --print("Updating  for: " .. self.currentX .. ", " .. self.currentZ );

        
        local startWorldX =  self.currentX * g_currentMission.terrainSize / self.mapSegments - g_currentMission.terrainSize / 2;
        local startWorldZ =  self.currentZ * g_currentMission.terrainSize / self.mapSegments - g_currentMission.terrainSize / 2;
        local widthWorldX = startWorldX + g_currentMission.terrainSize / self.mapSegments - 0.1; -- -0.1 to avoid overlap.
        local widthWorldZ = startWorldZ;
        local heightWorldX = startWorldX;
        local heightWorldZ = startWorldZ + g_currentMission.terrainSize / self.mapSegments - 0.1; -- -0.1 to avoid overlap.

        --print("- " .. startWorldX .. ", " .. startWorldZ .. ", " .. widthWorldX .. ", " .. widthWorldZ .. ", " .. heightWorldX .. ", " .. heightWorldZ );


        --ssSnow:addSnow(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ);
        local detailId = g_currentMission.terrainDetailId;
        
        

        for index,fruit in pairs(g_currentMission.fruits) do
            local desc = FruitUtil.fruitIndexToDesc[index];
            local fruitName = desc.name;

            local x,z, widthX,widthZ, heightX,heightZ = Utils.getXZWidthAndHeight(id, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ);

            if self.growthData[self.currentGrowthTransitionPeriod][fruitName] ~= nil then -- TODO: need to add default config to non-standard fruits

                local fruitData = FruitUtil.fruitTypeGrowths[fruitName];

                --setGrowthState
                if self.growthData[self.currentGrowthTransitionPeriod][fruitName].setGrowthMinState ~= nil 
                    and self.growthData[self.currentGrowthTransitionPeriod][fruitName].setGrowthMaxState ~= nil then
                        --print("FruitID " .. fruit.id .. " FruitName: " .. fruitName .. " - reset growth at season transition: " .. self.currentGrowthTransitionPeriod .. " between growth states " .. self.growthData[self.currentGrowthTransitionPeriod][fruitName].setGrowthMinState .. " and " .. self.growthData[self.currentGrowthTransitionPeriod][fruitName].setGrowthMaxState .. " to growth state: " .. self.growthData[self.currentGrowthTransitionPeriod][fruitName].setGrowthState);
                        
                    local minState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].setGrowthMinState;
                    local maxState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].setGrowthMaxState;
                    

                    if self.growthData[self.currentGrowthTransitionPeriod][fruitName].setGrowthMaxState == LAST_GROWTH_STATE then
                        maxState = fruitData.numGrowthStates;
                    end

                    setDensityMaskParams(fruit.id, "between", minState,maxState);
                    --local sum = addDensityMaskedParallelogram(fruit.id,x,z, widthX,widthZ, heightX,heightZ, 0, g_currentMission.numFruitStateChannels, fruit.id, 0, g_currentMission.numFruitStateChannels, 1)
                    local sum = setDensityMaskedParallelogram(fruit.id,x,z, widthX,widthZ, heightX,heightZ,0, g_currentMission.numFruitStateChannels, fruit.id, 0, g_currentMission.numFruitStateChannels, 1); 
                                                                    
                end

                --increment by 1 for crops between normalGrowthState  normalGrowthMaxState
                if self.growthData[self.currentGrowthTransitionPeriod][fruitName].normalGrowthState ~= nil then
                    
                    local minState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].normalGrowthState;

                    if self.growthData[self.currentGrowthTransitionPeriod][fruitName].normalGrowthMaxState ~= nil then
                        
                        
                        local maxState = self.growthData[self.currentGrowthTransitionPeriod][fruitName].normalGrowthMaxState;
                        
                        -- print("Fruit: " .. fruitName);
                        -- print("MinState: " .. minState);
                        -- print("Maxstate: " .. maxState);
                        
                        if self.growthData[self.currentGrowthTransitionPeriod][fruitName].normalGrowthMaxState == LAST_GROWTH_STATE then
                            maxState = fruitData.numGrowthStates-1;
                        end                      

                        setDensityMaskParams(fruit.id, "between",minState,maxState);
                    else
                        setDensityMaskParams(fruit.id, "equals",minState);
                    end

                    local sum = addDensityMaskedParallelogram(fruit.id,x,z, widthX,widthZ, heightX,heightZ, 0, g_currentMission.numFruitStateChannels, fruit.id, 0, g_currentMission.numFruitStateChannels, 1)
                end

                --increment by extraGrowthFactor between extraGrowthMinState and extraGrowthMaxState
                if self.growthData[self.currentGrowthTransitionPeriod][fruitName].extraGrowthMinState ~= nil 
                    and self.growthData[self.currentGrowthTransitionPeriod][fruitName].extraGrowthMaxState ~= nil then

                end
                


            end -- end of for loop

        end

        -- for index,fruit in pairs(g_currentMission.fruits) do

        --     print("debug start");
        --     local desc = FruitUtil.fruitIndexToDesc[index];
		-- 	local hours = FruitUtil.fruitTypeGrowths[desc.name].growthStateTime/3.6e6;

        --     print("index: " .. tostring(index) .. "desc.name " .. tostring(desc.name));
        --     print("fruit hours " .. tostring(hours));
            
        --     local growthData = FruitUtil.fruitTypeGrowths[desc.name];
		-- 	local maxState = growthData.numGrowthStates;
        --     print("minHarvestingGrowthState: " .. desc.minHarvestingGrowthState);
        --     print("growthdata: " .. tostring(growthData));
        --     print("max state: " .. tostring(maxState));
        --     print("Growth Data");
        --     --print_r(growthData);
        --     --print_r(fruit);
        --     --print_r(g_currentMission.numFruitStateChannels);
        --     local detailId = g_currentMission.terrainDetailId;
            
            
        --     --print("growthstate time: " .. getGrowthStateTime(detailId));
        --    -- local st,gt = getGrowthStateTime(detailId)
        --     --print("st: " .. st .. " gt " .. gt);
        --     local maxState = growthData.numGrowthStates;
        --     maxState = maxState -1;
        --     local x,z, widthX,widthZ, heightX,heightZ = Utils.getXZWidthAndHeight(id, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ);
        --     setDensityMaskParams(fruit.id, "between", 1,maxState)
		-- 	-- 			
		--     local sum = addDensityMaskedParallelogram(fruit.id,x,z, widthX,widthZ, heightX,heightZ,0, g_currentMission.numFruitStateChannels, fruit.id, 0, g_currentMission.numFruitStateChannels, 1)

        --     print("Done debug sum: " .. sum);


        -- end

        if self.currentZ < self.mapSegments - 1 then -- Starting with column 0 So index of last column is one less then the number of columns.
            -- Next column
            self.currentZ = self.currentZ + 1;
        elseif  self.currentX < self.mapSegments - 1 then -- Starting with row 0
            -- Next row
            self.currentX = self.currentX + 1;
            self.currentZ = 0;
        else
            -- Done with the loop, set up for the next one.
            self.currentX = 0;
            self.currentZ = 0;
            self.doGrowthTransition = false;
        end
    end
end

function ssGrowthManager:draw()

    

end

function ssGrowthManager:dayChanged()
end


function ssGrowthManager:seasonChanged()
    log("GM seasonChanged")
    -- local currentSeason = ssSeasonsUtil:seasonName()
    -- log("Today's season:" .. currentSeason)
    -- log("Today's season number:" .. ssSeasonsUtil:season())

    -- local funcTable =
    -- {
    --     [0] = self.handleSpring,
    --     [1] = self.handleAutumn,
    --     [2] = self.handleWinter,
    --     [3] = self.handleSummer,
    -- }

    -- local func = funcTable[ssSeasonsUtil:season()]

    -- if (func) then
    --     func()
    -- else
    --     log("GrowthManager: Fatal error. Season not found")
    -- end



end

