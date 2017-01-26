
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

SectorGenerator = require ("SectorGenerator")
ShipGenerator = require ("shipgenerator")
Placer = require("placer")

local SectorTemplate = {}

-- must be defined, will be used to get the probability of this sector
function SectorTemplate.getProbabilityWeight(x, y)
    return 650
end

function SectorTemplate.offgrid(x, y)
    return false
end

-- this function returns whether or not a sector should have space gates
function SectorTemplate.gates(x, y)
    return false
end

-- player is the player who triggered the creation of the sector (only set in start sector, otherwise nil)
function SectorTemplate.generate(player, seed, x, y)
    math.randomseed(seed);

    local generator = SectorGenerator(x, y)

    local numFields = math.random(3, 5)
    local numAsteroids = math.random(1, 2)

    for i = 1, numFields do
        local mat = generator:createAsteroidField(0.075);
        if math.random() < 0.5 then generator:createBigAsteroid(mat); end
    end

    local numSmallFields = math.random(8, 15)
    for i = 1, numSmallFields do
        local mat = generator:createSmallAsteroidField(0.1)
        if math.random() < 0.15 then generator:createStash(mat) end
    end

    local numAsteroids = math.random(0, 1)
    for i = 1, numAsteroids do
        local mat = generator:createAsteroidField()
        local asteroid = generator:createClaimableAsteroid()
        asteroid.position = mat
    end

    local faction = Galaxy():getLocalFaction(x, y) or Galaxy():getNearestFaction(x, y)
    local numMiners = math.random(1, 2)
    for i = 1, numMiners do
        local ship = ShipGenerator.createMiningShip(faction, generator:getPositionInSector(5000))
        ship:addScript("ai/mine.lua")
    end

    if math.random() < generator:getWormHoleProbability() then generator:createRandomWormHole() end

    Sector():addScript("data/scripts/sector/events.lua", "events/pirateattack.lua")

    generator:addAmbientEvents()
    Placer.resolveIntersections()
end

return SectorTemplate
