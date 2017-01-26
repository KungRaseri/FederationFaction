package.path = package.path .. ";data/scripts/lib/?.lua"
require ("randomext")
require ("galaxy")
require ("faction")
require ("utility")
require ("tradingmanager")
require("stringutility")
Dialog = require("dialogutility")

stationSpace = 1000


-- if this function returns false, the script will not be listed in the interaction window on the client,
-- even though its UI may be registered
function interactionPossible(playerIndex, option)
    if Player(playerIndex).craftIndex == Entity().index then return false end

    return CheckFactionInteraction(playerIndex, -45000, 40000)
end

function restore(data)
    restoreTradingGoods(data)
end

function secure()
    return secureTradingGoods()
end

-- this function gets called on creation of the entity the script is attached to, on client and server
function initialize()
    local station = Entity()

    if station.title == "" then
        station.title = "Trading Post"%_t
    end

    if onServer() then
        math.randomseed(Sector().seed + station.index); math.random(); math.random(); math.random();

        -- make lists of all items that will be sold/bought
        local bought, sold = generateGoods(13, 15) -- generate both at the same time, this won't create duplicates

        buyPriceFactor = math.random() * 0.2 + 0.9 -- 0.9 to 1.1
        sellPriceFactor = math.random() * 0.2 + 0.9 -- 0.9 to 1.1

        initializeTrading(bought, sold)

    else
        requestGoods()

        if EntityIcon().icon == "" then
            EntityIcon().icon = "data/textures/icons/pixel/trade.png"
            InteractionText(station.index).text = Dialog.generateStationInteractionText(station, random())
        end

    end
end

-- this function gets called on creation of the entity the script is attached to, on client only
-- AFTER initialize above
-- create all required UI elements for the client side
function initUI()

    local size = vec2(950, 650)
    local res = getResolution()

    local menu = ScriptUI()
    local mainWindow = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5));
    menu:registerWindow(mainWindow, "Buy / Sell Goods"%_t);

    mainWindow.caption = "Trading Post"%_t
    mainWindow.showCloseButton = 1
    mainWindow.moveable = 1

    -- create a tabbed window inside the main window
    tabbedWindow = mainWindow:createTabbedWindow(Rect(vec2(10, 10), size - 10))

    -- create buy tab
    local buyTab = tabbedWindow:createTab("Buy"%_t, "data/textures/icons/purse.png", "Buy from station"%_t)
    buildBuyGui(buyTab)

    -- create sell tab
    local sellTab = tabbedWindow:createTab("Sell"%_t, "data/textures/icons/coins.png", "Sell to station"%_t)
    buildSellGui(sellTab)

    guiInitialized = true

    requestGoods()
end

-- this functions gets called when the indicator of the station is rendered on the client
--function renderUIIndicator(px, py, size)
--
--end
--
---- this function gets called every time the window is shown on the client, ie. when a player presses F and if interactionPossible() returned 1
function onShowWindow()
    requestGoods()
end
--
---- this function gets called every time the window is closed on the client
--function onCloseWindow()
--
--end
--
---- this function gets called once each frame, on client and server
--function update(timeStep)
--
--end
--
---- this function gets called once each frame, on client only
--function updateClient(timeStep)
--
--end

function getUpdateInterval()
    return 5
end

---- this function gets called once each frame, on server only
function updateServer(timeStep)
    useUpBoughtGoods(timeStep)

    updateOrganizeGoodsBulletins(timeStep)
    updateDeliveryBulletins(timeStep)
end
--
---- this function gets called whenever the ui window gets rendered, AFTER the window was rendered (client only)
--function renderUI()
--
--end





