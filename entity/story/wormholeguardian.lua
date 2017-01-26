package.path = package.path .. ";data/scripts/lib/?.lua"

require ("randomext")
require ("stringutility")
Xsotan = require ("story/xsotan")
Placer = require ("placer");
ShipGenerator = require("shipgenerator")

-- variables are all non-local so the tests have access
shieldDurability = 0

spawningStateDuration = 60 -- seconds that the wormhole will be open
spawningStateTime = 0
shieldLoss = 0.1
spawnAllyFrequency = 7.5
spawnAllyTime = 0
spawnPlayerAllyFrequency = 15.0
spawnPlayerAllyTime = 0

channelStateTime = 0
channelDuration = 15
channelingPlayers = {}

playerWormholes = {}
xsotanWormholes = {}

playerAlliesSpawned = {}

channelLaser = nil
lasers = {}
playerChannelLasers = {}

local State =
{
    Fighting = 0,
    Channeling = 1,
    Spawning = 2,
}

state = State.Fighting

local time = 0

function initialize()
    shieldDurability = Entity().shieldMaxDurability

    if onClient() then
        registerBoss(Entity().index)
    end

    if onServer() then
        Entity():registerCallback("onDestroyed", "onDestroyed")
    end
end

if onServer() then
function getUpdateInterval()
    return 0.25
end
end

if onClient() then
function getUpdateInterval()
    return 0.033
end
end

function onDestroyed()
    Server():setValue("guardian_respawn_time", 60 * 60)
end

function hasAllies()
    local allies = {Sector():getEntitiesByFaction(Entity().factionIndex)}

    local self = Entity()
    for _, ally in pairs(allies) do
        if ally.index ~= self.index and ally:hasComponent(ComponentType.Plan) and ally:hasComponent(ComponentType.ShipAI) then
            return true
        end
    end

    return false
end

function aggroAllies()
    local allies = {Sector():getEntitiesByFaction(Entity().factionIndex)}

    local players = {Sector():getPlayers()}
    for _, ally in pairs(allies) do
        if ally:hasComponent(ComponentType.Plan) and ally:hasComponent(ComponentType.ShipAI) then

            local ai = ShipAI(ally.index)
            for _, player in pairs(players) do
                ai:registerEnemyFaction(player.index)
            end
        end
    end

    return false
end

function setFighting()
    shieldDurability = Entity().shieldDurability
    ShipAI():setAggressive()

    for player, _ in pairs(channelingPlayers) do
        playerAlliesSpawned[player] = true
    end

    channelingPlayers = {}
    xsotanWormholes = {}
    playerWormholes = {}

    state = State.Fighting
end

function setChanneling()
    channelStateTime = 0
    state = State.Channeling
    createChannelBeam()

    Sector():broadcastChatMessage("", 2, "The guardian is starting to channel the black hole's energy!"%_t)
end

function setSpawning()
    spawningStateTime  = 0
    spawnAllyTime = 0
    spawnPlayerAllyTime = 0

    state = State.Spawning
end

function channel(timePassed)
    ShipAI():setPassive()
    Entity():damageShield(timePassed / (spawningStateDuration + channelDuration) * shieldLoss * Entity().shieldMaxDurability, vec3(), -1)
end

function morePlayerWormholes()
    if tablelength(playerWormholes) < tablelength(channelingPlayers) then
        return true
    end

    -- as long as not every channeling player has at least 10 wormholes, continue creating them
    for _, wormholes in pairs(playerWormholes) do
        if #wormholes < 10 then return true end
    end

    return false
end

function updateServer(timePassed)

    time = time + timePassed

    if state == State.Fighting then
        -- while he's fighting, his shield is invulnerable
        Entity().shieldDurability = shieldDurability

        -- once he has no more allies, he will go into the channeling state
        if not hasAllies() then
            setChanneling()
        end

    elseif state == State.Channeling then
        channel(timePassed)

        channelStateTime = channelStateTime + timePassed

        if channelStateTime > channelDuration then
            setSpawning()
        end

    elseif state == State.Spawning then

        spawnAllyTime = spawnAllyTime + timePassed
        spawnPlayerAllyTime = spawnPlayerAllyTime + timePassed
        spawningStateTime  = spawningStateTime  + timePassed

        channel(timePassed)

        if morePlayerWormholes() then
            createPlayerWormhole()
        end

        if #xsotanWormholes < 15 then
            createXsotanWormhole()
        end

        local usedFrequency = spawnAllyFrequency
        if Sector().numPlayers > 1 then
            usedFrequency = usedFrequency / (Sector().numPlayers * 1.25)
        end

        while spawnAllyTime > usedFrequency do
            createXsotan()
            spawnAllyTime = spawnAllyTime - usedFrequency
        end

        if spawnPlayerAllyTime > spawnPlayerAllyFrequency then
            createPlayerAllies()
            spawnPlayerAllyTime = spawnPlayerAllyTime - spawnPlayerAllyFrequency
        end

        if spawningStateTime > spawningStateDuration then
            setFighting()
        end

    end

    aggroAllies()
end

function createXsotan()
    if #xsotanWormholes == 0 then return end

    -- pick a random wormhole
    local wormhole = xsotanWormholes[random():getInt(1, #xsotanWormholes)]

    if not valid(wormhole) then return end

    local spawn = 1
    local spawned = {}
    for i = 1, spawn do
        local ally
        if Entity().durability < Entity().maxDurability * 0.75 and random():getInt(1, 2) == 1 then
            ally = Xsotan.createCarrier(wormhole.position, 2.0, 5)
        else
            ally = Xsotan.createShip(wormhole.position, 1.0)
        end

        table.insert(spawned, ally)
    end

    Placer.resolveIntersections(spawned)
    aggroAllies()
end

function createPlayerAllies()
    local spawned = {}

    for playerIndex, wormholes in pairs(playerWormholes) do

        if playerAlliesSpawned[playerIndex] then goto continue1 end
        playerAlliesSpawned[playerIndex] = true

        local player = Player(playerIndex)

        -- spawn all allies of the player at once
        -- get all allies
        local ok, allies = player:invokeFunction("organizedallies.lua", "getAllies")
        if not allies then goto continue1 end

        for _, p in pairs(allies) do
            local factionIndex = p.factionIndex
            local amount = p.amount

            local faction = Faction(factionIndex)
            if not faction then goto continue2 end

            -- pick a random wormhole
            local wormhole = wormholes[random():getInt(1, #wormholes)]

            for i = 1, amount do
                local ally = ShipGenerator.createDefender(faction, wormhole.position)
                ally:addScript("entity/story/wormholeguardianally.lua")
                table.insert(spawned, ally)
            end

            ::continue2::
        end

        ::continue1::
    end

    Placer.resolveIntersections(spawned)
end

function createXsotanWormhole()
    -- print ("create Xsotan Wormhole, time: " .. time)

    local wormhole = createWormhole(Entity().translationf)

    table.insert(xsotanWormholes, wormhole)

    createBeam(Entity().index, wormhole.index, ColorRGB(1.0, 0.1, 0.1))
end

function createPlayerWormhole()
    for playerIndex, _ in pairs(channelingPlayers) do
        local player = Player(playerIndex)

        local ship = Entity(player.craftIndex)
        if ship then
            local wormhole = createWormhole(ship.translationf)

            playerWormholes[playerIndex] = playerWormholes[playerIndex] or {}
            table.insert(playerWormholes[playerIndex], wormhole)

            createBeam(ship.index, wormhole.index, ColorRGB(0.1, 0.1, 1.0))
        end
    end
end

function createWormhole(center)
    center = center or vec3()

    -- spawn a wormhole
    local desc = WormholeDescriptor()
    desc:removeComponent(ComponentType.EntityTransferrer)
    desc:addComponents(ComponentType.DeletionTimer)
    desc.position = MatrixLookUpPosition(vec3(0, 1, 0), vec3(1, 0, 0), center + random():getDirection() * random():getFloat(500, 750))

    local size = random():getFloat(75, 150)

    local wormhole = desc.cpwormhole
    wormhole:setTargetCoordinates(random():getInt(-400, 400), random():getInt(-400, 400))
    wormhole.visible = true
    wormhole.visualSize = size
    wormhole.passageSize = size
    wormhole.oneWay = true
    wormhole.simplifiedVisuals = true

    local wormhole = Sector():createEntity(desc)

    local timer = DeletionTimer(wormhole.index)
    timer.timeLeft = spawningStateDuration

    return wormhole
end

function createBeam(fromIndex, toIndex, color)
    if onServer() then
        broadcastInvokeClientFunction("createBeam", fromIndex, toIndex, color)
        return
    end

    local a = Entity(fromIndex)
    local b = Entity(toIndex)

    if not a or not b then return end

    local laser = Sector():createLaser(a.translationf, b.translationf, color, 5.0)

    local fromLocal = vec3()
    local toLocal = vec3()

    local planA = Plan(fromIndex)
    local planB = Plan(toIndex)
    if planA then fromLocal = planA.root.box.center end
    if planB then toLocal = planB.root.box.center end

    laser.maxAliveTime = 8.0
    laser.animationSpeed = -500
    laser.collision = false

    table.insert(lasers, {laser = laser, fromIndex = fromIndex, toIndex = toIndex, fromLocal = fromLocal, toLocal = toLocal})
end

function createChannelBeam()
    if onServer() then
        broadcastInvokeClientFunction("createChannelBeam")
        return
    end

    local dir = vec3(1, 0, 0)
    local planet = Planet(0)
    if planet then
        dir = normalize(planet.position.translation)
    end

    channelLaser = Sector():createLaser(vec3(), dir * 500000, ColorRGB(0.9, 0.6, 0.2), 25.0)

    channelLaser.maxAliveTime = channelDuration
    channelLaser.collision = false
end

function createPlayerChannelBeam(craftIndex)
    if onServer() then
        broadcastInvokeClientFunction("createPlayerChannelBeam", craftIndex)
        return
    end

    local ship = Entity(craftIndex)
    if not ship then return end

    local laser = Sector():createLaser(Entity().translationf, ship.translationf, ColorRGB(0.9, 0.6, 0.2), 25.0)

    laser.maxAliveTime = channelDuration
    laser.collision = false

    table.insert(playerChannelLasers, {laser = laser, index = craftIndex})
end

function channelPlayer()
    if onClient() then
        invokeServerFunction("channelPlayer")
        return true
    end

    if state == State.Channeling then
        local player = Player(callingPlayer)

        createPlayerChannelBeam(player.craftIndex)
        channelingPlayers[player.index] = true
    end
end

function updateClient(timeStep)

    local position = Entity().position
    local rootPosition = Plan().root.box.center
    local beamOrigin = position:transformCoord(rootPosition)

    registerBoss(Entity().index)

    -- update the positions of the guardian - black hole channeling laser
    if valid(channelLaser) then
        local dir = vec3(1, 0, 0)
        local planet = Planet(0)
        if planet then
            dir = normalize(planet.position.translation)
        end

        channelLaser.from = beamOrigin
        channelLaser.to = dir * 500000
    end

    -- update the positions of the guardian - wormhole lasers
    for k, p in pairs(lasers) do
        local laser = p.laser
        local a = Entity(p.fromIndex)
        local b = Entity(p.toIndex)

        local from = a.position:transformCoord(p.fromLocal)
        local to = b.position:transformCoord(p.toLocal)

        if valid(laser) and a and b then
            laser.from = from
            laser.to = to
        else
            lasers[k] = nil
        end
    end

    -- update the positions of the guardian - player channeling lasers
    for k, p in pairs(playerChannelLasers) do
        local laser = p.laser
        local ship = Entity(p.index)

        if valid(laser) and valid(ship) then
            laser.to = beamOrigin
            laser.from = ship.translationf
        else
            if valid(laser) then Sector():removeLaser(laser) end
            playerChannelLasers[k] = nil
        end
    end

end


