package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

SectorGenerator = require ("SectorGenerator")
OperationExodus = require ("story/operationexodus")
NamePool = require ("namepool")
Placer = require("placer")
require("stringutility")

local SectorTemplate = {}

-- must be defined, will be used to get the probability of this sector
function SectorTemplate.getProbabilityWeight(x, y)
    return 150
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

    local faction = Galaxy():getNearestFaction(x, y)
    local wreckages = {generator:createWreckage(faction)}

    -- find largest wreckage
    local wreckage = findMaximum(wreckages, function(w) return Plan(w.index).numBlocks end)

    NamePool.setWreckageName(wreckage)
    for _, other in pairs(wreckages) do
        other.name = wreckage.name
    end

    local position = wreckage.position
    local beaconPosition = copy(position)
    beaconPosition.pos = beaconPosition.pos + random():getDirection() * 5.0

    local stashPosition = copy(position)
    stashPosition.pos = stashPosition.pos + random():getDirection() * 5.0

    generator:createBeacon(beaconPosition, nil, "Mayday, Mayday! We were ambushed and our hyperdrive is no longer... [END OF MESSAGE]"%_t)
    generator:createStash(stashPosition, "Traveler's Stash"%_t)

    OperationExodus.tryGenerateBeacon(generator)

    if math.random() < generator:getWormHoleProbability() then generator:createRandomWormHole() end

    Sector():addScript("data/scripts/sector/events.lua", "events/pirateattack.lua")

    generator:addOffgridAmbientEvents()
    Placer.resolveIntersections()
end

return SectorTemplate
