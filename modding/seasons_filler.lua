----------------------------------------------------------------------------------------------------
-- MAP COMPATIBILITY
----------------------------------------------------------------------------------------------------
-- Purpose:  Filler functions that are used when Seasons is not loaded.
-- Authors:  Rahkiin
--
-- Without this script, objects that are set to be invisible by default, when seasons is not
-- loaded, will still have an active collision mask. So this code creates the admirers and
-- when it is set invisible, it disables the collision mask as well.
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

-- Always create the objects.
-- We can't properly detect if Seasons is loaded, because
-- that depends on the load order.
if ssIcePlane == nil then
    local fn = function (self, id)
        if getVisibility(id) == false then
            setCollisionMask(id, 0)
        end
    end

    local class = {}
    class.onCreate = fn

    getfenv(0)["ssIcePlane"] = class
    getfenv(0)["ssSeasonAdmirer"] = class
    getfenv(0)["ssSnowAdmirer"] = class
end
