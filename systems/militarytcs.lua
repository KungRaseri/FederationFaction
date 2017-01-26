
package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
require ("basesystem")
require ("randomext")
require ("utility")

function getNumTurrets(seed, rarity)
    return math.max(1, rarity.value + 1)
end

function onInstalled(seed, rarity)
    addMultiplyableBias(StatsBonuses.ArmedTurrets, getNumTurrets(seed, rarity))
end

function onUninstalled(seed, rarity)
end

function getName(seed, rarity)
    return "Turret Control System M-TCS-${num}"%_t % {num = getNumTurrets(seed, rarity)}
end

function getIcon(seed, rarity)
    return "data/textures/icons/turret.png"
end

function getEnergy(seed, rarity)
    local num = getNumTurrets(seed, rarity)
    return num * 200 * 1000 * 1000 / (1.2 ^ rarity.value)
end

function getPrice(seed, rarity)
    local num = getNumTurrets(seed, rarity)
    local price = 6000 * num;
    return price * 2.5 ^ rarity.value
end

function getTooltipLines(seed, rarity)
    return
    {
        {ltext = "Armed Turrets"%_t, rtext = "+" .. getNumTurrets(seed, rarity), icon = "data/textures/icons/turret.png"}
    }
end

function getDescriptionLines(seed, rarity)
    return
    {
        {ltext = "Military Turret Control System"%_t, rtext = "", icon = ""}
    }
end
