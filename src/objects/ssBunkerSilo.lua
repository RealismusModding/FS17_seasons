----------------------------------------------------------------------------------------------------
-- BUNKER SILO SCRIPT
----------------------------------------------------------------------------------------------------
-- Purpose:  To change the duration of the bunker silo fermentation
-- Authors:  Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssBunkerSilo = {}

function ssBunkerSilo:preLoad()
    ssUtil.overwrittenFunction(BunkerSilo, "loadFromAttributesAndNodes", ssBunkerSilo.bunkerSiloLoadFromAttributesAndNodes)
    ssUtil.overwrittenFunction(BunkerSilo, "delete", ssBunkerSilo.bunkerSiloDelete)
    ssUtil.overwrittenConstant(BunkerSilo, "seasonLengthChanged", ssBunkerSilo.bunkerSiloSeasonLengthChanged)
end

function ssBunkerSilo:loadMap()
end

function ssBunkerSilo:bunkerSiloLoadFromAttributesAndNodes(superFunc, xmlFile, key)
    self.fermentingDuration = g_seasons.environment.daysInSeason / 3 * 24 * 60 * 60 -- '4 weeks'

    g_seasons.environment:addSeasonLengthChangeListener(self)

    return superFunc(self, xmlFile, key)
end

function ssBunkerSilo:bunkerSiloDelete(superFunc)
    superFunc(self)

    g_seasons.environment:removeSeasonLengthChangeListener(self)
end

function ssBunkerSilo:bunkerSiloSeasonLengthChanged()
    self.fermentingDuration = g_seasons.environment.daysInSeason / 3 * 24 * 60 * 60 -- '4 weeks'
end
