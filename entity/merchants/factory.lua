package.path = package.path .. ";data/scripts/lib/?.lua"
require ("randomext")
require ("galaxy")
require ("utility")
require ("tradingmanager")
require ("goods")
require ("productions")
require ("faction")
require ("stationextensions")
require("stringutility")
Dialog = require("dialogutility")

tabbedWindow = 0

production = {}

factorySize = 1

maxDuration = 15
maxNumProductions = 2
currentProductions = {}

lowestPriceFactor = 0.5
highestPriceFactor = 1.5

buyTab = nil
sellTab = nil

-- this is only important for initialization, won't be used afterwards
minLevel = nil
maxLevel = nil

-- if this function returns false, the script will not be listed in the interaction window on the client,
-- even though its UI may be registered
function interactionPossible(playerIndex, option)
    if Player(playerIndex).craftIndex == Entity().index then return false end

    return CheckFactionInteraction(playerIndex, -10000, 40000)
end


function restore(data)
    maxDuration = data.maxDuration
    maxNumProductions = data.maxNumProductions
    factorySize = data.maxNumProductions - 1
    production = data.production
    currentProductions = data.currentProductions
    restoreTradingGoods(data.tradingData)
end

function secure()
    local data = {}
    data.maxDuration = maxDuration
    data.maxNumProductions = maxNumProductions
    data.production = production
    data.currentProductions = currentProductions
    data.tradingData = secureTradingGoods()
    return data
end


-- this function gets called on creation of the entity the script is attached to, on client and server
function initialize(producedGood, productionIndex, size)

    if onServer() then

        local station = Entity()
        local seed = Sector().seed + station.index

        math.randomseed(seed);

        -- determine the ratio with which the factory will set its sell/buy prices
        setBuySellFactor(math.random() * (highestPriceFactor - lowestPriceFactor) + lowestPriceFactor)

        if producedGood and productionIndex == nil then

            if producedGood == "nothing" then
                return
            end

            local numProductions = tablelength(productionsByGood[producedGood])
            if numProductions == nil or numProductions == 0 then
                -- good is not produced, skip and choose randomly
                print("No productions found for " .. producedGood .. ", choosing production at random")

                producedGood = nil
            else
                productionIndex = 1
            end
        end

        if producedGood == nil or productionIndex == nil then
            -- choose a production by evaluating importance
            minLevel = minLevel or 0
            maxLevel = maxLevel or 10000

            -- choose a product by level
            -- read all levels of all products
            local potentialGoods = {}
            local highestLevel = 0

            for _, good in pairs(goodsArray) do
                if good.level ~= nil then -- if it has no level, it is not produced
                    if good.level >= minLevel and good.level <= maxLevel then

                        table.insert(potentialGoods, good)

                        -- increase max level
                        if highestLevel < good.level then
                            highestLevel = good.level;
                        end
                    end
                end
            end

            -- calculate the probability that a certain production is chosen
            local probabilities = {}
            for i, good in pairs(potentialGoods) do
                -- highestlevel - good.level makes sure the higher goods have a smaller probability of being chosen
                -- +3 to add a little more randomness, so not only the "important" factories are created
                probabilities[i] = (highestLevel - good.level) + good.importance + 3
            end

            -- choose produced good
            local numProductions = nil

            while ((numProductions == nil) or (numProductions == 0)) do

                -- choose produced good at random from probability table
                local i = getValueFromDistribution(probabilities)
                producedGood = potentialGoods[i].name

                -- choose a production type, a good may be produced in multiple factories
                numProductions = tablelength(productionsByGood[producedGood])

                if numProductions == nil or numProductions == 0 then
                    -- good is not produced, skip and take next
                    -- print("product is invalid: " .. product .. "\n")
                    probabilities[i] = nil
                end
            end

            productionIndex = math.random(1, numProductions)
        end

        if size == nil then
            local distanceFromCenter = length(vec2(Sector():getCoordinates()))
            local probabilities = {}

            probabilities[1] = 1.0

            if distanceFromCenter < 450 then
                probabilities[2] = 0.5
            end

            if distanceFromCenter < 400 then
                probabilities[3] = 0.35
            end

            if distanceFromCenter < 350 then
                probabilities[4] = 0.25
            end

            if distanceFromCenter < 300 then
                probabilities[5] = 0.15
            end

            size = getValueFromDistribution(probabilities)
        end

        local chosenProduction = productionsByGood[producedGood][productionIndex]
        if chosenProduction then
            setProduction(chosenProduction, size)
        end
    else
        requestGoods()
        sync()
    end

end

function setBuySellFactor(factor)
    buyPriceFactor = factor
    sellPriceFactor = buyPriceFactor * (math.random() * 0.2 + 1.0) -- this is coupled to the buy factor with variation 1.0 to 1.2
end

function setProduction(production_in, size)

    factorySize = size or 1
    maxNumProductions = 1 + factorySize
    production = production_in

    -- make lists of all items that will be sold/bought
    local bought = {}

    -- ingredients are bought
    for i, ingredient in pairs(production.ingredients) do
        local g = goods[ingredient.name]
        table.insert(bought, g:good())
    end

    -- results and garbage are sold
    local sold = {}

    for i, result in pairs(production.results) do
        local g = goods[result.name]
        table.insert(sold, g:good())
    end

    for i, garbage in pairs(production.garbages) do
        local g = goods[garbage.name]
        table.insert(sold, g:good())
    end

    local station = Entity()

    -- set title
    if station.title == "" then
        station.title = "Factory"%_t

        local size = ""
        if factorySize == 1 then size = "S /* Size, as in S, M, L, XL etc.*/"%_t
        elseif factorySize == 2 then size = "M /* Size, as in S, M, L, XL etc.*/"%_t
        elseif factorySize == 3 then size = "L /* Size, as in S, M, L, XL etc.*/"%_t
        elseif factorySize == 4 then size = "XL /* Size, as in S, M, L, XL etc.*/"%_t
        elseif factorySize == 5 then size = "XXL /* Size, as in S, M, L, XL etc.*/"%_t
        end

        local name, args = formatFactoryName(production, size)

        local station = Entity()
        station:setTitle(name, args)

        local arms = factorySize

        if string.match(production.factory, "Solar") then
            addSolarPanels(station, arms)
        end

        if string.match(production.factory, "Mine") then
            addAsteroid(station)
        end

        if string.match(production.factory, "Farm") or string.match(production.factory, "Ranch") then

            local x = 4 + math.floor(factorySize * 2.5)
            local y = 5 + factorySize * 4

            addFarmingCenters(station, arms, x, y)
        end

        if string.match(production.factory, "Factory")
            or string.match(production.factory, "Manufacturer")
            or string.match(production.factory, "Extractor") then

            local x = 4 + math.floor(factorySize * 1.5)
            local y = 5 + factorySize * 2

            addProductionCenters(station, arms, x, y)
        end

        if string.match(production.factory, "Collector") then
            addCollectors(station, arms)
        end

    end

    initializeTrading(bought, sold)
end

function sync(data)
    if onClient() then
        if not data then
            invokeServerFunction("sync")
        else
            maxDuration = data.maxDuration
            maxNumProductions = data.maxNumProductions
            factorySize = data.maxNumProductions - 1
            production = data.production

            InteractionText().text = Dialog.generateStationInteractionText(Entity(), random())

        end
    else
        local data = {}
        data.maxDuration = maxDuration
        data.maxNumProductions = maxNumProductions
        data.factorySize = factorySize
        data.production = production

        invokeClientFunction(Player(callingPlayer), "sync", data)
    end
end

-- this function gets called on creation of the entity the script is attached to, on client only
-- AFTER initialize above
-- create all required UI elements for the client side
function initUI()

    local res = getResolution()
    local size = vec2(950, 650)

    local menu = ScriptUI()
    local window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5));
    menu:registerWindow(window, "Buy/Sell Goods"%_t);

    window.caption = "Factory"%_t
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

    guiInitialized = true

    requestGoods()
end

-- this functions gets called when the indicator of the station is rendered on the client
function renderUIIndicator(px, py, size)

    x = px - size / 2;
    y = py + size / 2;

    local index = 0
    for i, progress in pairs(currentProductions) do
        index = index + 1

        -- outer rect
        dx = x
        dy = y + index * 5

        sx = size + 2
        sy = 4

        drawRect(Rect(dx, dy, sx + dx, sy + dy), ColorRGB(0, 0, 0));

        -- inner rect
        dx = dx + 1
        dy = dy + 1

        sx = sx - 2
        sy = sy - 2

        sx = sx * progress / maxDuration

        drawRect(Rect(dx, dy, sx + dx, sy + dy), ColorRGB(0.66, 0.66, 1.0));
    end

end

-- this function gets called every time the window is shown on the client, ie. when a player presses F and if interactionPossible() returned 1
function onShowWindow()

    if buyTab then
        if #soldGoods == 0 then
            tabbedWindow:deactivateTab(buyTab)
        else
            tabbedWindow:activateTab(buyTab)
        end
    end

    if sellTab then
        if #boughtGoods == 0 then
            tabbedWindow:deactivateTab(sellTab)
        else
            tabbedWindow:activateTab(sellTab)
        end
    end

    requestGoods()

end

-- this function gets called every time the window is closed on the client
--function onCloseWindow()
--
--end

function startProduction()

    table.insert(currentProductions, 0)

    if onServer() then
        broadcastInvokeClientFunction("startProduction")
    end
end

function getUpdateInterval()
    return 1.0
end

-- this function gets called once each frame, on client and server
function update(timeStep)

    local numProductions = 0
    for i, duration in pairs(currentProductions) do
        duration = duration + timeStep

        if duration >= maxDuration then

            -- production finished
            currentProductions[i] = nil

            if onServer() then
                for i, result in pairs(production.results) do
                    increaseGoods(result.name, result.amount)
                end

                for i, garbage in pairs(production.garbages) do
                    increaseGoods(garbage.name, garbage.amount)
                end
            end
        else
            currentProductions[i] = duration

            numProductions = numProductions + 1
        end
    end

end

function updateClient(timeStep)
    if EntityIcon().icon == "" then

        local title = Entity().title

        if string.match(title, "Mine") then
            EntityIcon().icon = "data/textures/icons/pixel/mine.png"
        elseif string.match(title, "Ranch") then
            EntityIcon().icon = "data/textures/icons/pixel/ranch.png"
        elseif string.match(title, "Farm") then
            EntityIcon().icon = "data/textures/icons/pixel/farm.png"
        else
            EntityIcon().icon = "data/textures/icons/pixel/factory.png"
        end
    end
end

---- this function gets called once each frame, on server only
function updateServer(timeStep)

    -- if the result hasn't yet been received, don't produce
    if not production then return end

    -- if not yet fully used, start producing
    local numProductions = tablelength(currentProductions)
    local canProduce = true

    if numProductions >= maxNumProductions then
        canProduce = false
        -- print("can't produce as there are no more slots free for production")
    end

    if math.random() < 0.5 then
        canProduce = false
        -- print("can't produce due to random not producing")
    end

    -- only start if there are actually enough ingredients for producing
    for i, ingredient in pairs(production.ingredients) do
        if ingredient.optional == 0 and getNumGoods(ingredient.name) < ingredient.amount then
            canProduce = false
            -- print("can't produce due to missing ingredients: " .. ingredient.amount .. " " .. ingredient.name .. ", have: " .. getNumGoods(ingredient.name))
            break
        end
    end

    for i, garbage in pairs(production.garbages) do
        local newAmount = getNumGoods(garbage.name) + garbage.amount

        if newAmount > getMaxStock(getGoodSize(garbage.name)) then
            canProduce = false
            -- print("can't produce due to missing room for garbage")
            break
        end
    end

    for _, result in pairs(production.results) do
        local newAmount = getNumGoods(result.name) + result.amount
        if newAmount > getMaxStock(getGoodSize(result.name)) then
            -- print("can't produce due to missing room for result")
            canProduce = false
            break
        end
    end

    if canProduce then
        for i, ingredient in pairs(production.ingredients) do
            decreaseGoods(ingredient.name, ingredient.amount)
        end

        -- print("start production")

        -- start production
        startProduction()
    end

    updateOrganizeGoodsBulletins(timeStep)
    updateDeliveryBulletins(timeStep)
end


---- this function gets called once each frame, on client only
--function updateClient(timeStep)
--
--end

--
---- this function gets called whenever the ui window gets rendered, AFTER the window was rendered (client only)
--function renderUI()
--
--end
