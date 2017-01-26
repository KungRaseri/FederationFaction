if onServer() then

package.path = package.path .. ";data/scripts/lib/?.lua"

require ("randomext")
Balancing = require("galaxy")

function initialize()
    Sector():registerCallback("onStartFiring", "onSetToAggressive")
    Entity():registerCallback("onDestroyed", "onDestroyed")
end

function onSetToAggressive(entityIndex)
    local entity = Entity(entityIndex)
    local self = Entity()

    if entity.factionIndex ~= self.factionIndex then
        ShipAI():registerEnemyFaction(entity.factionIndex)
    end
end

function onDestroyed()
    local position = vec2(Sector():getCoordinates())

    if length2(position) < Balancing.BlockRingMin2 then
        if random():getInt(1, 3) == 1 then

            local entity = Entity()
            Sector():dropUpgrade(
                entity.translationf,
                nil,
                nil,
                SystemUpgradeTemplate("data/scripts/systems/wormholeopener.lua", Rarity(RarityType.Rare), random():createSeed()))
        end
    end
end


end
