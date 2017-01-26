package.path = package.path .. ";data/scripts/lib/?.lua"
require ("galaxy")
require ("utility")
require ("faction")
require ("stationextensions")
require ("randomext")
require("stringutility")
Dialog = require("dialogutility")

local window = 0
local planDisplayer = 0
local repairButton = 0

local original
local colored
local visible = false

local planShowCounter = 0

local uiMoneyCost
local uiResourceCost

if onClient() then
    original = BlockPlan()
    colored = BlockPlan()
end

-- if this function returns false, the script will not be listed in the interaction window on the client,
-- even though its UI may be registered
function interactionPossible(playerIndex, option)
    if Player(playerIndex).craft.type == EntityType.Drone then
        return false, "We don't do drones."%_t
    end

    return CheckFactionInteraction(playerIndex, -25000)
end

-- this function gets called on creation of the entity the script is attached to, on client and server
function initialize()
    local station = Entity()

    if station.title == "" then
        station.title = "Repair Dock /* Station Title*/"%_t

        if onServer() then
            local x, y = Sector():getCoordinates()
            local seed = Server().seed

            math.randomseed(makeHash(station.index, x, y, seed.value))
            addConstructionScaffold(station)
            math.randomseed(os.time())
        end
    end

    if onClient() and EntityIcon().icon == "" then
        EntityIcon().icon = "data/textures/icons/pixel/repair.png"
        InteractionText(station.index).text = Dialog.generateStationInteractionText(station, random())
    end
end

-- this function gets called on creation of the entity the script is attached to, on client only
-- AFTER initialize above
-- create all required UI elements for the client side
function initUI()

    local res = getResolution()
    local size = vec2(510, 560)

    local menu = ScriptUI()
    window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5));
    menu:registerWindow(window, "Repair Dock /* Station Title*/"%_t);

    window.caption = "Repair Dock /* Station Title*/"%_t
    window.showCloseButton = 1
    window.moveable = 1

--    window:createFrame(Rect(10, 10, 490 + 10, 490 + 10));

    -- create the viewer
    planDisplayer = window:createPlanDisplayer(Rect(0, 0, 500, 500));
    planDisplayer.showStats = 0

    -- create the repair button
    repairButton = window:createButton(Rect(10, 510, 490 + 10, 40 + 510), "Repair /* Action */"%_t, "onRepairButtonPressed")

end

---- this functions gets called when the indicator of the station is rendered on the client
--function renderUIIndicator(px, py, size)
--
--end

-- this function gets called every time the window is shown on the client, ie. when a player presses F and if interactionPossible() returned 1
function onShowWindow()
    local player = Player()
    local ship = player.craft

    -- get the plan of the player's ship template
    original = player:getShipPlan(ship.name)
    colored = player:getShipPlan(ship.name)

    -- get the plan of the player's ship
    local actual = ship:getPlan()

    -- check which blocks are missing
    local indices = {original:getBlockIndices()}
    for _, index in pairs(indices) do

        if not actual:exists(index) then
            colored:setBlockColor(index, ColorRGB(1, 1, 0.5))
        end

    end

    -- set to display
    planDisplayer.plan = original
    planDisplayer.autoCenter = 0

    uiMoneyCost = getRepairMoneyCost(player, original, actual, ship.durability / ship.maxDurability)
    uiResourceCost = getRepairResourcesCost(player, original, actual, ship.durability / ship.maxDurability)

    local damaged = false

    if uiMoneyCost > 0 then
        damaged = true
    end

    for _, cost in pairs(uiResourceCost) do
        if cost > 0 then
            damaged = true
        end
    end

    if damaged then
        repairButton.active = true
        repairButton.tooltip = "Repair ship"%_t
    else
        repairButton.active = false
        repairButton.tooltip = "Your ship is not damaged."%_t
    end

    visible = true
end

-- this function gets called every time the window is closed on the client
function onCloseWindow()
    visible = false
end

---- this function gets called once each frame, on client and server
--function update(timeStep)
--
--end

function getUpdateInterval()
    return 0.5
end

-- this function gets called once each frame, on client only
function updateClient(timeStep)
    if visible then

        local center = original:getBoundingBox().center

        if planShowCounter == 0 then
            planShowCounter = 1
            planDisplayer.plan = original
        else
            planShowCounter = 0
            planDisplayer.plan = colored
        end

        planDisplayer.center = center
    end
end

---- this function gets called once each frame, on server only
--function updateServer(timeStep)
--
--end

-- this function gets called whenever the ui window gets rendered, AFTER the window was rendered (client only)
function renderUI()
    renderPrices(window.lower + 15, "Repair Costs:"%_t, uiMoneyCost, uiResourceCost)
end

function onRepairButtonPressed()
    invokeServerFunction("repairCraft", Player().craftIndex)
end

function transactionComplete()
    ScriptUI():stopInteraction()
end

function repairCraft(craftIndex)

    local ship = Entity(craftIndex)
    if ship.factionIndex ~= callingPlayer then return end

    local buyer = Player(ship.factionIndex)

    local station = Entity()
    local seller = Faction()

    local dist = station:getNearestDistance(ship)
    if dist > 100 then
        buyer:sendChatMessage(station.title, 1, "You can't be more than 1km away to repair your ship."%_t)
        return
    end

    -- this function is executed on the server
    local perfectPlan = buyer:getShipPlan(ship.name)
    local damagedPlan = ship:getPlan()

    local requiredMoney = getRepairMoneyCost(buyer, perfectPlan, damagedPlan, ship.durability / ship.maxDurability)
    local requiredResources = getRepairResourcesCost(buyer, perfectPlan, damagedPlan, ship.durability / ship.maxDurability)

    local canPay, msg, args = buyer:canPay(requiredMoney, unpack(requiredResources))

    if not canPay then
        buyer:sendChatMessage(station.title, 1, msg, unpack(args))
        return
    end

    buyer:pay(requiredMoney, unpack(requiredResources))

    perfectPlan:resetDurability()
    ship:setPlan(perfectPlan)
    ship.durability = ship.maxDurability

    -- relations of the player to the faction owning the repair dock get better
    local relationsChange = requiredMoney / 40

    for i = 1, NumMaterials() do
        relationsChange = relationsChange + requiredResources[i] / 4
    end

    Galaxy():changeFactionRelations(buyer, Faction(), relationsChange)

    invokeClientFunction(buyer, "onShowWindow")
    invokeClientFunction(buyer, "transactionComplete")

end

function getRepairResourcesCost(orderingFaction, perfectPlan, damagedPlan, durabilityPercentage)

    -- value of blockplan template
    local templateValue = {perfectPlan:getResourceValue()}
    -- value of player's craft blockplan
    local craftValue = {damagedPlan:getResourceValue()}
    local diff = {}

    -- calculate difference
    for i = 1, NumMaterials() do
        local value = templateValue[i] - craftValue[i]
        value = value + templateValue[i] * (1.0 - durabilityPercentage)
        value = value / 2

        local fee = getRepairFactor() + GetFee(Faction(), orderingFaction)

        table.insert(diff, i, value * fee)
    end

    return diff

end

function getRepairMoneyCost(orderingFaction, perfectPlan, damagedPlan, durabilityPercentage)

    local value = perfectPlan:getMoneyValue() - damagedPlan:getMoneyValue();
    value = value + perfectPlan:getMoneyValue() * (1.0 - durabilityPercentage)
    value = value / 2

    local fee = getRepairFactor() + GetFee(Faction(), orderingFaction)

    return value * fee

end

function getRepairFactor()
    return 0.75 -- Completely repairing a ship would cost 0.75x the ship's value
end

