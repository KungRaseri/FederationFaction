package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

SectorGenerator = require ("SectorGenerator")
require ("productions")
Placer = require("placer")

local SectorTemplate = {}

probability = 400
minNumFactories = 4
maxNumFactories = 6

-- must be defined, will be used to get the probability of this sector
function SectorTemplate.getProbabilityWeight(x, y)
    return probability
end

function SectorTemplate.offgrid(x, y)
    return false
end

-- this function returns whether or not a sector should have space gates
function SectorTemplate.gates(x, y)
    return true
end

-- player is the player who triggered the creation of the sector (only set in start sector, otherwise nil)
function SectorTemplate.generate(player, seed, x, y)
    math.randomseed(seed);

    local generator = SectorGenerator(x, y)
    local faction = Galaxy():getLocalFaction(x, y) or Galaxy():getNearestFaction(x, y)

    -- find out productions that take place in mines
    local miningProductions = getMiningProductions()

    -- create several mines
    local numFactories = math.random(minNumFactories, maxNumFactories)
    for i = 1, numFactories do
        -- create asteroid field
        local pos = generator:createAsteroidField(0.075);
        local p = miningProductions[getInt(1, #miningProductions)]

        -- create the mine inside the field
        local mine = generator:createStation(faction);
        mine:addScript("data/scripts/entity/merchants/factory.lua", "nothing")
        mine:invokeFunction("factory.lua", "setProduction", p.production)

        mine.position = pos
    end

    -- maybe create some asteroids
    local numFields = math.random(0, 2)
    for i = 1, numFields do
        generator:createEmptyAsteroidField();
    end

    -- create a trading post
    if math.random() < 0.33 then
        generator:createStation(faction, "data/scripts/entity/merchants/tradingpost.lua");
    end

    if math.random() < 0.75 then
        generator:createStation(faction, "data/scripts/entity/merchants/resourcetrader.lua");
    end

    -- create defenders
    local defenders = math.random(4, 6)
    for i = 1, defenders do
        ShipGenerator.createDefender(faction, generator:getPositionInSector())
    end

    -- create ships of an other faction
    local otherFaction = Galaxy():getNearestFaction(x + math.random(-15, 15), y + math.random(-15, 15))

    if faction:getRelations(otherFaction.index) < -20000 then
        otherFaction = nil
    end

    -- create a trader from maybe another faction
    if otherFaction and math.random() < 0.33 then
        if faction.index ~= otherFaction.index then
            generator:createStation(otherFaction, "data/scripts/entity/merchants/tradingpost.lua");
        end
    end

    local numAsteroids = math.random(0, 1)
    for i = 1, numAsteroids do
        local mat = generator:createAsteroidField()
        local asteroid = generator:createClaimableAsteroid()
        asteroid.position = mat
    end

    local numMiners = math.random(1, 2)
    for i = 1, numMiners do
        local ship = ShipGenerator.createMiningShip(faction, generator:getPositionInSector(5000))
        ship:addScript("ai/mine.lua")
    end

    local numSmallFields = math.random(0, 5)
    for i = 1, numSmallFields do
        generator:createSmallAsteroidField(0.1)
    end

    if SectorTemplate.gates(x, y) then generator:createGates() end

    if math.random() < generator:getWormHoleProbability() then generator:createRandomWormHole() end

    Sector():addScript("data/scripts/sector/events.lua", "events/pirateattack.lua")

    generator:addAmbientEvents()
    Placer.resolveIntersections()
end

return SectorTemplate

