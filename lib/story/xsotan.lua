package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

require ("randomext")
require ("utility")
require ("stringutility")
require ("defaultscripts")
FighterGenerator = require ("fightergenerator")
TurretGenerator = require ("turretgenerator")
UpgradeGenerator = require ("upgradegenerator")
ShipUtility = require ("shiputility")
PlanGenerator = require ("plangenerator")


local Xsotan = {}

function Xsotan.getFaction()
    local name = "The Xsotan"%_T

    local galaxy = Galaxy()
    local faction = galaxy:findFaction(name)
    if faction == nil then
        faction = galaxy:createFaction(name, 0, 0)
        faction.initialRelations = -100000
        faction.initialRelationsToPlayer = 0
        faction.staticRelationsToPlayers = true

        for trait, value in pairs(faction:getTraits()) do
            faction:setTrait(trait, 0) -- completely neutral / unknown
        end
    end

    return faction
end

function Xsotan.createShip(position, volumeFactor)
    position = position or Matrix()
    local volume = Balancing_GetSectorShipVolume(Sector():getCoordinates())

    volume = volume * (volumeFactor or 1)
    volume = volume * 0.5 -- xsotan ships aren't supposed to be very big

    local x, y = Sector():getCoordinates()
    local probabilities = Balancing_GetMaterialProbability(x, y)
    local material = Material(getValueFromDistribution(probabilities))
    local faction = Xsotan.getFaction()
    local plan = PlanGenerator.makeShipPlan(faction, volume, nil, material)
    local ship = Sector():createShip(faction, "", plan, position)

    Xsotan.infectShip(ship)

    -- Xsotan have random turrets
    TurretGenerator.initialize(random():createSeed())
    local turret = TurretGenerator.generateArmed(x, y)
    local numTurrets = math.max(2, Balancing_GetEnemySectorTurrets(x, y) * 0.75)

    ShipUtility.addTurretsToCraft(ship, turret, numTurrets)

    ship:setTitle("Xsotan ${ship}", {ship = ShipUtility.getMilitaryNameByVolume(ship.volume)})
    ship.crew = ship.minCrew
    ship.shieldDurability = ship.shieldMaxDurability

    AddDefaultShipScripts(ship)

    ship:addScript("ai/patrol.lua")
    ship:addScript("story/xsotanbehaviour.lua")
    ship:setValue("is_xsotan", 1)

    return ship
end

function Xsotan.createCarrier(position, volumeFactor, fighters)
    position = position or Matrix()
    fighters = fighters or 30
    local volume = Balancing_GetSectorShipVolume(Sector():getCoordinates())

    volume = volume * (volumeFactor or 1)
    volume = volume * 5.0

    local x, y = Sector():getCoordinates()
    local probabilities = Balancing_GetMaterialProbability(x, y)
    local material = Material(getValueFromDistribution(probabilities))
    local faction = Xsotan.getFaction()
    local plan = PlanGenerator.makeCarrierPlan(faction, volume, nil, material)
    local ship = Sector():createShip(faction, "", plan, position)

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

    -- Xsotan have random turrets
    TurretGenerator.initialize(random():createSeed())
    local turret = TurretGenerator.generateArmed(x, y)
    local numTurrets = math.max(1, Balancing_GetEnemySectorTurrets(x, y) / 2)

    ShipUtility.addTurretsToCraft(ship, turret, numTurrets)

    ship:setTitle("Xsotan ${ship}", {ship = ShipUtility.getMilitaryNameByVolume(ship.volume)})
    ship.crew = ship.minCrew
    ship.shieldDurability = ship.shieldMaxDurability

    AddDefaultShipScripts(ship)

    ship:addScript("ai/patrol.lua")
    ship:addScript("story/xsotanbehaviour.lua")
    ship:setValue("is_xsotan", 1)

    return ship
end

local function attachMax(plan, attachment, dimStr)
    local self = findMaxBlock(plan, dimStr)
    local other = findMinBlock(attachment, dimStr)

    plan:addPlanDisplaced(self.index, attachment, other.index, self.box.center - other.box.center)
end

local function attachMin(plan, attachment, dimStr)
    local self = findMinBlock(plan, dimStr)
    local other = findMaxBlock(attachment, dimStr)

    plan:addPlanDisplaced(self.index, attachment, other.index, self.box.center - other.box.center)
end


function Xsotan.createPlasmaTurret()
    TurretGenerator.initialize(Seed(151))

    local turret = TurretGenerator.generate(0, 0, 0, Rarity(RarityType.Uncommon), WeaponType.PlasmaGun)
    local weapons = {turret:getWeapons()}
    turret:clearWeapons()
    for _, weapon in pairs(weapons) do
        weapon.reach = 600
        weapon.pmaximumTime = weapon.reach / weapon.pvelocity
        weapon.hullDamageMultiplicator = 0.35
        turret:addWeapon(weapon)
    end

    turret.turningSpeed = 2.0
    turret.crew = Crew()

    return turret
end

function Xsotan.createLaserTurret()
    TurretGenerator.initialize(Seed(152))

    local turret = TurretGenerator.generate(0, 0, 0, Rarity(RarityType.Exceptional), WeaponType.Laser)
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

function Xsotan.createRailgunTurret()
    TurretGenerator.initialize(Seed(153))

    local turret = TurretGenerator.generate(0, 0, 0, Rarity(RarityType.Uncommon), WeaponType.RailGun)
    local weapons = {turret:getWeapons()}
    turret:clearWeapons()
    for _, weapon in pairs(weapons) do
        weapon.reach = 1000
        turret:addWeapon(weapon)
    end

    turret.turningSpeed = 2.0
    turret.crew = Crew()

    return turret
end

function Xsotan.createGuardian(position, volumeFactor)
    position = position or Matrix()
    local volume = Balancing_GetSectorShipVolume(Sector():getCoordinates())

    volume = volume * (volumeFactor or 10)

    local x, y = Sector():getCoordinates()
    local probabilities = Balancing_GetMaterialProbability(x, y)
    local material = Material(MaterialType.Avorion)
    local faction = Xsotan.getFaction()

    local plan = PlanGenerator.makeShipPlan(faction, volume, nil, material)
    local front = PlanGenerator.makeShipPlan(faction, volume, nil, material)
    local back = PlanGenerator.makeShipPlan(faction, volume, nil, material)
    local top = PlanGenerator.makeShipPlan(faction, volume, nil, material)
    local bottom = PlanGenerator.makeShipPlan(faction, volume, nil, material)
    local left = PlanGenerator.makeShipPlan(faction, volume, nil, material)
    local right = PlanGenerator.makeShipPlan(faction, volume, nil, material)
    local frontleft= PlanGenerator.makeShipPlan(faction, volume, nil, material)
    local frontright = PlanGenerator.makeShipPlan(faction, volume, nil, material)

    Xsotan.infectPlan(plan)
    Xsotan.infectPlan(front)
    Xsotan.infectPlan(back)
    Xsotan.infectPlan(top)
    Xsotan.infectPlan(bottom)
    Xsotan.infectPlan(left)
    Xsotan.infectPlan(right)
    Xsotan.infectPlan(frontleft)
    Xsotan.infectPlan(frontright)

    --
    attachMin(plan, back, "z")
    attachMax(plan, front, "z")
    attachMax(plan, front, "z")

    attachMin(plan, bottom, "y")
    attachMax(plan, top, "y")

    attachMin(plan, left, "x")
    attachMax(plan, right, "x")

    local self = findMaxBlock(plan, "z")
    local other = findMinBlock(frontleft, "x")
    plan:addPlanDisplaced(self.index, frontleft, other.index, self.box.center - other.box.center)

    local other = findMaxBlock(frontright, "x")
    plan:addPlanDisplaced(self.index, frontright, other.index, self.box.center - other.box.center)

    Xsotan.infectPlan(plan)
    local boss = Sector():createShip(faction, "", plan, position)

    -- Xsotan have random turrets

    local numTurrets = math.max(1, Balancing_GetEnemySectorTurrets(x, y) / 2)

    ShipUtility.addTurretsToCraft(boss, Xsotan.createPlasmaTurret(), numTurrets)
    ShipUtility.addTurretsToCraft(boss, Xsotan.createLaserTurret(), numTurrets)
    ShipUtility.addTurretsToCraft(boss, Xsotan.createRailgunTurret(), numTurrets)

    boss.title = "Xsotan Wormhole Guardian"%_t
    boss.crew = boss.minCrew
    boss.shieldDurability = boss.shieldMaxDurability

    local upgrades =
    {
        {rarity = Rarity(RarityType.Legendary), amount = 2},
        {rarity = Rarity(RarityType.Exotic), amount = 3},
        {rarity = Rarity(RarityType.Exceptional), amount = 3},
        {rarity = Rarity(RarityType.Rare), amount = 5},
        {rarity = Rarity(RarityType.Uncommon), amount = 8},
        {rarity = Rarity(RarityType.Common), amount = 14},
    }

    local turrets =
    {
        {rarity = Rarity(RarityType.Legendary), amount = 2},
        {rarity = Rarity(RarityType.Exotic), amount = 3},
        {rarity = Rarity(RarityType.Exceptional), amount = 3},
        {rarity = Rarity(RarityType.Rare), amount = 5},
        {rarity = Rarity(RarityType.Uncommon), amount = 8},
        {rarity = Rarity(RarityType.Common), amount = 14},
    }


    UpgradeGenerator.initialize(random():createSeed())
    for _, p in pairs(upgrades) do
        for i = 1, p.amount do
            Loot(boss.index):insert(UpgradeGenerator.generateSystem(p.rarity))
        end
    end

    for _, p in pairs(turrets) do
        for i = 1, p.amount do
            Loot(boss.index):insert(InventoryTurret(TurretGenerator.generate(x, y, 0, p.rarity)))
        end
    end

    AddDefaultShipScripts(boss)
    boss:addScript("story/wormholeguardian.lua")
    boss:addScript("story/xsotanbehaviour.lua")
    boss:setValue("is_xsotan", 1)

    return boss
end

function Xsotan.infectAsteroids()
    local x, y = Sector():getCoordinates()

    local dist = length(vec2(x, y))
    local toInfect = lerp(dist, 150, 50, 5, 250)
    local infected = {}
    local numInfected = 0

    local asteroids = {Sector():getEntitiesByType(EntityType.Asteroid)}
    shuffle(random(), asteroids)

    while numInfected < toInfect and #asteroids > 0 do

        -- pick a random asteroid
        local asteroid = asteroids[#asteroids]
        asteroids[#asteroids] = nil

        if not infected[asteroid.index] then

            -- find surroundings
            local current = {Sector():getEntitiesByLocation(Sphere(asteroid.translationf, 60))}
            table.insert(current, asteroid)

            -- infect it and surrounding asteroids
            for _, asteroid in pairs(current) do
                if not infected[asteroid.index] then
                    Xsotan.infect(asteroid, getInt(1, 2))

                    infected[asteroid.index] = true
                    numInfected = numInfected + 1
                end
            end
        end
    end

end

function Xsotan.createSmallInfectedAsteroid(position, level)
    local probabilities = Balancing_GetMaterialProbability(Sector():getCoordinates())
    local material = Material(getValueFromDistribution(probabilities))

    local asteroid = SectorGenerator(0, 0):createSmallAsteroid(position, getFloat(5, 8), 0, material)
    return Xsotan.infect(asteroid, level)
end

function Xsotan.infectPlan(plan)
    plan:center()

    local tree = PlanBspTree(plan)

    local height = plan:getBoundingBox().size.y

    local positions = {}

    for i = 0, 15 do

        local rad = getFloat(0, math.pi * 2)
        local hspread = height / getFloat(2.5, 3.5)

        for h = -hspread, hspread, 15 do
            local ray = Ray()
            ray.origin = vec3(math.sin(rad), 0, math.cos(rad)) * 100 + vec3(getFloat(10, 100), 0, getFloat(10, 100))
            ray.direction = -ray.origin

            ray.origin = ray.origin + vec3(0, h + getFloat(-7.5, 7.5), 0)

            local dir = normalize(ray.direction)

            local index, p = tree:intersectRay(ray, 0, 1)
            if index then
                table.insert(positions, {position = p + dir, index = index})
            end
        end
    end

    local material = plan.root.material

    for _, p in pairs(positions) do
        local addition = Xsotan.makeInfectAddition(vec3(15, 4, 15), material, 0)

        addition:scale(vec3(getFloat(0.5, 2.5), getFloat(0.9, 1.1), getFloat(0.5, 2.5)))
        addition:center()

        plan:addPlanDisplaced(p.index, addition, addition.rootIndex, p.position)
    end

end

function Xsotan.createBigInfectedAsteroid(position)
    local probabilities = Balancing_GetMaterialProbability(Sector():getCoordinates())
    local material = Material(getValueFromDistribution(probabilities))

    local plan = PlanGenerator.makeBigAsteroidPlan(100, 0, material)
    Xsotan.infectPlan(plan)

    local desc = AsteroidDescriptor()
    desc:removeComponent(ComponentType.MineableMaterial)
    desc:addComponents(
       ComponentType.Owner,
       ComponentType.FactionNotifier,
       ComponentType.Title
       )

    desc.title = "Big Xsotan Breeder"%_t
    desc.position = MatrixLookUpPosition(random():getDirection(), random():getDirection(), position)
    desc:setPlan(plan)
    desc:addScript("claim.lua")
    desc.factionIndex = Xsotan.getFaction().index

    return Sector():createEntity(desc)
end

function Xsotan.infectShip(ship)

    local tree = BspTree(ship.index)
    local height = ship.size.y
    local positions = {}

    for i = 0, 25 do

        local rad = getFloat(0, math.pi * 2)
        local hspread = height / getFloat(2.5, 3.5)

        for h = -hspread, hspread, 4 do
            local ray = Ray()
            ray.origin = vec3(math.sin(rad), 0, math.cos(rad)) * 100-- + vec3(getFloat(10, 100), 0, getFloat(10, 100))
            ray.direction = -ray.origin

            ray.origin = ray.origin + vec3(0, h + getFloat(-7.5, 7.5), 0)

            local dir = normalize(ray.direction)

            local intersects, p = tree:intersectRay(ray, 0, 1)
            if intersects then
                table.insert(positions, p + dir)
            end
        end
    end

    local plan = Plan(ship.index)
    local material = plan.root.material

    for _, p in pairs(positions) do
        local addition = Xsotan.makeInfectAddition(vec3(3, 1, 3), material, 0)

        addition:scale(vec3(getFloat(0.5, 2.5), getFloat(0.9, 1.1), getFloat(0.5, 2.5)))
        addition:center()

        local attach = tree:getBlocksByBox(Box(p, vec3(0.1, 0.1, 0.1)))
        if attach then
            plan:addPlanDisplaced(attach.index, addition, addition.rootIndex, p)
        end
    end


end

function Xsotan.makeInfectAddition(size, material, level)

    level = level or 0

    local color = ColorRGB(0.35, 0.35, 0.35)

    local ls = vec3(getFloat(0.1, 0.3), getFloat(0.1, 0.3), getFloat(0.1, 0.3))
    local us = vec3(getFloat(0.1, 0.3), getFloat(0.1, 0.3), getFloat(0.1, 0.3))
    local s = vec3(1, 1, 1) - ls - us

    local hls = ls * 0.5
    local hus = us * 0.5
    local hs = s * 0.5

    local center = BlockType.BlankHull
    local edge = BlockType.EdgeHull
    local corner = BlockType.CornerHull

    local plan = BlockPlan()
    local ci = plan:addBlock(vec3(0, 0, 0), s, -1, -1, color, material, Matrix(), center)

    -- top left right
    plan:addBlock(vec3(hs.x + hus.x, 0, 0), vec3(us.x, s.y, s.z), ci, -1, color, material, MatrixLookUp(vec3(-1, 0, 0), vec3(0, 1, 0)), edge)
    plan:addBlock(vec3(-hs.x - hls.x, 0, 0), vec3(ls.x, s.y, s.z), ci, -1, color, material, MatrixLookUp(vec3(1, 0, 0), vec3(0, 1, 0)), edge)

    -- top front back
    plan:addBlock(vec3(0, 0, hs.z + hus.z), vec3(s.x, s.y, us.z), ci, -1, color, material, MatrixLookUp(vec3(0, 0, -1), vec3(0, 1, 0)), edge)
    plan:addBlock(vec3(0, 0, -hs.z - hls.z), vec3(s.x, s.y, ls.z), ci, -1, color, material, MatrixLookUp(vec3(0, 0, 1), vec3(0, 1, 0)), edge)

    -- top edges
    -- left right
    plan:addBlock(vec3(hs.x + hus.x, 0, -hs.z - hls.z), vec3(us.x, s.y, ls.z), ci, -1, color, material, MatrixLookUp(vec3(-1, 0, 0), vec3(0, 1, 0)), corner)
    plan:addBlock(vec3(-hs.x - hls.x, 0, -hs.z - hls.z), vec3(ls.x, s.y, ls.z), ci, -1, color, material, MatrixLookUp(vec3(1, 0, 0), vec3(0, 0, -1)), corner)

    -- front back
    plan:addBlock(vec3(hs.x + hus.x, 0, hs.z + hus.z), vec3(us.x, s.y, us.z), ci, -1, color, material, MatrixLookUp(vec3(-1, 0, 0), vec3(0, 0, 1)), corner)
    plan:addBlock(vec3(-hs.x - hls.x, 0, hs.z + hus.z), vec3(ls.x, s.y, us.z), ci, -1, color, material, MatrixLookUp(vec3(1, 0, 0), vec3(0, 1, 0)), corner)

    plan:scale(size)

    local addition = copy(plan)
    addition:displace(vec3(size.x * 0.05, -size.y * getFloat(0.6, 0.9), size.z * 0.05))

    if level >= 1 then
        local displacement = vec3(
            size.x * getFloat(0.1, 0.2),
            0,
            size.z * getFloat(0.1, 0.2)
        )

        addition:addPlanDisplaced(addition.rootIndex, plan, 0, displacement)
    end
    if level >= 2 then
        local displacement = vec3(
            size.x * getFloat(0.2, 0.3),
            size.y * getFloat(0.6, 0.9),
            size.z * getFloat(0.2, 0.3)
        )

        addition:addPlanDisplaced(addition.rootIndex, plan, 0, displacement)
    end

    return addition
end

function Xsotan.infect(asteroid, level)

    local material = Plan(asteroid.index).root.material

    local size = asteroid.size
    size.y = size.y * 0.25

    local addition = Xsotan.makeInfectAddition(size, material, level)

    local desc = AsteroidDescriptor()
    desc:removeComponent(ComponentType.MineableMaterial)
    desc:addComponents(
       ComponentType.Owner,
       ComponentType.FactionNotifier,
       ComponentType.Title
    )

    local plan = asteroid:getPlan()
    plan:addPlan(plan.rootIndex, addition, 0)

    desc:setPlan(plan)
    desc.position = asteroid.position
    desc.title = "Small Xsotan Breeder"%_t
    desc.factionIndex = Xsotan.getFaction().index

    Sector():deleteEntity(asteroid)
    return Sector():createEntity(desc)
end

return Xsotan
