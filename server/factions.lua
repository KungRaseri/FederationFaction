package.path = package.path .. ";data/scripts/lib/?.lua"
require ("randomext")
require ("galaxy")
UpgradeGenerator = require("upgradegenerator")
TurretGenerator = require("turretgenerator")

local distFromCenter = 450.0
local distBetweenPlayers = 3 -- distance between the home sectors of different players

function initializeAIFaction(faction)

    local seed = Server().seed + faction.index
    local random = Random(seed)

    function createRandomTrait(trait, contrary)
        local a = random:getFloat(-1.0, 1.0)
        local b = -a

        faction:setTrait(trait, a)
        faction:setTrait(contrary, b)
    end

    TurretGenerator.initialize(seed)

    local x, y = faction:getHomeSectorCoordinates()
    local armed1 = TurretGenerator.generateArmed(x, y, 0, Rarity(RarityType.Common))
    local armed2 = TurretGenerator.generateArmed(x, y, 0, Rarity(RarityType.Common))
    local unarmed1 = TurretGenerator.generate(x, y, 0, Rarity(RarityType.Common), WeaponType.MiningLaser)

    -- make sure the armed turrets don't have a too high fire rate
    -- so they don't slow down update times too much when there's lots of firing going on
    for _, turret in pairs({armed1, armed2}) do

        local weapons = {turret:getWeapons()}
        turret:clearWeapons()

        for _, weapon in pairs(weapons) do

            if weapon.isProjectile and weapon.fireRate > 2 then
                local old = weapon.fireRate
                weapon.fireRate = math.random(1.0, 2.0)
                weapon.damage = weapon.damage * old / weapon.fireRate;
            end

            turret:addWeapon(weapon)
        end
    end

    faction:getInventory():add(armed1)
    faction:getInventory():add(armed2)
    faction:getInventory():add(unarmed1)

    createRandomTrait("opportunistic"%_T, "honorable"%_T)
    createRandomTrait("aggressive"%_T, "peaceful"%_T)
    createRandomTrait("paranoid"%_T, "brave"%_T)
    createRandomTrait("active"%_T, "passive"%_T)
    createRandomTrait("greedy"%_T, "generous"%_T)
    createRandomTrait("dumb"%_T, "smart"%_T)
    createRandomTrait("mistrustful"%_T, "naive"%_T)
    createRandomTrait("sadistic"%_T, "empathic"%_T)
    createRandomTrait("forgiving"%_T, "strict"%_T)

end

function initializePlayer(player)

    local galaxy = Galaxy()
    local server = Server()

    local random = Random(server.seed)

    -- get a random angle, fixed for the server seed
    local angle = random:getFloat(2.0 * math.pi)


    -- for each player registered, add a small amount on top of this angle
    -- this way, all players are near each other
    local home = {x = 0, y = 0}

    if server.sameStartSector then
        home.x = math.cos(angle) * distFromCenter
        home.y = math.sin(angle) * distFromCenter
    else
        local delta = player.index * (distBetweenPlayers / distFromCenter)

        angle = angle + delta

        for i = 1, 1000 do
            angle = angle + (1.0 / distFromCenter)

            home.x = math.cos(angle) * distFromCenter
            home.y = math.sin(angle) * distFromCenter

            -- try to create a sector, if it failed, restart
            if not galaxy:sectorExists(home.x, home.y) then
                break
            end
        end

    end

    player:setHomeSectorCoordinates(home.x, home.y)

    -- make sure the player has an early ally
    local faction = Galaxy():getNearestFaction(home.x, home.y)
    faction:setValue("enemy_faction", -1) -- this faction doesn't participate in faction wars
    Galaxy():setFactionRelations(faction, player, 75000)
    player:setValue("start_ally", faction.index)

    local random = Random(getSectorSeed(home.x, home.y) + player.index)

    if server.difficulty == Difficulty.Beginner then
        player:receive(40000, 5000)
    elseif server.difficulty == Difficulty.Easy then
        player:receive(20000, 2000)
    else
        player:receive(10000)
    end

    -- create turret generator
    local dps, tech = Balancing_GetSectorWeaponDPS(450, 0)
    local turret = InventoryTurret(GenerateTurretTemplate(random:createSeed(), WeaponType.ChainGun, dps, tech, Rarity(RarityType.Uncommon), Material(MaterialType.Iron)))
    player:getInventory():add(turret)
    player:getInventory():add(turret)

    local dps, tech = Balancing_GetSectorMiningDPS(450, 0)
    local turret = InventoryTurret(GenerateTurretTemplate(random:createSeed(), WeaponType.MiningLaser, dps, tech, Rarity(RarityType.Uncommon), Material(MaterialType.Iron)))
    player:getInventory():add(turret)
    player:getInventory():add(turret)

    player:createShipStyle("TestStyle")

end

function matchResources(player)

    player.infiniteResources = Server().infiniteResources
    if player.infiniteResources then
        -- unlock all colors as well
        for _, color in pairs({ColorPalette()}) do
            player:addColor(color)
        end
    end

    -- add colors if player has none
    if player.numColors == 0 then
        -- add basic colors
        player:addColor(ColorInt(0xffff0000)) -- red
        player:addColor(ColorInt(0xff00ff00)) -- green
        player:addColor(ColorInt(0xff0000ff)) -- blue
        player:addColor(ColorInt(0xffffff00)) -- yellow
        player:addColor(ColorInt(0xff00ffff)) -- turquoise
        player:addColor(ColorInt(0xffff00ff)) -- magenta
        player:addColor(ColorInt(0xff696969)) -- dim grey

        -- add random colors
        local palette = {ColorPalette()}
        for i = 1, 30 do
            local i = random():getInt(1, #palette)
            player:addColor(palette[i])
        end
    end
end
