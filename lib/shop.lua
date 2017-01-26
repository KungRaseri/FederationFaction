--[[

This script is a template for creating station or entity scripts.
The script runs on the server and on the client simultaneously.

There are various methods that get called at specific points of the game,
read the comments of the methods for further information.
It is required that these methods do not get changed, otherwise this will
lead to controlled crashes of the game.

]]--

package.path = package.path .. ";data/scripts/lib/?.lua"
require ("galaxy")
require ("randomext")
require ("utility")
require ("stringutility")
require ("player")
SellableInventoryItem = require ("sellableinventoryitem")
Dialog = require("dialogutility")

local Shop = {}

Shop.ItemWrapper = SellableInventoryItem

-- UI
soldItemFrames = {}
soldItemNameLabels = {}
soldItemPriceLabels = {}
soldItemMaterialLabels = {}
soldItemStockLabels = {}
soldItemButtons = {}
soldItemIcons = {}

boughtItemFrames = {}
boughtItemNameLabels = {}
boughtItemPriceLabels = {}
boughtItemMaterialLabels = {}
boughtItemStockLabels = {}
boughtItemButtons = {}
boughtItemIcons = {}

pageLabel = 0

buybackItemFrames = {}
buybackItemNameLabels = {}
buybackItemPriceLabels = {}
buybackItemMaterialLabels = {}
buybackItemStockLabels = {}
buybackItemButtons = {}
buybackItemIcons = {}

itemsPerPage = 15

soldItems = {}
boughtItems = {}
buybackItems = {}

boughtItemsPage = 0

local guiInitialized = false

buyTab = nil
sellTab = nil
buyBackTab = nil

-- this function gets called on creation of the entity the script is attached to, on client and server
function initialize(title)

    local station = Entity()
    if onServer() then
        if station.title == "" then
            station.title = title
        end

        addItems()
    else
        InteractionText().text = Dialog.generateStationInteractionText(station, random())
        requestItems()
    end
end

-- this function gets called on creation of the entity the script is attached to, on client only
-- AFTER initialize above
-- create all required UI elements for the client side
function initUI(buttonCaption, windowCaption)

    local size = vec2(900, 690)
    local res = getResolution()

    local menu = ScriptUI()
    local window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5));
    menu:registerWindow(window, buttonCaption);

    window.caption = windowCaption
    window.showCloseButton = 1
    window.moveable = 1

    -- create a tabbed window inside the main window
    tabbedWindow = window:createTabbedWindow(Rect(vec2(10, 10), size - 10))

    -- create buy tab
    buyTab = tabbedWindow:createTab("Buy"%_t, "data/textures/icons/purse.png", "Buy from station"%_t)
    buildBuyGui(buyTab)

    -- create sell tab
    sellTab = tabbedWindow:createTab("Sell"%_t, "data/textures/icons/coins.png", "Sell to station"%_t)
    buildSellGui(sellTab)

    buyBackTab = tabbedWindow:createTab("Buyback"%_t, "data/textures/icons/cycle.png", "Buy back sold items"%_t)
    buildBuyBackGui(buyBackTab)

    guiInitialized = true

    requestItems()
end

function buildBuyGui(tab) -- client
    buildGui(tab, 0)
end

function buildSellGui(tab) -- client
    buildGui(tab, 1)
end

function buildBuyBackGui(tab) -- client
    buildGui(tab, 2)

end

function buildGui(window, guiType) -- client

    local buttonCaption = ""
    local buttonCallback = ""

    local size = window.size
    local pos = window.lower

--    window:createFrame(Rect(size))

    if guiType == 0 then
        buttonCaption = "Buy"%_t
        buttonCallback = "onBuyButtonPressed"
    elseif guiType == 1 then
        buttonCaption = "Sell"%_t
        buttonCallback = "onSellButtonPressed"

        window:createButton(Rect(0, 50 + 35 * 15, 70, 80 + 35 * 15), "<", "onLeftButtonPressed")
        window:createButton(Rect(size.x - 70, 50 + 35 * 15, 60 + size.x - 60, 80 + 35 * 15), ">", "onRightButtonPressed")

        pageLabel = window:createLabel(vec2(10, 50 + 35 * 15), "", 20)
        pageLabel.lower = vec2(pos.x + 10, pos.y + 50 + 35 * 15)
        pageLabel.upper = vec2(pos.x + size.x - 70, pos.y + 75)
        pageLabel.centered = 1
    else
        buttonCaption = "Buy"%_t
        buttonCallback = "onBuybackButtonPressed"
    end

    local pictureX = 20
    local nameX = 60
    local materialX = 480
    local stockX = 560
    local priceX = 600
    local buttonX = 720

    -- header
    window:createLabel(vec2(nameX, 0), "Name"%_t, 15)
    window:createLabel(vec2(materialX, 0), "Mat"%_t, 15)
    window:createLabel(vec2(priceX, 0), "Cr"%_t, 15)
    window:createLabel(vec2(stockX, 0), "#"%_t, 15)

    local y = 25
    for i = 1, itemsPerPage do

        local yText = y + 6

        local frame = window:createFrame(Rect(0, y, buttonX - 10, 30 + y))

        local nameLabel = window:createLabel(vec2(nameX, yText), "", 15)
        local priceLabel = window:createLabel(vec2(priceX, yText), "", 15)
        local materialLabel = window:createLabel(vec2(materialX, yText), "", 15)
        local stockLabel = window:createLabel(vec2(stockX, yText), "", 15)
        local button = window:createButton(Rect(buttonX, yText - 6, 160 + buttonX, 30 + yText - 6), buttonCaption, buttonCallback)
        local icon = window:createPicture(Rect(pictureX, yText - 5, 29 + pictureX, 29 + yText - 5), "")

        button.maxTextSize = 16
        icon.isIcon = 1

        if guiType == 0 then
            table.insert(soldItemFrames, frame)
            table.insert(soldItemNameLabels, nameLabel)
            table.insert(soldItemPriceLabels, priceLabel)
            table.insert(soldItemMaterialLabels, materialLabel)
            table.insert(soldItemStockLabels, stockLabel)
            table.insert(soldItemButtons, button)
            table.insert(soldItemIcons, icon)
        elseif guiType == 1 then
            table.insert(boughtItemFrames, frame)
            table.insert(boughtItemNameLabels, nameLabel)
            table.insert(boughtItemPriceLabels, priceLabel)
            table.insert(boughtItemMaterialLabels, materialLabel)
            table.insert(boughtItemStockLabels, stockLabel)
            table.insert(boughtItemButtons, button)
            table.insert(boughtItemIcons, icon)
        elseif guiType == 2 then
            table.insert(buybackItemFrames, frame)
            table.insert(buybackItemNameLabels, nameLabel)
            table.insert(buybackItemPriceLabels, priceLabel)
            table.insert(buybackItemMaterialLabels, materialLabel)
            table.insert(buybackItemStockLabels, stockLabel)
            table.insert(buybackItemButtons, button)
            table.insert(buybackItemIcons, icon)
        end

        frame:hide();
        nameLabel:hide();
        priceLabel:hide();
        materialLabel:hide();
        stockLabel:hide();
        button:hide();
        icon:hide();

        y = y + 35
    end

end

-- this function gets called every time the window is shown on the client, ie. when a player presses F and if interactionPossible() returned 1
function onShowWindow()

    boughtItemsPage = 0

    updatePlayerItems()
    updateBuyGui()
    updateBuybackGui()
end

-- send a request to the server for the sold items
function requestItems() -- client
    soldItems = {}
    boughtItems = {}

    invokeServerFunction("sendItems", Player().index)
end

-- send sold items to client
function sendItems(playerIndex) -- server
    invokeClientFunction(Player(playerIndex), "receiveSoldItems", soldItems, buybackItems)
end

function receiveSoldItems(sold, buyback) -- client

    soldItems = sold
    for i, v in pairs(soldItems) do
        local item = Shop.ItemWrapper(v.item)
        item.amount = v.amount

        soldItems[i] = item
    end

    buybackItems = buyback
    for i, v in pairs(buybackItems) do
        local item = SellableInventoryItem(v.item)
        item.amount = v.amount

        buybackItems[i] = item
    end

    updatePlayerItems()
    updateSellGui()
    updateBuyGui()
    updateBuybackGui()
end

function updatePlayerItems() -- client only

    boughtItems = {}

    local player = Player()
    local items = player:getInventory():getItems()

    for index, slotItem in pairs(items) do
        table.insert(boughtItems, SellableInventoryItem(slotItem.item, index, player))
    end

    table.sort(boughtItems, SortSellableInventoryItems)
end

function updateBoughtItem(index, stock) -- client
    for i, item in pairs(boughtItems) do
        if item.index == index then
            if stock > 0 then
                item.amount = stock
            else
                boughtItems[i] = nil
                rebuildTables()
            end

            break
        end
    end

    updateBuyGui()
    updatePlayerItems()
end

-- update the buy tab (the tab where the STATION SELLS)
function updateSellGui() -- client

    if not guiInitialized then return end

    for i, v in pairs(soldItemFrames) do v:hide() end
    for i, v in pairs(soldItemNameLabels) do v:hide() end
    for i, v in pairs(soldItemPriceLabels) do v:hide() end
    for i, v in pairs(soldItemMaterialLabels) do v:hide() end
    for i, v in pairs(soldItemStockLabels) do v:hide() end
    for i, v in pairs(soldItemButtons) do v:hide() end
    for i, v in pairs(soldItemIcons) do v:hide() end

    for index, item in pairs(soldItems) do

        soldItemFrames[index]:show()
        soldItemNameLabels[index]:show()
        soldItemPriceLabels[index]:show()
        soldItemMaterialLabels[index]:show()
        soldItemStockLabels[index]:show()
        soldItemButtons[index]:show()
        soldItemIcons[index]:show()

        soldItemNameLabels[index].caption = item.name
        soldItemNameLabels[index].color = item.rarity.color
        soldItemNameLabels[index].bold = false

        if item.material then
            soldItemMaterialLabels[index].caption = item.material.name
            soldItemMaterialLabels[index].color = item.material.color
        else
            soldItemMaterialLabels[index]:hide()
        end

        if item.icon then
            soldItemIcons[index].picture = item.icon
            soldItemIcons[index].color = item.rarity.color
        end

        soldItemPriceLabels[index].caption = createMonetaryString(item.price)

        soldItemStockLabels[index].caption = item.amount

    end

end

-- update the sell tab (the tab where the STATION BUYS)
function updateBuyGui() -- client

    if not guiInitialized then return end

    local numDifferentItems = #boughtItems

    while boughtItemsPage * itemsPerPage >= numDifferentItems do
        boughtItemsPage = boughtItemsPage - 1
    end

    if boughtItemsPage < 0 then
        boughtItemsPage = 0
    end


    for i, v in pairs(boughtItemFrames) do v:hide() end
    for i, v in pairs(boughtItemNameLabels) do v:hide() end
    for i, v in pairs(boughtItemPriceLabels) do v:hide() end
    for i, v in pairs(boughtItemMaterialLabels) do v:hide() end
    for i, v in pairs(boughtItemStockLabels) do v:hide() end
    for i, v in pairs(boughtItemButtons) do v:hide() end
    for i, v in pairs(boughtItemIcons) do v:hide() end

    local itemStart = boughtItemsPage * itemsPerPage + 1
    local itemEnd = math.min(numDifferentItems, itemStart + 14)

    local uiIndex = 1

    for index = itemStart, itemEnd do

        local item = boughtItems[index]

        if item == nil then
            break
        end

        boughtItemFrames[uiIndex]:show()
        boughtItemNameLabels[uiIndex]:show()
        boughtItemPriceLabels[uiIndex]:show()
        boughtItemMaterialLabels[uiIndex]:show()
        boughtItemStockLabels[uiIndex]:show()
        boughtItemButtons[uiIndex]:show()
        boughtItemIcons[uiIndex]:show()

        boughtItemNameLabels[uiIndex].caption = item.name
        boughtItemNameLabels[uiIndex].color = item.rarity.color
        boughtItemNameLabels[uiIndex].bold = false

        boughtItemPriceLabels[uiIndex].caption = createMonetaryString(item.price * 0.25)

        if item.material then
            boughtItemMaterialLabels[uiIndex].caption = item.material.name
            boughtItemMaterialLabels[uiIndex].color = item.material.color
        else
            boughtItemMaterialLabels[uiIndex]:hide()
        end

        if item.icon then
            boughtItemIcons[uiIndex].picture = item.icon
            boughtItemIcons[uiIndex].color = item.rarity.color
        end

        boughtItemStockLabels[uiIndex].caption = item.amount

        uiIndex = uiIndex + 1
    end

    if itemEnd < itemStart then
        itemEnd = 0
        itemStart = 0
    end

    pageLabel.caption = itemStart .. " - " .. itemEnd .. " / " .. numDifferentItems

end

-- update the sell tab (the tab where the STATION BUYS)
function updateBuybackGui() -- client

    if not guiInitialized then return end

    for i, v in pairs(buybackItemFrames) do v:hide() end
    for i, v in pairs(buybackItemNameLabels) do v:hide() end
    for i, v in pairs(buybackItemPriceLabels) do v:hide() end
    for i, v in pairs(buybackItemMaterialLabels) do v:hide() end
    for i, v in pairs(buybackItemStockLabels) do v:hide() end
    for i, v in pairs(buybackItemButtons) do v:hide() end
    for i, v in pairs(buybackItemIcons) do v:hide() end

    for index = 1, math.min(15, #buybackItems) do

        local item = buybackItems[index]

        buybackItemFrames[index]:show()
        buybackItemNameLabels[index]:show()
        buybackItemPriceLabels[index]:show()
        buybackItemMaterialLabels[index]:show()
        buybackItemStockLabels[index]:show()
        buybackItemButtons[index]:show()
        buybackItemIcons[index]:show()

        buybackItemNameLabels[index].caption = item.name
        buybackItemNameLabels[index].color = item.rarity.color
        buybackItemNameLabels[index].bold = false

        buybackItemPriceLabels[index].caption = createMonetaryString(item.price * 0.25)

        if item.material then
            buybackItemMaterialLabels[index].caption = item.material.name
            buybackItemMaterialLabels[index].color = item.material.color
        else
            buybackItemMaterialLabels[index]:hide()
        end

        if item.icon then
            buybackItemIcons[index].picture = item.icon
            buybackItemIcons[index].color = item.rarity.color
        end

        buybackItemStockLabels[index].caption = item.amount
    end

end

function onLeftButtonPressed()
    boughtItemsPage = boughtItemsPage - 1
    updateBuyGui()
end

function onRightButtonPressed()
    boughtItemsPage = boughtItemsPage + 1
    updateBuyGui()
end

function onBuyButtonPressed(button) -- client
    local itemIndex = 0
    for i, b in pairs(soldItemButtons) do
        if button.index == b.index then
            itemIndex = i
        end
    end

    invokeServerFunction("sellToPlayer", Player().craftIndex, itemIndex)
end

function onSellButtonPressed(button) -- client
    local itemIndex = 0
    for i, b in pairs(boughtItemButtons) do
        if button.index == b.index then
            itemIndex = boughtItemsPage * itemsPerPage + i
        end
    end

    invokeServerFunction("buyFromPlayer", Player().craftIndex, boughtItems[itemIndex].index)
end

function onBuybackButtonPressed(button) -- client
    local itemIndex = 0
    for i, b in pairs(buybackItemButtons) do
        if button.index == b.index then
            itemIndex = i
        end
    end

    invokeServerFunction("sellBackToPlayer", Player().craftIndex, itemIndex)
end


function add(item_in, amount)
    amount = amount or 1

    local item = Shop.ItemWrapper(item_in)

    item.name = item.name or ""
    item.price = item.price or 0
    item.amount = amount

    table.insert(soldItems, item)

end

function addFront(item_in, amount)
    local items = soldItems
    soldItems = {}

    add(item_in, amount)

    for _, item in pairs(items) do
        table.insert(soldItems, item)
    end

end

function sellToPlayer(shipIndex, itemIndex) -- server

    local ship = Entity(shipIndex)
    local station = Entity()

    if callingPlayer ~= ship.factionIndex then
        player:sendChatMessage(station.title, 1, "Wrong player"%_t)
        return
    end

    local player = Player(ship.factionIndex)

    local item = soldItems[itemIndex]
    if item == nil then
        player:sendChatMessage(station.title, 1, "Item to buy not found"%_t)
        return
    end

    local canPay, msg, args = player:canPay(item.price)
    if not canPay then
        player:sendChatMessage(station.title, 1, msg, unpack(args))
        return
    end

    -- test the docking last so the player can know what he can buy from afar already
    local errors = {}
    errors[EntityType.Station] = "You must be docked to the station to buy items."%_T
    errors[EntityType.Ship] = "You must be closer to the ship to buy items."%_T
    if not CheckPlayerDocked(player, station, errors) then
        return
    end

    local msg, args = item:boughtByPlayer(ship)
    if msg and msg ~= "" then
        player:sendChatMessage(station.title, 1, msg, unpack(args))
        return
    end

    player:pay(item.price)

    -- remove item
    item.amount = item.amount - 1
    if item.amount == 0 then
        soldItems[itemIndex] = nil
        rebuildTables()
    end

    Galaxy():changeFactionRelations(player, Faction(), GetRelationChangeFromMoney(item.price))

    -- do a broadcast to all clients that the item is sold out/changed
    broadcastInvokeClientFunction("receiveSoldItems", soldItems, buybackItems)
end

function buyFromPlayer(shipIndex, itemIndex) -- server

    local ship = Entity(shipIndex)
    local station = Entity()

    if callingPlayer ~= ship.factionIndex then
        player:sendChatMessage(station.title, 1, "Wrong player"%_t)
        return
    end

    local player = Player(ship.factionIndex)

    -- test the docking last so the player can know what he can buy from afar already
    local errors = {}
    errors[EntityType.Station] = "You must be docked to the station to sell items."%_T
    errors[EntityType.Ship] = "You must be closer to the ship to sell items."%_T
    if not CheckPlayerDocked(player, station, errors) then
        return
    end

    local iitem = player:getInventory():find(itemIndex)
    if iitem == nil then
        player:sendChatMessage(station.title, 1, "Item to sell not found."%_t)
        return
    end

    local item = SellableInventoryItem(iitem, itemIndex, player)
    item.amount = 1

    local msg, args = item:soldByPlayer(ship)
    if msg and msg ~= "" then
        player:sendChatMessage(station.title, 1, msg, unpack(args))
        return
    end

    player:receive(item.price * 0.25)

    -- insert the item into buyback list
    for i = 14, 1, -1 do
        buybackItems[i + 1] = buybackItems[i]
    end
    buybackItems[1] = item

    Galaxy():changeFactionRelations(player, Faction(), GetRelationChangeFromMoney(item.price))

    broadcastInvokeClientFunction("updateBoughtItem", item.index, item.amount - 1)
    broadcastInvokeClientFunction("receiveSoldItems", soldItems, buybackItems)
end

function sellBackToPlayer(shipIndex, itemIndex) -- server

    local ship = Entity(shipIndex)
    local station = Entity()

    if callingPlayer ~= ship.factionIndex then
        player:sendChatMessage(station.title, 1, "Wrong player"%_t)
        return
    end

    local player = Player(ship.factionIndex)

    local item = buybackItems[itemIndex]
    if item == nil then
        player:sendChatMessage(station.title, 1, "Item to buy not found"%_t)
        return
    end

    local canPay, msg, args = player:canPay(item.price * 0.25)
    if not canPay then
        player:sendChatMessage(station.title, 1, msg, unpack(args))
        return
    end

    -- test the docking last so the player can know what he can buy from afar already
    local errors = {}
    errors[EntityType.Station] = "You must be docked to the station to buy items."%_T
    errors[EntityType.Ship] = "You must be closer to the ship to buy items."%_T
    if not CheckPlayerDocked(player, station, errors) then
        return
    end

    local msg, args = item:boughtByPlayer(ship)
    if msg and msg ~= "" then
        player:sendChatMessage(station.title, 1, msg, unpack(args))
        return
    end

    player:pay(item.price * 0.25)

    -- remove item
    item.amount = item.amount - 1
    if item.amount == 0 then
        buybackItems[itemIndex] = nil
        rebuildTables()
    end

    Galaxy():changeFactionRelations(player, Faction(), GetRelationChangeFromMoney(item.price))

    -- do a broadcast to all clients that the item is sold out/changed
    broadcastInvokeClientFunction("receiveSoldItems", soldItems, buybackItems)

end

function rebuildTables() -- server + client
    -- rebuild sold table
    local temp = soldItems
    soldItems = {}
    for i, item in pairs(temp) do
        table.insert(soldItems, item)
    end

    local temp = boughtItems
    boughtItems = {}
    for i, item in pairs(temp) do
        table.insert(boughtItems, item)
    end

    local temp = buybackItems
    buybackItems = {}
    for i, item in pairs(temp) do
        table.insert(buybackItems, item)
    end

end

-- this function gets called whenever the ui window gets rendered, AFTER the window was rendered (client only)
function renderUI()

    local mouse = Mouse().position

    if tabbedWindow:getActiveTab().index == buyTab.index then
        for i, frame in pairs(soldItemFrames) do

            if soldItems[i] ~= nil then
                if frame.visible then

                    local l = frame.lower
                    local u = frame.upper

                    if mouse.x >= l.x and mouse.x <= u.x then
                    if mouse.y >= l.y and mouse.y <= u.y then
                        soldItems[i]:getTooltip():drawMouseTooltip(Mouse().position)
                    end
                    end
                end
            end
        end

    elseif tabbedWindow:getActiveTab().index == sellTab.index then

        for i, frame in pairs(boughtItemFrames) do

            local index = i + boughtItemsPage * itemsPerPage

            if boughtItems[index] ~= nil then
                if frame.visible then

                    local l = frame.lower
                    local u = frame.upper

                    if mouse.x >= l.x and mouse.x <= u.x then
                    if mouse.y >= l.y and mouse.y <= u.y then
                        boughtItems[index]:getTooltip():drawMouseTooltip(Mouse().position)
                    end
                    end
                end
            end
        end

    elseif tabbedWindow:getActiveTab().index == buyBackTab.index then

        for i, frame in pairs(buybackItemFrames) do

            if buybackItems[i] ~= nil then
                if frame.visible then

                    local l = frame.lower
                    local u = frame.upper

                    if mouse.x >= l.x and mouse.x <= u.x then
                    if mouse.y >= l.y and mouse.y <= u.y then
                        buybackItems[i]:getTooltip():drawMouseTooltip(Mouse().position)
                    end
                    end
                end
            end
        end

    end
end

Shop.add = add
Shop.initialize = initialize
Shop.updatePlayerItems = updatePlayerItems
Shop.initUI = initUI
Shop.buildBuyGui = buildBuyGui
Shop.buildSellGui = buildSellGui
Shop.buildBuyBackGui = buildBuyBackGui
Shop.buildGui = buildGui
Shop.requestItems = requestItems
Shop.sendItems = sendItems
Shop.receiveSoldItems = receiveSoldItems
Shop.updateBoughtItem = updateBoughtItem
Shop.updateSellGui = updateSellGui
Shop.updateBuyGui = updateBuyGui
Shop.sellToPlayer = sellToPlayer
Shop.buyFromPlayer = buyFromPlayer
Shop.onShowWindow = onShowWindow
Shop.renderUI = renderUI

return Shop


