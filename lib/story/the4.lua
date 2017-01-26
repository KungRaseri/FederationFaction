package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

require ("randomext")
require ("galaxy")
require ("utility")
require ("defaultscripts")
require ("goods")
require ("stringutility")
PlanGenerator = require ("plangenerator")
ShipUtility = require ("shiputility")
SectorSpecifics = require ("sectorspecifics")
TurretGenerator = require ("turretgenerator")
SectorGenerator = require ("SectorGenerator")

local The4 = {}
local lastPosition
local lastSector = {}

function The4.getFaction()
    local name = "The Brotherhood"%_T
    local faction = Galaxy():findFaction(name)

    if not faction then
        faction = Galaxy():createFaction(name, 150, 0)

        -- those dudes are completely neutral in the beginning
        faction.initialRelations = 0
        faction.initialRelationsToPlayer = 0
    end

    return faction
end

function The4.checkForDrop()
    -- if it's the last one, then drop the key
    local faction = The4.getFaction()
    local position = nil

    -- make sure this is all happening in the same sector
    local x, y = Sector():getCoordinates()
    if lastSector.x ~= x or lastSector.y ~= y then
        -- this must be set in order to drop the loot
        -- if the sector changed, simply unset it
        lastPosition = nil
    end
    lastSector.x = x
    lastSector.y = y

    local entity = Sector():getEntitiesByFaction(faction.index)
    if entity then
        position = entity.translationf

    end

    -- if there are no ais now but there have been before, drop the upgrade
    local dropped
    if position == nil and lastPosition ~= nil then
        local players = {Sector():getPlayers()}

        for _, player in pairs(players) do
            local system = SystemUpgradeTemplate("data/scripts/systems/teleporterkey5.lua", Rarity(RarityType.Legendary), random():createSeed())
            Sector():dropUpgrade(lastPosition, player, nil, system)
            dropped = true
        end
    end

    lastPosition = position

    return dropped
end

function The4.createShip(faction, position, volume, styleName)
    position = position or Matrix()
    volume = volume or Balancing_GetSectorShipVolume(Sector():getCoordinates()) * Balancing_GetShipVolumeDeviation()

    local plan = PlanGenerator.makeShipPlan(faction, volume, styleName)
    local ship = Sector():createShip(faction, "", plan, position)

    ship.crew = ship.minCrew
    ship.shieldDurability = ship.shieldMaxDurability

    AddDefaultShipScripts(ship)

    return ship
end

function The4.createHealingTurret()
    -- create custom heal turrets
    TurretGenerator.initialize(Seed(153))

    local turret = TurretGenerator.generate(150, 0, 0, Rarity(RarityType.Common), WeaponType.RepairBeam)
    local weapons = {turret:getWeapons()}
    turret:clearWeapons()
    for _, weapon in pairs(weapons) do
        weapon.reach = 800
        weapon.blength = 800

        weapon.shieldRepair = 250
        weapon.hullRepair = 0
        weapon.bouterColor = ColorRGB(0.1, 0.2, 0.4);
        weapon.binnerColor = ColorRGB(0.2, 0.4, 0.9);
        weapon.shieldPenetration = 0.0
        turret:addWeapon(weapon)

        weapon.hullRepair = 250
        weapon.shieldRepair = 0
        weapon.bouterColor = ColorRGB(0.1, 0.5, 0.1);
        weapon.binnerColor = ColorRGB(1.0, 1.0, 1.0);
        weapon.shieldPenetration = 1.0
        turret:addWeapon(weapon)
    end

    turret.turningSpeed = 2.0
    turret.crew = Crew()

    return turret
end

function The4.createPlasmaTurret()
    -- create custom heal turrets
    TurretGenerator.initialize(Seed(151))

    local turret = TurretGenerator.generate(150, 0, 0, Rarity(RarityType.Common), WeaponType.PlasmaGun)
    local weapons = {turret:getWeapons()}
    turret:clearWeapons()
    for _, weapon in pairs(weapons) do
        weapon.reach = 800
        weapon.reach = 800
        weapon.pmaximumTime = weapon.reach / weapon.pvelocity
        weapon.hullDamageMultiplicator = 0.25
        turret:addWeapon(weapon)
    end

    turret.turningSpeed = 2.0
    turret.crew = Crew()

    return turret
end

function The4.createRailgunTurret()
    -- create custom heal turrets
    TurretGenerator.initialize(Seed(151))

    local turret = TurretGenerator.generate(150, 0, 0, Rarity(RarityType.Common), WeaponType.RailGun)
    local weapons = {turret:getWeapons()}
    turret:clearWeapons()
    for _, weapon in pairs(weapons) do
        weapon.reach = 800
        weapon.blength = 800
        weapon.shieldDamageMultiplicator = 0.1
        turret:addWeapon(weapon)
    end

    turret.turningSpeed = 2.0
    turret.crew = Crew()

    return turret
end

function The4.createLaserTurret()
    -- create custom heal turrets
    TurretGenerator.initialize(Seed(152))

    local turret = TurretGenerator.generate(450, 0, 0, Rarity(RarityType.Petty), WeaponType.Laser)
    local weapons = {turret:getWeapons()}
    turret:clearWeapons()
    for _, weapon in pairs(weapons) do
        weapon.reach = 600
        weapon.blength = 600
        turret:addWeapon(weapon)
    end

    turret.turningSpeed = 2.0
    turret.crew = Crew()

    return turret
end

function The4.spawnHealer(x, y)
    local faction = The4.getFaction()
    local volume = Balancing_GetSectorShipVolume(faction:getHomeSectorCoordinates()) * 8

    local translation = random():getDirection() * 500
    local position = MatrixLookUpPosition(-translation, vec3(0, 1, 0), translation)

    local boss = The4.createShip(faction, position, volume, "Style 1")
    local turret = The4.createHealingTurret()
    ShipUtility.addTurretsToCraft(boss, turret, 15)
    boss.title = "Reconstructo"
    boss:addScript("story/healer")
    boss:addScript("story/the4")

    Loot(boss.index):insert(InventoryTurret(TurretGenerator.generate(x, y, 0, Rarity(RarityType.Exotic), WeaponType.RepairBeam)))

    return boss
end

function The4.spawnShieldBreaker(x, y)
    local faction = The4.getFaction()
    local volume = Balancing_GetSectorShipVolume(faction:getHomeSectorCoordinates()) * 10

    local translation = random():getDirection() * 500
    local position = MatrixLookUpPosition(-translation, vec3(0, 1, 0), translation)

    local boss = The4.createShip(faction, position, volume, "Style 2")
    local turret = The4.createPlasmaTurret()
    ShipUtility.addTurretsToCraft(boss, turret, 15)
    boss.title = "Shieldbreaker"
    boss:addScript("story/the4")

    Loot(boss.index):insert(InventoryTurret(TurretGenerator.generate(x, y, 0, Rarity(RarityType.Exotic), WeaponType.RailGun)))

    return boss
end

function The4.spawnHullBreaker(x, y)
    local faction = The4.getFaction()
    local volume = Balancing_GetSectorShipVolume(faction:getHomeSectorCoordinates()) * 10

    local translation = random():getDirection() * 500
    local position = MatrixLookUpPosition(-translation, vec3(0, 1, 0), translation)

    local boss = The4.createShip(faction, position, volume, "Style 2")
    local turret = The4.createRailgunTurret()
    ShipUtility.addTurretsToCraft(boss, turret, 15)
    boss.title = "Hullbreaker"
    boss:addScript("story/the4")

    Loot(boss.index):insert(InventoryTurret(TurretGenerator.generate(x, y, 0, Rarity(RarityType.Exotic), WeaponType.RailGun)))

    return boss
end

function The4.spawnTank(x, y)
    local faction = The4.getFaction()
    local volume = Balancing_GetSectorShipVolume(faction:getHomeSectorCoordinates()) * 20

    local translation = random():getDirection() * 500
    local position = MatrixLookUpPosition(-translation, vec3(0, 1, 0), translation)

    local boss = The4.createShip(faction, position, volume, "Style 3")
    local turret = The4.createLaserTurret()
    ShipUtility.addTurretsToCraft(boss, turret, 20)
    boss.title = "Tankem"
    boss:addScript("story/the4")

    Loot(boss.index):insert(InventoryTurret(TurretGenerator.generate(x, y, 0, Rarity(RarityType.Exotic), WeaponType.Laser)))

    return boss
end


function The4.spawn(x, y)

    local ships = {Sector():getEntitiesByFaction(The4.getFaction().index)}

    for _, ship in pairs(ships) do
        if ship:hasComponent(ComponentType.Title) then
            if ship.title == "Tankem"
                or ship.title == "Shieldbreaker"
                or ship.title == "Hullbreaker"
                or ship.title == "Reconstructo" then

                return
            end
        end
    end

    print ("spawning the The 4!")

    -- spawn
    local healer = The4.spawnHealer(x, y)
    local dd1 = The4.spawnShieldBreaker(x, y)
    local dd2 = The4.spawnHullBreaker(x, y)
    local tank = The4.spawnTank(x, y)

    enemies = {}
    table.insert(enemies, healer)
    table.insert(enemies, dd1)
    table.insert(enemies, dd2)
    table.insert(enemies, tank)

    local players = {Sector():getPlayers()}

    for _, boss in pairs(enemies) do
        ShipAI(boss.index):setAggressive()

        -- like all players
        for _, player in pairs(players) do
            ShipAI(boss.index):registerFriendFaction(player.index)
        end
    end

    print ("The 4 spawned!")

    return healer, dd1, dd2, tank
end

function The4.spawnBeacon()
    local generator = SectorGenerator(Sector():getCoordinates())

    local beacon = generator:createBeacon(Matrix(), nil, "Scanners online."%_t)
    beacon:addScript("story/artifactdeliverybeacon")
    beacon:addScript("deleteonplayersleft")

end

local description = [[
Fellow Galaxy Dweller,

In times like these, where the Xsotan threat is looming at all times, we are trying to protect you. Dangerous artifacts of the Xsotan have been found all over the galaxy, causing great harm to everyone near them.
Should you find any of those artifacts, you must bring them to us. We will take care of them and destroy them, to eradicate the Xsotan threat and to make the galaxy a better place.
Even if your life may be at risk, what is your life compared to the safety of trillions?

You can find one of our outposts at (${x}, ${y}).
We will pay a reward of 100.000.000 credits for each delivered artifact.

- The Brotherhood
]]%_t

function The4.tryPostBulletin(entity)
    entity = entity or Entity()

    if random():getFloat() > 0.25 then return end

    local mind = 150
    local maxd = 180


    local distance = length(vec2(Sector():getCoordinates()))
    if not (distance >= mind and distance < maxd) then
        return
    end

    local location
    local x, y = Sector():getCoordinates()

    local specs = SectorSpecifics()
    local coordinates = specs.getShuffledCoordinates(random(), x, y, 0, 40)
    local seed = Server().seed

    for _, coords in pairs(coordinates) do

        local distance = length(vec2(coords.x, coords.y))
        if distance >= mind and distance < maxd then

            local regular, offgrid, blocked, home = specs:determineContent(coords.x, coords.y, seed)
            if offgrid and not regular and not blocked and not home then

                specs:initialize(coords.x, coords.y, seed)
                if string.match(specs:getScript(), "wreckagefield") then
                    location = {x = coords.x, y = coords.y}
                    break
                end
            end
        end
    end

    -- if no location could be found, don't post
    if not location then
        return
    end

    local bulletin =
    {
        brief = "Looking for Xsotan Artifacts"%_t,
        description = description % location,
        difficulty = "Hard"%_t,
        reward = "$100.000.000",
        script = "story/artifactdelivery.lua",
        arguments = {location.x, location.y},
        checkAccept = [[
            local self, player = ...
            if player:hasScript("story/artifactdelivery") then
                player:removeScript("data/scripts/player/story/artifactdelivery.lua")
            end
            return 1
        ]],
        onAccept = [[ ]]
    }

    entity:invokeFunction("bulletinboard", "postBulletin", bulletin)
end


return The4;
