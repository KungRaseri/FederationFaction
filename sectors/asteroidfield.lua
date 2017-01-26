
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

SectorGenerator = require ("SectorGenerator")
OperationExodus = require ("story/operationexodus")
Placer = require("placer")

local SectorTemplate = {}

-- must be defined, will be used to get the probability of this sector
function SectorTemplate.getProbabilityWeight(x, y)
    return 300
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
    math.randomseed(seed)

    local generator = SectorGenerator(x, y)

    local numFields = math.random(2, 5)
    for i = 1, numFields do
        local position = generator:createAsteroidField(0.075);
        if math.random() < 0.35 then generator:createBigAsteroid(position) end
    end

    for i = 1, 5 - numFields do
        local position = generator:createEmptyAsteroidField();
        if math.random() < 0.5 then generator:createEmptyBigAsteroid(position) end
    end

    local numSmallFields = math.random(8, 15)
    for i = 1, numSmallFields do
        local mat = generator:createSmallAsteroidField()

        if math.random() < 0.2 then generator:createStash(mat) end
    end

    local numAsteroids = math.random(0, 2)
    for i = 1, numAsteroids do
        local mat = generator:createAsteroidField()
        local asteroid = generator:createClaimableAsteroid()
        asteroid.position = mat
    end

    OperationExodus.tryGenerateBeacon(generator)

    if math.random() < generator:getWormHoleProbability() then generator:createRandomWormHole() end

    Sector():addScript("data/scripts/sector/events.lua", "events/pirateattack.lua")

    generator:addOffgridAmbientEvents()
    Placer.resolveIntersections()
end

return SectorTemplate
