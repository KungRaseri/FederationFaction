package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

require ("galaxy")
require ("utility")
require ("defaultscripts")
require ("goods")
PlanGenerator = require ("plangenerator")
FighterGenerator = require ("fightergenerator")
ShipUtility = require ("shiputility")

local ShipGenerator = {}

function ShipGenerator.createShip(faction, position, volume)
    position = position or Matrix()
    volume = volume or Balancing_GetSectorShipVolume(Sector():getCoordinates()) * Balancing_GetShipVolumeDeviation()

    local plan = PlanGenerator.makeShipPlan(faction, volume)
    local ship = Sector():createShip(faction, "", plan, position)

    ship.crew = ship.minCrew
    ship.shieldDurability = ship.shieldMaxDurability

    AddDefaultShipScripts(ship)


    return ship
end

function ShipGenerator.createDefender(faction, position)
    -- defenders should be a lot beefier than the normal ships
    local volume = Balancing_GetSectorShipVolume(faction:getHomeSectorCoordinates()) * 10

    local ship = ShipGenerator.createShip(faction, position, volume)
    local turrets = Balancing_GetEnemySectorTurrets(Sector():getCoordinates()) * 1.5 + 3

    ShipUtility.addArmedTurretsToCraft(ship, turrets)
    ship.crew = ship.minCrew
    ship.title = ShipUtility.getMilitaryNameByVolume(ship.volume)

    ship:addScript("ai/patrol.lua")
    ship:addScript("antismuggle.lua")

    ship:setValue("is_armed", 1)

    return ship
end

function ShipGenerator.createCarrier(faction, position, fighters)
    -- carriers should be even beefier than the defenders
    position = position or Matrix()
    fighters = fighters or 10
    local volume = volume or Balancing_GetSectorShipVolume(Sector():getCoordinates()) * Balancing_GetShipVolumeDeviation()

    local plan = PlanGenerator.makeCarrierPlan(faction, volume)
    local ship = Sector():createShip(faction, "", plan, position)

    ship.shieldDurability = ship.shieldMaxDurability

    -- add fighters
    local hangar = Hangar(ship.index)
    hangar:addSquad("Alpha")
    hangar:addSquad("Beta")
    hangar:addSquad("Gamma")

    local numFighters = 0
    for squad = 0, 9 do
        local fighter = FighterGenerator.generateArmed(faction:getHomeSectorCoordinates())
        for i = 1, 10 do
            hangar:addFighter(squad, fighter)

            numFighters = numFighters + 1
            if numFighters >= fighters then break end
        end

        if numFighters >= fighters then break end
    end


    ship.crew = ship.minCrew

    local turrets = Balancing_GetEnemySectorTurrets(Sector():getCoordinates())

    ShipUtility.addArmedTurretsToCraft(ship, turrets)
    ship.crew = ship.minCrew
    ship.title = ShipUtility.getMilitaryNameByVolume(ship.volume)

    ship:addScript("ai/patrol.lua")
    ship:setValue("is_armed", 1)

    return ship
end

function ShipGenerator.createMilitaryShip(faction, position, volume)
    local ship = ShipGenerator.createShip(faction, position, volume)

    local turrets = Balancing_GetEnemySectorTurrets(Sector():getCoordinates())

    ShipUtility.addArmedTurretsToCraft(ship, turrets)
    ship.crew = ship.minCrew
    ship.title = ShipUtility.getMilitaryNameByVolume(ship.volume)

    ship:setValue("is_armed", 1)

    return ship
end

function ShipGenerator.createTradingShip(faction, position, volume)
    local ship = ShipGenerator.createShip(faction, position, volume)

    if math.random() < 0.5 then
        local turrets = Balancing_GetEnemySectorTurrets(Sector():getCoordinates())

        ShipUtility.addArmedTurretsToCraft(ship, turrets)
    end

    ship.crew = ship.minCrew
    ship.title = ShipUtility.getTraderNameByVolume(ship.volume)

    ship:addScript("civilship.lua")
    ship:addScript("dialogs/storyhints.lua")
    ship:setValue("is_civil", 1)

    return ship
end

function ShipGenerator.createFreighterShip(faction, position, volume)
    position = position or Matrix()
    volume = volume or Balancing_GetSectorShipVolume(Sector():getCoordinates()) * Balancing_GetShipVolumeDeviation()

    local plan = PlanGenerator.makeFreighterPlan(faction, volume)
    local ship = Sector():createShip(faction, "", plan, position)

    ship.shieldDurability = ship.shieldMaxDurability
    ship.crew = ship.minCrew

    AddDefaultShipScripts(ship)

    if math.random() < 0.5 then
        local turrets = Balancing_GetEnemySectorTurrets(Sector():getCoordinates())

        ShipUtility.addArmedTurretsToCraft(ship, turrets)
    end

    ship.crew = ship.minCrew
    ship.title = ShipUtility.getFreighterNameByVolume(ship.volume)

    ship:addScript("civilship.lua")
    ship:addScript("dialogs/storyhints.lua")
    ship:setValue("is_civil", 1)

    return ship
end

function ShipGenerator.createMiningShip(faction, position, volume)
    local ship = ShipGenerator.createShip(faction, position, volume)

    local turrets = Balancing_GetEnemySectorTurrets(Sector():getCoordinates())

    ShipUtility.addUnarmedTurretsToCraft(ship, turrets)
    ship.crew = ship.minCrew
    ship.title = ShipUtility.getMinerNameByVolume(ship.volume)

    ship:addScript("civilship.lua")
    ship:addScript("dialogs/storyhints.lua")
    ship:setValue("is_civil", 1)

    return ship
end

return ShipGenerator;
