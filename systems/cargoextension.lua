package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
require ("basesystem")
require ("utility")
require ("randomext")

function getBonuses(seed, rarity)
    math.randomseed(seed)

    local perc = 10 -- base value, in percent
    -- add flat percentage based on rarity
    perc = perc + rarity.value * 4 -- add -4% (worst rarity) to +20% (best rarity)

    -- add randomized percentage, span is based on rarity
    perc = perc + math.random() * (rarity.value * 4) -- add random value between -4% (worst rarity) and +20% (best rarity)
    perc = perc / 100


    local flat = 20 -- base value
    -- add flat value based on rarity
    flat = flat + (rarity.value + 1) * 50 -- add +0 (worst rarity) to +300 (best rarity)

    -- add randomized value, span is based on rarity
    flat = flat + math.random() * ((rarity.value + 1) * 50) -- add random value between +0 (worst rarity) and +300 (best rarity)
    flat = round(flat)

    if math.random() < 0.5 then
        perc = 0
    else
        flat = 0
    end

    return perc, flat
end

function onInstalled(seed, rarity)
    local perc, flat = getBonuses(seed, rarity)

    addBaseMultiplier(StatsBonuses.CargoHold, perc)
    addAbsoluteBias(StatsBonuses.CargoHold, flat)
end

function onUninstalled(seed, rarity)

end

function getName(seed, rarity)
    return "T1M-LRD-Tech Cargo Upgrade MK ${mark}"%_t % {mark = toRomanLiterals(rarity.value + 2)}
end

function getIcon(seed, rarity)
    return "data/textures/icons/cubeforce.png"
end

function getEnergy(seed, rarity)
    local perc, flat = getBonuses(seed, rarity)
    return perc * 1.5 * 1000 * 1000 * 1000 + flat * 0.01 * 1000 * 1000 * 1000
end

function getPrice(seed, rarity)
    local perc, flat = getBonuses(seed, rarity)
    local price = perc * 100 * 450 + flat * 75
    return price * 2.5 ^ rarity.value
end

function getTooltipLines(seed, rarity)

    local texts = {}
    local perc, flat = getBonuses(seed, rarity)

    if perc ~= 0 then
        table.insert(texts, {ltext = "Cargo Hold"%_t, rtext = string.format("%+i%%", perc * 100), icon = "data/textures/icons/wooden-crate.png"})
    end

    if flat ~= 0 then
        table.insert(texts, {ltext = "Cargo Hold"%_t, rtext = string.format("%+i", flat), icon = "data/textures/icons/wooden-crate.png"})
    end

    return texts
end

function getDescriptionLines(seed, rarity)
    return
    {
        {ltext = "It's bigger on the inside!"%_t, lcolor = ColorRGB(1, 0.5, 0.5)}
    }
end

