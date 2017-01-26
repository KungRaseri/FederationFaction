if onServer() then

package.path = package.path .. ";data/scripts/lib/?.lua"

require ("utility")
require ("stringutility")

function initialize()
    Sector():registerCallback("onDestroyed", "onDestroyed")

end

function onDestroyed(destroyedIndex, destroyerIndex)

    local destroyed = Sector():getEntity(destroyedIndex)
    local destroyer = Sector():getEntity(destroyerIndex)

    if not destroyed or not destroyer then return end

    local destroyedFaction = destroyed.factionIndex
    local destroyerFaction = destroyer.factionIndex

    if not destroyedFaction or not destroyerFaction then return end

    if destroyed.factionIndex == destroyer.factionIndex then return end
    if destroyedFaction == -1 or destroyedFaction == 0 or destroyerFaction == -1 or destroyerFaction == 0 then return end

    -- find all factions that are present in the sector
    local crafts = {Sector():getEntitiesByComponent(ComponentType.Crew)}

    local factions = {}
    for _, entity in pairs(crafts) do
        factions[entity.factionIndex] = 1
    end

    factions[destroyedFaction] = nil
    factions[destroyerFaction] = nil

    local contributors = {}
    for _, index in pairs({destroyed:getDamageContributors()}) do
        contributors[index] = true
    end

    -- walk over all factions and determine relations to destroyed ship
    for factionIndex, _ in pairs(factions) do
        -- the faction is a third party who witnessed the destruction
        local faction = Faction(factionIndex)

        -- only react for AI factions
        if not faction.isPlayer then

            local relationsToVictim = faction:getRelations(destroyedFaction)
            local relationsToKiller = faction:getRelations(destroyerFaction)

            local change = -relationsToVictim / 50

             -- getting disliked by a faction that already doesn't like you is easy
             -- getting liked by a faction that already likes you takes more time
            if relationsToKiller < -20000 and change < 0 then change = change * 1.5 end
            if relationsToKiller > 20000 and change > 0 then change = change * 0.75 end

            -- modify the changes depending on faction properties
            local trust = (faction:getTrait("naive") + 1.4) / 2 -- 0.2 to 1.2
            local aggressive = faction:getTrait("sadistic") -- -0.5 to 1.5

            change = change * trust
            change = change + aggressive * 1500

            local destroyers = Faction(destroyerFaction)
            if not contributors[factionIndex] then
                if destroyed:hasScript("civilship.lua") then
                    change = change - 30000

                    if destroyers.isPlayer then
                        Player(destroyerFaction):sendChatMessage("Server", 2, "You destroyed a civil ship. Relations to all witnessing factions worsened."%_t)
                    end
                end
            else
                -- relations can't worsen when the observing faction helped destroy the ship
                change = math.max(change, 0)
            end

            -- relations can't worsen when the observing faction has really bad relations to the victim
            if relationsToVictim < -70000 then change = math.max(change, 0) end

            Galaxy():changeFactionRelations(destroyers, faction, change)
        end
    end

end

end
