
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

SectorGenerator = require ("SectorGenerator")
Placer = require("placer")

local SectorTemplate = {}

-- must be defined, will be used to get the probability of this sector
function SectorTemplate.getProbabilityWeight(x, y)
    return 100
end

function SectorTemplate.offgrid(x, y)
    return true
end

-- this function returns whether or not a sector should have space gates
function SectorTemplate.gates(x, y)
    return false
end

-- player is the player who triggered the creation of the sector (only set in start sector, otherwise nil)
function SectorTemplate.generate(player, seed, x, y)
    math.randomseed(seed);

    local generator = SectorGenerator(x, y)

    local faction = Galaxy():getPirateFaction(Balancing_GetPirateLevel(x, y))

    -- create a shipyard station
    generator:createShipyard(faction);

    -- maybe create some asteroids
    local numFields = math.random(0, 2)
    for i = 1, numFields do
        generator:createAsteroidField();
    end

    for i = 1, numFields do
        generator:createBigAsteroid();
    end

    -- create ships
    local numShips = math.random(10, 15)

    for i = 1, numShips do
        local ship = ShipGenerator.createMilitaryShip(faction, generator:getPositionInSector())
        ship:addScript("ai/patrol.lua")
    end

    local defenders = math.random(4, 6)
    for i = 1, defenders do
        ShipGenerator.createDefender(faction, generator:getPositionInSector())
    end

    local numSmallFields = math.random(2, 5)
    for i = 1, numSmallFields do
        generator:createSmallAsteroidField()
    end

    if math.random() < generator:getWormHoleProbability() then generator:createRandomWormHole() end

    Sector():addScript("data/scripts/sector/events.lua", "events/pirateattack.lua")

    generator:addOffgridAmbientEvents()
    Placer.resolveIntersections()
end


return SectorTemplate
