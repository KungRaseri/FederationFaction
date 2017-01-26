package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
require ("basesystem")
require ("utility")

-- this key is dropped by the smuggler

function getNumTurrets(seed, rarity)
    return math.max(1, rarity.value)
end

function onInstalled(seed, rarity)
    addMultiplyableBias(StatsBonuses.ArbitraryTurrets, getNumTurrets(seed, rarity))
end

function onUninstalled(seed, rarity)
end

function getName(seed, rarity)
    return "XSTN-K VIII"%_t
end

function getIcon(seed, rarity)
    return "data/textures/icons/key8.png"
end

function getEnergy(seed, rarity)
    return 0
end

function getPrice(seed, rarity)
    return 10000
end

function getTooltipLines(seed, rarity)
    return
    {
--        {ltext = "All Turrets", rtext = "+" .. getNumTurrets(seed, rarity), icon = "data/textures/icons/turret.png"}
    }
end

function getDescriptionLines(seed, rarity)
    return
    {
        {ltext = "This system has 8 vertical "%_t, rtext = "", icon = ""},
        {ltext = "scratches on its surface."%_t, rtext = "", icon = ""}
    }
end
