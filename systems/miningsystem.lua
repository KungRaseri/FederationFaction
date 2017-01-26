package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
require ("basesystem")
require ("utility")
require ("randomext")

materialLevel = 0
range = 0
amount = 0

function getBonuses(seed, rarity)
    math.randomseed(seed)

    local range = 200 -- base value
    -- add flat range based on rarity
    range = range + (rarity.value + 1) * 40 -- add 0 (worst rarity) to +240 (best rarity)
    -- add randomized range, span is based on rarity
    range = range + math.random() * ((rarity.value + 1) * 20) -- add random value between 0 (worst rarity) and 120 (best rarity)

    local material = rarity.value + 1
    if math.random() < 0.25 then
        material = material + 1
    end

    local amount = 3
    -- add flat amount based on rarity
    amount = amount + (rarity.value + 1) * 2 -- add 0 (worst rarity) to +120 (best rarity)
    -- add randomized amount, span is based on rarity
    amount = amount + math.random() * ((rarity.value + 1) * 5) -- add random value between 0 (worst rarity) and 60 (best rarity)

    return material, range, amount
end

function onInstalled(seed, rarity)
    if onClient() then
        Player():registerCallback("onPreRenderHud", "onPreRenderHud")
    end

    materialLevel, range, amount = getBonuses(seed, rarity)
end

function onUninstalled(seed, rarity)

end

function sort(a, b)
    return a.distance < b.distance
end

function onPreRenderHud()

    local ship = Entity()
    local shipPos = ship.translationf

    local sphere = Sphere(shipPos, 500)
    local nearby = {Sector():getEntitiesByLocation(sphere)}
    local displayed = {}

    -- detect all asteroids in range
    for _, entity in pairs(nearby) do

        if entity.type == EntityType.Asteroid then
            local resources = entity:getMineableResources()
            if resources ~= nil and resources > 0 then
                local material = entity:getMineableMaterial()

                if material.value <= materialLevel then

                    local d = distance2(entity.translationf, shipPos)

                    table.insert(displayed, {material = material, asteroid = entity, distance = d})
                end
            end
        end

    end

    -- sort by distance
    table.sort(displayed, sort)

    -- display nearest x
    local renderer = UIRenderer()

    for i = 1, math.min(#displayed, amount) do
        local tuple = displayed[i]
        renderer:renderEntityTargeter(tuple.asteroid, tuple.material.color);
        renderer:renderEntityArrow(tuple.asteroid, 30, 10, 250, tuple.material.color, 0);


    end

    renderer:display()
end

function getName(seed, rarity)
    return "Mining System"%_t
end

function getIcon(seed, rarity)
    return "data/textures/icons/mining.png"
end

function getEnergy(seed, rarity)
    local materialLevel, range, amount = getBonuses(seed, rarity)

    return (range * 0.0005 * materialLevel * 1000 * 1000 * 1000) + (amount * 5 * 1000 * 1000)
end

function getPrice(seed, rarity)
    local materialLevel, range, amount = getBonuses(seed, rarity)

    local price = materialLevel * 5000 + amount * 750 + range * 1.5;

    return price * 2.5 ^ rarity.value
end

function getTooltipLines(seed, rarity)
    local texts = {}

    local materialLevel, range, amount = getBonuses(seed, rarity)
    materialLevel = math.max(0, math.min(materialLevel, NumMaterials() - 1))
    local material = Material(materialLevel)

    table.insert(texts, {ltext = "Material"%_t, rtext = material.name%_t, rcolor = material.color, icon = "data/textures/icons/metal-bar.png"})
    table.insert(texts, {ltext = "Range"%_t, rtext = string.format("%g", round(range / 100, 2)), icon = "data/textures/icons/rss.png"})
    table.insert(texts, {ltext = "Asteroids"%_t, rtext = string.format("%i", amount), icon = "data/textures/icons/rock.png"})

    return texts
end

function getDescriptionLines(seed, rarity)
    local texts = {}

    local materialLevel, range, amount = getBonuses(seed, rarity)
    materialLevel = math.max(0, math.min(materialLevel, NumMaterials() - 1))
    local material = Material(materialLevel)

    table.insert(texts, {ltext = "Highlights nearby asteroids"%_t})

    return texts
end
