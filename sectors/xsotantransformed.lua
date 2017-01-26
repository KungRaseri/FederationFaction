package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local SectorTemplate = {}

-- must be defined, will be used to get the probability of this sector
function SectorTemplate.getProbabilityWeight(x, y)
    local d2 = length2(vec2(x, y))

    if d2 < Balancing.BlockRingMin2 then
        return 2500
    else
        return 0
    end
end

function SectorTemplate.offgrid(x, y)
    return true
end

-- this function returns whether or not a sector should have space gates
function SectorTemplate.gates(x, y)
    return false
end

function SectorTemplate.split(entity)

    local plan = Plan(entity.index)

    -- disable accumulation of health to disable expensive superflous recalculations of health
    plan.accumulatingHealth = false

    local blocks = plan.numBlocks
    local bb = plan.boundingBox
    local bblower = bb.lower
    local bbupper = bb.upper
    local bbsize = bb.size

    local toDestroy = {}
    for i = 0, blocks - 1 do
        local block = plan:getNthBlock(i)
        local b = block.box
        local lower = b.lower
        local upper = b.upper

        local add
        for p = 1, 3 do

            local x = bblower.x + bbsize.x * 0.25 * p
            if x > lower.x and x < upper.x then
                add = true
                break
            end

            local y = bblower.y + bbsize.y * 0.25 * p
            if y > lower.y and y < upper.y then
                add = true
                break
            end

            local z = bblower.z + bbsize.z * 0.25 * p
            if z > lower.z and z < upper.z then
                add = true
                break
            end
        end

        if add then
            table.insert(toDestroy, block.index)
        end
    end

    plan:destroy(unpack(toDestroy))

    plan.accumulatingHealth = true
end

-- player is the player who triggered the creation of the sector (only set in start sector, otherwise nil)
function SectorTemplate.generate(player, seed, x, y)

    math.randomseed(seed)

    -- take a random generation script
    local specs = SectorSpecifics();
    specs:addTemplates()

    local template = specs.templates[random():getInt(1, #specs.templates)]
    while string.match(template.path, "xsotan") or template:offgrid(x, y) do
        template = specs.templates[random():getInt(1, #specs.templates)]
    end

    template.generate(player, seed, x, y)

    -- destroy everything
    local entities = {Sector():getEntitiesByComponent(ComponentType.Owner)}
    for _, entity in pairs(entities) do

        -- remove backup script so there won't be any additional ships
        if entity:hasComponent(ComponentType.Scripts) then
            for i, script in pairs(entity:getScripts()) do
                if string.match(script, "backup") then
                    entity:removeScript(script) -- don't spawn military ships coming for help
                end
            end
        end

        if entity:hasComponent(ComponentType.Durability) then
            SectorTemplate.split(entity)

            -- splitting it probably won't destroy it
            -- make sure it will be destroyed
            entity.durability = 0
        else
            entity.factionIndex = 0
        end

    end

    -- delete loot
    local sector = Sector()
    local loot = {sector:getEntitiesByType(EntityType.Loot)}
    for _, entity in pairs(loot) do
        sector:deleteEntity(entity)
    end

    -- re-orient them all
    for _, entity in pairs({Sector():getEntities()}) do
        entity.orientation = MatrixLookUp(vec3(math.random(), math.random(), math.random()), -vec3(math.random(), math.random(), math.random()))
    end

    -- generate xsotan
    local generator = SectorGenerator(x, y)

    Xsotan.infectAsteroids()

    for i = 1, math.random(10, 15) do
        Xsotan.createShip(generator:getPositionInSector(), random():getFloat(0.5, 2.0))
    end

    for _, script in pairs(sector:getScripts()) do
        sector:removeScript(script)
    end


    generator:addOffgridAmbientEvents()
    Placer.resolveIntersections()
end

return SectorTemplate
