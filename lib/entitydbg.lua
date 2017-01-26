
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

require ("utility")
require ("stationextensions")
SectorSpecifics = require ("sectorspecifics")
SectorGenerator = require ("SectorGenerator")
ShipUtility = require ("shiputility")
TurretGenerator = require ("turretgenerator")
UpgradeGenerator = require ("upgradegenerator")
PirateGenerator = require ("pirategenerator")
Rewards = require ("rewards")
Scientist = require ("story/scientist")
The4 = require ("story/the4")
Smuggler = require ("story/smuggler")
Placer = require ("placer")
Xsotan = require ("story/xsotan")
AdventurerGuide = require("story/adventurerguide")
OperationExodus = require("story/operationexodus")

local scriptsWindow
local scriptList
local scripts
local addScriptButton
local removeScriptButton
local templateButtons

local numButtons = 0
function ButtonRect(w, h)

    local width = w or 280
    local height = h or 35

    local space = math.floor((window.size.y - 80) / (height + 10))

    local row = math.floor(numButtons % space)
    local col = math.floor(numButtons / space)

    local lower = vec2((width + 10) * col, (height + 10) * row)
    local upper = lower + vec2(width, height)

    numButtons = numButtons + 1

    return Rect(lower, upper)
end

function interactionPossible(player)
    return true, ""
end

function initialize()

end

function onShowWindow()
    scriptsWindow:hide()
    valuesWindow:hide()
end

function onCloseWindow()
    scriptsWindow:hide()
    valuesWindow:hide()
end

function initUI()

    local res = getResolution()
    local size = vec2(1200, 650)

    local menu = ScriptUI()
    window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))

    window.caption = "Debug"
    window.showCloseButton = 1
    window.moveable = 1
    menu:registerWindow(window, "~dev");

    -- create a tabbed window inside the main window
    local tabbedWindow = window:createTabbedWindow(Rect(vec2(10, 10), size - 10))

    local tab = tabbedWindow:createTab("Entity", "data/textures/icons/ship.png", "Ship Commands")
    numButtons = 0
    tab:createButton(ButtonRect(), "GoTo", "onGoToButtonPressed")
    tab:createButton(ButtonRect(), "Entity Scripts", "onEntityScriptsButtonPressed")
    tab:createButton(ButtonRect(), "Entity Values", "onEntityValuesButtonPressed")
    tab:createButton(ButtonRect(), "Faction Scripts", "onFactionScriptsButtonPressed")
    tab:createButton(ButtonRect(), "Faction Values", "onFactionValuesButtonPressed")
    tab:createButton(ButtonRect(), "Spawn Ship", "onCreateShipsButtonPressed")
    tab:createButton(ButtonRect(), "Spawn Beacon", "onCreateBeaconButtonPressed")
    tab:createButton(ButtonRect(), "Fly", "onFlyButtonPressed")
    tab:createButton(ButtonRect(), "Own", "onOwnButtonPressed")
    tab:createButton(ButtonRect(), "Add Crew", "onAddCrewButtonPressed")
    tab:createButton(ButtonRect(), "Add Cargo", "onAddCargoButtonPressed")
    tab:createButton(ButtonRect(), "Clear Cargo", "onClearCargoButtonPressed")
    tab:createButton(ButtonRect(), "Clear Crew", "onClearCrewButtonPressed")
    tab:createButton(ButtonRect(), "Destroy", "onDestroyButtonPressed")
    tab:createButton(ButtonRect(), "Delete", "onDeleteButtonPressed")
    tab:createButton(ButtonRect(), "Toggle Invincible", "onInvincibleButtonPressed")
    tab:createButton(ButtonRect(), "Set Gate Plan", "onSetGatePlanPressed")
    tab:createButton(ButtonRect(), "Make Freighter", "onSetFreighterPlanPressed")
    tab:createButton(ButtonRect(), "Like", "onLikePressed")
    tab:createButton(ButtonRect(), "Dislike", "onDislikePressed")
    tab:createButton(ButtonRect(), "Damage", "onDamagePressed")
    tab:createButton(ButtonRect(), "Title", "onTitlePressed")

    local tab = tabbedWindow:createTab("Inventory", "data/textures/icons/greek-temple.png", "Player Commands")
    numButtons = 0
    tab:createButton(ButtonRect(), "Player Scripts", "onPlayerScriptsButtonPressed")
    tab:createButton(ButtonRect(), "Player Values", "onPlayerValuesButtonPressed")
    tab:createButton(ButtonRect(), "Reset Money", "onResetMoneyButtonPressed")
    tab:createButton(ButtonRect(), "Guns Guns Guns", "onGunsButtonPressed")
    tab:createButton(ButtonRect(), "Gimme Systems", "onSystemsButtonPressed")
    tab:createButton(ButtonRect(), "Mining Lasers", "onMiningLasersButtonPressed")
    tab:createButton(ButtonRect(), "Clear Inventory", "onClearInventoryButtonPressed")
    tab:createButton(ButtonRect(), "Quest Reward", "onQuestRewardButtonPressed")
    tab:createButton(ButtonRect(), "Mission Upgrades", "onKeysButtonPressed")
    tab:createButton(ButtonRect(), "Disable Events", "onDisableEventsButtonPressed")

    local tab = tabbedWindow:createTab("Sector", "data/textures/icons/compass.png", "Sector Commands")
    numButtons = 0
    tab:createButton(ButtonRect(), "Sector Scripts", "onSectorScriptsButtonPressed")
    tab:createButton(ButtonRect(), "Sector Values", "onSectorValuesButtonPressed")
    tab:createButton(ButtonRect(), "Server Values", "onServerValuesButtonPressed")
    tab:createButton(ButtonRect(), "Clear Sector", "onClearButtonPressed")
    tab:createButton(ButtonRect(), "Infect Asteroids", "onInfectAsteroidsButtonPressed")
    tab:createButton(ButtonRect(), "Align", "onAlignButtonPressed")
    tab:createButton(ButtonRect(), "Resolve Intersections", "onResolveIntersectionsButtonPressed")

    local tab = tabbedWindow:createTab("Spawn", "data/textures/icons/slow-blob.png", "Spawn")
    numButtons = 0
    tab:createButton(ButtonRect(), "Infected Asteroid", "onCreateInfectedAsteroidPressed")
    tab:createButton(ButtonRect(), "Big Infected Asteroid", "onCreateBigInfectedAsteroidPressed")
    tab:createButton(ButtonRect(), "Ownable Asteroid", "onCreateOwnableAsteroidPressed")
    tab:createButton(ButtonRect(), "Adventurer", "onCreateAdventurerPressed")
    tab:createButton(ButtonRect(), "Travelling Merchant", "onCreateMerchantPressed")
    tab:createButton(ButtonRect(), "Wreckage", "onCreateWreckagePressed")
    tab:createButton(ButtonRect(), "Resistance Outpost", "onCreateResistanceOutpostPressed")
    tab:createButton(ButtonRect(), "Smuggler's Market", "onCreateSmugglersMarketPressed")
    tab:createButton(ButtonRect(), "Headquarters", "onCreateHeadQuartersPressed")
    tab:createButton(ButtonRect(), "Research Station", "onCreateResearchStationPressed")
    tab:createButton(ButtonRect(), "Shipyard", "onCreateShipyardButtonPressed")
    tab:createButton(ButtonRect(), "Repair Dock", "onCreateRepairDockButtonPressed")
    tab:createButton(ButtonRect(), "Equipment Dock", "onCreateEquipmentDockButtonPressed")
    tab:createButton(ButtonRect(), "Turret Merchant", "onCreateTurretMerchantButtonPressed")
    tab:createButton(ButtonRect(), "Turret Factory", "onCreateTurretFactoryButtonPressed")
    tab:createButton(ButtonRect(), "Trading Post", "onCreateTradingPostButtonPressed")
    tab:createButton(ButtonRect(), "Resource Trader", "onCreateResourceTraderButtonPressed")
    tab:createButton(ButtonRect(), "Mine", "onCreateMineButtonPressed")
    tab:createButton(ButtonRect(), "Power Plant", "onCreateSolarPlantButtonPressed")
    tab:createButton(ButtonRect(), "Manufacturer", "onCreateManufacturerButtonPressed")
    tab:createButton(ButtonRect(), "Farm", "onCreateFarmButtonPressed")
    tab:createButton(ButtonRect(), "Collector", "onCreateCollectorButtonPressed")
    tab:createButton(ButtonRect(), "Scrapyard", "onCreateScrapyardButtonPressed")
    tab:createButton(ButtonRect(), "Military Outpost", "onCreateMilitaryOutpostPressed")
    tab:createButton(ButtonRect(), "Big Asteroid", "onCreateBigAsteroidButtonPressed")
    tab:createButton(ButtonRect(), "Asteroid Field", "onCreateAsteroidFieldButtonPressed")
    tab:createButton(ButtonRect(), "Rich Asteroid Field", "onCreateRichAsteroidFieldButtonPressed")
    tab:createButton(ButtonRect(), "Container Field", "onCreateContainerFieldButtonPressed")
    tab:createButton(ButtonRect(), "Resource Asteroid", "onCreateResourceAsteroidButtonPressed")
    tab:createButton(ButtonRect(), "Carrier", "onSpawnCarrierButtonPressed")
    tab:createButton(ButtonRect(), "Xsotan Carrier", "onSpawnXsotanCarrierButtonPressed")
    tab:createButton(ButtonRect(), "Defenders", "onSpawnDefendersButtonPressed")
    tab:createButton(ButtonRect(), "Battle", "onSpawnBattleButtonPressed")
    tab:createButton(ButtonRect(), "Deferred Battle", "onSpawnDeferredBattleButtonPressed")
    tab:createButton(ButtonRect(), "Fleet", "onSpawnFleetButtonPressed")
    tab:createButton(ButtonRect(), "Swoks", "onSpawnSwoksButtonPressed")
    tab:createButton(ButtonRect(), "The AI", "onSpawnTheAIButtonPressed")
    tab:createButton(ButtonRect(), "Smuggler", "onSpawnSmugglerButtonPressed")
    tab:createButton(ButtonRect(), "Scientist", "onSpawnScientistButtonPressed")
    tab:createButton(ButtonRect(), "The 4", "onSpawnThe4ButtonPressed")
    tab:createButton(ButtonRect(), "Guardian", "onSpawnGuardianButtonPressed")


    local tab = tabbedWindow:createTab("Generate Sectors", "data/textures/icons/gears.png", "Generator Scripts")
    numButtons = 0

    local specs = SectorSpecifics(0, 0, Seed());
    specs:addTemplates()

    templateButtons = {}
    for i, template in pairs(specs.templates) do
        local parts = template.path:split("/")
        local button = tab:createButton(ButtonRect(), parts[2], "onGenerateTemplateButtonPressed")
        table.insert(templateButtons, {button = button, template = template});
    end

    local tab = tabbedWindow:createTab("Missions", "data/textures/icons/treasure-map.png", "Missions")
    numButtons = 0
    tab:createButton(ButtonRect(), "Smuggler Retaliation", "onSmugglerRetaliationButtonPressed")
    tab:createButton(ButtonRect(), "Exodus Beacon", "onExodusBeaconButtonPressed")
    tab:createButton(ButtonRect(), "Exodus Corner Points", "onExodusPointsButtonPressed")
    tab:createButton(ButtonRect(), "Exodus Final Beacon", "onExodusFinalBeaconButtonPressed")
    tab:createButton(ButtonRect(), "Distress Call", "onDistressCallButtonPressed")
    tab:createButton(ButtonRect(), "Fake Distress Call", "onFakeDistressCallButtonPressed")
    tab:createButton(ButtonRect(), "Pirate Attack", "onPirateAttackButtonPressed")
    tab:createButton(ButtonRect(), "Xsotan Attack", "onAlienAttackButtonPressed")



    local tab = tabbedWindow:createTab("Icons", "data/textures/icons/wooden-crate.png", "Cargo Commands")
    numButtons = 0
    local sortedGoods = {}
    for name, good in pairs(goods) do
        table.insert(sortedGoods, good)
    end

    stolenCargoCheckBox = tab:createCheckBox(Rect(vec2(150, 25)), "Stolen", "onStolenChecked")
    local organizer = UIOrganizer(Rect(tabbedWindow.size))

    organizer:placeElementTopRight(stolenCargoCheckBox)

    function goodsByName(a, b) return a.name < b.name end
    table.sort(sortedGoods, goodsByName)

    for _, good in pairs(sortedGoods) do
        local rect = ButtonRect(40, 40)

        rect.upper = rect.lower + vec2(rect.size.y, rect.size.y)

        local button = tab:createButton(rect, "", "onGoodsButtonPressed")
        button.icon = good.icon
        button.tooltip = good.name



--        local p = vec2(rect.upper.x, rect.lower.y + 5)

--        local label = tab:createLabel(p, name, 15)

    end


    local size = vec2(800, 500)
    scriptsWindow = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
    scriptsWindow.visible = false
    scriptsWindow.caption = "Scripts"
    scriptsWindow.showCloseButton = 1
    scriptsWindow.moveable = 1
    scriptsWindow.closeableWithEscape = 1

    local hsplit = UIHorizontalSplitter(Rect(vec2(0, 0), size), 10, 10, 0.5)
    hsplit.bottomSize = 80

    scriptList = scriptsWindow:createListBox(hsplit.top)

    local hsplit = UIHorizontalSplitter(hsplit.bottom, 10, 0, 0.5)
    hsplit.bottomSize = 35

    scriptTextBox = scriptsWindow:createTextBox(hsplit.top, "")

    local vsplit = UIVerticalSplitter(hsplit.bottom, 10, 0, 0.5)

    addScriptButton = scriptsWindow:createButton(vsplit.left, "Add", "")
    removeScriptButton = scriptsWindow:createButton(vsplit.right, "Remove", "")


    -- values window
    local size = vec2(1000, 700)
    valuesWindow = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
    valuesWindow.visible = false
    valuesWindow.caption = "Values"
    valuesWindow.showCloseButton = 1
    valuesWindow.moveable = 1
    valuesWindow.closeableWithEscape = 1

    valuesLines = {}

    local horizontal = 2
    local vertical = 19

    local vsplit = UIVerticalMultiSplitter(Rect(size), 5, 0, horizontal - 1)


    local previous = nil
    for x = 1, horizontal do
        local hsplit = UIHorizontalMultiSplitter(vsplit:partition(x - 1), 5, 10, vertical - 1)

        for y = 1, vertical do
            local vsplit = UIVerticalSplitter(hsplit:partition(y - 1), 5, 0, 0.5)

            local vsplit2 = UIVerticalSplitter(vsplit.right, 5, 0, 0.5)
            local vsplit3 = UIVerticalSplitter(vsplit2.right, 5, 0, 0.5)


            local key = valuesWindow:createTextBox(vsplit.left, "")
            local value = valuesWindow:createTextBox(vsplit2.left, "")

            local set = valuesWindow:createButton(vsplit3.left, "set", "onSetValuePressed")
            local delete = valuesWindow:createButton(vsplit3.right, "X", "onDeleteValuePressed")

            key.tabTarget = value

            if previous then previous.tabTarget = key end
            previous = value

            table.insert(valuesLines, {key = key, value = value, set = set, delete = delete})
        end
    end

end

--[[
function updateClient()
    if not docks then
        syncDocks()
    else
        for _, dock in pairs(docks) do
            dock = Entity().position:transformCoord(dock)
            drawDebugSphere(Sphere(dock, 1), ColorRGB(1, 1, 0))
        end
    end

    local ownDocks = {Entity():getDockingPositions()}
    for _, dock in pairs(ownDocks) do
        dock = Entity().position:transformCoord(dock)
        --drawDebugSphere(Sphere(dock, 3), ColorRGB(1, 0, 0))
    end

end
--]]

function syncDocks(docks_in)
    if onClient() then
        if docks_in then
            docks = docks_in
        else
            invokeServerFunction("syncDocks")
        end
    else
        local docks = {Entity():getDockingPositions()}
        invokeClientFunction(Player(callingPlayer), "syncDocks", docks)
    end
end



function onGenerateTemplateButtonPressed(arg)

    if onClient() then
        local button = arg
        for _, p in pairs(templateButtons) do
            if button.index == p.button.index then
                invokeServerFunction("onGenerateTemplateButtonPressed", p.template.path)
                break
            end
        end

        return
    end

    print("generating sector: " .. arg)

    -- clear sector except for player's entities
    local sector = Sector()
    for _, entity in pairs({sector:getEntities()}) do

        if entity.factionIndex == nil or entity.factionIndex ~= Entity().factionIndex then
            sector:deleteEntity(entity)
        end
    end

    sector:collectGarbage()

    local specs = SectorSpecifics(0, 0, Seed());
    specs:addTemplates()

    local path = arg
    for _, template in pairs(specs.templates) do
        if path == template.path then
            template.generate(Faction(), sector.seed, sector:getCoordinates())
            return
        end
    end

end

function onSmugglerRetaliationButtonPressed()

    if onClient() then
        invokeServerFunction("onSmugglerRetaliationButtonPressed")
        return
    end

    local player = Player(callingPlayer)
    player:setValue("smuggler_letter", nil)

    player:removeScript("story/smugglerretaliation.lua")
    player:removeScript("story/smugglerdelivery.lua")
    player:removeScript("story/smugglerletter.lua")

    player:addScriptOnce("story/smugglerletter.lua")

end

function onExodusBeaconButtonPressed()

    if onClient() then
        invokeServerFunction("onExodusBeaconButtonPressed")
        return
    end

    OperationExodus.generateBeacon(SectorGenerator(Sector():getCoordinates()))
end

function onExodusPointsButtonPressed()
    if onClient() then
        invokeServerFunction("onExodusPointsButtonPressed")
        return
    end

    local str = "Points: "
    for _, point in pairs(OperationExodus.getCornerPoints()) do
        str = str .. "\\s(${x}, ${y})  " % point
    end

    Player(callingPlayer):sendChatMessage("", 0, str)
end

function onExodusFinalBeaconButtonPressed()
    if onClient() then
        invokeServerFunction("onExodusFinalBeaconButtonPressed")
        return
    end

    local beacon = SectorGenerator(Sector():getCoordinates()):createBeacon(nil, nil, "")
    beacon:removeScript("data/scripts/entity/beacon.lua")
    beacon:addScript("story/exodustalkbeacon.lua")
end

function onDistressCallButtonPressed()
    if onClient() then
        invokeServerFunction("onDistressCallButtonPressed")
        return
    end

    local player = Player(callingPlayer)
    player:addScript("convoidistresssignal.lua", true)
end

function onFakeDistressCallButtonPressed()
    if onClient() then
        invokeServerFunction("onFakeDistressCallButtonPressed")
        return
    end

    local player = Player(callingPlayer)
    player:addScript("fakedistresssignal.lua", true)
end

function onPirateAttackButtonPressed()
    if onClient() then
        invokeServerFunction("onPirateAttackButtonPressed")
        return
    end

    Sector():addScript("pirateattack.lua")
end

function onAlienAttackButtonPressed()
    if onClient() then
        invokeServerFunction("onAlienAttackButtonPressed")
        return
    end

    Player():addScript("alienattack.lua")
end

function onStolenChecked(index, checked)
end

function onAddCrewButtonPressed()
    if onClient() then
        invokeServerFunction("onAddCrewButtonPressed")
        return
    end

    local craft = Entity()

    craft.crew = craft.minCrew
    craft:addCrew(1, CrewMan(CrewProfessionType.Captain))
end

function onGoodsButtonPressed(button, stolen)
    if onClient() then
        invokeServerFunction("onGoodsButtonPressed", button.tooltip, stolenCargoCheckBox.checked)
        return
    end

    -- we're using the same argument name for both the button and the
    -- good's name, on client it's a button, on server it's a string
    local name = button

    local craft = Entity()
    local good = goods[name]:good()

    good.stolen = stolen

    for i = 1, 10 do
        craft:addCargo(good, 1)
    end
end

function onAddCargoButtonPressed()
    if onClient() then
        invokeServerFunction("onAddCargoButtonPressed")
        return
    end

    local max = #goodsArray
    local goods = {
        goodsArray[random():getInt(1, max)],
        goodsArray[random():getInt(1, max)],
        goodsArray[random():getInt(1, max)],
        goodsArray[random():getInt(1, max)],
    }

    local craft = Entity()

    local add = true
    while add do
        add = false

        for _, g in pairs(goods) do
            local freeBefore = craft.freeCargoSpace
            if freeBefore > g.size then
                craft:addCargo(g:good(), 1)
                add = true
            end
        end
    end

end

function onClearCargoButtonPressed()
    if onClient() then
        invokeServerFunction("onClearCargoButtonPressed")
        return
    end

    local ship = Entity()

    for cargo, amount in pairs(ship:getCargos()) do
        ship:removeCargo(cargo, amount)
    end

end

function onClearCrewButtonPressed()
    if onClient() then
        invokeServerFunction("onClearCrewButtonPressed")
        return
    end

    Entity().crew = Crew()
end

function onDestroyButtonPressed(destroyer)
    if onClient() then
        invokeServerFunction("onDestroyButtonPressed", Player().craft.index)
        return
    end

    local craft = Entity()

    craft:destroy(destroyer)
end

function onSpawnDefendersButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnDefendersButtonPressed")
        return
    end

    local x, y = Sector():getCoordinates()

    local faction = Galaxy():getNearestFaction(x, y)

    local right = Entity().right
    local dir = Entity().look
    local up = Entity().up
    local position = Entity().translationf

    for i = -2, 2 do
        local pos = position - right * 500 + dir * i * 100
        ShipGenerator.createDefender(faction, MatrixLookUpPosition(right, up, pos))
    end

end

function onSpawnCarrierButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnCarrierButtonPressed")
        return
    end

    local x, y = Sector():getCoordinates()

    local faction = Galaxy():getNearestFaction(x, y)

    local right = Entity().right
    local dir = Entity().look
    local up = Entity().up
    local position = Entity().translationf

    local pos = position + dir * 100
    ShipGenerator.createCarrier(faction, MatrixLookUpPosition(right, up, pos))

end

function onSpawnXsotanCarrierButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnXsotanCarrierButtonPressed")
        return
    end

    local x, y = Sector():getCoordinates()

    local faction = Galaxy():getNearestFaction(x, y)

    local right = Entity().right
    local dir = Entity().look
    local up = Entity().up
    local position = Entity().translationf

    local pos = position + dir * 100
    Xsotan.createCarrier(MatrixLookUpPosition(right, up, pos))

end

function onSpawnBattleButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnBattleButtonPressed")
        return
    end

    local x, y = Sector():getCoordinates()

    local pirates = Galaxy():getPirateFaction(Balancing_GetPirateLevel(x, y))
    local faction = Galaxy():getNearestFaction(x, y)

    local right = Entity().right
    local dir = Entity().look
    local up = Entity().up
    local position = Entity().translationf

    local ships = {}

    for i = -5, 5 do
        local pos = position + dir * 1500 + right * i * 100
        if i >= -1 and i <= 1 then
            local ship = ShipGenerator.createCarrier(pirates, MatrixLookUpPosition(-right, up, pos))
            table.insert(ships, ship)
        else
            local ship = ShipGenerator.createDefender(pirates, MatrixLookUpPosition(-right, up, pos))
            table.insert(ships, ship)
        end
    end

    for i = -3, 3 do
        local pos = position + dir * 500 + right * i * 100
        if i >= -1 and i <= 1 then
            local ship = ShipGenerator.createCarrier(faction, MatrixLookUpPosition(-right, up, pos))
            table.insert(ships, ship)
        else
            local ship = ShipGenerator.createDefender(faction, MatrixLookUpPosition(-right, up, pos))
            table.insert(ships, ship)
        end
    end

    Placer.resolveIntersections(ships)

end

function onSpawnDeferredBattleButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnDeferredBattleButtonPressed")
        return
    end

    deferredCallback(15.0, "onSpawnBattleButtonPressed")
end


function onSpawnFleetButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnFleetButtonPressed")
        return
    end

    local x, y = Sector():getCoordinates()

    local pirates = Galaxy():getPirateFaction(Balancing_GetPirateLevel(x, y))
    local faction = Faction()

    local right = Entity().right
    local dir = Entity().look
    local up = Entity().up
    local position = Entity().translationf

    for i = -3, 3 do
        local pos = position - right * 500 + dir * i * 100
        local ship = ShipGenerator.createDefender(faction, MatrixLookUpPosition(right, up, pos))

        local waypoints = {}
        for j = 0, 8 do
            local pos = position + random():getVector(-400, 400)
            table.insert(waypoints, pos)
        end

        ShipAI(ship.index):setPatrol(unpack(waypoints))
    end

end

function prepareCleanUp()
    local safe =
    {
        cleanUp = cleanUp,
        initialize = initialize,
        interactionPossible = interactionPossible,
        onShowWindow = onShowWindow,
        onCloseWindow = onCloseWindow,
        initUI = initUI,
        update = update,
        updateServer = updateServer,
        updateClient = updateClient,
    }

    return safe
end

function cleanUp(safe)
    cleanUp = safe.cleanUp
    initialize = safe.initialize
    interactionPossible = safe.interactionPossible
    onShowWindow = safe.onShowWindow
    onCloseWindow = safe.onCloseWindow
    initUI = safe.initUI

    update = nil
    updateServer = nil
    updateClient = nil
    getUpdateInterval = nil
    secure = nil
    restore = nil
end

function onResolveIntersectionsButtonPressed()
    if onClient() then
        invokeServerFunction("onResolveIntersectionsButtonPressed")
        return
    end

    Placer.resolveIntersections()
end

function onSpawnSwoksButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnSwoksButtonPressed")
        return
    end

    local safe = prepareCleanUp()

    dofile("data/scripts/player/story/spawnswoks.lua")
    spawnEnemies(Player(), Sector():getCoordinates())

    safe.cleanUp(safe)
end

function onSpawnTheAIButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnTheAIButtonPressed")
        return
    end

    local safe = prepareCleanUp()

    dofile("data/scripts/player/story/spawnai.lua")
    spawnEnemies(Player(), Sector():getCoordinates())

    safe.cleanUp(safe)

end

function onSpawnSmugglerButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnSmugglerButtonPressed")
        return
    end

    Smuggler.spawn()
end

function onSpawnScientistButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnScientistButtonPressed")
        return
    end

    Scientist.spawn()
end

function onSpawnGuardianButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnGuardianButtonPressed")
        return
    end

    Xsotan.createGuardian()
    Placer.resolveIntersections()
end

function onSpawnThe4ButtonPressed()
    if onClient() then
        invokeServerFunction("onSpawnThe4ButtonPressed")
        return
    end

    The4.spawn(Sector():getCoordinates())
end

function onAlignButtonPressed()
    if onClient() then
        invokeServerFunction("onAlignButtonPressed")
        return
    end

    ShipGenerator.placeNextToEachOther(vec3(0, 0, 0), vec3(1, 0, 0), vec3(0, 1, 0), Sector():getEntitiesByComponent(ComponentType.Plan))
    Placer.resolveIntersections()
end

function onEntityScriptsButtonPressed()
    scriptList:clear()
    scripts = {}
    scriptsWindow:show()


    addScriptButton.onPressedFunction = "addEntityScript"
    removeScriptButton.onPressedFunction = "removeEntityScript"

    invokeServerFunction("sendEntityScripts", Player().index)
end

function addEntityScript(name)
    if onClient() then
        invokeServerFunction("addEntityScript", scriptTextBox.text)
        invokeServerFunction("sendEntityScripts", Player().index)
        return
    end

    print("add script " .. name )

    Entity():addScript(name)

end

function removeEntityScript(script)

    if onClient() then

        local entry = tonumber(scripts[scriptList.selected])
        if entry ~= nil then
            invokeServerFunction("removeEntityScript", entry)
            invokeServerFunction("sendEntityScripts", Player().index)
        end

        return
    end

    print("remove script " .. script)

    Entity():removeScript(tonumber(script))

    print("remove script done ")
end

function sendEntityScripts(playerIndex)
    invokeClientFunction(Player(playerIndex), "receiveScripts", Entity():getScripts())
end



function onSectorScriptsButtonPressed()
    scriptList:clear()
    scripts = {}
    scriptsWindow:show()

    addScriptButton.onPressedFunction = "addSectorScript"
    removeScriptButton.onPressedFunction = "removeSectorScript"

    invokeServerFunction("sendSectorScripts", Player().index)
end

function addSectorScript(name)

    if onClient() then
        invokeServerFunction("addSectorScript", scriptTextBox.text)
        invokeServerFunction("sendSectorScripts", Player().index)
        return
    end

    print("add sector script " .. name )

    Sector():addScript(name)

end

function removeSectorScript(script)

    if onClient() then

        local entry = tonumber(scripts[scriptList.selected])
        if entry ~= nil then
            invokeServerFunction("removeSectorScript", entry)
            invokeServerFunction("sendSectorScripts", Player().index)
        end

        return
    end

    print("remove script " .. script )

    Sector():removeScript(tonumber(script))

end

function sendSectorScripts(playerIndex)
    invokeClientFunction(Player(playerIndex), "receiveScripts", Sector():getScripts())
end


function onPlayerScriptsButtonPressed()
    scriptList:clear()
    scripts = {}
    scriptsWindow:show()

    addScriptButton.onPressedFunction = "addPlayerScript"
    removeScriptButton.onPressedFunction = "removePlayerScript"

    invokeServerFunction("sendPlayerScripts")
end

function addPlayerScript(name)

    if onClient() then
        invokeServerFunction("addPlayerScript", scriptTextBox.text)
        invokeServerFunction("sendPlayerScripts")
        return
    end

    print("adding player script " .. name )

    Player(callingPlayer):addScript(name)

end

function removePlayerScript(script)

    if onClient() then

        local entry = tonumber(scripts[scriptList.selected])
        if entry ~= nil then
            invokeServerFunction("removePlayerScript", entry)
            invokeServerFunction("sendPlayerScripts")
        end

        return
    end

    print("removing player script " .. script )

    Player(callingPlayer):removeScript(tonumber(script))

end

function sendPlayerScripts()
    invokeClientFunction(Player(callingPlayer), "receiveScripts", Player(callingPlayer):getScripts())
end





function receiveScripts(scripts_in)

    scriptList:clear()
    scripts = {}

    local c = 0
    for i, name in pairs(scripts_in) do
        scriptList:addEntry(string.format("[%i] %s", i, name))

        scripts[c] = i
        c = c + 1
    end
end

function syncValues(valueType_in, values_in)
    if onClient() then
        if not values_in then
            invokeServerFunction("syncValues", valueType_in)
        else
            valueType = valueType_in
            values = values_in

            fillValues()
        end
    else
        local values

        if valueType_in == 0 then
            values = Entity():getValues()
        elseif valueType_in == 1 then
            values = Sector():getValues()
        elseif valueType_in == 2 then
            values = Faction():getValues()
        elseif valueType_in == 3 then
            values = Player(callingPlayer):getValues()
        elseif valueType_in == 4 then
            values = Server():getValues()
        end

        invokeClientFunction(Player(callingPlayer), "syncValues", valueType_in, values)
    end
end

function setValue(tp, key, value)

    if tp == 0 then
        values = Entity():setValue(key, value)
    elseif tp == 1 then
        values = Sector():setValue(key, value)
    elseif tp == 2 then
        values = Faction():setValue(key, value)
    elseif tp == 3 then
        values = Player(callingPlayer):setValue(key, value)
    elseif tp == 4 then
        values = Server():setValue(key, value)
    end

    syncValues(tp)
end

function onEntityValuesButtonPressed()
    syncValues(0)
    valuesWindow:show()
end

function onSectorValuesButtonPressed()
    syncValues(1)
    valuesWindow:show()
end

function onFactionValuesButtonPressed()
    syncValues(2)
    valuesWindow:show()
end

function onPlayerValuesButtonPressed()
    syncValues(3)
    valuesWindow:show()
end

function onServerValuesButtonPressed()
    syncValues(4)
    valuesWindow:show()
end

function fillValues()
    for _, line in pairs(valuesLines) do
        line.key.text = ""
        line.value.text = ""
    end

    local sorted = {}

    for k, v in pairs(values) do
        table.insert(sorted, {k=k, v=v})
    end

    function comp(a, b) return a.k < b.k end
    table.sort(sorted, comp)


    local c = 1
    for _, p in pairs(sorted) do
        local line = valuesLines[c]

        line.key.text = p.k
        line.value.text = tostring(p.v)

        c = c + 1
    end

end

function onSetValuePressed(button)
    for _, line in pairs(valuesLines) do
        if line.set.index == button.index then
            local str = line.value.text
            local number = tonumber(str)

            if number then
                invokeServerFunction("setValue", valueType, line.key.text, number)
            elseif str == "true" then
                invokeServerFunction("setValue", valueType, line.key.text, true)
            elseif str == "false" then
                invokeServerFunction("setValue", valueType, line.key.text, false)
            else
                invokeServerFunction("setValue", valueType, line.key.text, str)
            end
        end
    end
end

function onDeleteValuePressed(button)
    for _, line in pairs(valuesLines) do
        if line.delete.index == button.index then
            invokeServerFunction("setValue", valueType, line.key.text, nil)
        end
    end
end


function onQuestRewardButtonPressed(arg)
    if onClient() then
        invokeServerFunction("onQuestRewardButtonPressed")
        return
    end

    local player = Player(callingPlayer)
    local faction = Galaxy():getNearestFaction(Sector():getCoordinates())

    Rewards.standard(player, faction, nil, 12345, 500, true, true)
end

function onKeysButtonPressed(arg)
    if onClient() then
        invokeServerFunction("onKeysButtonPressed")
        return
    end

    local player = Player(callingPlayer)
    player:getInventory():add(SystemUpgradeTemplate("data/scripts/systems/teleporterkey1.lua", Rarity(RarityType.Legendary), Seed(0)))
    player:getInventory():add(SystemUpgradeTemplate("data/scripts/systems/teleporterkey2.lua", Rarity(RarityType.Legendary), Seed(0)))
    player:getInventory():add(SystemUpgradeTemplate("data/scripts/systems/teleporterkey3.lua", Rarity(RarityType.Legendary), Seed(0)))
    player:getInventory():add(SystemUpgradeTemplate("data/scripts/systems/teleporterkey4.lua", Rarity(RarityType.Legendary), Seed(0)))
    player:getInventory():add(SystemUpgradeTemplate("data/scripts/systems/teleporterkey5.lua", Rarity(RarityType.Legendary), Seed(0)))
    player:getInventory():add(SystemUpgradeTemplate("data/scripts/systems/teleporterkey6.lua", Rarity(RarityType.Legendary), Seed(0)))
    player:getInventory():add(SystemUpgradeTemplate("data/scripts/systems/teleporterkey7.lua", Rarity(RarityType.Legendary), Seed(0)))
    player:getInventory():add(SystemUpgradeTemplate("data/scripts/systems/teleporterkey8.lua", Rarity(RarityType.Legendary), Seed(0)))

    player:getInventory():add(SystemUpgradeTemplate("data/scripts/systems/wormholeopener.lua", Rarity(RarityType.Exotic), Seed(0)))
    player:getInventory():add(SystemUpgradeTemplate("data/scripts/systems/wormholeopener.lua", Rarity(RarityType.Exotic), Seed(0)))
    player:getInventory():add(SystemUpgradeTemplate("data/scripts/systems/wormholeopener.lua", Rarity(RarityType.Exotic), Seed(0)))
    player:getInventory():add(SystemUpgradeTemplate("data/scripts/systems/wormholeopener.lua", Rarity(RarityType.Exotic), Seed(0)))
    player:getInventory():add(SystemUpgradeTemplate("data/scripts/systems/wormholeopener.lua", Rarity(RarityType.Exotic), Seed(0)))
    player:getInventory():add(SystemUpgradeTemplate("data/scripts/systems/wormholeopener.lua", Rarity(RarityType.Legendary), Seed(0)))
    player:getInventory():add(SystemUpgradeTemplate("data/scripts/systems/smugglerblocker.lua", Rarity(RarityType.Exotic), Seed(0)))

    for i = 0, 3 do
        player:getInventory():add(SystemUpgradeTemplate("data/scripts/systems/enginebooster.lua", Rarity(RarityType.Legendary), Seed(0)))
    end

end

function onDisableEventsButtonPressed(arg)

    if onClient() then
        invokeServerFunction("onDisableEventsButtonPressed")
        return
    end

    Player(callingPlayer):removeScript("eventscheduler.lua")
    Player(callingPlayer):removeScript("piratehunter.lua")
    Player(callingPlayer):removeScript("headhunter.lua")
    Player(callingPlayer):removeScript("alienattack.lua")

    Sector():removeScript("events.lua")
    Sector():removeScript("pirateattack.lua")
end

function onFlyButtonPressed(arg)

    if onClient() then
        invokeServerFunction("onFlyButtonPressed", Player().index)
        return
    end

    local player = Player(arg)
    player.craft = Entity()
end

function onOwnButtonPressed(arg)

    if onClient() then
        invokeServerFunction("onOwnButtonPressed", Player().index)
        return
    end

    Entity().factionIndex = arg
end

function onCreateShipsButtonPressed()

    if onClient() then
        invokeServerFunction("onCreateShipsButtonPressed")
        return
    end

    local faction = Faction()
    local this = Entity()

    local position = this.position
    local p = this.right * (this:getBoundingBox().size.x + 50.0)
    position.pos = position.pos + vec3(p.x, p.y, p.z)

    local ship = ShipGenerator.createMilitaryShip(faction, position)
    ship:addScript("data/scripts/entity/stationfounder.lua")

end

function onCreateBeaconButtonPressed()

    if onClient() then
        invokeServerFunction("onCreateBeaconButtonPressed")
        return
    end

    local faction = Faction()
    local this = Entity()

    local position = this.position
    local p = this.right * (this:getBoundingBox().size.x + 50.0)
    position.pos = position.pos + vec3(p.x, p.y, p.z)

    SectorGenerator(Sector():getCoordinates()):createBeacon(position, nil, "This is the ${text}", {text = "Beacon Text"})

end

function onGunsButtonPressed()
    if onClient() then
        invokeServerFunction("onGunsButtonPressed")
        return
    end

    local player = Player()

    local weaponTypes = {}
    weaponTypes[WeaponType.ChainGun] = 1
    weaponTypes[WeaponType.Laser] = 1
    weaponTypes[WeaponType.MiningLaser] = 1
    weaponTypes[WeaponType.SalvagingLaser] = 1
    weaponTypes[WeaponType.PlasmaGun] = 1
    weaponTypes[WeaponType.RocketLauncher] = 1
    weaponTypes[WeaponType.Cannon] = 1
    weaponTypes[WeaponType.RailGun] = 1
    weaponTypes[WeaponType.RepairBeam] = 1
    weaponTypes[WeaponType.Bolter] = 1
    weaponTypes[WeaponType.LightningGun] = 1
    weaponTypes[WeaponType.ForceGun] = 1

    local rarities = {}
    rarities[RarityType.Petty] = 1
    rarities[RarityType.Common] = 1
    rarities[RarityType.Uncommon] = 1
    rarities[RarityType.Rare] = 1
    rarities[RarityType.Exceptional] = 1
    rarities[RarityType.Exotic] = 1
    rarities[RarityType.Legendary] = 1


    local materials = {}
    materials[0] = 1
    materials[1] = 1
    materials[2] = 1
    materials[3] = 1
    materials[4] = 1
    materials[5] = 1
    materials[6] = 1

    local dps, tech = Balancing_GetSectorWeaponDPS(Sector():getCoordinates())

    local x, y = Sector():getCoordinates()

    for i = 1, 15 do

        local rarity = selectByWeight(random(), rarities)
        local material = selectByWeight(random(), materials)
        local weaponType = selectByWeight(random(), weaponTypes)

        local turret = TurretGenerator.generate(x, y, 0, Rarity(rarity), weaponType, Material(material))

        for j = 1, 20 do
            player:getInventory():add(InventoryTurret(turret))
        end
    end

end

function onSystemsButtonPressed()
    if onClient() then
        invokeServerFunction("onSystemsButtonPressed")
        return
    end

    UpgradeGenerator.initialize()

    for i = 1, 15 do
        Faction():getInventory():add(UpgradeGenerator.generateSystem())
    end
end

function onMiningLasersButtonPressed()
    if onClient() then
        invokeServerFunction("onMiningLasersButtonPressed")
        return
    end

    local rarities = {}
    rarities[RarityType.Petty] = 1
    rarities[RarityType.Common] = 1
    rarities[RarityType.Uncommon] = 1
    rarities[RarityType.Rare] = 1
    rarities[RarityType.Exceptional] = 1
    rarities[RarityType.Exotic] = 1
    rarities[RarityType.Legendary] = 1

    for rarity, _ in pairs(rarities) do
        for i = 1, 500, 10 do
            local turret = TurretGenerator.generate(500 - i, 0, 0, Rarity(rarity), WeaponType.MiningLaser, nil)
            Faction():getInventory():add(InventoryTurret(turret))
        end
    end

end

function onClearInventoryButtonPressed()
    if onClient() then
        invokeServerFunction("onClearInventoryButtonPressed")
        return
    end

    Faction():getInventory():clear()

end

function onCreateWreckagePressed()
    if onClient() then
        invokeServerFunction("onCreateWreckagePressed")
        return
    end

    SectorGenerator(Sector():getCoordinates()):createWreckage(Galaxy():getNearestFaction(Sector():getCoordinates()))
end

function onCreateInfectedAsteroidPressed()
    if onClient() then
        invokeServerFunction("onCreateInfectedAsteroidPressed")
        return
    end

    local ship = Entity()
    local asteroid = SectorGenerator(0, 0):createSmallAsteroid(ship.translationf + ship.look * (ship.size.z * 0.5 + 20), 7, true, Material(MaterialType.Iron))
    Xsotan.infect(asteroid)

    Placer.resolveIntersections()
end

function onCreateBigInfectedAsteroidPressed()
    if onClient() then
        invokeServerFunction("onCreateBigInfectedAsteroidPressed")
        return
    end

    local ship = Entity()
    Xsotan.createBigInfectedAsteroid(ship.translationf + ship.look * (ship.size.z * 0.5 + 50))

    Placer.resolveIntersections()
end

function onCreateOwnableAsteroidPressed()
    if onClient() then
        invokeServerFunction("onCreateOwnableAsteroidPressed")
        return
    end

    SectorGenerator(0, 0):createClaimableAsteroid()
    Placer.resolveIntersections()
end

function onCreateAdventurerPressed()
    if onClient() then
        invokeServerFunction("onCreateAdventurerPressed")
        return
    end

    AdventurerGuide.spawn1(Player(callingPlayer))
end

function onCreateMerchantPressed()
    if onClient() then
        invokeServerFunction("onCreateMerchantPressed")
        return
        end

        Player(callingPlayer):addScript("spawntravellingmerchant.lua")
        end

function onGoToButtonPressed()

    local ship = Player().craft
    local target = ship.selectedObject

    ship.position = target.position

    Velocity(ship.index).velocity = dvec3(0, 0, 0)
    ship.desiredVelocity = 0

    if target.type == EntityType.Station then
        local pos, dir = target:getDockingPositions()

        pos = target.position:transformCoord(pos)
        dir = target.position:transformNormal(dir)

        pos = pos + dir * (ship:getBoundingSphere().radius + 10)

        local up = target.position.up

        ship.position = MatrixLookUpPosition(-dir, up, pos)
    end

end

function onCreateContainerFieldButtonPressed()

    if onClient() then
        invokeServerFunction("onCreateContainerFieldButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())
    generator:createContainerField()

    Placer.resolveIntersections()
end

function onCreateResourceAsteroidButtonPressed()

    if onClient() then
        invokeServerFunction("onCreateResourceAsteroidButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())
    generator:createSmallAsteroid(vec3(0, 0, 0), 1.0, 1, generator:getAsteroidType())

    Placer.resolveIntersections()
end

function onCreateTurretFactoryButtonPressed()

    if onClient() then
        invokeServerFunction("onCreateTurretFactoryButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createStation(faction, "data/scripts/entity/merchants/turretfactory.lua")
    station:addScript("data/scripts/entity/merchants/turretmerchant.lua")
    station.position = Matrix()

    Placer.resolveIntersections()

end

function onCreateTradingPostButtonPressed()

    if onClient() then
        invokeServerFunction("onCreateTradingPostButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createStation(faction, "data/scripts/entity/merchants/tradingpost.lua")
    station.position = Matrix()

    Placer.resolveIntersections()

end

function onCreateSmugglersMarketPressed()

    if onClient() then
        invokeServerFunction("onCreateSmugglersMarketPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createStation(faction, "data/scripts/entity/merchants/smugglersmarket.lua")
--    station:addScript("merchants/tradingpost")
    station.position = Matrix()
    station.title = "Smuggler's Market"

    Placer.resolveIntersections()

end

function onCreateResistanceOutpostPressed()

    if onClient() then
        invokeServerFunction("onCreateResistanceOutpostPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createStation(faction, "merchants/resistanceoutpost.lua")

    Placer.resolveIntersections()
end

function onCreateHeadQuartersPressed()

    if onClient() then
        invokeServerFunction("onCreateHeadQuartersPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createStation(faction, "data/scripts/entity/merchants/headquarters.lua")
    station.position = Matrix()

    Placer.resolveIntersections()

end

function onCreateResearchStationPressed()

    if onClient() then
        invokeServerFunction("onCreateResearchStationPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createResearchStation(faction)
    station.position = Matrix()

    Placer.resolveIntersections()

end

function onCreateShipyardButtonPressed()

    if onClient() then
        invokeServerFunction("onCreateShipyardButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createShipyard(faction)
    station.position = Matrix()

    Placer.resolveIntersections()

end

function onCreateRepairDockButtonPressed()

    if onClient() then
        invokeServerFunction("onCreateRepairDockButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createRepairDock(faction)
    station.position = Matrix()

    Placer.resolveIntersections()
end

function onCreateEquipmentDockButtonPressed()

    if onClient() then
        invokeServerFunction("onCreateEquipmentDockButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createEquipmentDock(faction)
    station.position = Matrix()

    Placer.resolveIntersections()
end

function onCreateTurretMerchantButtonPressed()

    if onClient() then
        invokeServerFunction("onCreateTurretMerchantButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createStation(faction, "data/scripts/entity/merchants/turretmerchant.lua")
    station.position = Matrix()

    Placer.resolveIntersections()
end

function onCreateResourceTraderButtonPressed()

    if onClient() then
        invokeServerFunction("onCreateResourceTraderButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createStation(faction, "data/scripts/entity/merchants/resourcetrader.lua")
    station.position = Matrix()

    Placer.resolveIntersections()
end


function onResetMoneyButtonPressed()
    if onClient() then
        invokeServerFunction("onResetMoneyButtonPressed")
        return
    end

    local player = Player()
    if player ~= nil then
        local money = 5000000

        if player.money == money * 100 then
            money = 0

            player.money = money * 100
            player:setResources(money, money, money, money, money, money, money, money, money, money, money) -- too much, don't care

        elseif player.money == 0 then
            local x, y = Sector():getCoordinates()

            player.money = Balancing_GetSectorRichnessFactor(x, y) * 200000

            local probabilities = Balancing_GetMaterialProbability(x, y)

            for i, p in pairs(probabilities) do
                probabilities[i] = p * Balancing_GetSectorRichnessFactor(x, y) * 5000
            end

            local num = 0
            for i = NumMaterials() - 1, 0, -1 do
                probabilities[i] = probabilities[i] + num
                num = num + probabilities[i] / 2;
            end


            player:setResources(unpack(probabilities))
        else
            player.money = money * 100
            player:setResources(money, money, money, money, money, money, money, money, money, money, money) -- too much, don't care
        end

    end

end

function onSetGatePlanPressed()
	if onClient() then
        invokeServerFunction("onSetGatePlanPressed")
        return
    end

	local plan = PlanGenerator.makeGatePlan()

    local entity = Entity()

    entity:setPlan(plan)
end

function onSetFreighterPlanPressed()
	if onClient() then
        invokeServerFunction("onSetFreighterPlanPressed")
        return
    end

	local plan = PlanGenerator.makeFreighterPlan(Faction())

    Entity():setPlan(plan)
end

function onLikePressed()
    if onClient() then
        invokeServerFunction("onLikePressed")
        return
    end

	Galaxy():changeFactionRelations(Player(callingPlayer), Faction(Entity().factionIndex), 20000)
end

function onDislikePressed()
    if onClient() then
        invokeServerFunction("onDislikePressed")
        return
    end

	Galaxy():changeFactionRelations(Player(callingPlayer), Faction(Entity().factionIndex), -20000)

end

function onTitlePressed()

    local str = "args: "
    for k, v in pairs(Entity():getTitleArguments()) do
        str = str .. " k: " .. k .. ", v: " .. v
    end

    print (str)
    print (Entity().title)

    if onClient() then
        invokeServerFunction("onTitlePressed")
        return
    end
end

function onDamagePressed()
    if onClient() then
        invokeServerFunction("onDamagePressed")
        return
    end

    local ship = Entity()
    if ship.shieldDurability > 0 then
        local damage = ship.shieldMaxDurability * 0.2
        ship:damageShield(damage, ship.translationf, Player(callingPlayer).craftIndex)
    else
        local damage = ship.maxDurability * 0.2
        ship:inflictDamage(damage, 0, vec3(), Player(callingPlayer).craftIndex)
    end

end

function onInvincibleButtonPressed()
    if onClient() then
        invokeServerFunction("onInvincibleButtonPressed")
        return
    end

    local entity = Entity()

    local name = string.format("%s %s", entity.title or "", entity.name or "")

    if entity.invincible then
        entity.invincible = false
        Player(callingPlayer):sendChatMessage("Server", 0, name .. " is no longer invincible")
    else
        entity.invincible = true
        Player(callingPlayer):sendChatMessage("Server", 0, name .. " is now invincible")
    end
end

function onDeleteButtonPressed()
    if onClient() then
        invokeServerFunction("onDeleteButtonPressed")
        return
    end

    Sector():deleteEntityJumped(Entity())
end

function onCreateBigAsteroidButtonPressed()
    if onClient() then
        invokeServerFunction("onCreateBigAsteroidButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())
    local asteroid = generator:createBigAsteroid()

    Placer.resolveIntersections()
end

function onCreateAsteroidFieldButtonPressed()
    if onClient() then
        invokeServerFunction("onCreateAsteroidFieldButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())
    local asteroid = generator:createAsteroidField()

    Placer.resolveIntersections()
end

function onCreateRichAsteroidFieldButtonPressed()
    if onClient() then
        invokeServerFunction("onCreateRichAsteroidFieldButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())
    local asteroid = generator:createAsteroidField(0.8)

    Placer.resolveIntersections()
end

function onCreateManufacturerButtonPressed()

    if onClient() then
        invokeServerFunction("onCreateManufacturerButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createStation(faction)
    station.position = Matrix()
    station:addScript("data/scripts/entity/merchants/factory.lua", "Rubber")

    Placer.resolveIntersections()
end

function onCreateFarmButtonPressed()

    if onClient() then
        invokeServerFunction("onCreateFarmButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createStation(faction)
    station.position = Matrix()
    station:addScript("data/scripts/entity/merchants/factory.lua", "Wheat")

    Placer.resolveIntersections()
end

function onCreateCollectorButtonPressed()

    if onClient() then
        invokeServerFunction("onCreateCollectorButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createStation(faction)
    station.position = Matrix()
    station:addScript("data/scripts/entity/merchants/factory.lua", "Water")

    Placer.resolveIntersections()
end

function onCreateScrapyardButtonPressed()

    if onClient() then
        invokeServerFunction("onCreateScrapyardButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createStation(faction)
    station.position = Matrix()
    station:addScript("data/scripts/entity/merchants/scrapyard.lua", "Water")

    Placer.resolveIntersections()
end

function onCreateMilitaryOutpostPressed()

    if onClient() then
        invokeServerFunction("onCreateMilitaryOutpostPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createMilitaryBase(faction)
    station.position = Matrix()

    Placer.resolveIntersections()
end

function onCreateSolarPlantButtonPressed()

    if onClient() then
        invokeServerFunction("onCreateSolarPlantButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createStation(faction)
    station.position = Matrix()
    station:addScript("data/scripts/entity/merchants/factory.lua", "Energy Cell")

    Placer.resolveIntersections()
end

function onCreateMineButtonPressed()

    if onClient() then
        invokeServerFunction("onCreateMineButtonPressed")
        return
    end

    local generator = SectorGenerator(Sector():getCoordinates())

    local faction = Galaxy():createRandomFaction(Sector():getCoordinates())
    local station = generator:createStation(faction)
    station.position = Matrix()
    station:addScript("data/scripts/entity/merchants/factory.lua", "Silicium")

    Placer.resolveIntersections()
end

function onClearButtonPressed()
    if onClient() then
        invokeServerFunction("onClearButtonPressed")
        return
    end

    -- portion that is executed on server
    local sector = Sector()
    local self = Entity()

    for _, entity in pairs({sector:getEntities()}) do
        if entity.factionIndex == nil or entity.factionIndex ~= callingPlayer then
            sector:deleteEntity(entity)
        end
    end

end

function onInfectAsteroidsButtonPressed()
    if onClient() then
        invokeServerFunction("onInfectAsteroidsButtonPressed")
        return
    end

    Xsotan.infectAsteroids()
end

function clearStations()
    local sector = Sector()
    for _, entity in pairs({sector:getEntitiesByType(EntityType.Station)}) do
        sector:deleteEntity(entity)
    end
end
