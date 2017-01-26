package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
require ("basesystem")
require ("utility")
require ("randomext")

function getBonuses(seed, rarity)
    math.randomseed(seed)

    local energy = (6.0 - (rarity.value + 1)) * 8  -- base value 60 for worst, 0 for best rarity
    energy = energy + getInt(0, 10) -- add a random number of 10
    energy = energy / 100

    return energy
end


function onInstalled(seed, rarity)
    local energy = getBonuses(seed, rarity)

    addAbsoluteBias(StatsBonuses.Velocity, 10000000.0)
    addBaseMultiplier(StatsBonuses.GeneratedEnergy, -energy)
end

function onUninstalled(seed, rarity)

end

function getName(seed, rarity)
    return "Velocity Security Control Bypass"%_t
end

function getIcon(seed, rarity)
    return "data/textures/icons/bypass.png"
end

function getPrice(seed, rarity)
    return 15000 * (2.5 ^ rarity.value)
end

function getTooltipLines(seed, rarity)
    local energy = getBonuses(seed, rarity)

    local texts = {}
    table.insert(texts, {ltext = "Velocity"%_t, rtext = "+?", icon = "data/textures/icons/lucifer-cannon.png"})
    table.insert(texts, {ltext = "Generated Energy"%_t, rtext = string.format("%+i%%", -energy * 100), icon = "data/textures/icons/power-lightning.png"})
    table.insert(texts, {})
    table.insert(texts, {ltext = "Bypasses the velocity security control,"%_t})
    table.insert(texts, {ltext = "but leaks energy from the generators."%_t})
    return texts
end

function getDescriptionLines(seed, rarity)
    return
    {
        {ltext = "Weeeeeee!"%_t, lcolor = ColorRGB(1, 0.5, 0.5)}
    }
end

