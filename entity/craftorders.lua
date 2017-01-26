
package.path = package.path .. ";data/scripts/lib/?.lua"

require ("stringutility")
local AIAction =
{
    Escort = 1,
    Attack = 2,
    FlyThroughWormhole = 3,
    FlyToPosition = 4
}

-- variables for strategy state
targetAction = nil
targetIndex = nil
targetPosition = nil

-- variables for finding the entity index after a sector change
targetFaction = nil
targetName = nil

function setAIAction(action, index, position)
    targetAction = action
    targetIndex = index
    targetPosition = position

    local entity = Entity(targetIndex)
    if entity then
        targetFaction = entity.factionIndex
        targetName = entity.name
    end

    if onServer() then
        local player = Player()
        if player then
            invokeClientFunction(player, "setAIAction", action, index, position)
        end
    end
end

function onSectorChanged()
    -- only required on server, client script gets newly created when changing the sector
    local entity
    if targetName then
        -- find new entity index
        entity = Sector():getEntityByFactionAndName(targetFaction, targetName)
    end
    if not entity or entity.index == -1 then
        targetAction = nil
        targetIndex = nil
        targetPosition = nil
        return
    end

    targetIndex = entity.index
end

function initialize()
    if onClient() then
        sync()
    end
end

function sync(dataIn)
    if onClient() then
        if dataIn then
            targetAction = dataIn.action
            targetFaction = dataIn.faction
            targetName = dataIn.name
            targetIndex = dataIn.index
            targetPosition = dataIn.position
        else
            invokeServerFunction("sync")
        end
    else
        assert(callingPlayer)

        local data = {
            action = targetAction,
            faction = targetFaction,
            name = targetName,
            index = targetIndex,
            position = targetPosition
        }
        invokeClientFunction(Player(callingPlayer), "sync", data)
    end
end

-- if this function returns false, the script will not be listed in the interaction window,
-- even though its UI may be registered
function interactionPossible(playerIndex, option)
    -- giving the own craft orders does not work
    if Entity().index == Player().craftIndex then
        return false
    end

    -- ordering other crafts can only work on your own crafts
    if Faction().index ~= playerIndex then
        return false
    end

    return true
end

-- create all required UI elements for the client side
function initUI()

    local res = getResolution()
    local size = vec2(250, 290)

    local menu = ScriptUI()
    local window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
    menu:registerWindow(window, "Orders"%_t)

    window.caption = "Craft Orders"%_t
    window.showCloseButton = 1
    window.moveable = 1

    local splitter = UIHorizontalMultiSplitter(Rect(window.size), 10, 10, 6)

    window:createButton(splitter:partition(0), "Idle"%_t, "onIdleButtonPressed")
    window:createButton(splitter:partition(1), "Passive"%_t, "onPassiveButtonPressed")
    window:createButton(splitter:partition(2), "Guard This Position"%_t, "onGuardButtonPressed")
    window:createButton(splitter:partition(3), "Patrol Sector"%_t, "onPatrolButtonPressed")
    window:createButton(splitter:partition(4), "Escort Me"%_t, "onEscortMeButtonPressed")
    window:createButton(splitter:partition(5), "Attack Enemies"%_t, "onAttackEnemiesButtonPressed")
    window:createButton(splitter:partition(6), "Mine"%_t, "onMineButtonPressed")
    --window:createButton(Rect(10, 250, 230 + 10, 30 + 250), "Attack My Targets", "onWingmanButtonPressed")

end

function checkCaptain()
    local entity = Entity()

    if callingPlayer and entity.factionIndex then
        if callingPlayer ~= entity.factionIndex then
            return
        end
    end

    local captains = entity:getCrewMembers(CrewProfessionType.Captain)
    if captains and captains > 0 then
        return true
    end

    local faction = Faction()
    if faction.isPlayer then
        Player():sendChatMessage("", 1, "Your ship has no captain!"%_t)
    end
end

function onIdleButtonPressed()
    if onClient() then
        invokeServerFunction("onIdleButtonPressed")
        ScriptUI():stopInteraction()
        return
    end

    if checkCaptain() then
        local ai = ShipAI()
        ai:setIdle()

        removeSpecialOrders()
    end
end

function onPassiveButtonPressed()
    if onClient() then
        invokeServerFunction("onPassiveButtonPressed")
        ScriptUI():stopInteraction()
        return
    end

    if checkCaptain() then
        local ai = ShipAI()
        ai:setPassive()

        removeSpecialOrders()
    end
end

function onGuardButtonPressed()
    if onClient() then
        invokeServerFunction("onGuardButtonPressed")
        ScriptUI():stopInteraction()
        return
    end

    if checkCaptain() then
        local ai = ShipAI()
        ai:setGuard(ship.translationf)

        removeSpecialOrders()
    end
end


function onEscortMeButtonPressed(index)
    if onClient() then
        local ship = Player().craft
        if ship == nil then return end

        invokeServerFunction("onEscortMeButtonPressed", ship.index)
        ScriptUI():stopInteraction()
        return
    end

    if checkCaptain() then
        local ai = ShipAI()
        ai:setEscort(Entity(index))

        removeSpecialOrders()
    end
end

function escortEntity(index)
    if onClient() then
        invokeServerFunction("escortEntity", index)
        return
    end

    if checkCaptain() then
        local ai = ShipAI()
        ai:setEscort(Entity(index))
        setAIAction(AIAction.Escort, index)

        removeSpecialOrders()
    end
end

function attackEntity(index)
    if onClient() then
        invokeServerFunction("attackEntity", index);
        return
    end

    if checkCaptain() then
        local ai = ShipAI()
        ai:setAttack(Entity(index))
        setAIAction(AIAction.Attack, index)

        removeSpecialOrders()
    end
end

function flyToPosition(pos)
    if onClient() then
        invokeServerFunction("flyToPosition", pos);
        return
    end

    if checkCaptain() then
        removeSpecialOrders()

        local ai = ShipAI()
        ai:setFly(pos, 0)
        setAIAction(AIAction.FlyToPosition, nil, pos)
    end
end

function flyThroughWormhole(index)
    if onClient() then
        invokeServerFunction("flyThroughWormhole", index);
        return
    end

    if checkCaptain() then
        removeSpecialOrders()

        local ship = Entity()
        local target = Entity(index)

        if target:hasComponent(ComponentType.Plan) then
            -- gate
            local entryPos
            local flyThroughPos
            local waypoints = {}

            -- determine best direction for entering the gate
            if dot(target.look, ship.translationf - target.translationf) > 0 then
                entryPos = target.translationf + target.look * ship:getBoundingSphere().radius * 10
                flyThroughPos = target.translationf - target.look * ship:getBoundingSphere().radius * 5
            else
                entryPos = target.translationf - target.look * ship:getBoundingSphere().radius * 10
                flyThroughPos = target.translationf + target.look * ship:getBoundingSphere().radius * 5
            end
            table.insert(waypoints, entryPos)
            table.insert(waypoints, flyThroughPos)

            Entity():addScript("ai/fly.lua", unpack(waypoints))
        else
            -- wormhole
            ShipAI():setFly(target.translationf, 0)
        end

        setAIAction(AIAction.FlyThroughWormhole, index)
    end
end

function stopFlying()
    if onClient() then
        invokeServerFunction("stopFlying")
        return
    end

    if checkCaptain() then
        removeSpecialOrders()

        ShipAI():setPassive()
        setAIAction()
    end
end

function onAttackEnemiesButtonPressed()
    if onClient() then
        invokeServerFunction("onAttackEnemiesButtonPressed")
        ScriptUI():stopInteraction()
        return
    end

    if checkCaptain() then
        local ai = ShipAI()
        ai:setAggressive()

        removeSpecialOrders()
    end
end

function onPatrolButtonPressed()
    if onClient() then
        invokeServerFunction("onPatrolButtonPressed")
        ScriptUI():stopInteraction()
        return
    end

    if checkCaptain() then
        removeSpecialOrders()
        Entity():addScript("ai/patrol.lua")
    end
end

function onMineButtonPressed()
    if onClient() then
        invokeServerFunction("onMineButtonPressed")
        ScriptUI():stopInteraction()
        return
    end

    if checkCaptain() then
        removeSpecialOrders()
        Entity():addScript("ai/mine.lua")
    end
end

function removeSpecialOrders()

    local entity = Entity()

    for index, name in pairs(entity:getScripts()) do
        if string.match(name, "data/scripts/entity/ai/") then
            entity:removeScript(index)
        end
    end
end

-- this function will be executed every frame both on the server and the client
--function update(timeStep)
--
--end
--
---- this function gets called every time the window is shown on the client, ie. when a player presses F
--function onShowWindow()
--
--end
--
---- this function gets called every time the window is shown on the client, ie. when a player presses F
--function onCloseWindow()
--
--end
