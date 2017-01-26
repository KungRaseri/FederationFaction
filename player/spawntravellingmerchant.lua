if onServer() then

package.path = package.path .. ";data/scripts/lib/?.lua"

ShipGenerator = require ("shipgenerator")
NamePool = require ("namepool")
require ("randomext")
require ("stringutility")

local merchants = {}
table.insert(merchants, {name = "Mobile Equipment Merchant", script = "data/scripts/entity/merchants/equipmentdock.lua"})
table.insert(merchants, {name = "Mobile Resource Merchant", script = "data/scripts/entity/merchants/resourcetrader.lua"})
table.insert(merchants, {name = "Mobile Merchant", script = "data/scripts/entity/merchants/tradingpost.lua"})
table.insert(merchants, {name = "Mobile Turret Merchant", script = "data/scripts/entity/merchants/turretmerchant.lua"})

function initialize()

    -- create the merchant
    local pos = random():getDirection() * 1500
    local matrix = MatrixLookUpPosition(normalize(-pos), vec3(0, 1, 0), pos)
    local faction = Galaxy():getNearestFaction(Sector():getCoordinates())

    local ship = ShipGenerator.createTradingShip(faction, matrix)

    local index = random():getInt(1, #merchants)
    local merchant = merchants[index]
    ship.title = merchant.name
    ship:addScript(merchant.script)
    ship:addScript("data/scripts/entity/merchants/travellingmerchant.lua")
    NamePool.setShipName(ship)

    if index == 1 and math.random() < 0.5 then
        ship:invokeFunction("equipmentdock", "addFront", SystemUpgradeTemplate("data/scripts/systems/teleporterkey4.lua", Rarity(RarityType.Legendary), random():createSeed()), 1)
    end

    Sector():broadcastChatMessage("${title} ${name}"%_t % ship, 0, "Hello Everybody! %s %s here. I'll be here for the next 15 minutes. Come look at my merchandise!"%_t, ship.title, ship.name)

    terminate()
end

end
