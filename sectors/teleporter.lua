package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

SectorGenerator = require ("SectorGenerator")
Balancing = require ("galaxy")
Placer = require("placer")
require ("stationextensions")
require ("stringutility")

local SectorTemplate = {}

-- must be defined, will be used to get the probability of this sector
function SectorTemplate.getProbabilityWeight(x, y, serverSeed)

    local d = length(vec2(x, y)) - Balancing.BlockRingMax
    if d > 0 and d < 1.2 then
        if makeFastHash(x, y, serverSeed.int32) % 4 == 1 then
            return 10000000
        end
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

function SectorTemplate.getPlan()

    if SectorTemplate.plan then return SectorTemplate.plan end

    -- 107, 108, 118
    local style = GenerateStationStyle(Seed(118), 1, 1, 1, vec3(1, 2, 1), ColorRGB(0.3, 0.0, 0.0), ColorRGB(0.7, 0.7, 0.7), ColorRGB(0.25, 0.25, 0.25))
    local volume = Balancing.GetSectorShipVolume(150, 0) * 100

    local plan = GeneratePlanFromStyle(style, Seed(666), volume, 7500, 1, Material(4))
    plan.accumulatingHealth = false

    for i = 0, plan.numBlocks - 1 do
        local block = plan:getNthBlock(i)
        if block.blockIndex == BlockType.Quarters  then
            plan:setBlockType(block.index, BlockType.Hull)
        end
    end

    plan.accumulatingHealth = true

    SectorTemplate.plan = plan

    return plan
end

-- player is the player who triggered the creation of the sector (only set in start sector, otherwise nil)
function SectorTemplate.generate(player, seed, x, y)
    math.randomseed(seed);

    local generator = SectorGenerator(x, y)

    local num = 8
    for i = 1, num do
        local angle = i * (1 / num) * math.pi * 2.0
        local p = vec3(math.sin(angle), 0, math.cos(angle)) * 1000

        local desc = EntityDescriptor()
        desc:addComponents(
           ComponentType.Plan,
           ComponentType.BspTree,
           ComponentType.Intersection,
           ComponentType.Asleep,
           ComponentType.DamageContributors,
           ComponentType.BoundingSphere,
           ComponentType.BoundingBox,
           ComponentType.Velocity,
           ComponentType.Physics,
           ComponentType.Scripts,
           ComponentType.ScriptCallback,
           ComponentType.Title,
           ComponentType.WreckageCreator
           )

        desc:setPlan(SectorTemplate.getPlan())
        desc.title = toRomanLiterals(i)
        desc.position = MatrixLookUpPosition(vec3(0, 1, 0), p, p)

        addAsteroid(desc)

        local entity = Sector():createEntity(desc)

        entity:setValue("teleporter", i)
    end

    Sector():addScriptOnce("story/activateteleport")

    Placer.resolveIntersections()
end

return SectorTemplate
