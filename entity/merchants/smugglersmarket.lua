package.path = package.path .. ";data/scripts/lib/?.lua"

require ("tradingmanager")
require ("stringutility")
require ("goods")
require ("randomext")
require("stringutility")

local brandlines = {}
local playerCargos = {}

function interactionPossible(playerIndex, option)
    return true
end

function generateInteractionText()
    local a = {
        "This is a free station, where everybody can mind his own business."%_t,
        "Best wares in the galaxy."%_t,
        "Welcome to the true, free market."%_t,
        "You'll find members for nearly everything on this station, if the coin is right."%_t,
    }
    local b = {
        "What do you want?"%_t,
        "If you get in trouble, it's your own fault."%_t,
        "Don't make any trouble."%_t,
        "I'm sure you'll find what you're looking for."%_t,
        "What's up?"%_t,
    }

    return randomEntry(random(), a) .. " " .. randomEntry(random(), b)
end

function initialize()
    if onClient() and EntityIcon().icon == "" then
        EntityIcon().icon = "data/textures/icons/pixel/crate.png"
    end

    if onClient() then
        InteractionText().text = generateInteractionText()
    end
end

function initUI()

    local res = getResolution()
    local size = vec2(950, 600)

    local menu = ScriptUI()
    window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))

    window.caption = "Smuggler's Market"%_t
    window.showCloseButton = 1
    window.moveable = 1
    menu:registerWindow(window, "Sell Stolen Goods"%_t);

    -- create a tabbed window inside the main window
    tabbedWindow = window:createTabbedWindow(Rect(vec2(10, 10), size - 10))

    -- create unbrand tab
    local brandTab = tabbedWindow:createTab("Unbrand"%_t, "data/textures/icons/domino-mask.png", "Unbrand Stolen Goods"%_t)

    local lister = UIVerticalLister(Rect(tabbedWindow.size), 5, 0)
    local rect = lister:placeCenter(vec2(lister.inner.width, 21))

    local split1, split2 = 640, 720
    local vasplit1 = UIArbitraryVerticalSplitter(rect, 10, 0, split1, split2)
    local vasplit2 = UIArbitraryVerticalSplitter(vasplit1:partition(0), 10, 0, 350, 390, 530)

    brandTab:createLabel(vasplit2:partition(0).lower + vec2(10, 0), "Name"%_t, 15)
    brandTab:createLabel(vasplit2:partition(2).lower + vec2(10, 0), "Price/u"%_t, 15)
    brandTab:createLabel(vasplit2:partition(3).lower + vec2(10, 0), "You"%_t, 15)


    brandlines = {}
    for i = 1, 14 do
        local line = {}
        local rect = lister:placeCenter(vec2(lister.inner.width, 30))

        local vasplit1 = UIArbitraryVerticalSplitter(rect, 10, 0, split1, split2)
        line.frame = brandTab:createFrame(vasplit1:partition(0))

        line.numbers = brandTab:createTextBox(vasplit1:partition(1), "", "")
        line.button = brandTab:createButton(vasplit1:partition(2), "Unbrand"%_t, "onUnbrandClicked")
        line.button.maxTextSize = 16

        local vasplit2 = UIArbitraryVerticalSplitter(vasplit1:partition(0), 10, 0, 350, 390, 530)

        line.name = brandTab:createLabel(vasplit2:partition(0).lower + vec2(10, 6), "Name"%_t, 15)
        line.icon = brandTab:createPicture(vasplit2:partition(1), "")
        line.price = brandTab:createLabel(vasplit2:partition(2).lower + vec2(10, 6), "560.501", 15)
        line.you = brandTab:createLabel(vasplit2:partition(3).lower + vec2(10, 6), "750", 15)

        line.icon.isIcon = 1
        line.numbers.clearOnClick = 1

        line.hide = function(self)
            self.frame:hide()
            self.numbers:hide()
            self.button:hide()
            self.name:hide()
            self.icon:hide()
            self.price:hide()
            self.you:hide()
        end

        line.show = function(show)
            show.frame:show()
            show.numbers:show()
            show.button:show()
            show.name:show()
            show.icon:show()
            show.price:show()
            show.you:show()
        end

        table.insert(brandlines, line)
    end

    -- create sell tab
    local sellTab = tabbedWindow:createTab("Sell"%_t, "data/textures/icons/coins.png", "Sell Stolen Goods"%_t)
    buildSellGui(sellTab)

    guiInitialized = true

    setCrewInteractionThresholds()
end

function setCrewInteractionThresholds()
    if onClient() then
        invokeServerFunction("setCrewInteractionThresholds")
    end

    Entity():invokeFunction("data/scripts/entity/crewboard.lua", "overrideRelationThreshold", -200000)
    Entity():invokeFunction("crewboard.lua", "overrideArmedThreshold", -200000)
end

function onShowWindow()
    local ship = Player().craft

    -- read cargos and sort
    local cargos = {}
    for good, amount in pairs(ship:getCargos()) do
        table.insert(cargos, {good = good, amount = amount})
    end

    function comp(a, b) return a.good.name < b.good.name end
    table.sort (cargos, comp)

    for _, line in pairs(boughtLines) do line:hide(); line.number.text = "0" end
    for _, line in pairs(brandlines) do line:hide(); line.numbers.text = "0" end

    boughtGoods = {}
    local i = 1
    for _, p in pairs(cargos) do
        local good, amount = p.good, p.amount

        if good.stolen then
            -- do sell lines
            local line = boughtLines[i]
            line:show()
            line.icon.picture = good.icon
            line.name.caption = good.displayName
            line.price.caption = round(good.price * 0.25)
            line.size.caption = round(good.size, 2)
            line.you.caption = amount
            line.stock.caption = "   -"

            boughtGoods[i] = good

            -- do unbranding lines
            local line = brandlines[i]

            line:show()
            line.icon.picture = good.icon
            line.name.caption = good.displayName
            line.price.caption = round(good.price * 0.5)
            line.you.caption = amount

            i = i + 1
        end
    end
end

function onUnbrandClicked(button)
    for i, line in pairs(brandlines) do
        if line.button.index == button.index then
            invokeServerFunction("unbrand", boughtGoods[i].name, tonumber(line.numbers.text))
        end
    end
end

function unbrand(goodName, amount)
    local player = Player(callingPlayer)
    local ship = player.craft
    local station = Entity()

    local cargos = ship:findCargos(goodName)
    local good = nil
    for g, cargoAmount in pairs(cargos) do
        if g.stolen then
            good = g
            amount = math.min(cargoAmount, amount)
            break
        end
    end

    if not good then
        sendError(player, "You don't have any stolen %s!"%_t, goodName)
        return
    end

    local price = amount * round(good.price * 0.5)

    local canPay, msg, args = player:canPay(price)
    if not canPay then
        sendError(player, msg, unpack(args))
        return
    end

    if not station:isDocked(ship) then
        sendError(player, "You have to be docked to the station to unbrand goods!"%_t)
        return
    end

    -- pay and exchange
    player:pay(price)

    local purified = copy(good)
    purified.stolen = false

    ship:removeCargo(good, amount)
    ship:addCargo(purified, amount)

    invokeClientFunction(Player(callingPlayer), "onShowWindow")
end

function receiveGoods()
    onShowWindow()
end

function isBoughtBySelf(good)
    local perfect = goods[good.name]
    if not perfect then
        return false, "You can't sell ${displayPlural} here."%_t % good
    end

    return true
end

oldBuyFromShip = buyFromShip
function buyFromShip(...)
    oldBuyFromShip(...)
    invokeClientFunction(Player(callingPlayer), "onShowWindow")
end

-- price for which goods are bought from players
function getBuyPrice(goodName)
    local good = goods[goodName]
    if not good then return 0 end

    return round(good.price * 0.15)
end

--function onSellTextEntered()
--
--end

