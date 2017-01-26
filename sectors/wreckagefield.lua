
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

OperationExodus = require ("story/operationexodus")
SectorGenerator = require ("SectorGenerator")
PirateGenerator = require ("pirategenerator")
Placer = require("placer")

local SectorTemplate = {}

-- must be defined, will be used to get the probability of this sector
function SectorTemplate.getProbabilityWeight(x, y)
    return 450
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

    local faction = Galaxy():getNearestFaction(x, y);

    for i = 0, 30 do
        generator:createWreckage(faction);
    end

    if math.random() < 0.3 then
        local numSmallFields = math.random(0, 3)
        for i = 1, numSmallFields do
            generator:createSmallAsteroidField()
        end
    end

    OperationExodus.tryGenerateBeacon(generator)

    local numShips = math.random(5, 10)

    -- skip creating pirates in some cases
    if math.random(1, 3) == 1 then numShips = 0 end

    for i = 1, numShips do
        PirateGenerator.createBandit(generator:getPositionInSector(5000))
    end

    if math.random() < generator:getWormHoleProbability() then generator:createRandomWormHole() end

    Sector():addScript("data/scripts/sector/events.lua", "events/pirateattack.lua")

    generator:addOffgridAmbientEvents()
    Placer.resolveIntersections()
end

return SectorTemplate
