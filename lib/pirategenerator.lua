package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

require ("galaxy")
require ("stringutility")
local PlanGenerator = require ("plangenerator")
local ShipUtility = require ("shiputility")


local PirateGenerator = {}

function PirateGenerator.getScaling()
    local scaling = Sector().numPlayers

    if scaling == 0 then scaling = 1 end
    return scaling
end


function PirateGenerator.createScaledOutlaw(position)
    local scaling = PirateGenerator.getScaling()
    return PirateGenerator.create(position, 0.75 * scaling, 0.25, "Outlaw"%_t)
end

function PirateGenerator.createScaledBandit(position)
    local scaling = PirateGenerator.getScaling()
    return PirateGenerator.create(position, 1.0 * scaling, 0.5, "Bandit"%_t)
end

function PirateGenerator.createScaledPirate(position)
    local scaling = PirateGenerator.getScaling()
    return PirateGenerator.create(position, 1.5 * scaling, 0.65, "Pirate"%_t)
end

function PirateGenerator.createScaledMarauder(position)
    local scaling = PirateGenerator.getScaling()
    return PirateGenerator.create(position, 2.0 * scaling, 0.75, "Marauder"%_t)
end

function PirateGenerator.createScaledRaider(position)
    local scaling = PirateGenerator.getScaling()
    return PirateGenerator.create(position, 4.0 * scaling, 1.0, "Raider"%_t)
end

function PirateGenerator.createScaledBoss(position)
    local scaling = PirateGenerator.getScaling()
    return PirateGenerator.create(position, 30.0 * scaling, 1.5, "Pirate Mothership"%_t)
end


function PirateGenerator.createOutlaw(position)
    return PirateGenerator.create(position, 0.75, 0.5, "Outlaw"%_t)
end

function PirateGenerator.createBandit(position)
    return PirateGenerator.create(position, 1.0, 1.0, "Bandit"%_t)
end

function PirateGenerator.createPirate(position)
    return PirateGenerator.create(position, 1.5, 1.0, "Pirate"%_t)
end

function PirateGenerator.createMarauder(position)
    return PirateGenerator.create(position, 2.0, 1.25, "Marauder"%_t)
end

function PirateGenerator.createRaider(position)
    return PirateGenerator.create(position, 4.0, 1.5, "Raider"%_t)
end

function PirateGenerator.createBoss(position)
    return PirateGenerator.create(position, 30.0, 2.0, "Pirate Mothership"%_t)
end

function PirateGenerator.create(position, volumeFactor, turretFactor, title)
    position = position or Matrix()
    local x, y = Sector():getCoordinates()
    PirateGenerator.pirateLevel = PirateGenerator.pirateLevel or Balancing_GetPirateLevel(x, y)

    local faction = Galaxy():getPirateFaction(PirateGenerator.pirateLevel)

    local volume = Balancing_GetSectorShipVolume(x, y) * volumeFactor;

    local plan = PlanGenerator.makeShipPlan(faction, volume)
    local ship = Sector():createShip(faction, "", plan, position)

    -- turrets should also scale with pirate strength, but every pirate must have at least 1 turret
    local turrets = math.max(2, math.floor(Balancing_GetEnemySectorTurrets(x, y) * turretFactor))

    ShipUtility.addArmedTurretsToCraft(ship, turrets)

    ship.crew = ship.minCrew
    ship.title = title
    ship.shieldDurability = ship.shieldMaxDurability

    ShipAI(ship.index):setAggressive()

    ship:setValue("is_pirate", 1)

    return ship
end

function PirateGenerator.getPirateFaction()
    local x, y = Sector():getCoordinates()
    PirateGenerator.pirateLevel = PirateGenerator.pirateLevel or Balancing_GetPirateLevel(x, y)
    return Galaxy():getPirateFaction(PirateGenerator.pirateLevel)
end


return PirateGenerator
