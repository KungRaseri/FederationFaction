package.path = package.path .. ";data/scripts/lib/?.lua"
require ("galaxy")
require ("randomext")
require ("utility")
require ("faction")
require ("tradingmanager")
require("stringutility")
Dialog = require("dialogutility")

tabbedWindow = 0

consumerName = ""
consumerIcon = ""
consumedGoods = {}

-- if this function returns false, the script will not be listed in the interaction window on the client,
-- even though its UI may be registered
function interactionPossible(playerIndex, option)

    if Player(playerIndex).craftIndex == Entity().index then return false end

    return CheckFactionInteraction(playerIndex, -20000, 40000)
end

function restore(values)
    restoreTradingGoods(values)
    consumerName = values.consumerName
end

function secure()
    local values = secureTradingGoods()
    values.consumerName = consumerName

    return values
end


-- this function gets called on creation of the entity the script is attached to, on client and server
function initialize(name_in, ...)

    local entity = Entity()

    if onServer() then
        consumerName = name_in or consumerName

        local consumedGoods_in = {...}
        if #consumedGoods_in > 0 then
            consumedGoods = consumedGoods_in
        end

        local station = Entity()

        -- add the name as a category
        if consumerName ~= "" and entity.title == "" then
            entity.title = consumerName
        end


        local seed = Sector().seed + station.index
        math.randomseed(seed);

        -- consumers only buy
        buyPriceFactor = math.random() * 0.2 + 0.9 -- 0.9 to 1.1

        local bought = {}

        for i, name in pairs(consumedGoods) do
            local g = goods[name]
            table.insert(bought, g:good())
        end

        initializeTrading(bought, {})
    else
        requestGoods()

        if consumerIcon ~= "" and EntityIcon().icon == "" then
            EntityIcon().icon = consumerIcon
            InteractionText().text = Dialog.generateStationInteractionText(entity, random())
        end
    end

end

-- this function gets called on creation of the entity the script is attached to, on client only
-- AFTER initialize above
-- create all required UI elements for the client side
function initUI()

    local res = getResolution()
    local size = vec2(950, 650)

    local menu = ScriptUI()
    window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5));
    menu:registerWindow(window, "Sell Goods"%_t);

    window.caption = ""
    window.showCloseButton = 1
    window.moveable = 1

    -- create a tabbed window inside the main window
    tabbedWindow = window:createTabbedWindow(Rect(vec2(10, 10), size - 10))

    -- create buy tab
    local buyTab = tabbedWindow:createTab("Buy"%_t, "data/textures/icons/purse.png", "Buy from station"%_t)
    buildBuyGui(buyTab)

    -- create sell tab
    local sellTab = tabbedWindow:createTab("Sell"%_t, "data/textures/icons/coins.png", "Sell to station"%_t)
    buildSellGui(sellTab)

    tabbedWindow:deactivateTab(buyTab)

    guiInitialized = 1

    invokeServerFunction("sendName")
    requestGoods()

end

function sendName()
    invokeClientFunction(Player(callingPlayer), "receiveName", consumerName)
end

function receiveName(name)
    window.caption = name%_t
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

-- this function gets called once each frame, on server only
function updateServer(timeStep)
    useUpBoughtGoods(timeStep)
    updateOrganizeGoodsBulletins(timeStep)
end





-- this function gets called whenever the ui window gets rendered, AFTER the window was rendered (client only)
--function renderUI()
--
--end
