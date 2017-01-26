
package.path = package.path .. ";data/scripts/entity/merchants/?.lua;"
package.path = package.path .. ";data/scripts/lib/?.lua;"

require ("galaxy")
require ("utility")
require ("faction")
require ("player")
require ("randomext")
require ("stringutility")
SellableInventoryItem = require ("sellableinventoryitem")
TurretGenerator = require ("turretgenerator")
Dialog = require("dialogutility")

function initialize()
    if onClient() and EntityIcon().icon == "" then
        EntityIcon().icon = "data/textures/icons/pixel/research.png"
        InteractionText().text = Dialog.generateStationInteractionText(Entity(), random())
    end
end

function interactionPossible(playerIndex, option)
    return CheckFactionInteraction(playerIndex, -25000, 40000)
end

function initUI()

    local res = getResolution()
    local size = vec2(800, 600)

    local menu = ScriptUI()
    window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))

    window.caption = "Research /* station title */"%_t
    window.showCloseButton = 1
    window.moveable = 1
    menu:registerWindow(window, "Research"%_t);

    local hsplit = UIHorizontalSplitter(Rect(window.size), 10, 10, 0.4)

    inventory = window:createSelection(hsplit.bottom, 11)

    local vsplit = UIVerticalSplitter(hsplit.top, 10, 10, 0.4)

    local hsplitleft = UIHorizontalSplitter(vsplit.left, 10, 10, 0.5)

    hsplitleft.padding = 6
    local rect = hsplitleft.top
    rect.width = 220
    required = window:createSelection(rect, 3)

    local rect = hsplitleft.bottom
    rect.width = 150
    optional = window:createSelection(rect, 2)

    for _, sel in pairs({required, optional}) do
        sel.dropIntoEnabled = 1
        sel.entriesSelectable = 0
        sel.onReceivedFunction = "onRequiredReceived"
        sel.onDroppedFunction = "onRequiredDropped"
        sel.onClickedFunction = "onRequiredClicked"
    end

    inventory.dragFromEnabled = 1
    inventory.onClickedFunction = "onInventoryClicked"


    vsplit.padding = 30
    local rect = vsplit.right
    rect.width = 70
    rect.height = 70
    results = window:createSelection(rect, 1)
    results.entriesSelectable = 0
    results.dropIntoEnabled = 0
    results.dropIntoEnabled = 0

    vsplit.padding = 10
    local organizer = UIOrganizer(vsplit.right)
    organizer.marginBottom = 5

    button = window:createButton(Rect(), "Research"%_t, "onClickResearch")
    button.width = 200
    button.height = 40
    organizer:placeElementBottom(button)

end

function removeItemFromMainSelection(key)
    local item = inventory:getItem(key)
    if not item then return end

    if item.amount then
        item.amount = item.amount - 1
        if item.amount == 0 then item.amount = nil end
    end

    inventory:remove(key)

    if item.amount then
        inventory:add(item, key)
    end

end

function addItemToMainSelection(item)
    if not item then return end

    if item.item.stackable then
        -- find the item and increase the amount
        for k, v in pairs(inventory:getItems()) do
            if v.item == item.item then
                v.amount = v.amount + 1

                inventory:remove(k)
                inventory:add(v, k)
                return
            end
        end

        item.amount = 1
    end

    -- when not found or not stackable, add it
    inventory:add(item)

end

function moveItem(item, from, to, fkey, tkey)
    if not item then return end

    if from.index == inventory.index then -- move from inventory to a selection
        -- first, move the item that might be in place back to the inventory
        if tkey then
            addItemToMainSelection(to:getItem(tkey))
            to:remove(tkey)
        end

        removeItemFromMainSelection(fkey)

        -- fix item amount, we don't want numbers in the upper selections
        item.amount = nil
        to:add(item, tkey)

    elseif to.index == inventory.index then
        -- move from selection to inventory
        addItemToMainSelection(item)
        from:remove(fkey)
    end
end

function onRequiredReceived(selectionIndex, fkx, fky, item, fromIndex, toIndex, tkx, tky)
    if not item then return end

    -- don't allow dragging from/into the left hand selections
    if fromIndex == optional.index or fromIndex == required.index then
        return
    end

    moveItem(item, inventory, Selection(selectionIndex), ivec2(fkx, fky), ivec2(tkx, tky))

    refreshButton()
    results:clear()
    results:addEmpty()
end

function onRequiredClicked(selectionIndex, fkx, fky, item, button)
    if button == 3 or button == 2 then
        moveItem(item, Selection(selectionIndex), inventory, ivec2(fkx, fky), nil)
        refreshButton()
    end
end

function onRequiredDropped(selectionIndex, kx, ky)
    local selection = Selection(selectionIndex)
    local key = ivec2(kx, ky)
    moveItem(selection:getItem(key), Selection(selectionIndex), inventory, key, nil)
    refreshButton()
end

function onInventoryClicked(selectionIndex, kx, ky, item, button)

    if button == 2 or button == 3 then
        -- fill required first, then, once it's full, fill optional
        local items = required:getItems()
        if tablelength(items) < 3 then
            moveItem(item, inventory, required, ivec2(kx, ky), nil)

            refreshButton()
            results:clear()
            results:addEmpty()
            return
        end

        local items = optional:getItems()
        if tablelength(items) < 2 then
            moveItem(item, inventory, optional, ivec2(kx, ky), nil)

            refreshButton()
            results:clear()
            results:addEmpty()
            return
        end
    end
end

function refreshButton()
    local items = required:getItems()
    button.active = (tablelength(items) == 3)

    if tablelength(items) ~= 3 then
        button.tooltip = "Place at least 3 items for research!"%_t
    else
        button.tooltip = "Transform into a new item"%_t
    end

end

function onShowWindow()

    inventory:clear()
    required:clear()
    optional:clear()

    required:addEmpty()
    required:addEmpty()
    required:addEmpty()

    optional:addEmpty()
    optional:addEmpty()

    results:addEmpty()

    refreshButton()

    for i = 1, 50 do
        inventory:addEmpty()
    end

    local items = {}
    local player = Player()
    for index, slot in pairs(Player():getInventory():getItems()) do
        local item = SellableInventoryItem(slot.item, index, player)
        table.insert(items, item)
    end

    table.sort(items, SortSellableInventoryItems)

    for i, p in pairs(items) do
        local item = SelectionItem()
        item.item = p.item
        item.uvalue = p.index -- use the uvalue uservalue to store the index of the item in the inventory

        -- show numbers for stackable items
        if p.item.stackable then
            item.amount = p.amount
        else
            item.amount = nil
        end

        inventory:add(item)
    end

end

function checkRarities(items) -- items must not be more than 1 rarity apart
    local min = math.huge
    local max = -math.huge

    for _, item in pairs(items) do
        if item.rarity.value < min then min = item.rarity.value end
        if item.rarity.value > max then max = item.rarity.value end
    end

    if max - min <= 1 then
        return true
    end

    return false
end

function getRarityProbabilities(items)

    local probabilities = {}

    -- for each item there is a 20% chance that the researched item has a rarity 1 better
    for _, item in pairs(items) do
        -- next rarity cannot exceed legendary
        local nextRarity = math.min(RarityType.Legendary, item.rarity.value + 1)

        local p = probabilities[nextRarity] or 0
        p = p + 0.2
        probabilities[nextRarity] = p
    end

    -- if the amount of items is < 5 then add their own rarities as a result as well
    if #items < 5 then
        local left = (1.0 - #items * 0.2)
        local perItem = left / #items

        for _, item in pairs(items) do
            local p = probabilities[item.rarity.value] or 0
            p = p + perItem
            probabilities[item.rarity.value] = p
        end
    end

    local sum = 0
    for _, p in pairs(probabilities) do
        sum = sum + p
    end

    return probabilities
end

function getTypeProbabilities(items)
    local probabilities = {}

    for _, item in pairs(items) do
        local p = probabilities[item.itemType] or 0
        p = p + 1
        probabilities[item.itemType] = p
    end

    return probabilities
end

-- since there are no more exact weapon types in the finished weapons,
-- we have to gather the weapon types by their stats, such as icons
function getWeaponTypesByIcon()
    if weaponTypes then return weaponTypes end
    weaponTypes = {}

    local weapons = Balancing_GetWeaponProbability(0, 0)

    for weaponType, _ in pairs(weapons) do
        local turret = GenerateTurretTemplate(Seed(1), weaponType, 15, 5, Rarity(RarityType.Common), Material(MaterialType.Iron))
        weaponTypes[turret.weaponIcon] = weaponType
    end

    return weaponTypes
end

function getWeaponProbabilities(items)
    local probabilities = {}
    local typesByIcons = getWeaponTypesByIcon()

    for _, item in pairs(items) do
        if item.itemType == InventoryItemType.Turret
            or item.itemType == InventoryItemType.TurretTemplate then

            local weaponType = typesByIcons[item.weaponIcon]
            local p = probabilities[weaponType] or 0
            p = p + 1
            probabilities[weaponType] = p
        end
    end

    return probabilities
end

function getWeaponMaterials(items)
    local probabilities = {}

    for _, item in pairs(items) do
        if item.itemType == InventoryItemType.Turret
            or item.itemType == InventoryItemType.TurretTemplate then

            local p = probabilities[item.material.value] or 0
            p = p + 1
            probabilities[item.material.value] = p
        end
    end

    return probabilities
end

function getAutoFires(items)
    local probabilities = {}

    for _, item in pairs(items) do
        if item.itemType == InventoryItemType.Turret
            or item.itemType == InventoryItemType.TurretTemplate then

            local p = probabilities[item.automatic] or 0
            p = p + 1
            probabilities[item.automatic] = p
        end
    end

    return probabilities
end

function getSystemProbabilities(items)
    local probabilities = {}

    for _, item in pairs(items) do
        if item.itemType == InventoryItemType.SystemUpgrade then
            local p = probabilities[item.script] or 0
            p = p + 1
            probabilities[item.script] = p
        end
    end

    return probabilities
end





function onClickResearch()

    local items = {}
    local itemIndices = {}

    for _, item in pairs(required:getItems()) do
        table.insert(items, item.item)

        local amount = itemIndices[item.uvalue] or 0
        amount = amount + 1
        itemIndices[item.uvalue] = amount
    end
    for _, item in pairs(optional:getItems()) do
        table.insert(items, item.item)

        local amount = itemIndices[item.uvalue] or 0
        amount = amount + 1
        itemIndices[item.uvalue] = amount
    end

    if not checkRarities(items) then
        displayChatMessage("Your items cannot be more than one rarity apart!"%_t, Entity().title, 1)
        return
    end

    invokeServerFunction("research", itemIndices)
end

function research(itemIndices)

    local player = Player(callingPlayer)

    -- check if the player has enough of the items
    local items = {}

    for index, amount in pairs(itemIndices) do
        local item = player:getInventory():find(index)
        local has = player:getInventory():amount(index)

        if not item or has < amount then
            player:sendChatMessage(Entity().title, 1, "You dont have enough items!"%_t)
            return
        end

        for i = 1, amount do
            table.insert(items, item)
        end
    end

    if #items < 3 then
        player:sendChatMessage(Entity().title, 1, "You need at least 3 items to do research!"%_t)
        return
    end

    if not checkRarities(items) then
        player:sendChatMessage(Entity().title, 1, "Your items cannot be more than one rarity apart!"%_t)
        return
    end

    local player = Player(callingPlayer)
    local ship = player.craft
    local station = Entity()

    local errors = {}
    errors[EntityType.Station] = "You must be docked to the station to research items."%_T
    errors[EntityType.Ship] = "You must be closer to the ship to research items."%_T
    if not CheckPlayerDocked(player, station, errors) then
        return
    end

    local result = transform(items)

    if result then
        for index, amount in pairs(itemIndices) do
            for i = 1, amount do
                player:getInventory():take(index)
            end
        end

        player:getInventory():add(result)

        invokeClientFunction(player, "receiveResult", result)
    else
        print ("no result")
    end


end

function receiveResult(result)
    results:clear();
    results:addInventoryItem(result);

    onShowWindow()
end

function transform(items)

    local transformToKey

    if items[1].itemType == InventoryItemType.SystemUpgrade
        and items[2].itemType == InventoryItemType.SystemUpgrade
        and items[3].itemType == InventoryItemType.SystemUpgrade
        and items[1].rarity.value == RarityType.Legendary
        and items[2].rarity.value == RarityType.Legendary
        and items[3].rarity.value == RarityType.Legendary then

        local inputKeys = 0
        for _, item in pairs(items) do
            if string.match(item.script, "systems/teleporterkey") then
                inputKeys = inputKeys + 1
            end
        end

        if inputKeys <= 1 then
            transformToKey = true
        end
    end

    local result

    if transformToKey then
        result = SystemUpgradeTemplate("data/scripts/systems/teleporterkey2.lua", Rarity(RarityType.Legendary), random():createSeed())
    else
        local rarities = getRarityProbabilities(items)
        local types = getTypeProbabilities(items, "type")

        local itemType = selectByWeight(random(), types)
        local rarity = Rarity(selectByWeight(random(), rarities))


        if itemType == InventoryItemType.Turret
            or itemType == InventoryItemType.TurretTemplate then

            local weaponTypes = getWeaponProbabilities(items)
            local materials = getWeaponMaterials(items)
            local autoFires = getAutoFires(items)

            local weaponType = selectByWeight(random(), weaponTypes)
            local material = Material(selectByWeight(random(), materials))
            local autoFire = selectByWeight(random(), autoFires)

            local x, y = Sector():getCoordinates()
            result = TurretGenerator.generate(x, y, -5, rarity, weaponType, material)

            if itemType == InventoryItemType.Turret then
                result = InventoryTurret(result)
            end

            result.automatic = autoFire or false

        elseif itemType == InventoryItemType.SystemUpgrade then
            local scripts = getSystemProbabilities(items)

            local script = selectByWeight(random(), scripts)

            result = SystemUpgradeTemplate(script, rarity, random():createSeed())
        end
    end

    return result
end


























