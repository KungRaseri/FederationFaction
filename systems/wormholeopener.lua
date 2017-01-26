package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
require ("basesystem")
require ("utility")

function onInstalled(seed, rarity)
    if onClient() then
        if rarity == Rarity(RarityType.Legendary) then
            Player():registerCallback("onStartDialog", "onStartDialog")
        end
    end
end

function onStartDialog(entityIndex)
    local entity = Entity(entityIndex)
    if entity:hasScript("story/wormholeguardian.lua") then
        ScriptUI(entityIndex):addDialogOption("[Harness Wormhole Power]"%_t, "onHarnessPower")
    end
end

function onHarnessPower(entityIndex)
    local guardian = Entity(entityIndex)

    local _, ok = guardian:invokeFunction("wormholeguardian.lua", "channelPlayer")

    if not ok then
        local dialog = {}
        dialog.text = "This didn't work."%_t
        ScriptUI(entityIndex):showDialog(dialog)
    end
end

function onUninstalled(seed, rarity)
end

function getName(seed, rarity)
    if rarity == Rarity(RarityType.Legendary) then
        return "Wormhole Power Diverter"%_t
    else
        return "Xsotan Technology Fragment"%_t
    end
end

function getIcon(seed, rarity)
    if rarity == Rarity(RarityType.Legendary) then
        return "data/textures/icons/flower-twirl.png"
    else
        return "data/textures/icons/technology-part.png"
    end
end

function getEnergy(seed, rarity)
    if rarity == Rarity(RarityType.Legendary) then
        return 250 * 1000 * 1000
    else
        return 0
    end
end

function getPrice(seed, rarity)
    return 5000
end

function getTooltipLines(seed, rarity)
    return
    {
--        {ltext = "All Turrets", rtext = "+" .. getNumTurrets(seed, rarity), icon = "data/textures/icons/turret.png"}
    }
end

function getDescriptionLines(seed, rarity)
    if rarity == Rarity(RarityType.Legendary) then
        return
        {
            {ltext = "Lets you harness the power"%_t, rtext = "", icon = ""},
            {ltext = "of Xsotan Wormhole Technology."%_t, rtext = "", icon = ""},
        }
    else
        return
        {
            {ltext = "A fragment of Xsotan technology."%_t, rtext = "", icon = ""},
        }
    end
end
