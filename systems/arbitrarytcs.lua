
package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
require ("basesystem")
require ("utility")

function getNumTurrets(seed, rarity)
    return math.max(1, rarity.value)
end

function onInstalled(seed, rarity)
    addMultiplyableBias(StatsBonuses.ArbitraryTurrets, getNumTurrets(seed, rarity))
end

function onUninstalled(seed, rarity)
end

function getName(seed, rarity)
    return "Turret Control System A-TCS-${num}"%_t % {num = getNumTurrets(seed, rarity)}
end

function getIcon(seed, rarity)
    return "data/textures/icons/turret.png"
end

function getEnergy(seed, rarity)
    local num = getNumTurrets(seed, rarity)
    return num * 250 * 1000 * 1000 / (1.1 ^ rarity.value)
end

function getPrice(seed, rarity)
    local num = getNumTurrets(seed, rarity)
    local price = 7500 * num;
    return price * 2.5 ^ rarity.value
end

function getTooltipLines(seed, rarity)
    return
    {
        {ltext = "All Turrets"%_t, rtext = "+" .. getNumTurrets(seed, rarity), icon = "data/textures/icons/turret.png"}
    }
end

function getDescriptionLines(seed, rarity)
    return
    {
        {ltext = "All-round Turret Control System"%_t, rtext = "", icon = ""}
    }
end
