package.path = package.path .. ";data/scripts/lib/?.lua"

require("stringutility")
TurretGenerator = require("turretgenerator")
ShipGenerator = require("shipgenerator")
ShipUtility = require("shiputility")
Balancing = require("galaxy")

local Smuggler = {}

function Smuggler.getFaction()
    local name = "Bottan's Smugglers"%_T
    local faction = Galaxy():findFaction(name)

    if not faction then
        faction = Galaxy():createFaction(name, 240, 0)
    end

    return faction
end


function Smuggler.spawn(x, y)
    if not x or not y then
        x, y = Sector():getCoordinates()
    end

    -- only spawn him once
    if Sector():getEntitiesByScript("data/scripts/entity/story/smuggler.lua") then return end

    -- spawn
    local faction = Smuggler.getFaction()
    local volume = Balancing_GetSectorShipVolume(faction:getHomeSectorCoordinates()) * 15

    local translation = random():getDirection() * 500
    local position = MatrixLookUpPosition(-translation, vec3(0, 1, 0), translation)


    local boss = ShipGenerator.createShip(faction, position, volume)
    ShipUtility.addArmedTurretsToCraft(boss, 15)
    boss.title = "Bottan"

    Loot(boss.index):insert(InventoryTurret(TurretGenerator.generate(x, y, 0, Rarity(RarityType.Exotic))))
    Loot(boss.index):insert(SystemUpgradeTemplate("data/scripts/systems/teleporterkey8.lua", Rarity(RarityType.Legendary), Seed()))

    boss:addScript("story/smuggler.lua")

    return boss
end

function Smuggler.spawnEngineer(x, y)

    if not x or not y then
        x, y = Sector():getCoordinates()
    end

    -- only spawn him once
    if Sector():getEntitiesByScript("data/scripts/entity/story/smuggler.lua") then return end

    -- spawn
    local faction = Smuggler.getFaction()
    local volume = Balancing_GetSectorShipVolume(faction:getHomeSectorCoordinates()) * 2

    local translation = random():getDirection() * 500
    local position = MatrixLookUpPosition(-translation, vec3(0, 1, 0), translation)


    local entity = ShipGenerator.createShip(faction, position, volume)
    ShipUtility.addArmedTurretsToCraft(entity, 15)
    entity.title = "A Friend"%_T

    entity:addScript("story/smugglerengineer.lua")

    local player = Player()
    if player then
        ShipAI(entity.index):registerFriendFaction(player)
    end

    return entity
end

function Smuggler.spawnRepresentative(station)

    -- don't spawn him in the center
    local coords = vec2(Sector():getCoordinates())
    if length2(coords) < Balancing.BlockRingMin2 then return end

    -- only spawn him once
    if Sector():getEntitiesByScript("data/scripts/entity/story/smuggler.lua") then return end

    -- spawn
    local faction = Smuggler.getFaction()
    local volume = Balancing_GetSectorShipVolume(faction:getHomeSectorCoordinates()) * 2

    local translation = random():getDirection() * 500
    local position = MatrixLookUpPosition(-translation, vec3(0, 1, 0), translation)


    local entity = ShipGenerator.createShip(faction, Matrix(), volume)
    ShipUtility.addArmedTurretsToCraft(entity, 15)
    entity:addScript("story/smugglerrepresentative.lua")

    local distance = station:getBoundingSphere().radius + entity:getBoundingSphere().radius + 10
    local position = station.position
    position.pos = position.pos + position.up * distance
    entity.position = position

    ShipAI(entity.index):setPassive()

    return entity
end

return Smuggler
