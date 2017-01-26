
package.path = package.path .. ";data/scripts/lib/?.lua"

if onServer() then

ShipGenerator = require("shipgenerator")
Placer = require("placer")

require ("randomext")
require ("stringutility")

local data = {}
local defenderTimer = 0

function getUpdateInterval()
    return 5
end

function initialize(defenders, attackers)
    data.defenders = defenders
    data.attackers = attackers
    data.defendersSpawned = false

    if not defenders or not attackers then
        return
    end

    local defendingFaction = Faction(defenders)
    local attackingFaction = Faction(attackers)
    Galaxy():setFactionRelations(attackingFaction, defendingFaction, -100000)

    -- spawn enemy ships
    spawnShips(Faction(data.attackers))

    deferredCallback(5.0, "defendersReaction");

    -- spawn defenders shortly after
    deferredCallback(20.0, "trySpawnDefenders")
end

function spawnShips(faction)
    local x, y = Sector():getCoordinates()

    local position = random():getDirection() * 1500
    local dir = normalize(-position)
    local up = vec3(0, 1, 0)
    local right = normalize(cross(up, dir))
    up = normalize(cross(right, dir))

    local ships = {}
    for i = -4, 4 do
        local pos = position + right * i * 100

        local ship
        if i >= -1 and i <= 1 and random():test(0.75) then
            ship = ShipGenerator.createCarrier(faction, MatrixLookUpPosition(dir, up, pos))
        else
            ship = ShipGenerator.createDefender(faction, MatrixLookUpPosition(dir, up, pos))
        end

        ship:addScriptOnce("data/scripts/sector/factionwar/temporarydefender.lua")
        table.insert(ships, ship)
    end

    Placer.resolveIntersections(ships)
end

function defendersReaction()
    local defendingFaction = Faction(data.defenders)
    Sector():broadcastChatMessage(defendingFaction.name, ChatMessageType.Normal, "We're under attack! Call in reinforcements, NOW!"%_T)
    Sector():broadcastChatMessage(defendingFaction.name, ChatMessageType.Warning, "This sector is under attack by another faction!"%_T)
end

function trySpawnDefenders()
    spawnShips(Faction(data.defenders))
end

function updateServer()
    local temporaryDefenders = {Sector():getEntitiesByScript("factionwar/temporarydefender")}

    if #temporaryDefenders == 0 then
        terminate()
    end
end

function secure()
    return data
end

function restore(data_in)
    data = data_in
end

end
