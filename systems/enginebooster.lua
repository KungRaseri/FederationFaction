package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
require ("basesystem")
require ("utility")
require ("randomext")

function getBonuses(seed, rarity)
    math.randomseed(seed)

    local vfactor = 3 -- base value, in percent
    -- add flat percentage based on rarity
    vfactor = vfactor + (rarity.value + 1) * 3 -- add 0% (worst rarity) to +18% (best rarity)

    -- add randomized percentage, span is based on rarity
    vfactor = vfactor + math.random() * ((rarity.value + 1) * 4) -- add random value between 0% (worst rarity) and +24% (best rarity)
    vfactor = vfactor / 100

    local afactor = 6 -- base value, in percent
    -- add flat percentage based on rarity
    afactor = afactor + (rarity.value + 1) * 5 -- add 0% (worst rarity) to +30% (best rarity)

    -- add randomized percentage, span is based on rarity
    afactor = afactor + math.random() * ((rarity.value + 1) * 4) -- add random value between 0% (worst rarity) and +24% (best rarity)
    afactor = afactor / 100

    -- probability for both of them being used
    -- when rarity.value >= 4, always both
    -- when rarity.value <= 0 always only one
    local probability = math.max(0, rarity.value * 0.25)
    if math.random() > probability then
        -- only 1 will be used
        if math.random() < 0.5 then
            vfactor = 0
        else
            afactor = 0
        end
    end

    return vfactor, afactor
end

function onInstalled(seed, rarity)
    local vel, acc = getBonuses(seed, rarity)

    addBaseMultiplier(StatsBonuses.Velocity, vel)
    addBaseMultiplier(StatsBonuses.Acceleration, acc)
end

function onUninstalled(seed, rarity)

end

function getName(seed, rarity)
    return "Engine Upgrade"%_t
end

function getIcon(seed, rarity)
    return "data/textures/icons/rocket-thruster.png"
end

function getEnergy(seed, rarity)
    local vel, acc = getBonuses(seed, rarity)
    return (vel + acc) * 1.5 * 1000 * 1000 * 1000
end

function getPrice(seed, rarity)
    local vel, acc = getBonuses(seed, rarity)
    local price = vel * 100 * 500 + acc * 100 * 500
    return price * 2.5 ^ rarity.value
end

function getTooltipLines(seed, rarity)

    local texts = {}
    local vel, acc = getBonuses(seed, rarity)

    if vel ~= 0 then
        table.insert(texts, {ltext = "Velocity"%_t, rtext = string.format("%+i%%", vel * 100), icon = "data/textures/icons/lucifer-cannon.png"})
    end

    if acc ~= 0 then
        table.insert(texts, {ltext = "Acceleration"%_t, rtext = string.format("%+i%%", acc * 100), icon = "data/textures/icons/blaster.png"})
    end

    return texts
end
