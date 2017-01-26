package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

require ("galaxy")
require ("stringutility")
SectorSpecifics = require ("sectorspecifics")

local base = 0

local dirs =
{
    {name = "E"%_t,    angle = math.pi * 2 * 0 / 16},
    {name = "ENE"%_t,  angle = math.pi * 2 * 1 / 16},
    {name = "NE"%_t,   angle = math.pi * 2 * 2 / 16},
    {name = "NNE"%_t,  angle = math.pi * 2 * 3 / 16},
    {name = "N"%_t,    angle = math.pi * 2 * 4 / 16},
    {name = "NNW"%_t,  angle = math.pi * 2 * 5 / 16},
    {name = "NW"%_t,   angle = math.pi * 2 * 6 / 16},
    {name = "WNW"%_t,  angle = math.pi * 2 * 7 / 16},
    {name = "W"%_t,    angle = math.pi * 2 * 8 / 16},
    {name = "WSW"%_t,  angle = math.pi * 2 * 9 / 16},
    {name = "SW"%_t,   angle = math.pi * 2 * 10 / 16},
    {name = "SSW"%_t,  angle = math.pi * 2 * 11 / 16},
    {name = "S"%_t,    angle = math.pi * 2 * 12 / 16},
    {name = "SSE"%_t,  angle = math.pi * 2 * 13 / 16},
    {name = "SE"%_t,   angle = math.pi * 2 * 14 / 16},
    {name = "ESE"%_t,  angle = math.pi * 2 * 15 / 16},
    {name = "E"%_t,    angle = math.pi * 2 * 16 / 16}
}

function getGateName()

    local x, y = Sector():getCoordinates()
    local tx, ty = WormHole():getTargetCoordinates()

    local specs = SectorSpecifics(tx, ty, getGameSeed())

    -- find "sky" direction to name the gate
    local ownAngle = math.atan2(ty - y, tx - x) + math.pi * 2
    if ownAngle > math.pi * 2 then ownAngle = ownAngle - math.pi * 2 end
    if ownAngle < 0 then ownAngle = ownAngle + math.pi * 2 end

    local dirString = ""
    local min = 3.0
    for _, dir in pairs(dirs) do

        local d = math.abs(ownAngle - dir.angle)
        if d < min then
            min = d
            dirString = dir.name
        end
    end

    return "${dir} Gate to ${sector}"%_t % {dir = dirString, sector = specs.name}
end

function initialize()

    local entity = Entity()
    local wormhole = entity.cpwormhole

    local tx, ty = wormhole:getTargetCoordinates()
    local x, y = Sector():getCoordinates()

    local d = distance(vec2(x, y), vec2(tx, ty))

    local cx = (x + tx) / 2
    local cy = (y + ty) / 2

    base = math.ceil(d * 30 * Balancing_GetSectorRichnessFactor(cx, cy))

--    print("richness: " .. Balancing_GetSectorRichnessFactor(cx, cy))

    if onServer() then
        -- get callbacks for sector readiness
        entity:registerCallback("destinationSectorReady", "updateTooltip")

        updateTooltip()
    end

    if onClient() then
        invokeServerFunction("updateTooltip")

        if EntityIcon().icon == "" then
            EntityIcon().icon = "data/textures/icons/pixel/gate.png"
        end

        Entity().title = getGateName()
    end
end

function updateTooltip(ready)

    if onServer() then
        -- on the server, check if the sector is ready,
        -- then invoke client sided tooltip update with the ready variable
        if ready == nil then
            local entity = Entity()
            local transferrer = EntityTransferrer(entity.index)

            ready = transferrer.sectorReady
        end

        broadcastInvokeClientFunction("updateTooltip", ready);
        return
    else
        -- on the client, calculate the fee and update the tooltip
        local fee = math.ceil(base * factor(Player(), Faction()))
        local tooltip = EntityTooltip(Entity().index)

        tooltip:setDisplayTooltip(0, "Fee"%_t, tostring(fee) .. "$")

        if not ready then
            tooltip:setDisplayTooltip(1, "Not Ready"%_t, "Not Ready"%_t)
        else
            tooltip:setDisplayTooltip(1, "Ready"%_t, "Ready"%_t)
        end

    end
end

function factor(providingFaction, orderingFaction)

    if orderingFaction.index == providingFaction.index then return 0 end

    local relation = 0

    if onServer() then
        relation = providingFaction:getRelations(orderingFaction.index)
    else
        local player = Player()
        if providingFaction.index == player.index then
            relation = player:getRelations(orderingFaction.index)
        else
            relation = player:getRelations(providingFaction.index)
        end
    end

    local factor = relation / 100000 -- -1 to 1

    factor = factor + 1.0 -- 0 to 2
    factor = 2.0 - factor -- 2 to 0

    -- pay extra if relations are not good
    if relation < 0 then
        factor = factor * 1.5
    end

    return factor
end

function canTransfer(index)

    local entity = Entity(index)

    local faction = Faction(entity.factionIndex)

    -- AI factions can always pass
    if not faction.isPlayer then return 1 end

    local player = Player(entity.factionIndex)

    local fee = math.ceil(base * factor(player, Faction()))
    local canPay, msg, args = player:canPay(fee)

    if not canPay then
        player:sendChatMessage("Gate Control"%_t, 1, msg, unpack(args))
        return 0
    end

    player:sendChatMessage("Gate Control"%_t, 3, "You paid %i credits passage fee."%_t, fee)

    player:pay(fee)

    return 1
end
