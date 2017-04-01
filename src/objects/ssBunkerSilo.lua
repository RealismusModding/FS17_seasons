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
    BunkerSilo.loadFromAttributesAndNodes = Utils.overwrittenFunction(BunkerSilo.loadFromAttributesAndNodes, ssBunkerSilo.bunkerSiloLoadFromAttributesAndNodes)

    BunkerSilo.delete = Utils.overwrittenFunction(BunkerSilo.delete, ssBunkerSilo.bunkerSiloDelete)

    BunkerSilo.seasonChanged = ssBunkerSilo.bunkerSiloSeasonChanged
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

function ssBunkerSilo:bunkerSiloSeasonChanged()
    self.fermentingDuration = g_seasons.environment.daysInSeason / 3 * 24 * 60 * 60 -- '4 weeks'
end
