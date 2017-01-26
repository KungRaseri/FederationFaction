
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

SectorGenerator = require ("SectorGenerator")
Scientist = require ("story/scientist")
Placer = require("placer")

local SectorTemplate = {}

-- must be defined, will be used to get the probability of this sector
function SectorTemplate.getProbabilityWeight(x, y)
    local d2 = length2(vec2(x, y))

    if d2 > 150 * 150 and d2 < 240 * 240 then
        return 300
    end

    return 0
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

    for i = 1, 3 do
        local position = generator:createAsteroidField(0.075);
        if math.random() < 0.35 then generator:createBigAsteroid(position) end
    end

    Scientist.createSatellite(Matrix())
    --createSatellite(generator:getPositionInSector())

    if math.random() < generator:getWormHoleProbability() then generator:createRandomWormHole() end

    Sector():addScriptOnce("story/respawnresearchsatellite.lua")

    generator:addOffgridAmbientEvents()
    Placer.resolveIntersections()

end

return SectorTemplate
