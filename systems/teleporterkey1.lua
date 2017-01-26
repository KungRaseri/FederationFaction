package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
require ("basesystem")
require ("utility")

-- this teleporter key is given by the Haatii

function getNumTurrets(seed, rarity)
    return math.max(1, rarity.value)
end

function onInstalled(seed, rarity)
    addMultiplyableBias(StatsBonuses.ArbitraryTurrets, getNumTurrets(seed, rarity))
end

function onUninstalled(seed, rarity)
end

function getName(seed, rarity)
    return "XSTN-K I"%_t
end

function getIcon(seed, rarity)
    return "data/textures/icons/key1.png"
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
        {ltext = "This system has a vertical "%_t, rtext = "", icon = ""},
        {ltext = "scratch on its surface."%_t, rtext = "", icon = ""}
    }
end
