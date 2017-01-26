
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
    return true
end

-- player is the player who triggered the creation of the sector (only set in start sector, otherwise nil)
function SectorTemplate.generate(player, seed, x, y)
    math.randomseed(seed);

    local generator = SectorGenerator(x, y)

    local faction = Galaxy():getLocalFaction(x, y) or Galaxy():getNearestFaction(x, y)
    local otherFaction = Galaxy():getNearestFaction(x + math.random(-15, 15), y + math.random(-15, 15))

    if faction:getRelations(otherFaction.index) < -20000 then
        otherFaction = nil
    end

    -- create stations
    local numShipyards = 1

    for i = 1, numShipyards do
        generator:createShipyard(faction);
    end

    -- create resource trader
    local numResourceTraders = 1
    for i = 1, numResourceTraders do
        generator:createStation(faction, "data/scripts/entity/merchants/resourcetrader.lua");
    end

    -- create repair dock
    local numRepairDocks = 1
    for i = 1, numRepairDocks do
        generator:createRepairDock(faction);
    end

    -- create a trading post
    if math.random() < 0.5 then
        generator:createStation(faction, "data/scripts/entity/merchants/tradingpost.lua");
    end

    -- create headquarters
    local hx, hy = faction:getHomeSectorCoordinates()

    if hx == x and hy == y then
        local station = generator:createStation(faction, "data/scripts/entity/merchants/headquarters.lua")
        ShipUtility.addArmedTurretsToCraft(station)
    end

    -- equipment dock
    generator:createEquipmentDock(faction)

    -- create a trader from maybe another faction
    if math.random() < 0.5 then
        if otherFaction and faction.index ~= otherFaction.index then
            generator:createStation(otherFaction, "data/scripts/entity/merchants/tradingpost.lua");
        end
    end

    -- create several factories
    local numFactories = math.random(2, 4)
    local containerStations = {}
    for i = 1, numFactories do
        local station = generator:createStation(faction, "data/scripts/entity/merchants/factory.lua");
        table.insert(containerStations, station)
    end

    -- create a random consumer, those are unarmed!
    local consumerType = math.random(1, 4)
    if consumerType == 1 then
        generator:createStation(faction, "data/scripts/entity/merchants/casino.lua");
    elseif consumerType == 2 then
        generator:createStation(faction, "data/scripts/entity/merchants/biotope.lua");
    elseif consumerType == 3 then
        generator:createStation(faction, "data/scripts/entity/merchants/habitat.lua");
    elseif consumerType == 4 then
        generator:createResearchStation(faction);
    end

    generator:createMilitaryBase(faction)

    -- maybe create some asteroids
    local numFields = math.random(0, 1)
    for i = 1, numFields do
        local pos = generator:createEmptyAsteroidField();
        if math.random() < 0.4 then generator:createEmptyBigAsteroid(pos) end
    end

    numFields = math.random(0, 1)
    for i = 1, numFields do
        local pos = generator:createAsteroidField();
        if math.random() < 0.4 then generator:createBigAsteroid(pos) end
    end

    -- create defenders
    local defenders = math.random(4, 6)
    for i = 1, defenders do
        ShipGenerator.createDefender(faction, generator:getPositionInSector())
    end

    local numSmallFields = math.random(0, 5)
    for i = 1, numSmallFields do
        generator:createSmallAsteroidField()
    end

    -- generate station containers last so their stations won't get displaced by other stations being created
    for i, station in pairs(containerStations) do
        if math.random() < 0.3 then
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
