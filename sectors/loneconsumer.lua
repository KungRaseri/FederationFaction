package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

SectorGenerator = require ("SectorGenerator")
Placer = require("placer")

local SectorTemplate = {}

-- must be defined, will be used to get the probability of this sector
function SectorTemplate.getProbabilityWeight(x, y)
    return 350
end

function SectorTemplate.offgrid(x, y)
    return false
end

-- this function returns whether or not a sector should have space gates
function SectorTemplate.gates(x, y)
    return makeFastHash(x, y, 1) % 3 == 0
end

-- player is the player who triggered the creation of the sector (only set in start sector, otherwise nil)
function SectorTemplate.generate(player, seed, x, y)
    math.randomseed(seed);

    local generator = SectorGenerator(x, y)

    local faction = Galaxy():getLocalFaction(x, y) or Galaxy():getNearestFaction(x, y)

    -- create a consumer
    local consumerType = math.random(1, 5)
    if consumerType == 1 then
        generator:createStation(faction, "data/scripts/entity/merchants/casino.lua");
    elseif consumerType == 2 then
        generator:createStation(faction, "data/scripts/entity/merchants/biotope.lua");
    elseif consumerType == 3 then
        generator:createStation(faction, "data/scripts/entity/merchants/habitat.lua");
    elseif consumerType == 4 then
        generator:createResearchStation(faction);
    elseif consumerType == 5 then
        generator:createMilitaryBase(faction)
    end

    -- maybe create some asteroids
    local numFields = math.random(0, 4)
    for i = 1, numFields do
        local mat = generator:createAsteroidField();
        if math.random() < 0.15 then generator:createStash(mat) end
    end

    local numAsteroids = math.random(0, 2)
    for i = 1, numAsteroids do
        generator:createBigAsteroid();
    end

    -- create ships
    local defenders = math.random(0, 2)
    for i = 1, defenders do
        ShipGenerator.createDefender(faction, generator:getPositionInSector())
    end

    local numSmallFields = math.random(0, 3)
    for i = 1, numSmallFields do
        generator:createSmallAsteroidField()
    end

    local numAsteroids = math.random(0, 1)
    for i = 1, numAsteroids do
        local mat = generator:createAsteroidField()
        local asteroid = generator:createClaimableAsteroid()
        asteroid.position = mat
    end

    if SectorTemplate.gates(x, y) then generator:createGates() end

    if math.random() < generator:getWormHoleProbability() then generator:createRandomWormHole() end

    Sector():addScript("data/scripts/sector/events.lua", "events/pirateattack.lua")

    generator:addAmbientEvents()
    Placer.resolveIntersections()
end

return SectorTemplate

