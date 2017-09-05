----------------------------------------------------------------------------------------------------
-- ADMIRER REGISTRATION
----------------------------------------------------------------------------------------------------
-- Purpose:  For setting up and tearing down admirers
-- Authors:  Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssAdmirerRegistration = {}

function ssAdmirerRegistration:preload()
    ssUtil.overwrittenConstant(getfenv(0), "ssIcePlane", ssIcePlane)
    ssUtil.overwrittenConstant(getfenv(0), "ssSeasonAdmirer", ssSeasonAdmirer)
    ssUtil.overwrittenConstant(getfenv(0), "ssSnowAdmirer", ssSnowAdmirer)
end

function ssAdmirerRegistration:loadMap()
end
