package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
require ("basesystem")
require ("utility")
require ("randomext")

function getBonuses(seed, rarity)
    math.randomseed(seed)

    local energy = 15 -- base value, in percent
    -- add flat percentage based on rarity
    energy = energy + (rarity.value + 1) * 15 -- add 0% (worst rarity) to +80% (best rarity)

    -- add randomized percentage, span is based on rarity
    energy = energy + math.random() * ((rarity.value + 1) * 10) -- add random value between 0% (worst rarity) and +60% (best rarity)
    energy = energy / 100

    local charge = 15 -- base value, in percent
    -- add flat percentage based on rarity
    charge = charge + (rarity.value + 1) * 4 -- add 0% (worst rarity) to +24% (best rarity)

    -- add randomized percentage, span is based on rarity
    charge = charge + math.random() * ((rarity.value + 1) * 4) -- add random value between 0% (worst rarity) and +24% (best rarity)
    charge = charge / 100

    -- probability for both of them being used
    -- when rarity.value >= 4, always both
    -- when rarity.value <= 0 always only one
    local probability = math.max(0, rarity.value * 0.25)
    if math.random() > probability then
        -- only 1 will be used
        if math.random() < 0.5 then
            energy = 0
        else
            charge = 0
        end
    end

    return energy, charge
end

function onInstalled(seed, rarity)
    local energy, charge = getBonuses(seed, rarity)

    addBaseMultiplier(StatsBonuses.EnergyCapacity, energy)
    addBaseMultiplier(StatsBonuses.BatteryRecharge, charge)
end

function onUninstalled(seed, rarity)

end

function getName(seed, rarity)
    return "Battery Upgrade"%_t
end

function getIcon(seed, rarity)
    return "data/textures/icons/battery-pack-alt.png"
end

function getEnergy(seed, rarity)
    return 0
end

function getPrice(seed, rarity)
    local energy, charge = getBonuses(seed, rarity)
    local price = energy * 100 * 250 + charge * 100 * 150;
    return price * 2.5 ^ rarity.value
end

function getTooltipLines(seed, rarity)

    local texts = {}
    local energy, charge = getBonuses(seed, rarity)

    if energy ~= 0 then
        table.insert(texts, {ltext = "Energy Capacity"%_t, rtext = string.format("%+i%%", energy * 100), icon = "data/textures/icons/battery-pack-alt.png"})
    end

    if charge ~= 0 then
        table.insert(texts, {ltext = "Recharge Rate"%_t, rtext = string.format("%+i%%", charge * 100), icon = "data/textures/icons/energise.png"})
    end

    return texts
end

