package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"
require ("randomext")
require ("utility")
require ("stringutility")
TurretGenerator = require ("turretgenerator")
ShipUtility = require ("shiputility")

local AI = {}

function AI.getFaction()
    local faction = Galaxy():findFaction("The AI"%_T)
    if faction == nil then
        faction = Galaxy():createFaction("The AI"%_T, 300, 0)
        faction.initialRelations = 0
        faction.initialRelationsToPlayer = 0
    end

    return faction
end

function AI.addTurrets(boss, numTurrets)

    -- create custom plasma turrets
    TurretGenerator.initialize(Seed(150))
    local turret = TurretGenerator.generate(300, 0, 0, Rarity(RarityType.Common), WeaponType.PlasmaGun)
    local weapons = {turret:getWeapons()}
    turret:clearWeapons()
    for _, weapon in pairs(weapons) do
        weapon.damage = 10 / #weapons
        weapon.fireRate = 2
        weapon.reach = 1000
        weapon.pmaximumTime = weapon.reach / weapon.pvelocity
        weapon.pcolor = Material(2).color
        turret:addWeapon(weapon)
    end
    turret.crew = Crew()
    ShipUtility.addTurretsToCraft(boss, turret, numTurrets)

end

function AI.spawn(x, y)

    -- no double spawning
    if Sector():getEntitiesByScript("entity/story/aibehaviour.lua") then return end

    local faction = AI.getFaction()

    local plan = LoadPlanFromFile("data/plans/the_ai.xml")

    local s = 1.5
    plan:scale(vec3(s, s, s))
    plan.accumulatingHealth = false

    local pos = random():getVector(-1000, 1000)
    pos = MatrixLookUpPosition(-pos, vec3(0, 1, 0), pos)

    local boss = Sector():createShip(faction, "", plan, pos)

    boss.shieldDurability = boss.shieldMaxDurability
    boss.title = "The AI"%_T
    boss.name = ""
    boss.crew = boss.minCrew
    boss:addScriptOnce("story/aibehaviour")
    boss:addScriptOnce("story/aidialog")
    boss:addScriptOnce("deleteonplayersleft")

    WreckageCreator(boss.index).active = false
    Loot(boss.index):insert(InventoryTurret(TurretGenerator.generate(x, y, 0, Rarity(RarityType.Exotic))))
    Loot(boss.index):insert(InventoryTurret(TurretGenerator.generate(x, y, 0, Rarity(RarityType.Exotic))))

    -- create custom plasma turrets
    AI.addTurrets(boss, 25)

    return boss
end

local lastAIPosition = nil
local lastSector = {}

function AI.checkForDrop()

    -- if it's the last one, then drop the key
    local faction = AI.getFaction()

    local all = {Sector():getEntitiesByComponent(ComponentType.Owner)}
    local aiPosition = nil

    -- make sure this is all happening in the same sector
    local x, y = Sector():getCoordinates()
    if lastSector.x ~= x or lastSector.y ~= y then
        -- this must be set in order to drop the loot
        -- if the sector changed, simply unset it
        lastAIPosition = nil
    end
    lastSector.x = x
    lastSector.y = y

    for _, entity in pairs(all) do
        if entity.factionIndex == faction.index then
            aiPosition = entity.translationf
            break
        end
    end

    local dropped

    -- if there are no ais now but there have been before, drop the upgrade
    if aiPosition == nil and lastAIPosition ~= nil then
        local players = {Sector():getPlayers()}

        for _, player in pairs(players) do
            local system = SystemUpgradeTemplate("data/scripts/systems/teleporterkey6.lua", Rarity(RarityType.Legendary), random():createSeed())
            Sector():dropUpgrade(lastAIPosition, player, nil, system)
            dropped = true
        end
    end

    lastAIPosition = aiPosition

    return dropped
end


return AI
