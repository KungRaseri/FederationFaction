package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"
require ("randomext")
require ("utility")
require ("stringutility")
require ("galaxy")
TurretGenerator = require ("turretgenerator")
ShipGenerator = require ("shipgenerator")


local Scientist = {}

function Scientist.createSatellite(position)
    local desc = EntityDescriptor()
    desc:addComponents(
       ComponentType.Plan,
       ComponentType.BspTree,
       ComponentType.Intersection,
       ComponentType.Asleep,
       ComponentType.DamageContributors,
       ComponentType.BoundingSphere,
       ComponentType.BoundingBox,
       ComponentType.Velocity,
       ComponentType.Physics,
       ComponentType.Scripts,
       ComponentType.ScriptCallback,
       ComponentType.Title,
       ComponentType.Owner,
       ComponentType.WreckageCreator,
       ComponentType.Durability,
       ComponentType.PlanMaxDurability,
       ComponentType.EnergySystem,
       ComponentType.Loot
       )


    local faction = Scientist.getFaction()
    local plan = PlanGenerator.makeStationPlan(faction)

    local s = 25 / plan:getBoundingSphere().radius
    plan:scale(vec3(s, s, s))
    plan.accumulatingHealth = true

    desc.position = position
    desc:setPlan(plan)
    desc.factionIndex = faction.index
    desc.title = "Energy Research Satellite"%_T


    local satellite = Sector():createEntity(desc)
    satellite:addScript("data/scripts/lib/entitydbg.lua")
    satellite:addScript("story/researchsatellite.lua")

    Loot(satellite.index):insert(SystemUpgradeTemplate("data/scripts/systems/energybooster.lua", Rarity(RarityType.Rare), random():createSeed()))
end


function Scientist.getFaction()
    local name = "The M.A.D. Science Association"%_T
    local faction = Galaxy():findFaction(name)

    if not faction then
        faction = Galaxy():createFaction(name, 240, 0)

        -- those dudes are completely neutral in the beginning
        faction.initialRelations = 0
        faction.initialRelationsToPlayer = 0
    end

    return faction
end

function Scientist.createLightningTurret()

    -- create custom plasma turrets
    TurretGenerator.initialize(Seed(150))
    local turret = TurretGenerator.generate(300, 0, 0, Rarity(RarityType.Common), WeaponType.LightningGun)
    local weapons = {turret:getWeapons()}
    turret:clearWeapons()
    for _, weapon in pairs(weapons) do
        weapon.damage = 500
        weapon.fireRate = 2
        weapon.reach = 600
        weapon.accuracy = 0.97
        turret:addWeapon(weapon)
    end
    turret.turningSpeed = 2.0
    turret.crew = Crew()

    return turret

end

function Scientist.spawn(player, x, y)
    print ("spawning the scientist!")

    -- spawn
    local faction = Scientist.getFaction()
    local volume = Balancing_GetSectorShipVolume(faction:getHomeSectorCoordinates()) * 30

    local translation = random():getDirection() * 500
    local position = MatrixLookUpPosition(-translation, vec3(0, 1, 0), translation)


    local boss = ShipGenerator.createShip(faction, position, volume)
    local turret = Scientist.createLightningTurret()
    ShipUtility.addTurretsToCraft(boss, turret, 15)
    boss.title = "Mobile Energy Lab"%_T

    spawnCoords = {x=x, y=y}
    enemies = {}
    table.insert(enemies, boss)

    ShipAI(boss.index):setAggressive()

    Loot(boss.index):insert(InventoryTurret(TurretGenerator.generate(x, y, 0, Rarity(RarityType.Exotic))))
    Loot(boss.index):insert(SystemUpgradeTemplate("data/scripts/systems/teleporterkey7.lua", Rarity(RarityType.Legendary), Seed()))

    boss:addScript("story/scientist.lua")

    print ("Scientist spawned!")

    return boss
end


return Scientist
