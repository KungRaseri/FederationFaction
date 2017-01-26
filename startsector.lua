
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

SectorGenerator = require ("SectorGenerator")
Placer = require("placer")

local SectorTemplate = {}

-- player is the player who triggered the creation of the sector (only set in start sector, otherwise nil)
function SectorTemplate.generate(player, seed, x, y)
    math.randomseed(seed)

    local generator = SectorGenerator(x, y)

    -- create an early ally of the player
    local faction = Galaxy():getNearestFaction(x, y)

    -- create asteroid fields
    for i = 1, 2 do
        local mat = generator:createAsteroidField()
        if math.random() < 0.5 then generator:createStash(mat) end
    end

    -- create big asteroids
    local numSmallFields = math.random(4, 10)
    for i = 1, numSmallFields do
        generator:createSmallAsteroidField()
    end

    generator:createShipyard(faction)
    generator:createRepairDock(faction)
    local station = generator:createEquipmentDock(faction)
    station:removeScript("data/scripts/entity/merchants/fightermerchant.lua")

    -- create an asteroid field with a resource trader inside it, the player will spawn here and immediately have something to mine
    local mat = generator:createAsteroidField()
    local station = generator:createStation(faction, "data/scripts/entity/merchants/resourcetrader.lua");
    station.position = mat

    -- create a mine in the start sector
    local minedGoods = {"Silicium", "Ore", "Crystal", "Aluminium", "Coal"}
    local station = generator:createStation(faction)
    local mat = generator:createAsteroidField()
    station.position = mat
    station:addScript("data/scripts/entity/merchants/factory.lua", minedGoods[getInt(1, tablelength(minedGoods))])

    -- create a big asteroid
    local mat = generator:createAsteroidField()
    local asteroid = generator:createClaimableAsteroid()
    asteroid.position = mat

    for i = 1, 5 do
        ShipGenerator.createDefender(faction, generator:getPositionInSector())
    end

    generator:createGates()

    Sector():addScript("data/scripts/sector/events.lua", "events/pirateattack.lua")

    generator:addAmbientEvents()
    Sector():removeScript("factionwar/initfactionwar.lua")

    Placer.resolveIntersections()
end

return SectorTemplate
