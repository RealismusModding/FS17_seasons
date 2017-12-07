----------------------------------------------------------------------------------------------------
-- ADMIRER REGISTRATION
----------------------------------------------------------------------------------------------------
-- Purpose:  For setting up and tearing down admirers
-- Authors:  Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssAdmirerRegistration = {}

function ssAdmirerRegistration:preLoad()
    local sEnv = getfenv(0)

    self.icePlane = sEnv.ssIcePlane
    self.seasonAdmirer = sEnv.ssSeasonAdmirer
    self.snowAdmirer = sEnv.ssSnowAdmirer

    sEnv.ssIcePlane = ssIcePlane
    sEnv.ssSeasonAdmirer = ssSeasonAdmirer
    sEnv.ssSnowAdmirer = ssSnowAdmirer
end

function ssAdmirerRegistration:loadMap()
end

function ssAdmirerRegistration:deleteMap()
    local sEnv = getfenv(0)

    sEnv.ssIcePlane = self.icePlane
    sEnv.ssSeasonAdmirer = self.seasonAdmirer
    sEnv.ssSnowAdmirer = self.snowAdmirer
end
