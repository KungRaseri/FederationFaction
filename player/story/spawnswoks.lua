if onServer() then

package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"
require ("randomext")
require ("utility")
SectorSpecifics = require ("sectorspecifics")
PirateGenerator = require ("pirategenerator")
TurretGenerator = require ("turretgenerator")

local consecutiveJumps = 0
local noSpawnTimer = 0

function initialize()
    Player():registerCallback("onSectorEntered", "onSectorEntered")
end

function update()

end

function piratePosition()
    local pos = random():getVector(-1000, 1000)
    return MatrixLookUpPosition(-pos, vec3(0, 1, 0), pos)
end

function onSectorEntered(player, x, y)

    if noSpawnTimer > 0 then return end

    local dist = length(vec2(x, y))
    local spawn

    if dist > 380 and dist < 430 then
        local specs = SectorSpecifics()
        local regular, offgrid, blocked, home = specs:determineContent(x, y, Server().seed)

        if not regular and not offgrid and not blocked and not home then
            if math.random() < 0.05 or consecutiveJumps > 8 then
                spawn = true
                -- on spawn reset the jump counter
                consecutiveJumps = 0
            else
                consecutiveJumps = consecutiveJumps + 1
            end
        else
            -- when jumping into the "wrong" sector, reset the jump counter
            consecutiveJumps = 0
        end
    end

    if not spawn then return end

    spawnEnemies(Player(player), x, y)

end

function spawnEnemies(player, x, y)
    local bossBeaten = Server():getValue("swoks_beaten") or 2
    local number = bossBeaten + 1

    -- spawn
    local boss = PirateGenerator.createBoss(piratePosition())
    boss:setTitle("Boss Swoks ${num}"%_T, {num = toRomanLiterals(number)})

    pirates = {}
    table.insert(pirates, boss)
    table.insert(pirates, PirateGenerator.createMarauder(piratePosition()))
    table.insert(pirates, PirateGenerator.createPirate(piratePosition()))
    table.insert(pirates, PirateGenerator.createBandit(piratePosition()))
    table.insert(pirates, PirateGenerator.createBandit(piratePosition()))
    table.insert(pirates, PirateGenerator.createBandit(piratePosition()))

    boss:registerCallback("onDestroyed", "onBossDestroyed")

    Loot(boss.index):insert(InventoryTurret(TurretGenerator.generate(x, y, 0, Rarity(RarityType.Exotic))))
    Loot(boss.index):insert(SystemUpgradeTemplate("data/scripts/systems/teleporterkey3.lua", Rarity(RarityType.Legendary), Seed()))

    for _, pirate in pairs(pirates) do
        ShipAI(pirate.index):registerFriendFaction(player.index)
        pirate:addScript("deleteonplayersleft.lua")
    end

    boss:addScript("story/swoks.lua")
    boss:setValue("is_pirate", 1)

end

function onBossDestroyed()

    local beaten = Server():getValue("swoks_beaten") or 2
    beaten = beaten + 1

    Server():setValue("swoks_beaten", beaten)

    print (string.format("swoks was beaten for the %i. time!", beaten))

    noSpawnTimer = 30 * 60
end

function getUpdateInterval()
    return 60
end

function updateServer(timeStep)
    noSpawnTimer = noSpawnTimer - timeStep
end




function secure()

end

function restore()

end


end
