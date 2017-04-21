----------------------------------------------------------------------------------------------------
-- STORAGE SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  To change storage properties
-- Authors:  Rahkiin, reallogger, theSeb 
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

--FIXME: probably should not be in the placeable subdir but don't see a logical place for it right now. objects? misc?

ssStorage = {}

function ssStorage:preLoad()
    Storage.load = Utils.overwrittenFunction(Storage.load, ssStorage.load)
    Storage.seasonLengthChanged = ssStorage.storageSeasonLengthChanged
    
end

function ssStorage:loadMap()
end

function ssStorage:load(superFunc)
    local ret = superFunc(self)
    --TODO: implement
    --self.costsPerFillLevelAndDay = ???
    return ret
end

function ssStorage:placeableSeasonLengthChanged()
    --TODO: implement
end
