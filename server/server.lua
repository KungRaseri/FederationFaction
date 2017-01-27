package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/server/?.lua"
require ("factions")
require ("randomext")
require ("stringutility")

function onStartUp()
    Server():registerCallback("onPlayerLogIn", "onPlayerLogIn")
    Server():registerCallback("onPlayerLogOff", "onPlayerLogOff")
    Galaxy():registerCallback("onPlayerCreated", "onPlayerCreated")
    Galaxy():registerCallback("onFactionCreated", "onFactionCreated")
    Server():setValue("federation", createFederation(Server().seed))
end

function onShutDown()

end

function update(timeStep)
    local guardianRespawnTime = Server():getValue("guardian_respawn_time")
    if guardianRespawnTime then

        guardianRespawnTime = guardianRespawnTime - timeStep;
        if guardianRespawnTime < 0 then
            guardianRespawnTime = nil
        end

        Server():setValue("guardian_respawn_time", guardianRespawnTime)
    end

end

function onPlayerCreated(index)
    local player = Player(index)
    Server():broadcastChatMessage("Server", 0, "Player %s created!"%_t, player.name)
end

function onFactionCreated(index)

end

function onPlayerLogIn(playerIndex)
    local player = Player(playerIndex)
    Server():broadcastChatMessage("Server", 0, "Player %s joined the galaxy"%_t, player.name)
    player:addScriptOnce("headhunter.lua")
    player:addScriptOnce("eventscheduler.lua")
    player:addScriptOnce("story/spawnswoks.lua")
    player:addScriptOnce("story/spawnai.lua")
    player:addScriptOnce("story/spawnguardian.lua")
    player:addScriptOnce("story/spawnadventurer.lua")

    matchResources(player)
end

function onPlayerLogOff(playerIndex)
    local player = Player(playerIndex)
    Server():broadcastChatMessage("Server", 0, "Player %s left the galaxy"%_t, player.name)

end

function createFederation(seed)
    local min = -49
    local max = 50
    local random = Random(seed)
    local x = random:getInt(min, max)
    local y = random:getInt(min, max)
    local faction = Galaxy():createFaction("Federation of Engineers", x, y)
    faction.initialRelationsToPlayer = 0
    faction.initialRelations = 0
    faction.staticRelationsToAI = true

    faction:getInventory():clear()
    TurretGenerator.initialize(seed+faction.index)

    local x, y = faction:getHomeSectorCoordinates()
    local armed1 = TurretGenerator.generate(x, y, 0, Rarity(RarityType.Exotic), WeaponType.TeslaGun)
    local armed2 = TurretGenerator.generate(x, y, 0, Rarity(RarityType.Exotic), WeaponType.LightningGun)
    local unarmed1 = TurretGenerator.generate(x, y, 0, Rarity(RarityType.Legendary), WeaponType.MiningLaser)

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
    faction:setTrait("opportunistic"%_T,-.25)
    faction:setTrait("honorable"%_T, .25)

    faction:setTrait("peaceful"%_T,.9)
    faction:setTrait("aggressive"%_T, -.9)

    faction:setTrait("paranoid"%_T, -.25)
    faction:setTrait("brave"%_T, .25)

    faction:setTrait("active"%_T, 1.0)
    faction:setTrait("passive"%_T, -1.0)

    faction:setTrait("generous"%_T, .25)
    faction:setTrait("greedy"%_T, -.25)

    faction:setTrait("smart"%_T, 1.0)
    faction:setTrait("dumb"%_T, -1.0)

    faction:setTrait("mistrustful"%_T, .5)
    faction:setTrait("naive"%_T, -.5)

    faction:setTrait("sadistic"%_T, .5)
    faction:setTrait("empathic"%_T, -.5)

    faction:setTrait("forgiving"%_T, -.75)
    faction:setTrait("strict"%_T, .75)
    print(faction.index)
    return faction.index
end

