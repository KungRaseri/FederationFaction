
function initialize()

end

function getUpdateInterval()
    return 1
end

function updateServer()
    -- find an ally that's damaged
    local damaged
    local friend
    for _, entity in pairs({Sector():getEntitiesByFaction(Entity().factionIndex)}) do
        if entity:hasComponent(ComponentType.Durability) or entity:hasComponent(ComponentType.Shield) then
            friend = entity

            if entity.durability / entity.maxDurability < 0.9 then
                damaged = entity
            elseif entity.shieldDurability / entity.shieldMaxDurability < 0.9 then
                damaged = entity
            end
        end
    end

    if damaged then
        -- "attack" the damaged ally
        ShipAI():setAttack(damaged)

--        print ("healing friend " .. damaged.index)
    elseif friend then
        -- no damaged allies, fly near a friend
        ShipAI():setFollow(friend)
--        print ("following friend " .. friend.index)
    else
        -- no allies, run away
        Sector():deleteEntityJumped(Entity())
--        print ("running away")
    end
end
