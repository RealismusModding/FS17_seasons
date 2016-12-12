---------------------------------------------------------------------------------------------------------
-- mapDir
---------------------------------------------------------------------------------------------------------
-- Purpose:  to allow map authors to add their mod directory which the seasons mod and other mods can use
-- Authors:  theSeb
--
-- add your own versions of seasons_animals.xml and seasons_growth.xml into the root folder of your map 
-- so that the seasons mod to be able to read them

mapDir = {};

addModEventListener(mapDir);


function mapDir:loadMap(name)
    g_currentMission.mapDir = g_currentModDirectory;
end

function mapDir:deleteMap()
end

function mapDir:mouseEvent(posX, posY, isDown, isUp, button)
end

function mapDir:keyEvent(unicode, sym, modifier, isDown)
end

function mapDir:update(dt)	
end

function mapDir:draw()
end

