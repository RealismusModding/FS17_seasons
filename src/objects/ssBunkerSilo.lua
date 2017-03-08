---------------------------------------------------------------------------------------------------------
-- BUNKER SILO SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose:  To change the duration of the bunker silo fermentation
-- Authors:  Rahkiin
--

ssBunkerSilo = {}

function ssBunkerSilo:preLoad()
    BunkerSilo.loadFromAttributesAndNodes = Utils.overwrittenFunction(BunkerSilo.loadFromAttributesAndNodes, ssBunkerSilo.bunkerSiloLoadFromAttributesAndNodes)
end

function ssBunkerSilo:loadMap()
end

function ssBunkerSilo:bunkerSiloLoadFromAttributesAndNodes(superFunc, xmlFile, key)
    self.fermentingDuration = g_seasons.environment.daysInSeason / 3 * 24 * 60 * 60 -- '4 weeks'

    return superFunc(self, xmlFile, key)
end

-- FIXME: When season length changes this breaks
-- Solution: append load() and delete(), and add/remove a seasonChangeListener
