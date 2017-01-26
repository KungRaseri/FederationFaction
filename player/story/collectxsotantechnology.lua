package.path = package.path .. ";data/scripts/lib/?.lua"

require ("randomext")
require ("utility")
require ("mission")
require ("stringutility")

local Dialog = require ("dialogutility")

function initialize(dummy)

    if onClient() then
        sync()
    else
        Player():registerCallback("onItemAdded", "onItemAdded")

        if not dummy then return end

        missionData.justStarted = true
        missionData.title = "Getting Technical"%_t
        missionData.brief = "Getting Technical"%_t
        missionData.description = "Collect and research Xsotan technology to use against the wormhole guardian."%_t

    end
end

function onItemAdded(index, amount, before)
    if amount >= 1 then

        local item = Player():getInventory():find(index)
        if item.itemType == InventoryItemType.SystemUpgrade then
            if item.script:match("systems/wormholeopener.lua") then
                if item.rarity == Rarity(RarityType.Legendary) then
                    showMissionAccomplished()
                    terminate()
                end
            end
        end

    end
end

function updateDescription()

end
