package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

SectorGenerator = require ("SectorGenerator")
Placer = require("placer")

local SectorTemplate = {}

SectorTemplate.probability = probability or 300
SectorTemplate.minNumFactories = minNumFactories or 3
SectorTemplate.maxNumFactories = maxNumFactories or 5
SectorTemplate.factoryScript = factoryScript or "data/scripts/entity/merchants/factory.lua"

-- must be defined, will be used to get the probability of this sector
function SectorTemplate.getProbabilityWeight(x, y)
    return SectorTemplate.probability
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

    -- create a trading post
    if math.random() < 0.33 then
        generator:createStation(faction, "data/scripts/entity/merchants/tradingpost.lua");
    end

    -- create several factories
    local numFactories = math.random(SectorTemplate.minNumFactories, SectorTemplate.maxNumFactories)
    local containerStations = {}
    for i = 1, numFactories do
        local station = generator:createStation(faction, SectorTemplate.factoryScript);

        table.insert(containerStations, station)
    end

    -- create a turret factory
    if math.random() < 0.33 then
        generator:createStation(faction, "merchants/turretfactory.lua");
    end

    if math.random() < 0.5 then
        generator:createStation(faction, "merchants/resourcetrader.lua");
    end

    -- maybe create some asteroids
    local numFields = math.random(0, 2)
    for i = 1, numFields do
        generator:createEmptyAsteroidField();
    end

    numFields = math.random(0, 2)
    for i = 1, numFields do
        generator:createAsteroidField();
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

    local numSmallFields = math.random(0, 5)
    for i = 1, numSmallFields do
        generator:createSmallAsteroidField()
    end


    -- generate station containers last so their stations won't get displaced by other stations being created
    for i, station in pairs(containerStations) do
        if math.random() < 0.15 then
            generator:generateStationContainers(station)
        end
    end

    if SectorTemplate.gates(x, y) then generator:createGates() end

    if math.random() < generator:getWormHoleProbability() then generator:createRandomWormHole() end

    Sector():addScript("data/scripts/sector/events.lua", "events/pirateattack.lua")

    generator:addAmbientEvents()
    Placer.resolveIntersections()
end

return SectorTemplate
