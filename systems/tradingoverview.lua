package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
require ("basesystem")
require ("utility")
require ("randomext")
local RingBuffer = require ("ringbuffer")

sellableGoodFrames = {}
sellableGoodIcons = {}
sellableGoodNameLabels = {}
sellableGoodStockLabels = {}
sellableGoodPriceLabels = {}
sellableGoodSizeLabels = {}
sellableGoodStationLabels = {}
sellableGoodPriceFactorLabels = {}
sellableGoodButtons = {}

buyableGoodFrames = {}
buyableGoodIcons = {}
buyableGoodNameLabels = {}
buyableGoodStockLabels = {}
buyableGoodPriceLabels = {}
buyableGoodSizeLabels = {}
buyableGoodStationLabels = {}
buyableGoodPriceFactorLabels = {}
buyableGoodButtons = {}

routeIcons = {}
routeFrames = {}
routePriceLabels = {}
routeCoordLabels = {}
routeStationLabels = {}
routeButtons = {}


sellable = {}
buyable = {}

routes = {}
tradingData = nil


sellablesPage = 0
buyablesPage = 0
routesPage = 0

sellableSortFunction = nil
buyableSortFunction = nil

function seePrices(seed, rarity)
    return rarity.value >= 0
end

function seePriceFactors(seed, rarity)
    return rarity.value >= 1
end

function getHistorySize(seed, rarity)

    if rarity.value == 2 then
        return 1
    elseif rarity.value >= 3 then
        math.randomseed(seed)

        if rarity.value == 5 then
            return getInt(7, 15)
        elseif rarity.value == 4 then
            return getInt(4, 6)
        elseif  rarity.value == 3 then
            return getInt(2, 3)
        end
    end

    return 0
end

function onInstalled(seed, rarity)

    if onServer() then
        local size = getHistorySize(seed, rarity)
        if size > 0 then
            tradingData = RingBuffer(size)
            collectSectorData()
        end
    end

end

function onUninstalled(seed, rarity)
end

function getName(seed, rarity)
    local prefix = ""
    if rarity.value == 0 then
        return "Basic Trading System"%_t
    elseif rarity.value == 1 then
        return "Improved Trading System"%_t
    elseif rarity.value == 2 then
        return "Advanced Trading System"%_t
    elseif rarity.value == 3 then
        return "High-Tech Trading System"%_t
    elseif rarity.value == 4 then
        return "Salesman's Trading System"%_t
    elseif rarity.value == 5 then
        return "Ultra-Tech Trading System"%_t
    end

    return "Trading System"%_t
end

function getIcon(seed, rarity)
    return "data/textures/icons/cash.png"
end

function getPrice(seed, rarity)
    local num = getHistorySize(seed, rarity)
    local price = (rarity.value + 2) * 4000 + 5000 * num;
    return price * 2.5 ^ rarity.value
end

function getTooltipLines(seed, rarity)
    local lines = {}

    if seePrices(seed, rarity) then
        table.insert(lines, {ltext = "Display prices of goods"%_t, icon = "data/textures/icons/coins.png"})
    end
    if seePriceFactors(seed, rarity) then
        table.insert(lines, {ltext = "Display price ratios of goods"%_t, icon = "data/textures/icons/coins.png"})
    end

    return lines
end

function getDescriptionLines(seed, rarity)
    local lines =
    {
        {ltext = "View trading offers of all stations of the sector"%_t}
    }

    local history = getHistorySize(seed, rarity)

    if history == 1 then
        table.insert(lines, {ltext = "Display trade routes in current sector"%_t})
    elseif history > 1 then
        table.insert(lines, {ltext = string.format("Display trade routes in last %i sectors"%_t, history)})
    end

    return lines
end

function gatherData()

    local sellable = {}
    local buyable = {}
    local scripts = {"consumer.lua", "factory.lua", "tradingpost.lua"}

    for _, station in pairs({Sector():getEntitiesByType(EntityType.Station)}) do
        for _, script in pairs(scripts) do

            local results = {station:invokeFunction(script, "getBoughtGoods")}
            local callResult = results[1]

            if callResult == 0 then -- call was successful, the station buys goods

                for i = 2, #results do
                    local name = results[i];

                    local callOk, good = station:invokeFunction(script, "getGoodByName", name)
                    if callOk ~= 0 then print("getGoodByName failed: " .. callOk) end

                    local callOk, stock, maxStock = station:invokeFunction(script, "getStock", name)
                    if callOk ~= 0 then print("getStock failed" .. callOk) end

                    local callOk, price = station:invokeFunction(script, "getBuyPrice", name, Faction().index)
                    if callOk ~= 0 then print("getBuyPrice failed" .. callOk) end

                    table.insert(sellable, {good = good, price = price, stock = stock, maxStock = maxStock, station = station.title, titleArgs = station:getTitleArguments(), stationIndex = station.index, coords = vec2(Sector():getCoordinates())})
                end
            end

            local results = {station:invokeFunction(script, "getSoldGoods")}
            local callResult = results[1]

            if callResult == 0 then -- call was successful, the station sells goods

                for i = 2, #results do
                    local name = results[i];

                    local callOk, good = station:invokeFunction(script, "getGoodByName", name)
                    if callOk ~= 0 then print("getGoodByName failed: " .. callOk) end

                    local callOk, stock, maxStock = station:invokeFunction(script, "getStock", name)
                    if callOk ~= 0 then print("getStock failed" .. callOk) end

                    local callOk, price = station:invokeFunction(script, "getSellPrice", name, Faction().index)
                    if callOk ~= 0 then print("getSellPrice failed" .. callOk) end

                    table.insert(buyable, {good = good, price = price, stock = stock, maxStock = maxStock, station = station.title, titleArgs = station:getTitleArguments(), stationIndex = station.index, coords = vec2(Sector():getCoordinates())})
                end
            end
        end
    end

    return sellable, buyable
end

function onSectorChanged()
    collectSectorData()
end

function collectSectorData()
    if tradingData then
        local sellable, buyable = gatherData()

--        print("gathered " .. #sellable .. " sellable goods from sector " .. tostring(vec2(Sector():getCoordinates())))
--        print("gathered " .. #buyable .. " buyable goods from sector " .. tostring(vec2(Sector():getCoordinates())))

        tradingData:insert({sellable = sellable, buyable = buyable})

        analyzeSectorHistory()
    end
end

function analyzeSectorHistory()

--    print("analyzing sector history")

    local buyables = {}
    local sellables = {}
    routes = {}

    local counter = 0
    local gc = 0

    -- find best offer in buyables for every good
    for _, sectorData in ipairs(tradingData.data) do
        -- find best offer in buyable for every good
        for _, offer in pairs(sectorData.buyable) do
            local existing = buyables[offer.good.name]
            if existing == nil or offer.price < existing.price then
                buyables[offer.good.name] = offer
            end

            gc = gc + 1
        end

        -- find best offer in sellable for every good
        for _, offer in pairs(sectorData.sellable) do
            local existing = sellables[offer.good.name]
            if existing == nil or offer.price > existing.price then
                sellables[offer.good.name] = offer
            end

            gc = gc + 1
        end

        counter = counter + 1
    end

    -- match those two to find possible trading routes
    for name, offer in pairs(buyables) do

        if offer.stock > 0 then
            local sellable = sellables[name]

            if sellable ~= nil and sellable.price > offer.price then
                table.insert(routes, {sellable=sellable, buyable=offer})

    --            print(string.format("found trading route for %s, buy price (in sector %s): %i, sell price (in sector %s): %i", name, tostring(offer.coords), offer.price, tostring(sellable.coords), sellable.price))
            end
        end
    end

--    print("analyzed " .. counter .. " data sets with " .. gc .. " different goods")

end

function getData(playerIndex)
    local sellable, buyable = gatherData()
    invokeClientFunction(Player(playerIndex), "setData", sellable, buyable, routes)
end



-- if this function returns false, the script will not be listed in the interaction window on the client,
-- even though its UI may be registered
function interactionPossible(playerIndex, option)

    local player = Player()
    if Entity().index == player.craftIndex then
        return true
    end

    return false
end

function initUI()
    local size = vec2(1000, 670)
    local res = getResolution()

    local menu = ScriptUI()
    local mainWindow = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5));
    menu:registerWindow(mainWindow, "Trading Overview"%_t);

    mainWindow.caption = "Trading Overview"%_t
    mainWindow.showCloseButton = 1
    mainWindow.moveable = 1

    -- create a tabbed window inside the main window
    tabbedWindow = mainWindow:createTabbedWindow(Rect(vec2(10, 10), size - 10))

    -- create routes tab
    local routesTab = tabbedWindow:createTab("Trading Routes"%_t, "data/textures/icons/trade-route.png", "View detected trading routes"%_t)
    buildRoutesGui(routesTab)

    -- create buy tab
    local buyTab = tabbedWindow:createTab("Buy"%_t, "data/textures/icons/purse.png", "Buy from stations"%_t)
    buildGui(buyTab, 1)

    -- create sell tab
    local sellTab = tabbedWindow:createTab("Sell"%_t, "data/textures/icons/coins.png", "Sell to stations"%_t)
    buildGui(sellTab, 0)

    guiInitialized = 1

end

function onShowWindow()
    invokeServerFunction("getData", Player().index)
end

function setData(sellable_received, buyable_received, routes_received)

    sellable = sellable_received
    buyable = buyable_received
    routes = routes_received

    for _, route in pairs(routes) do
        for j, offer in pairs({route.buyable, route.sellable}) do
            -- translate argument values of station title
            for k, v in pairs(offer.titleArgs) do
                offer.titleArgs[k] = v%_t
            end
        end
    end

    for _, good in pairs(buyable) do
        -- translate argument values of station title
        for k, v in pairs(good.titleArgs) do
            good.titleArgs[k] = v%_t
        end
    end

    for _, good in pairs(sellable) do
        -- translate argument values of station title
        for k, v in pairs(good.titleArgs) do
            good.titleArgs[k] = v%_t
        end
    end


    refreshUI()
end

function sortByNameAsc(a, b) return a.good.name < b.good.name end
function sortByNameDes(a, b) return a.good.name > b.good.name end

function sortByStockAsc(a, b) return a.stock / a.maxStock < b.stock / b.maxStock end
function sortByStockDes(a, b) return a.stock / a.maxStock > b.stock / b.maxStock end

function sortByPriceAsc(a, b) return a.good.price < b.good.price end
function sortByPriceDes(a, b) return a.good.price > b.good.price end

function sortByVolAsc(a, b) return a.good.size < b.good.size end
function sortByVolDes(a, b) return a.good.size > b.good.size end

function sortByPriceFactorAsc(a, b) return a.price / a.good.price < b.price / b.good.price end
function sortByPriceFactorDes(a, b) return a.price / a.good.price > b.price / b.good.price end

function sortByStationAsc(a, b) return a.station < b.station end
function sortByStationDes(a, b) return a.station > b.station end

function routesByProfit(a, b)
    -- calculate max profit
    local pa = (a.sellable.price - a.buyable.price) * a.buyable.stock
    local pb = (b.sellable.price - b.buyable.price) * b.buyable.stock
    return pa > pb
end

function routesByPriceMargin(a, b)
    -- calculate max profit
    local pa = (a.sellable.price - a.buyable.price)
    local pb = (b.sellable.price - b.buyable.price)
    return pa > pb
end



sellableSortFunction = sortByNameAsc
buyableSortFunction = sortByNameAsc

function refreshBuyablesUI()
    table.sort(buyable, buyableSortFunction)

    for index = 1, 15 do
        buyableGoodFrames[index]:hide()
        buyableGoodIcons[index]:hide()
        buyableGoodNameLabels[index]:hide()
        buyableGoodStockLabels[index]:hide()
        buyableGoodPriceLabels[index]:hide()
        buyableGoodSizeLabels[index]:hide()
        buyableGoodStationLabels[index]:hide()
        buyableGoodPriceFactorLabels[index]:hide()
        buyableGoodButtons[index]:hide()
    end

    local index = 0
    for i, good in pairs(buyable) do

        if i > buyablesPage * 15 and i <= (buyablesPage + 1) * 15 then
            index = index + 1
            if index > 15 then break end

            buyableGoodNameLabels[index].caption = good.good.displayPlural
            buyableGoodStockLabels[index].caption = math.floor(good.stock) .. " / " .. math.floor(good.maxStock)
            buyableGoodPriceLabels[index].caption = createMonetaryString(good.price)
            buyableGoodPriceFactorLabels[index].caption = string.format("%+i%%", round((good.price / good.good.price - 1.0) * 100))
            buyableGoodSizeLabels[index].caption = round(good.good.size, 2)
            buyableGoodIcons[index].picture = good.good.icon
            buyableGoodStationLabels[index].caption = good.station%_t % good.titleArgs

            buyableGoodFrames[index]:show()
            buyableGoodIcons[index]:show()
            buyableGoodNameLabels[index]:show()
            buyableGoodStockLabels[index]:show()
            buyableGoodPriceLabels[index]:show()
            buyableGoodSizeLabels[index]:show()
            buyableGoodStationLabels[index]:show()
            buyableGoodPriceFactorLabels[index]:show()
            buyableGoodButtons[index]:show()

            if getRarity().value < 1 then
                buyableGoodPriceLabels[index].caption = "-"
            end

            if getRarity().value < 2 then
                buyableGoodPriceFactorLabels[index].caption = "-"
            end

        end
    end



end


function refreshSellablesUI()
    table.sort(sellable, sellableSortFunction)

    for index = 1, 15 do
        sellableGoodFrames[index]:hide()
        sellableGoodIcons[index]:hide()
        sellableGoodNameLabels[index]:hide()
        sellableGoodStockLabels[index]:hide()
        sellableGoodPriceLabels[index]:hide()
        sellableGoodSizeLabels[index]:hide()
        sellableGoodStationLabels[index]:hide()
        sellableGoodPriceFactorLabels[index]:hide()
        sellableGoodButtons[index]:hide()
    end

    local index = 0
    for i, good in pairs(sellable) do

        if i > sellablesPage * 15 and i <= (sellablesPage + 1) * 15 then
            index = index + 1
            if index > 15 then break end

            sellableGoodNameLabels[index].caption = good.good.displayPlural
            sellableGoodStockLabels[index].caption = math.floor(good.stock) .. " / " .. math.floor(good.maxStock)
            sellableGoodPriceLabels[index].caption = createMonetaryString(good.price)
            sellableGoodPriceFactorLabels[index].caption = string.format("%+i%%", round((good.price / good.good.price - 1.0) * 100))
            sellableGoodSizeLabels[index].caption = round(good.good.size, 2)
            sellableGoodIcons[index].picture = good.good.icon
            sellableGoodStationLabels[index].caption = good.station%_t % good.titleArgs

            sellableGoodFrames[index]:show()
            sellableGoodIcons[index]:show()
            sellableGoodNameLabels[index]:show()
            sellableGoodStockLabels[index]:show()
            sellableGoodPriceLabels[index]:show()
            sellableGoodSizeLabels[index]:show()
            sellableGoodStationLabels[index]:show()
            sellableGoodPriceFactorLabels[index]:show()
            sellableGoodButtons[index]:show()


            if getRarity().value < 1 then
                sellableGoodPriceLabels[index].caption = "-"
            end

            if getRarity().value < 2 then
                sellableGoodPriceFactorLabels[index].caption = "-"
            end

        end
    end

end

function refreshRoutesUI()

    for index = 1, 15 do

        for j = 1, 2 do
            routePriceLabels[index][j]:hide()
            routeStationLabels[index][j]:hide()
            routeCoordLabels[index][j]:hide()
            routeFrames[index][j]:hide()
            routeButtons[index][j]:hide()
            routeIcons[index]:hide()
        end
    end

    table.sort(routes, routesByPriceMargin)

    local index = 0
    for i, route in pairs(routes) do

        if i > routesPage * 15 and i <= (routesPage + 1) * 15 then
            index = index + 1
            if index > 15 then break end

            for j, offer in pairs({route.buyable, route.sellable}) do

                routePriceLabels[index][j].caption = createMonetaryString(offer.price)
                routeStationLabels[index][j].caption = offer.station%_t % offer.titleArgs
                routeCoordLabels[index][j].caption = tostring(offer.coords)
                routeIcons[index].picture = offer.good.icon
                routeIcons[index].tooltip = offer.good.plural

                routePriceLabels[index][j]:show()
                routeStationLabels[index][j]:show()
                routeCoordLabels[index][j]:show()
                routeFrames[index][j]:show()
                routeButtons[index][j]:show()
                routeIcons[index]:show()

            end
        end
    end

end

function refreshUI()

    refreshBuyablesUI()
    refreshSellablesUI()
    refreshRoutesUI()

end

function buildGui(window, guiType)

    local buttonCaption = "Show"%_t
    local buttonCallback = ""
    local nextPageFunc = ""
    local previousPageFunc = ""

    if guiType == 1 then
        buttonCallback = "onBuyShowButtonPressed"
        nextPageFunc = "onNextBuyablesPage"
        previousPageFunc = "onPreviousBuyablesPage"
    else
        buttonCallback = "onSellShowButtonPressed"
        nextPageFunc = "onNextSellablesPage"
        previousPageFunc = "onPreviousSellablesPage"
    end

    local size = window.size

    window:createFrame(Rect(size))

    local pictureX = 270
    local nameX = 20
    local stockX = 310
    local volX = 430
    local priceX = 480
    local priceFactorLabelX = 550
    local stationLabelX = 610
    local buttonX = 940

    -- header
    nameLabel = window:createLabel(vec2(nameX, 10), "Name"%_t, 15)
    stockLabel = window:createLabel(vec2(stockX, 10), "Stock"%_t, 15)
    volLabel = window:createLabel(vec2(volX, 10), "Vol"%_t, 15)
    priceLabel = window:createLabel(vec2(priceX, 10), "Cr"%_t, 15)
    priceFactorLabel = window:createLabel(vec2(priceFactorLabelX, 10), "%", 15)
    stationLabel = window:createLabel(vec2(stationLabelX, 10), "Station"%_t, 15)

    nameLabel.width = 250
    stockLabel.width = 90
    volLabel.width = 50
    priceLabel.width = 70
    priceFactorLabel.width = 60
    stationLabel.width = 240

    if guiType == 1 then
        nameLabel.mouseDownFunction = "onBuyableNameLabelClick"
        stockLabel.mouseDownFunction = "onBuyableStockLabelClick"
        volLabel.mouseDownFunction = "onBuyableVolLabelClick"
        priceLabel.mouseDownFunction = "onBuyablePriceLabelClick"
        priceFactorLabel.mouseDownFunction = "onBuyablePriceFactorLabelClick"
        stationLabel.mouseDownFunction = "onBuyableStationLabelClick"
    else
        nameLabel.mouseDownFunction = "onSellableNameLabelClick"
        stockLabel.mouseDownFunction = "onSellableStockLabelClick"
        volLabel.mouseDownFunction = "onSellableVolLabelClick"
        priceLabel.mouseDownFunction = "onSellablePriceLabelClick"
        priceFactorLabel.mouseDownFunction = "onSellablePriceFactorLabelClick"
        stationLabel.mouseDownFunction = "onSellableStationLabelClick"
    end

    -- footer
    window:createButton(Rect(10, size.y - 40, 60, size.y - 10), "<", previousPageFunc)
    window:createButton(Rect(size.x - 60, size.y - 40, size.x - 10, size.y - 10), ">", nextPageFunc)

    local y = 35
    for i = 1, 15 do

        local yText = y + 6

        local frame = window:createFrame(Rect(10, y, size.x - 50, 30 + y))

        local iconPicture = window:createPicture(Rect(pictureX, yText - 5, 29 + pictureX, 29 + yText - 5), "")
        local nameLabel = window:createLabel(vec2(nameX, yText), "", 15)
        local stockLabel = window:createLabel(vec2(stockX, yText), "", 15)
        local priceLabel = window:createLabel(vec2(priceX, yText), "", 15)
        local sizeLabel = window:createLabel(vec2(volX, yText), "", 15)
        local priceFactorLabel = window:createLabel(vec2(priceFactorLabelX, yText), "", 15)
        local stationLabel = window:createLabel(vec2(stationLabelX, yText), "", 15)
        local button = window:createButton(Rect(buttonX, yText - 6, buttonX + 30, 30 + yText - 6), "", buttonCallback)

        stockLabel.font = "Arial"
        priceLabel.font = "Arial"
        sizeLabel.font = "Arial"
        priceFactorLabel.font = "Arial"
        stationLabel.font = "Arial"

        button.icon = "data/textures/icons/look-at.png"
        iconPicture.isIcon = 1

        if guiType == 1 then
            table.insert(buyableGoodIcons, iconPicture)
            table.insert(buyableGoodFrames, frame)
            table.insert(buyableGoodNameLabels, nameLabel)
            table.insert(buyableGoodStockLabels, stockLabel)
            table.insert(buyableGoodPriceLabels, priceLabel)
            table.insert(buyableGoodSizeLabels, sizeLabel)
            table.insert(buyableGoodPriceFactorLabels, priceFactorLabel)
            table.insert(buyableGoodStationLabels, stationLabel)
            table.insert(buyableGoodButtons, button)
        else
            table.insert(sellableGoodIcons, iconPicture)
            table.insert(sellableGoodFrames, frame)
            table.insert(sellableGoodNameLabels, nameLabel)
            table.insert(sellableGoodStockLabels, stockLabel)
            table.insert(sellableGoodPriceLabels, priceLabel)
            table.insert(sellableGoodSizeLabels, sizeLabel)
            table.insert(sellableGoodPriceFactorLabels, priceFactorLabel)
            table.insert(sellableGoodStationLabels, stationLabel)
            table.insert(sellableGoodButtons, button)
        end

        frame:hide();
        iconPicture:hide();
        nameLabel:hide();
        stockLabel:hide();
        priceLabel:hide();
        sizeLabel:hide();
        stationLabel:hide();
        button:hide();

        y = y + 35
    end

end

function buildRoutesGui(window)
    local buttonCaption = "Show"%_t

    local buttonCallback = "onRouteShowStationPressed"
    local nextPageFunc = "onNextRoutesPage"
    local previousPageFunc = "onPreviousRoutesPage"

    local size = window.size

    window:createFrame(Rect(size))

    local priceX = 10
    local stationLabelX = 170
    local coordLabelX = 80

    -- footer
    window:createButton(Rect(10, size.y - 40, 60, size.y - 10), "<", previousPageFunc)
    window:createButton(Rect(size.x - 60, size.y - 40, size.x - 10, size.y - 10), ">", nextPageFunc)

    local y = 35
    for i = 1, 15 do

        local yText = y + 6

        local msplit = UIVerticalSplitter(Rect(10, y, size.x - 10, 30 + y), 10, 0, 0.5)
        msplit.leftSize = 30

        local icon = window:createPicture(msplit.left, "")
        icon.isIcon = 1
        icon.picture = "data/textures/icons/circuitry.png"
        icon:hide();

        local vsplit = UIVerticalSplitter(msplit.right, 10, 0, 0.5)

        routeIcons[i] = icon
        routeFrames[i] = {}
        routePriceLabels[i] = {}
        routeCoordLabels[i] = {}
        routeStationLabels[i] = {}
        routeButtons[i] = {}

        for j, rect in pairs({vsplit.left, vsplit.right}) do

            -- create UI for good + station where to get it
            local ssplit = UIVerticalSplitter(rect, 10, 0, 0.5)
            ssplit.rightSize = 30
            local x = ssplit.left.lower.x

            if i == 1 then
                -- header
                window:createLabel(vec2(x + priceX, 10), "Cr"%_t, 15)
                window:createLabel(vec2(x + coordLabelX, 10), "Coord"%_t, 15)

                if j == 1 then
                    window:createLabel(vec2(x + stationLabelX, 10), "From"%_t, 15)
                else
                    window:createLabel(vec2(x + stationLabelX, 10), "To"%_t, 15)
                end
            end


            local frame = window:createFrame(ssplit.left)

            local priceLabel = window:createLabel(vec2(x + priceX, yText), "", 15)
            local stationLabel = window:createLabel(vec2(x + stationLabelX, yText), "", 15)
            local coordLabel = window:createLabel(vec2(x + coordLabelX, yText), "", 15)

            local button = window:createButton(ssplit.right, "", buttonCallback)

            button.icon = "data/textures/icons/look-at.png"

            frame:hide();
            priceLabel:hide();
            coordLabel:hide();
            stationLabel:hide();
            button:hide();

            priceLabel.font = "Arial"
            coordLabel.font = "Arial"
            stationLabel.font = "Arial"

            table.insert(routeFrames[i], frame)
            table.insert(routePriceLabels[i], priceLabel)
            table.insert(routeCoordLabels[i], coordLabel)
            table.insert(routeStationLabels[i], stationLabel)
            table.insert(routeButtons[i], button)

        end


        y = y + 35
    end

end

function onRouteShowStationPressed(button_in)

    for i, buttons in pairs(routeButtons) do
        for j, button in pairs(buttons) do
            if button.index == button_in.index then
                local stationIndex
                local coords
                if j == 1 then
                    stationIndex = routes[routesPage * 15 + i].buyable.stationIndex
                    coords = routes[routesPage * 15 + i].buyable.coords
                else
                    stationIndex = routes[routesPage * 15 + i].sellable.stationIndex
                    coords = routes[routesPage * 15 + i].sellable.coords
                end

                local x, y = Sector():getCoordinates()

                if coords.x == x and coords.y == y then
                    Player().selectedObject = Entity(stationIndex)
                else
                    GalaxyMap():setSelectedCoordinates(coords.x, coords.y)
                    GalaxyMap():show(coords.x, coords.y)
                end
            end
        end
    end

end

function onNextRoutesPage()
    routesPage = routesPage + 1
    refreshUI()
end

function onPreviousRoutesPage()
    routesPage = math.max(0, routesPage - 1)
    refreshUI()
end

function onNextSellablesPage()
    sellablesPage = sellablesPage + 1
    refreshUI()
end

function onPreviousSellablesPage()
    sellablesPage = math.max(0, sellablesPage - 1)
    refreshUI()
end

function onNextBuyablesPage()
    buyablesPage = buyablesPage + 1
    refreshUI()
end

function onPreviousBuyablesPage()
    buyablesPage = math.max(0, buyablesPage - 1)
    refreshUI()
end

function onBuyShowButtonPressed(button_in)

    for index, button in pairs(buyableGoodButtons) do
        if button.index == button_in.index then
            Player().selectedObject = Entity(buyable[buyablesPage * 15 + index].stationIndex)
        end
    end

end

function onSellShowButtonPressed(button_in)

    for index, button in pairs(sellableGoodButtons) do
        if button.index == button_in.index then
            Player().selectedObject = Entity(sellable[sellablesPage * 15 + index].stationIndex)
        end
    end

end

function setSortFunction(default, alternative, buyable)

    if buyable == 1 then
        if buyableSortFunction == default then
            buyableSortFunction = alternative
        else
            buyableSortFunction = default
        end
    else
        if sellableSortFunction == default then
            sellableSortFunction = alternative
        else
            sellableSortFunction = default
        end
    end

    refreshUI()
end


function onBuyableNameLabelClick(index, button)
    setSortFunction(sortByNameAsc, sortByNameDes, 1)
end

function onBuyableStockLabelClick()
    setSortFunction(sortByStockAsc, sortByStockDes, 1)
end

function onBuyableVolLabelClick()
    setSortFunction(sortByVolAsc, sortByVolDes, 1)
end

function onBuyablePriceLabelClick()
    if getRarity().value < 1 then return end
    setSortFunction(sortByPriceAsc, sortByPriceDes, 1)
end

function onBuyablePriceFactorLabelClick()
    if getRarity().value < 2 then return end
    setSortFunction(sortByPriceFactorAsc, sortByPriceFactorDes, 1)
end

function onBuyableStationLabelClick()
    setSortFunction(sortByStationAsc, sortByStationDes, 1)
end


function onSellableNameLabelClick(index, button)
    setSortFunction(sortByNameAsc, sortByNameDes, 0)
end

function onSellableStockLabelClick()
    setSortFunction(sortByStockAsc, sortByStockDes, 0)
end

function onSellableVolLabelClick()
    setSortFunction(sortByVolAsc, sortByVolDes, 0)
end

function onSellablePriceLabelClick()
    if getRarity().value < 1 then return end
    setSortFunction(sortByPriceAsc, sortByPriceDes, 0)
end

function onSellablePriceFactorLabelClick()
    if getRarity().value < 2 then return end
    setSortFunction(sortByPriceFactorAsc, sortByPriceFactorDes, 0)
end

function onSellableStationLabelClick()
    setSortFunction(sortByStationAsc, sortByStationDes, 0)
end
