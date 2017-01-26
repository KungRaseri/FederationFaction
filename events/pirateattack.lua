if onServer() then

package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

require ("galaxy")
require ("randomext")
require ("stringutility")
local PirateGenerator = require ("pirategenerator")
local UpgradeGenerator = require ("upgradegenerator")
local TurretGenerator = require ("turretgenerator")


local ships = {}
local reward = 0
local reputation = 0

local participants = {}

function secure()
    return {reward = reward, reputation = reputation, ships = ships}
end

function restore(data)
    ships = data.ships
    reputation = data.reputation
    reward = data.reward
end

function initialize()

    -- no pirate attacks at the very edge of the galaxy
    local x, y = Sector():getCoordinates()
    if length(vec2(x, y)) > 560 then
        print ("Too far out for pirate attacks.")
        terminate()
        return
    end

    ships = {}
    participants = {}
    reward = 0
    reputation = 0

    local scaling = Sector().numPlayers
    if scaling == 0 then
        terminate()
        return
    end

    if scaling == 1 then
        local player = Sector():getPlayers()
        local hx, hy = player:getHomeSectorCoordinates()
        if hx == x and hy == y and player.playtime < 30 * 60 then
            print ("Player's playtime is below 30 minutes (%is), cancelling pirate attack.", player.playtime)
            terminate()
            return
        end
    end

    -- create attacking ships
    local dir = normalize(vec3(getFloat(-1, 1), getFloat(-1, 1), getFloat(-1, 1)))
    local up = vec3(0, 1, 0)
    local right = normalize(cross(dir, up))
    local pos = dir * 1000

    local attackers = getInt(1, 4)

    if attackers == 1 then
        reward = 2.0

        local pirate = PirateGenerator.createScaledRaider(MatrixLookUpPosition(-dir, up, pos))
        table.insert(ships, pirate.index)
        pirate:registerCallback("onDestroyed", "onShipDestroyed")

        local distance = pirate:getBoundingSphere().radius * 2 + 20

        local pirate = PirateGenerator.createScaledBandit(MatrixLookUpPosition(-dir, up, pos + right * distance))
        table.insert(ships, pirate.index)
        pirate:registerCallback("onDestroyed", "onShipDestroyed")

        local pirate = PirateGenerator.createScaledBandit(MatrixLookUpPosition(-dir, up, pos + right * -distance))
        table.insert(ships, pirate.index)
        pirate:registerCallback("onDestroyed", "onShipDestroyed")


    elseif attackers == 2 then
        reward = 1.5

        local pirate = PirateGenerator.createScaledPirate(MatrixLookUpPosition(-dir, up, pos))
        table.insert(ships, pirate.index)
        pirate:registerCallback("onDestroyed", "onShipDestroyed")

        local distance = pirate:getBoundingSphere().radius * 2 + 20

        local pirate = PirateGenerator.createScaledBandit(MatrixLookUpPosition(-dir, up, pos + right * distance))
        table.insert(ships, pirate.index)
        pirate:registerCallback("onDestroyed", "onShipDestroyed")

        local pirate = PirateGenerator.createScaledBandit(MatrixLookUpPosition(-dir, up, pos + right * -distance))
        table.insert(ships, pirate.index)
        pirate:registerCallback("onDestroyed", "onShipDestroyed")

    elseif attackers == 3 then
        reward = 1.5

        local pirate = PirateGenerator.createScaledPirate(MatrixLookUpPosition(-dir, up, pos))
        table.insert(ships, pirate.index)
        pirate:registerCallback("onDestroyed", "onShipDestroyed")

        local distance = pirate:getBoundingSphere().radius * 2 + 20

        local pirate = PirateGenerator.createScaledPirate(MatrixLookUpPosition(-dir, up, pos + right * distance))
        table.insert(ships, pirate.index)
        pirate:registerCallback("onDestroyed", "onShipDestroyed")

        local pirate = PirateGenerator.createScaledPirate(MatrixLookUpPosition(-dir, up, pos + right * -distance))
        table.insert(ships, pirate.index)
        pirate:registerCallback("onDestroyed", "onShipDestroyed")

    else
        reward = 1.0

        local pirate = PirateGenerator.createScaledBandit(MatrixLookUpPosition(-dir, up, pos))
        table.insert(ships, pirate.index)
        pirate:registerCallback("onDestroyed", "onShipDestroyed")

        local distance = pirate:getBoundingSphere().radius * 2 + 20

        local pirate = PirateGenerator.createScaledBandit(MatrixLookUpPosition(-dir, up, pos + right * distance))
        table.insert(ships, pirate.index)
        pirate:registerCallback("onDestroyed", "onShipDestroyed")

        local pirate = PirateGenerator.createScaledBandit(MatrixLookUpPosition(-dir, up, pos + right * -distance))
        table.insert(ships, pirate.index)
        pirate:registerCallback("onDestroyed", "onShipDestroyed")

        local pirate = PirateGenerator.createScaledOutlaw(MatrixLookUpPosition(-dir, up, pos + right * -distance * 2.0))
        table.insert(ships, pirate.index)
        pirate:registerCallback("onDestroyed", "onShipDestroyed")

        local pirate = PirateGenerator.createScaledOutlaw(MatrixLookUpPosition(-dir, up, pos + right * distance * 2.0))
        table.insert(ships, pirate.index)
        pirate:registerCallback("onDestroyed", "onShipDestroyed")

    end

    reputation = reward * 2000
    reward = reward * 4500 * Balancing_GetSectorRichnessFactor(Sector():getCoordinates())

    Sector():broadcastChatMessage("Server"%_t, 2, "Pirates are attacking the sector!"%_t)
end

function getUpdateInterval()
    return 15
end

function update(timeStep)

    -- check if all ships are still there
    -- ships might have changed sector or deleted in another way, which doesn't trigger destruction callback
    local sector = Sector()
    for i, entityIndex in pairs(ships) do
        local pirate = sector:getEntity(entityIndex)
        if pirate == nil then
            ships[i] = nil
        end
    end

    -- if not -> end event
    if tablelength(ships) == 0 then
        endEvent()
    end
end

function onShipDestroyed(shipIndex)

    ships[shipIndex] = nil

    local ship = Entity(shipIndex)
    local damagers = {ship:getDamageContributorPlayers()}
    for i, v in pairs(damagers) do
        participants[v] = v
    end

    -- if they're all destroyed, the event ends
    if tablelength(ships) == 0 then
        endEvent()
    end
end


function endEvent()

    local messages =
    {
        "Thank you for defeating those pirates. You have our endless gratitude."%_t,
        "We thank you for taking care of those ships. We transferred a reward to your account."%_t,
        "Thank you for taking care of those pirates. We transferred a reward to your account."%_t,
    }

    local faction = Galaxy():getLocalFaction(Sector():getCoordinates())
    if faction then
        -- give payment to players who participated
        for i, v in pairs(participants) do
            local player = Player(i)

            player:sendChatMessage(faction.name, 0, getRandomEntry(messages))
            player:receive(reward)
            Galaxy():changeFactionRelations(player, faction, reputation)

            local x, y = Sector():getCoordinates()
            local object

            if random():getFloat() < 0.5 then
                object = InventoryTurret(TurretGenerator.generate(x, y, 0, Rarity(RarityType.Uncommon)))
            else
                UpgradeGenerator.initialize(random():createSeed())
                object = UpgradeGenerator.generateSystem(Rarity(RarityType.Uncommon))
            end

            if object then player:getInventory():add(object) end
        end
    end

    terminate()
end

end
