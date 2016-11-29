---------------------------------------------------------------------------------------------------------
-- GROWTH MANAGER SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  to manage growth as the season changes
-- Authors:  theSeb
-- Credits: Inspired by upsidedown's growth manager mod

ssGrowthManager = {}


LAST_GROWTH_STATE = 99; -- needs to be set to the fruit's numGrowthStates-1


growthData = { 	[1]={ 				
						["barley"]			={fruitName="barley", normalGrowthMinState=1, normalGrowthMaxState=3},
						["wheat"]			={fruitName="wheat", normalGrowthMinState=1, normalGrowthMaxState=3},					
						["rape"]			={fruitName="rape", normalGrowthState=1},
						["maize"]			={fruitName="maize", normalGrowthState=1},
						["soybean"]			={fruitName="soybean", witherState=1},
						["sunflower"]		={fruitName="sunflower", witherState=1},
						["potato"]			={fruitName="potato", normalGrowthState=1},
						["sugarBeet"]		={fruitName="sugarBeet", normalGrowthState=1},
						["poplar"]			={fruitName="poplar", normalGrowthMinState=1, normalGrowthMaxState=LAST_GROWTH_STATE},
						["grass"]			={fruitName="grass", normalGrowthMinState=1, normalGrowthMaxState=LAST_GROWTH_STATE},
						
						
				}, 
				
				[2]={ 	["barley"]			={fruitName="barley", normalGrowthMinState=1, normalGrowthMaxState=3},
						["wheat"]			={fruitName="wheat", normalGrowthMinState=1, normalGrowthMaxState=3},
						["rape"]			={fruitName="rape", normalGrowthMinState=1, normalGrowthMaxState=2},
						["maize"]			={fruitName="maize", normalGrowthMinState=1, normalGrowthMaxState=2},
						["soybean"]			={fruitName="soybean", normalGrowthState=1},
						["sunflower"]		={fruitName="sunflower", normalGrowthState=1},
						["potato"]			={fruitName="potato", normalGrowthMinState=1, normalGrowthMaxState=2},
						["sugarBeet"]		={fruitName="sugarBeet", normalGrowthMinState=1, normalGrowthMaxState=2},
						["poplar"]			={fruitName="poplar", normalGrowthMinState=1, normalGrowthMaxState=LAST_GROWTH_STATE},
						["grass"]			={fruitName="grass", normalGrowthMinState=1, normalGrowthMaxState=LAST_GROWTH_STATE},

				},
				
				[3]={ 	["barley"]			={fruitName="barley", normalGrowthMinState=2, normalGrowthMaxState=4, witherState=1},
						["wheat"]			={fruitName="wheat", normalGrowthMinState=2, normalGrowthMaxState=4, witherState=1},
						["rape"]			={fruitName="rape", normalGrowthMinState=2, normalGrowthMaxState=3, witherState=1},
						["maize"]			={fruitName="maize", normalGrowthMinState=1, normalGrowthMaxState=3},
						["soybean"]			={fruitName="soybean", normalGrowthMinState=1, normalGrowthMaxState=2},
						["sunflower"]		={fruitName="sunflower", normalGrowthMinState=1, normalGrowthMaxState=2},
						["potato"]			={fruitName="potato", normalGrowthMinState=2, normalGrowthMaxState=3, witherState=1},
						["sugarBeet"]		={fruitName="sugarBeet", normalGrowthMinState=2, normalGrowthMaxState=3, witherState=1},
						["grass"]			={fruitName="grass", normalGrowthMinState=1, normalGrowthMaxState=LAST_GROWTH_STATE},
				},
				
				[4]={ 	["barley"]			={fruitName="barley",normalGrowthMinState=3, normalGrowthMaxState=5, witherState=1},
						["wheat"]			={fruitName="wheat",normalGrowthMinState=3, normalGrowthMaxState=5, witherState=1},
						["rape"]			={fruitName="rape", normalGrowthMinState=3, normalGrowthMaxState=4, witherState=1},
						["maize"]			={fruitName="maize", normalGrowthMinState=2, normalGrowthMaxState=4, witherState=1},
						["soybean"]			={fruitName="soybean", normalGrowthMinState=1, normalGrowthMaxState=3},
						["sunflower"]		={fruitName="sunflower", normalGrowthMinState=2, normalGrowthMaxState=3,witherState=1},
						["potato"]			={fruitName="potato", normalGrowthMinState=3, normalGrowthMaxState=4, witherState=1},
						["sugarBeet"]		={fruitName="sugarBeet", normalGrowthMinState=3, normalGrowthMaxState=4, witherState=1},
						["poplar"]			={fruitName="poplar", normalGrowthMinState=1, normalGrowthMaxState=LAST_GROWTH_STATE},
						["grass"]			={fruitName="grass", normalGrowthMinState=1, normalGrowthMaxState=LAST_GROWTH_STATE},

				},  
				
				[5]={ 	["barley"]			={fruitName="barley", normalGrowthState=6, witherState=1, extraGrowthMinState=4, extraGrowthMaxState=5, extraGrowthFactor=2},
						["wheat"]			={fruitName="wheat", normalGrowthState=6, witherState=1, extraGrowthMinState=4, extraGrowthMaxState=5, extraGrowthFactor=2},
						["rape"]			={fruitName="rape", extraGrowthMinState=4, extraGrowthMaxState=5, extraGrowthFactor=2, witherState=1},
						["maize"]			={fruitName="maize", extraGrowthMinState=3, extraGrowthMaxState=5, extraGrowthFactor=2, witherState=1},
						["soybean"]			={fruitName="soybean", normalGrowthMinState=2, normalGrowthMaxState=4,witherState=1},
						["sunflower"]		={fruitName="sunflower", normalGrowthMinState=3, normalGrowthMaxState=4,witherState=1},
						["potato"]			={fruitName="potato", normalGrowthMinState=4, normalGrowthMaxState=5, witherState=1},
						["sugarBeet"]			={fruitName="sugarBeet", normalGrowthMinState=4, normalGrowthMaxState=5, witherState=1},
						["grass"]			={fruitName="grass", normalGrowthMinState=2, normalGrowthMaxState=LAST_GROWTH_STATE},
				}, 
				
				[6]={ 	["barley"]			={fruitName="barley",normalGrowthState=6, witherState=1},
						["wheat"]			={fruitName="wheat",normalGrowthState=6, witherState=1},
						["rape"]			={fruitName="rape", normalGrowthMinState=6, witherState=1},
						["maize"]			={fruitName="maize", normalGrowthMinState=5, normalGrowthMaxState=6, witherState=1},
						["soybean"]			={fruitName="soybean", extraGrowthMinState=3, extraGrowthMaxState=5, extraGrowthFactor=2, witherState=1},
						["sunflower"]		={fruitName="sunflower", extraGrowthMinState=4, extraGrowthMaxState=5, extraGrowthFactor=2, witherState=1},
						["potato"]			={fruitName="potato", normalGrowthMinState=5, normalGrowthMaxState=LAST_GROWTH_STATE, witherState=1},
						["sugarBeet"]		={fruitName="sugarBeet", normalGrowthMinState=5, normalGrowthMaxState=6, witherState=1},
						["grass"]			={fruitName="grass", normalGrowthMinState=2, normalGrowthMaxState=LAST_GROWTH_STATE},
				},
				
				[7]={ 	["barley"]			={fruitName="barley",normalGrowthState=1},
						["wheat"]			={fruitName="wheat",normalGrowthState=1},			 	
						["maize"]			={fruitName="maize", normalGrowthState=6, witherState=1},	
						["soybean"]			={fruitName="soybean", normalGrowthMinState=5, normalGrowthMaxState=6, witherState=1},
						["sunflower"]		={fruitName="sunflower", normalGrowthState=6, witherState=1},
						["potato"]			={fruitName="potato", normalGrowthState=LAST_GROWTH_STATE, witherState=1},
						["sugarBeet"]		={fruitName="sugarBeet", normalGrowthState=6, witherState=1},
						["poplar"]			={fruitName="poplar", normalGrowthMinState=1, normalGrowthMaxState=LAST_GROWTH_STATE},
						["grass"]			={fruitName="grass", normalGrowthMinState=1, normalGrowthMaxState=LAST_GROWTH_STATE},
				}, 	
				
				[8]={ 	["barley"]			={fruitName="barley",normalGrowthMinState=1, normalGrowthMaxState=2,witherState=7},
						["wheat"]			={fruitName="wheat",normalGrowthMinState=1, normalGrowthMaxState=1,witherState=7},
						["rape"]			={fruitName="rape", witherMinState=1, witherMaxState=7}, 
						["maize"]			={fruitName="maize", witherMinState=1, witherMaxState=7},
						["soybean"]			={fruitName="soybean", normalGrowthState=6, witherState=1},
						["sunflower"]		={fruitName="sunflower", witherMinState=1, witherMaxState=7},
						["potato"]			={fruitName="potato", witherState=1},
						["sugarBeet"]		={fruitName="sugarBeet", witherState=1},
						["grass"]			={fruitName="grass", normalGrowthMinState=1, normalGrowthMaxState=LAST_GROWTH_STATE},
						
							
 				}, 	
				[9]={ 	["soybean"]			={fruitName="soybean", witherMinState=1, witherMaxState=7},
						["potato"]			={fruitName="potato", witherMinState=1, witherMaxState=7},
						["sugarBeet"]		={fruitName="sugarBeet", witherMinState=1, witherMaxState=7},
						["grass"]			={fruitName="grass", setGrowthMinState=1, setGrowthMaxState=LAST_GROWTH_STATE,setGrowthState=1},
						
 				},
				[10]={};
				[11]={};
				[12]={};			
};



ssGrowthManager.fakeDay = 1;
ssGrowthManager.doGrowthTransition = false;
ssGrowthManager.testGrowthTransitionPeriod = 1;

function ssGrowthManager.preSetup()
end

function ssGrowthManager.setup()
    addModEventListener(ssGrowthManager);
end

function ssGrowthManager:loadMap(name)
    --g_currentMission.environment:addDayChangeListener(self);
    --g_currentMission.environment:addHourChangeListener(self);

    --ssSeasonsMod:addSeasonChangeListener(self);
    log("Growth manager loading");
   
   --lock changing the growth speed option and set growth rate to 1 (no growth)
   g_currentMission:setPlantGrowthRate(1,nil);
   g_currentMission:setPlantGrowthRateLocked(true);

    print("here now");


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
        -- if (self.doAddSnow == true) then
        --     self.doAddSnow = false;
        -- else
        --     self.doAddSnow = true;
        -- end

        -- self.fakeDay = self.fakeDay + ssSeasonsUtil.daysInSeason;
        -- log("Season changed to " .. ssSeasonsUtil:seasonName(self.fakeDay) );
        --self:seasonChanged();

        log("Season change transition: " .. ssGrowthManager.testGrowthTransitionPeriod);
        ssGrowthManager.doGrowthTransition = true;

        if ssGrowthManager.testGrowthTransitionPeriod < 12 then
            ssGrowthManager.testGrowthTransitionPeriod = ssGrowthManager.testGrowthTransitionPeriod + 1;
        else
            ssGrowthManager.testGrowthTransitionPeriod = 1;
        end

        --log("Season change transition: " .. ssGrowthManager.testGrowthTransitionPeriod);    

        --print("here");
    end
end

function ssGrowthManager:readStream(streamId, connection)
    --self:seasonChanged()
end

function ssGrowthManager:update(dt)
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

