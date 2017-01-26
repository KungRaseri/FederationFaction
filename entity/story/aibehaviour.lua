package.path = package.path .. ";data/scripts/lib/?.lua"

TurretGenerator = require ("turretgenerator")
ShipUtility = require ("shiputility")
AI = require ("story/ai")
require ("randomext")
require ("stringutility")

local angry = 0


function initialize()
    if onServer() then
        local entity = Entity()
        entity:registerCallback("onBreak", "onBreak")
        entity:registerCallback("onDamaged" , "onDamaged")
        entity:registerCallback("onShieldDamaged" , "onShieldDamaged")
        Sector():addScriptOnce("story/aihealthbar.lua")
    end

end


function getUpdateInterval()
    time = time or math.random() * 0.5 + 0.5
    return time
end

function updateServer(timeStep)

    -- self destruct when it becomes too small
    local plan = Plan()
    if plan.numBlocks > 0 and plan.numBlocks <= 3 then
        local entity = Entity()
        entity:destroy(-1)
    end

    -- while it's not angry, it's got all power routed to its shield
    if angry == 0 then
        local entity = Entity()
        entity.shieldDurability = entity.shieldMaxDurability

        -- if there are multiple instances of the AI, the fight has begun and it should be angry, always
        local ais = {Sector():getEntitiesByFaction(entity.factionIndex)}
        if #ais > 1 then
            setAngry()
        end
    end
end

function onBreak(entityIndex, ...)
    local entity = Entity(entityIndex)

    setAngry()

    local parts = {...}
    for _, newPlan in pairs(parts) do

        newPlan.accumulatingHealth = false

        local root = newPlan:getNthBlock(0)
        local box = root.box

        -- calculate new relative position of the wreck
        -- Matrix wreckPosition = mut::translate(Matrix(), box.position + (newPlan.centerOfMass - box.position));
        local wreckPosition = Matrix()
        wreckPosition.translation = box.position + (newPlan.centerOfMass - box.position)

        -- desc->get<Position>().setWorldMatrix(wreckPosition * position.getWorldMatrix());
        wreckPosition = wreckPosition * entity.position

        -- displace the wreck plan so it will match with the new position
        newPlan:displace(-(box.position + (newPlan.centerOfMass - box.position)));

        if newPlan.numBlocks >= 8 then

            local desc = ShipDescriptor()

            desc.position = wreckPosition
            desc.factionIndex = entity.factionIndex
            desc:setPlan(newPlan)
            desc:addScriptOnce("story/aibehaviour")
            desc:addScriptOnce("deleteonplayersleft")
            desc.title = "The AI"%_T
            desc.name = ""

            -- finally create the "wreck"
            local child = Sector():createEntity(desc);

            local numTurrets = newPlan.numBlocks / 25 + 1
            AI.addTurrets(child, numTurrets)

            child.shieldDurability = child.shieldMaxDurability * math.random()

            WreckageCreator(child.index).active = false
            child:invokeFunction("story/aibehaviour.lua", "setAngry")

        elseif newPlan.numBlocks >= 3 then

            local desc = WreckageDescriptor()

            desc.position = wreckPosition
            desc:setPlan(newPlan)

            -- finally create the wreck
             Sector():createEntity(desc);

        end

    end
end

function setAngry()
    angry = 1

    -- when it gets angry, it starts attacking all players
    local ai = ShipAI()
    ai:setAggressive()

    local players = {Sector():getPlayers()}
    for _, player in pairs(players) do
        ai:registerEnemyFaction(player.index)
    end
end


local damageUntilAngry = 10000
local damages = {}

function registerDamage(damage, inflictor)

    inflictor = inflictor or 0

    local received = damages[inflictor] or 0
    received = received + damage
    damages[inflictor] = received

    if received > damageUntilAngry then
        ShipAI():registerEnemyEntity(inflictor)

        setAngry()
    end
end

function onDamaged(entityIndex, damage, inflictor)
    registerDamage(damage, inflictor)
end

function onShieldDamaged(entityIndex, damage, inflictor)
    registerDamage(damage, inflictor)
end

function secure()
    return {angry = angry}
end

function restore(data)
    angry = data.angry
end
