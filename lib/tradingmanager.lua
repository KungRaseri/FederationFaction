
package.path = package.path .. ";data/scripts/lib/?.lua"
require ("galaxy")
require ("utility")
require ("goods")
require ("stringutility")
require ("player")

buyPriceFactor = 1
sellPriceFactor = 1

boughtGoods = {}
soldGoods = {}

numSold = 0
numBought = 0

policies =
{
    sellsIllegal = false,
    buysIllegal = false,

    sellsStolen = false,
    buysStolen = false,

    sellsSuspicious = false,
    buysSuspicious = false,
}

-- UI
boughtLines = {}

soldLines = {}

guiInitialized = false

--
useTimeCounter = 0 -- time counter for using up bought products

-- help functions
function isSoldBySelf(good)
    if good.illegal and not policies.sellsIllegal then
        local msg = "This station doesn't sell illegal goods."%_t
        return false, msg
    end

    if good.stolen and not policies.sellsStolen then
        local msg = "This station doesn't sell stolen goods."%_t
        return false, msg
    end

    if good.suspicious and not policies.sellsSuspicious then
        local msg = "This station doesn't sell suspicious goods."%_t
        return false, msg
    end

    return true
end

function isBoughtBySelf(good)
    if good.illegal and not policies.buysIllegal then
        local msg = "This station doesn't buy illegal goods."%_t
        return false, msg
    end

    if good.stolen and not policies.buysStolen then
        local msg = "This station doesn't buy stolen goods."%_t
        return false, msg
    end

    if good.suspicious and not policies.buysSuspicious then
        local msg = "This station doesn't buy suspicious goods."%_t
        return false, msg
    end

    return true
end

function generateGoods(min, max)
    min = min or 10
    max = max or 15

    numGoods = math.random(min, max)

    local bought = {}
    local sold = {}
    local existingGoods = {}

    local maxNumGoods = tablelength(goodsArray)

    for i = 1, numGoods do
        local index = math.random(1, maxNumGoods)
        local g = goodsArray[index]
        local good = g:good()

        -- don't trade potentially illegal goods
        if isBoughtBySelf(good) then

            if existingGoods[good.name] == nil then

                good.size = round(good.size, 2)
                good.price = round(good.price)
                table.insert(bought, good)
                existingGoods[good.name] = 1
            end

        end
    end

    for i = 1, numGoods do
        local index = math.random(1, maxNumGoods)
        local g = goodsArray[index]
        local good = g:good()

        -- don't trade potentially illegal goods
        if isSoldBySelf(good.name) then

            if existingGoods[good.name] == nil then
                good.size = round(good.size, 2)
                good.price = round(good.price)

                table.insert(sold, good)
                existingGoods[good.name] = 1
            end
        end
    end

    return bought, sold
end

function restoreTradingGoods(data)
    buyPriceFactor = data.buyPriceFactor
    sellPriceFactor = data.sellPriceFactor
    policies = data.policies

    boughtGoods = {}
    for _, g in pairs(data.boughtGoods) do
        table.insert(boughtGoods, tableToGood(g))
    end

    soldGoods = {}
    for _, g in pairs(data.soldGoods) do
        table.insert(soldGoods, tableToGood(g))
    end

    numBought = #boughtGoods
    numSold = #soldGoods
end

function secureTradingGoods()
    local data = {}
    data.buyPriceFactor = buyPriceFactor
    data.sellPriceFactor = sellPriceFactor
    data.policies = policies

    data.boughtGoods = {}
    for _, g in pairs(boughtGoods) do
        table.insert(data.boughtGoods, goodToTable(g))
    end

    data.soldGoods = {}
    for _, g in pairs(soldGoods) do
        table.insert(data.soldGoods, goodToTable(g))
    end

    return data
end

function initializeTrading(boughtGoodsIn, soldGoodsIn, policiesIn)

    local self = Entity()

    policies = policiesIn or policies

    -- generate goods only once, this adds physical goods to the entity
    local generated = self:getValue("goods_generated")
    if not generated or generated ~= 1 then
        self:setValue("goods_generated", 1)
        generated = false
    else
        generated = true
    end

    boughtGoodsIn = boughtGoodsIn or {}
    soldGoodsIn = soldGoodsIn or {}

    numBought = #boughtGoodsIn
    numSold = #soldGoodsIn

    boughtGoods = {}

    for i, v in ipairs(boughtGoodsIn) do
        if not generated then
            local maxStock = getMaxStock(v.size)
            if maxStock > 0 then

                -- generate a random amount of things
                local amount = math.random(1, maxStock)
                if math.random() < 0.65 then -- what they buy is most likely not available
                    amount = 0
                end

                self:addCargo(v, amount)
            end
        end

        table.insert(boughtGoods, v)
    end

    soldGoods = {}

    for i, v in ipairs(soldGoodsIn) do
        if not generated then
            local maxStock = getMaxStock(v.size)
            if maxStock > 0 then

                -- generate a random amount of things
                local amount = math.random(1, maxStock)
                if math.random() < 0.35 then -- what they sell is most likely available
                    amount = 0
                end

                self:addCargo(v, amount)
            end
        end

        table.insert(soldGoods, v)
    end

    numBought = #boughtGoods
    numSold = #soldGoods

end

function requestGoods()
    boughtGoods = {}
    soldGoods = {}

    numBought = 0
    numSold = 0

    invokeServerFunction("sendGoods", Player().index)
end

function sendGoods(playerIndex)

    local player = Player(playerIndex)

    invokeClientFunction(player, "receiveGoods", buyPriceFactor, sellPriceFactor, boughtGoods, soldGoods, policies)
end

function receiveGoods(buyFactor, sellFactor, boughtGoods_in, soldGoods_in, policies_in)
    buyPriceFactor = buyFactor
    sellPriceFactor = sellFactor

    policies = policies_in

    boughtGoods = boughtGoods_in
    soldGoods = soldGoods_in

    numBought = #boughtGoods
    numSold = #soldGoods

    for i, good in ipairs(boughtGoods) do
        updateBoughtGoodGui(i, good, getBuyPrice(good.name, Player().index))
    end

    for i, good in ipairs(soldGoods) do
        updateSoldGoodGui(i, good, getSellPrice(good.name, Player().index))
    end

end

function updateBoughtGoodGui(index, good, price)

    if not guiInitialized then return end

    local maxAmount = getMaxStock(good.size)
    local amount = getNumGoods(good.name)

    line = boughtLines[index]

    line.name.caption = good.displayName
    line.stock.caption = amount .. "/" .. maxAmount
    line.price.caption = createMonetaryString(price)
    line.size.caption = round(good.size, 2)
    line.icon.picture = good.icon

    local ownCargo = 0
    local ship = Entity(Player().craftIndex)
    if ship then
        ownCargo = ship:getCargoAmount(good) or 0
    end
    if ownCargo == 0 then ownCargo = "-" end
    line.you.caption = tostring(ownCargo)

    line:show()
end

function updateSoldGoodGui(index, good, price)

    if not guiInitialized then return end

    local maxAmount = getMaxStock(good.size)
    local amount = getNumGoods(good.name)

    line = soldLines[index]

    line.icon.picture = good.icon
    line.name.caption = good.displayName
    line.stock.caption = amount .. "/" .. maxAmount
    line.price.caption = createMonetaryString(price)
    line.size.caption = round(good.size, 2)

    for i, good in pairs(soldGoods) do
        local line = soldLines[i]

        local ownCargo = 0
        local ship = Entity(Player().craftIndex)
        if ship then
            ownCargo = math.floor((ship.freeCargoSpace or 0) / good.size)
        end

        if ownCargo == 0 then ownCargo = "-" end
        line.you.caption = tostring(ownCargo)
    end

    line:show()

end

function updateBoughtGoodAmount(index)

    local good = boughtGoods[index];

    if good ~= nil then -- it's possible that the production may start before the initialization of the client version of the factory
        updateBoughtGoodGui(index, good, getBuyPrice(good.name, Player().index))
    end

end

function updateSoldGoodAmount(index)

    local good = soldGoods[index];

    if good ~= nil then -- it's possible that the production may start before the initialization of the client version of the factory
        updateSoldGoodGui(index, good, getSellPrice(good.name, Player().index))
    end
end

function buildBuyGui(window)
    buildGui(window, 1)
end

function buildSellGui(window)
    buildGui(window, 0)
end

function buildGui(window, guiType)

    local buttonCaption = ""
    local buttonCallback = ""
    local textCallback = ""

    if guiType == 1 then
        buttonCaption = "Buy"%_t
        buttonCallback = "onBuyButtonPressed"
        textCallback = "onBuyTextEntered"
    else
        buttonCaption = "Sell"%_t
        buttonCallback = "onSellButtonPressed"
        textCallback = "onSellTextEntered"
    end

    local size = window.size

--    window:createFrame(Rect(size))

    local pictureX = 270
    local nameX = 10
    local stockX = 310
    local volX = 460
    local priceX = 530
    local youX = 630
    local textBoxX = 720
    local buttonX = 790

    local buttonSize = 70

    -- header
    window:createLabel(vec2(nameX, 0), "Name"%_t, 15)
    window:createLabel(vec2(stockX, 0), "Stock"%_t, 15)
    window:createLabel(vec2(priceX, 0), "Cr"%_t, 15)
    window:createLabel(vec2(volX, 0), "Vol"%_t, 15)

    if guiType == 1 then
        window:createLabel(vec2(youX, 0), "Max"%_t, 15)
    else
        window:createLabel(vec2(youX, 0), "You"%_t, 15)
    end

    local y = 25
    for i = 1, 15 do

        local yText = y + 6

        local frame = window:createFrame(Rect(0, y, textBoxX - 10, 30 + y))

        local icon = window:createPicture(Rect(pictureX, yText - 5, 29 + pictureX, 29 + yText - 5), "")
        local nameLabel = window:createLabel(vec2(nameX, yText), "", 15)
        local stockLabel = window:createLabel(vec2(stockX, yText), "", 15)
        local priceLabel = window:createLabel(vec2(priceX, yText), "", 15)
        local sizeLabel = window:createLabel(vec2(volX, yText), "", 15)
        local youLabel = window:createLabel(vec2(youX, yText), "", 15)
        local numberTextBox = window:createTextBox(Rect(textBoxX, yText - 6, 60 + textBoxX, 30 + yText - 6), textCallback)
        local button = window:createButton(Rect(buttonX, yText - 6, window.size.x, 30 + yText - 6), buttonCaption, buttonCallback)

        button.maxTextSize = 16

        numberTextBox.text = "0"
        numberTextBox.allowedCharacters = "0123456789"
        numberTextBox.clearOnClick = 1

        icon.isIcon = 1

        local show = function (self)
            self.icon:show()
            self.frame:show()
            self.name:show()
            self.stock:show()
            self.price:show()
            self.size:show()
            self.number:show()
            self.button:show()
            self.you:show()
        end
        local hide = function (self)
            self.icon:hide()
            self.frame:hide()
            self.name:hide()
            self.stock:hide()
            self.price:hide()
            self.size:hide()
            self.number:hide()
            self.button:hide()
            self.you:hide()
        end

        local line = {icon = icon, frame = frame, name = nameLabel, stock = stockLabel, price = priceLabel, you = youLabel, size = sizeLabel, number = numberTextBox, button = button, show = show, hide = hide}
        line:hide()

        if guiType == 1 then
            table.insert(soldLines, line)
        else
            table.insert(boughtLines, line)
        end

        y = y + 35
    end

end

function onBuyTextEntered(textBox)

    local enteredNumber = tonumber(textBox.text)
    if enteredNumber == nil then
        enteredNumber = 0
    end

    local newNumber = enteredNumber

    local goodIndex = nil
    for i, line in pairs(soldLines) do
        if line.number.index == textBox.index then
            goodIndex = i
            break
        end
    end

    if goodIndex == nil then return end

    local good = soldGoods[goodIndex]

    if not good then
        print ("good with index " .. goodIndex .. " isn't sold.")
        printEntityDebugInfo()
        return
    end

    -- make sure the player can't buy more than the station has in stock
    local stock = getNumGoods(good.name)

    if stock < newNumber then
        newNumber = stock
    end

    local ship = Player().craft
    if ship.freeCargoSpace == nil then return end --> no cargo bay

    -- make sure the player does not buy more than he can have in his cargo bay
    local maxShipHold = math.floor(ship.freeCargoSpace / good.size)
    local msg

    if maxShipHold < newNumber then
        newNumber = maxShipHold
        if newNumber == 0 then
            msg = "Not enough space in your cargo bay!"%_t
        else
            msg = "You can only store ${amount} of this good!"%_t % {amount = newNumber}
        end
    end

    -- make sure the player does not buy more than he can afford (if this isn't his station)
    if Faction().index ~= Player().index then
        local maxAffordable = math.floor(Player().money / getSellPrice(good.name, Player().index))
        if Player().infiniteResources then maxAffordable = math.huge end

        if maxAffordable < newNumber then
            newNumber = maxAffordable

            if newNumber == 0 then
                msg = "You can't afford any of this good!"%_t
            else
                msg = "You can only afford ${amount} of this good!"%_t % {amount = newNumber}
            end
        end
    end

    if msg then
        sendError(nil, msg)
    end

    if newNumber ~= enteredNumber then
        textBox.text = newNumber
    end
end

function onSellTextEntered(textBox)

    local enteredNumber = tonumber(textBox.text)
    if enteredNumber == nil then
        enteredNumber = 0
    end

    local newNumber = enteredNumber

    local goodIndex = nil
    for i, line in pairs(boughtLines) do
        if line.number.index == textBox.index then
            goodIndex = i
            break
        end
    end
    if goodIndex == nil then return end

    local good = boughtGoods[goodIndex]
    if not good then
        print ("good with index " .. goodIndex .. " isn't bought")
        printEntityDebugInfo();
        return
    end

    local stock = getNumGoods(good.name)

    local maxAmountPlaceable = getMaxStock(good.size) - stock;
    if maxAmountPlaceable < newNumber then
        newNumber = maxAmountPlaceable
    end


    local ship = Player().craft

    local msg

    -- make sure the player does not sell more than he has in his cargo bay
    local amountOnPlayerShip = ship:getCargoAmount(good)
    if amountOnPlayerShip == nil then return end --> no cargo bay

    if amountOnPlayerShip < newNumber then
        newNumber = amountOnPlayerShip
        if newNumber == 0 then
            msg = "You don't have any of this!"%_t
        end
    end

    if msg then
        sendError(nil, msg)
    end

    -- maximum number of sellable things is the amount the player has on his ship
    if newNumber ~= enteredNumber then
        textBox.text = newNumber
    end
end

function onBuyButtonPressed(button)

    local shipIndex = Player().craftIndex
    local goodIndex = nil

    for i, line in ipairs(soldLines) do
        if line.button.index == button.index then
            goodIndex = i
        end
    end

    if goodIndex == nil then
        print("internal error, good matching 'Buy' button doesn't exist.")
        return
    end

    local amount = soldLines[goodIndex].number.text
    if amount == "" then
        amount = 0
    else
        amount = tonumber(amount)
    end

    local good = soldGoods[goodIndex]
    if not good then
        print ("internal error, good with index " .. goodIndex .. " of buy button not found.")
        printEntityDebugInfo()
        return
    end

    invokeServerFunction("sellToShip", shipIndex, good.name, amount)
end

function onSellButtonPressed(button)

    local shipIndex = Player().craftIndex
    local goodIndex = nil

    for i, line in ipairs(boughtLines) do
        if line.button.index == button.index then
            goodIndex = i
        end
    end

    if goodIndex == nil then
        return
    end

    local amount = boughtLines[goodIndex].number.text
    if amount == "" then
        amount = 0
    else
        amount = tonumber(amount)
    end

    local good = boughtGoods[goodIndex]
    if not good then
        print ("internal error, good with index " .. goodIndex .. " of sell button not found.")
        printEntityDebugInfo()
        return
    end

    invokeServerFunction("buyFromShip", shipIndex, good.name, amount)

end

function sendError(faction, msg, ...)
    if onServer() then
        if faction.isPlayer then
            Player(faction.index):sendChatMessage(Entity().title, 1, msg, ...)
        end
    elseif onClient() then
        displayChatMessage(msg, Entity().title, 1)
    end
end

function buyFromShip(shipIndex, goodName, amount, noDockCheck)

    -- check if the good can be bought
    if not getBoughtGoodByName(goodName) == nil then
        sendError(shipFaction, "%s isn't bought."%_t, goodName)
        return
    end

    local ship = Entity(shipIndex)
    local shipFaction = Faction(ship.factionIndex)
    if ship.freeCargoSpace == nil then
        sendError(shipFaction, "Your ship has no cargo bay!"%_t)
        return
    end

    -- check if the specific good from the player can be bought (ie. it's not illegal or something like that)
    local cargos = ship:findCargos(goodName)
    local good = nil
    local msg = "You don't have any %s that the station buys!"%_t
    local args = {goodName}

    for g, amount in pairs(cargos) do
        local ok
        ok, msg = isBoughtBySelf(g)
        args = {}
        if ok then
            good = g
            break
        end
    end

    if not good then
        sendError(shipFaction, msg, unpack(args))
        return
    end

    local station = Entity()
    local stationFaction = Faction()

    -- make sure the ship can not sell more than the station can have in stock
    local maxAmountPlaceable = getMaxStock(good.size) - getNumGoods(good.name);

    if maxAmountPlaceable < amount then
        amount = maxAmountPlaceable

        if maxAmountPlaceable == 0 then
            sendError(shipFaction, "This station is not able to take any more %s."%_t, good.plural)
        end
    end

    -- make sure the player does not sell more than he has in his cargo bay
    local amountOnShip = ship:getCargoAmount(good)

    if amountOnShip < amount then
        amount = amountOnShip

        if amountOnShip == 0 then
            sendError(shipFaction, "You don't have any %s on your ship"%_t, good.plural)
        end
    end

    if amount == 0 then
        return
    end

    -- begin transaction
    -- calculate price. if the seller is the owner of the station, the price is 0
    local price = getBuyPrice(good.name, shipFaction.index) * amount

    local canPay, msg, args = stationFaction:canPay(price);
    if not canPay then
        sendError(shipFaction, "This station's faction doesn't have enough money."%_t)
        return
    end

    if not noDockCheck then
        -- test the docking last so the player can know what he can buy from afar already
        local errors = {}
        errors[EntityType.Station] = "You must be docked to the station to trade."%_T
        errors[EntityType.Ship] = "You must be closer to the ship to trade."%_T
        if not CheckShipDocked(shipFaction, ship, station, errors) then
            return
        end
    end

    -- give money to ship faction
    shipFaction:receive(price)
    stationFaction:pay(price)

    -- remove goods from ship
    ship:removeCargo(good, amount)

    -- add goods to station
    increaseGoods(good.name, amount)

    -- trading (non-military) ships get double the relation gain
    local relationsChange = GetRelationChangeFromMoney(price)
    if ship:getNumArmedTurrets() <= 1 then
        relationsChange = relationsChange * 2
    end

    Galaxy():changeFactionRelations(shipFaction, stationFaction, relationsChange)

end

function sellToShip(shipIndex, goodName, amount, noDockCheck)

    local good = getSoldGoodByName(goodName)
    if good == nil then return end

    local ship = Entity(shipIndex)
    local shipFaction = Faction(ship.factionIndex)
    if ship.freeCargoSpace == nil then
        sendError(shipFaction, "Your ship has no cargo bay!"%_t)
        return
    end

    local station = Entity()
    local stationFaction = Faction()

    -- make sure the player can not buy more than the station has in stock
    local amountBuyable = getNumGoods(goodName)

    if amountBuyable < amount then
        amount = amountBuyable

        if amountBuyable == 0 then
             sendError(shipFaction, "This station has no more %s to sell."%_t, good.plural)
        end
    end

    -- make sure the player does not buy more than he can have in his cargo bay
    local maxShipHold = math.floor(ship.freeCargoSpace / good.size)

    if maxShipHold < amount then
        amount = maxShipHold

        if maxShipHold == 0 then
            sendError(shipFaction, "Your ship can not take more %s."%_t, good.plural)
        end
    end

    if amount == 0 then
        return
    end

    -- begin transaction
    -- calculate price. if the owner of the station wants to buy, the price is 0
    local price = getSellPrice(good.name, shipFaction.index) * amount

    local canPay, msg, args = shipFaction:canPay(price);
    if not canPay then
        sendError(shipFaction, msg, unpack(args))
        return
    end

    if not noDockCheck then
        -- test the docking last so the player can know what he can buy from afar already
        local errors = {}
        errors[EntityType.Station] = "You must be docked to the station to trade."%_T
        errors[EntityType.Ship] = "You must be closer to the ship to trade."%_T
        if not CheckShipDocked(shipFaction, ship, station, errors) then
            return
        end
    end

    -- make player pay
    shipFaction:pay(price)
    stationFaction:receive(price)

    -- give goods to player
    ship:addCargo(good, amount)

    -- remove goods from station
    decreaseGoods(good.name, amount)

    -- trading (non-military) ships get double the relation gain
    local relationsChange = GetRelationChangeFromMoney(price)
    if ship:getNumArmedTurrets() <= 1 then
        relationsChange = relationsChange * 2
    end

    Galaxy():changeFactionRelations(shipFaction, stationFaction, relationsChange)

end

function increaseGoods(name, delta)

    local self = Entity()

    for i, good in pairs(soldGoods) do
        if good.name == name then
            -- increase
            local current = self:getCargoAmount(good)
            delta = math.min(delta, getMaxStock(good.size) - current)

            self:addCargo(good, delta)

            broadcastInvokeClientFunction("updateSoldGoodAmount", i)
        end
    end

    for i, good in pairs(boughtGoods) do
        if good.name == name then
            -- increase
            local current = self:getCargoAmount(good)
            delta = math.min(delta, getMaxStock(good.size) - current)

            self:addCargo(good, delta)

            broadcastInvokeClientFunction("updateBoughtGoodAmount", i)
        end
    end

end

function decreaseGoods(name, amount)

    local self = Entity()

    for i, good in pairs(soldGoods) do
        if good.name == name then
            self:removeCargo(good, amount)

            broadcastInvokeClientFunction("updateSoldGoodAmount", i)
        end
    end

    for i, good in pairs(boughtGoods) do
        if good.name == name then
            self:removeCargo(good, amount)

            broadcastInvokeClientFunction("updateBoughtGoodAmount", i)
        end
    end

end

function useUpBoughtGoods(timeStep)

    useTimeCounter = useTimeCounter + timeStep

    if useTimeCounter > 5 then
        useTimeCounter = 0

        if math.random () < 0.5 then

            local amount = math.random(3, 6)
            local good = boughtGoods[math.random(1, #boughtGoods)]

            if good ~= nil then
                decreaseGoods(good.name, amount)
            end
        end
    end

end

function getBoughtGoods()
    local result = {}

    for i, good in pairs(boughtGoods) do
        table.insert(result, good.name)
    end

    return unpack(result)
end

function getSoldGoods()
    local result = {}

    for i, good in pairs(soldGoods) do
        table.insert(result, good.name)
    end

    return unpack(result)
end

function getStock(name)
    return getNumGoods(name), getMaxGoods(name)
end

function getNumGoods(name)
    local self = Entity()

    local good = goods[name]:good()
    if not good then return 0 end

    return self:getCargoAmount(good)
end

function getMaxGoods(name)
    local amount = 0

    for i, good in pairs(soldGoods) do
        if good.name == name then
            return getMaxStock(good.size)
        end
    end

    for i, good in pairs(boughtGoods) do
        if good.name == name then
            return getMaxStock(good.size)
        end
    end

    return amount
end

function getGoodSize(name)

    for i, good in pairs(soldGoods) do
        if good.name == name then
            return good.size
        end
    end

    for i, good in pairs(boughtGoods) do
        if good.name == name then
            return good.size
        end
    end

    print ("error: " .. name .. " is neither bought nor sold")
end

function getMaxStock(goodSize)

    local self = Entity()

    local space = self.maxCargoSpace
    local slots = numBought + numSold

    if slots > 0 then space = space / slots end

    if space / goodSize > 100 then
        -- round to 100
        return math.min(25000, round(space / goodSize / 100) * 100)
    else
        -- not very much space already, don't round
        return math.floor(space / goodSize)
    end
end

function getBoughtGoodByName(name)
    for _, good in pairs(boughtGoods) do
        if good.name == name then
            return good
        end
    end
end

function getSoldGoodByName(name)
    for _, good in pairs(soldGoods) do
        if good.name == name then
            return good
        end
    end
end

function getGoodByName(name)
    for _, good in pairs(boughtGoods) do
        if good.name == name then
            return good
        end
    end

    for _, good in pairs(soldGoods) do
        if good.name == name then
            return good
        end
    end
end

-- price for which goods are bought by this from others
function getBuyPrice(goodName, sellingFaction)

    local good = getBoughtGoodByName(goodName)

    -- empty stock -> higher price
    local factor = getNumGoods(goodName) / getMaxStock(good.size) -- 0 to 1 where 1 is 'full stock'
    factor = 1 - factor -- 1 to 0 where 0 is 'full stock'
    factor = factor * 0.4 -- 0.4 to 0
    factor = factor + 0.8 -- 1.2 to 0.8; 'no goods' to 'full'

    local relationFactor = 1
    if sellingFaction then
        local sellerIndex = nil
        if type(sellingFaction) == "number" then
            sellerIndex = sellingFaction
        else
            sellerIndex = sellingFaction.index
        end

        if sellerIndex then
            local relations = Faction():getRelations(sellerIndex)

            if relations < -10000 then
                -- bad relations: faction pays less for the goods
                -- 10% to 100% from -100.000 to -10.000
                relationFactor = lerp(relations, -100000, -10000, 0.1, 1.0)
            elseif relations >= 50000 then
                -- very good relations: factions pays MORE for the goods
                -- 100% to 120% from 80.000 to 100.000
                relationFactor = lerp(relations, 80000, 100000, 1.0, 1.15)
            end

            if Faction().index == sellerIndex then relationFactor = 0 end
        end
    end

    return round(good.price * relationFactor * factor * buyPriceFactor)
end

-- price for which goods are sold from this to others
function getSellPrice(goodName, buyingFaction)

    local good = getSoldGoodByName(goodName)

    -- empty stock -> higher price
    local factor = getNumGoods(goodName) / getMaxStock(good.size) -- 0 to 1 where 1 is 'full stock'
    factor = 1 - factor -- 1 to 0 where 0 is 'full stock'
    factor = factor * 0.4 -- 0.4 to 0
    factor = factor + 0.8 -- 1.2 to 0.8; 'no goods' to 'full'


    local relationFactor = 1
    if buyingFaction then
        local sellerIndex = nil
        if type(buyingFaction) == "number" then
            sellerIndex = buyingFaction
        else
            sellerIndex = buyingFaction.index
        end

        if sellerIndex then
            local relations = Faction():getRelations(sellerIndex)

            if relations < -10000 then
                -- bad relations: faction wants more for the goods
                -- 200% to 100% from -100.000 to -10.000
                relationFactor = lerp(relations, -100000, -10000, 2.0, 1.0)
            elseif relations > 30000 then
                -- good relations: factions start giving player better prices
                -- 100% to 80% from 30.000 to 90.000
                relationFactor = lerp(relations, 30000, 90000, 1.0, 0.8)
            end

            if Faction().index == sellerIndex then relationFactor = 0 end
        end

    end

    return round(good.price * relationFactor * factor * sellPriceFactor)
end


local r = Random(Seed(os.time()))

local organizeUpdateFrequency
local organizeUpdateTime

local organizeDescription = [[
Organize ${amount} ${good.displayPlural} in 30 Minutes.

You will be paid the double of the usual price, plus a bonus.

Time Limit: 30 minutes
Reward: $${reward}
]]%_t

function updateOrganizeGoodsBulletins(timeStep)

    if not organizeUpdateFrequency then
        -- more frequent updates when there are more ingredients
        organizeUpdateFrequency = math.max(60 * 8, 60 * 60 - (#boughtGoods * 7.5 * 60))
    end

    if not organizeUpdateTime then
        -- by adding half the time here, we have a chance that a factory immediately has a bulletin
        organizeUpdateTime = 0

        local minutesSimulated = r:getInt(10, 80)
        for i = 1, minutesSimulated do -- simulate bulletin posting / removing
            updateOrganizeGoodsBulletins(60)
        end
    end

    organizeUpdateTime = organizeUpdateTime + timeStep

    -- don't execute the following code if the time hasn't exceeded the posting frequency
    if organizeUpdateTime < organizeUpdateFrequency then return end
    organizeUpdateTime = organizeUpdateTime - organizeUpdateFrequency

    -- choose a random ingredient
    local good = boughtGoods[r:getInt(1, #boughtGoods)]
    if not good then return end

    local cargoVolume = 50 + r:getFloat(0, 200)
    local amount = math.min(math.floor(100 / good.size), 150)
    local reward = good.price * amount * 2.0 + 20000
    local x, y = Sector():getCoordinates()

    local bulletin =
    {
        brief = "Resource Shortage: ${amount} ${good.displayPlural}"%_T,
        description = organizeDescription,
        difficulty = "Easy"%_T,
        reward = string.format("$${reward}"%_T, createMonetaryString(reward)),
        script = "missions/organizegoods.lua",
        arguments = {good.name, amount, Entity().index, x, y, reward},
        formatArguments = {amount = amount, good = good, reward = createMonetaryString(reward)}
    }

    -- since in this case "add" can override "remove", adding a bulletin is slightly more probable
    local add = r:getFloat() < 0.5
    local remove = r:getFloat() < 0.5

    if not add and not remove then
        if r:getFloat() < 0.5 then
            add = true
        else
            remove = true
        end
    end

    if add then
        -- randomly add bulletins
        Entity():invokeFunction("bulletinboard", "postBulletin", bulletin)
    elseif remove then
        -- randomly remove bulletins
        Entity():invokeFunction("bulletinboard", "removeBulletin", bulletin.brief)
    end

end


local deliveryDescription = [[
Deliver ${amount} ${good.displayPlural} to a station near this location in 20 minutes.

You will have to make a deposit of $${deposit},
which will be reimbursed when the goods are delivered.

Deposit: $${deposit}
Time Limit: 20 minutes
Reward: $${reward}
]]%_t

local deliveryUpdateFrequency
local deliveryUpdateTime

function updateDeliveryBulletins(timeStep)

    if not deliveryUpdateFrequency then
        -- more frequent updates when there are more ingredients
        deliveryUpdateFrequency = math.max(60 * 8, 60 * 60 - (#soldGoods * 7.5 * 60))
    end

    if not deliveryUpdateTime then
        -- by adding half the time here, we have a chance that a factory immediately has a bulletin
        deliveryUpdateTime = 0

        local minutesSimulated = r:getInt(10, 80)
        for i = 1, minutesSimulated do -- simulate 1 hour of bulletin posting / removing
            updateDeliveryBulletins(60)
        end
    end

    deliveryUpdateTime = deliveryUpdateTime + timeStep

    -- don't execute the following code if the time hasn't exceeded the posting frequency
    if deliveryUpdateTime < deliveryUpdateFrequency then return end
    deliveryUpdateTime = deliveryUpdateTime - deliveryUpdateFrequency

    -- choose a sold good
    local good = soldGoods[r:getInt(1, #soldGoods)]
    if not good then return end

    local cargoVolume = 50 + r:getFloat(0, 200)
    local amount = math.min(math.floor(cargoVolume / good.size), 150)
    local reward = good.price * amount
    local x, y = Sector():getCoordinates()

    -- add a maximum of earnable money
    local maxEarnable = 20000 * Balancing_GetSectorRichnessFactor(x, y)
    if reward > maxEarnable then
        amount = math.floor(maxEarnable / good.price)
        reward = good.price * amount
    end

    if amount == 0 then return end

    reward = reward * 0.5 + 5000
    local deposit = math.floor(good.price * amount * 0.75 / 100) * 100
    local reward = math.floor(reward / 100) * 100

    -- todo: localization of entity titles
    local bulletin =
    {
        brief = "Delivery: ${good.displayPlural}"%_T,
        description = deliveryDescription,
        difficulty = "Easy"%_T,
        reward = string.format("$%s", createMonetaryString(reward)),
        formatArguments = {good = good, amount = amount, deposit = createMonetaryString(deposit), reward = createMonetaryString(reward)},

        script = "missions/delivery.lua",
        arguments = {good.name, amount, Entity().index, deposit + reward},

        checkAccept = [[
            local self, player = ...
            local ship = Entity(player.craftIndex)
            local space = ship.freeCargoSpace or 0
            if space < self.good.size * self.amount then
                player:sendChatMessage(self.sender, 1, self.msgCargo)
                return 0
            end
            if not Entity():isDocked(ship) then
                player:sendChatMessage(self.sender, 1, self.msgDock)
                return 0
            end
            local canPay = player:canPay(self.deposit)
            if not canPay then
                player:sendChatMessage(self.sender, 1, self.msgMoney)
                return 0
            end
            return 1
            ]],
        onAccept = [[
            local self, player = ...
            player:pay(self.deposit)
            local ship = Entity(player.craftIndex)
            ship:addCargo(goods[self.good.name]:good(), self.amount)
            ]],

        cargoVolume = cargoVolume,
        amount = amount,
        good = good,
        deposit = deposit,
        sender = "Client"%_T,
        msgCargo = "Not enough cargo space on your ship."%_T,
        msgDock = "You have to be docked to the station."%_T,
        msgMoney = "You don't have enough money for the deposit."%_T
    }

    -- since in this case "add" can override "remove", adding a bulletin is slightly more probable
    local add = r:getFloat() < 0.5
    local remove = r:getFloat() < 0.5

    if not add and not remove then
        if r:getFloat() < 0.5 then
            add = true
        else
            remove = true
        end
    end

    if add then
        -- randomly add bulletins
        Entity():invokeFunction("bulletinboard", "postBulletin", bulletin)
    elseif remove then
        -- randomly remove bulletins
        Entity():invokeFunction("bulletinboard", "removeBulletin", bulletin.brief)
    end

end

