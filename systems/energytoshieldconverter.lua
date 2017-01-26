package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
require ("basesystem")
require ("utility")
require ("randomext")

function onInstalled(seed, rarity)
    addBaseMultiplier(StatsBonuses.ShieldDurability, getAmplification(seed, rarity))
    addBaseMultiplier(StatsBonuses.GeneratedEnergy, getEnergyChange(seed, rarity))
end

function onUninstalled(seed, rarity)
end

function getName(seed, rarity)
    return "Energy to Shield Converter"%_t
end

function getIcon(seed, rarity)
    return "data/textures/icons/shield.png"
end

function getAmplification(seed, rarity)
    math.randomseed(seed)

    local amplification = 20
    -- add flat percentage based on rarity
    amplification = amplification + (rarity.value + 1) * 15 -- add 0% (worst rarity) to +120% (best rarity)

    -- add randomized percentage, span is based on rarity
    amplification = amplification + math.random() * (rarity.value + 1) * 10 -- add random value between 0% (worst rarity) and +60% (best rarity)
    amplification = amplification / 100

    return amplification
end

function getEnergyChange(seed, rarity)
    local amplification = getAmplification(seed, rarity)
    return -amplification * 0.4 / (1.1 ^ rarity.value) -- note the minus
end

function getPrice(seed, rarity)
    local amplification = getAmplification(seed, rarity)
    local price = 7500 * amplification;
    return price * 2.5 ^ rarity.value
end

function getTooltipLines(seed, rarity)
    local texts = {}
    local amplification = getAmplification(seed, rarity)
    local energy = getEnergyChange(seed, rarity)

    table.insert(texts, {ltext = "Shield Durability"%_t, rtext = string.format("%+i%%", amplification * 100), icon = "data/textures/icons/health-normal.png"})
    table.insert(texts, {ltext = "Generated Energy"%_t, rtext = string.format("%i%%", energy * 100), icon = "data/textures/icons/electric.png"})

    return texts
end

function getDescriptionLines(seed, rarity)
    return
    {
        {ltext = "Re-routes energy to shields"%_t, rtext = "", icon = ""}
    }
end
