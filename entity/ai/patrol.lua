local waypoints
local current = 1
local waypointSpread = 2000 -- fly up to 20 km from the center

function getUpdateInterval()
    return 1
end

function initialize(...)
    if onServer() then
        setWaypoints({...})
    end
end

-- this function will be executed every frame on the server only
function updateServer(timeStep)

    -- check if there are enemies
    local sector = Sector()
    local faction = Faction()
    local enemy = ShipAI():getNearestEnemy(-40000)

    if enemy then
        updateAttacking(timeStep)
    else
        updateFlying(timeStep)
    end
end

function updateFlying(timeStep)

    if not waypoints or #waypoints == 0 then
        waypoints = {}
        for i = 1, 5 do
            table.insert(waypoints, vec3(math.random(-1, 1), math.random(-1, 1), math.random(-1, 1)) * waypointSpread)
        end

        current = 1
    end

    local ship = Entity()
    local ai = ShipAI()

    local d = (ship:getBoundingSphere().radius * 2)
    local d2 = d * d

    if distance2(ship.translationf, waypoints[current]) < d2 then
        current = current + 1
        if current > #waypoints then
            current = 1
        end
    end

    ai:setFly(waypoints[current], ship:getBoundingSphere().radius)
end

function updateAttacking(timeStep)
    local ai = ShipAI()
    if ai.state ~= AIState.Aggressive then
        ai:setAggressive()
    end
end

function setWaypoints(waypointsIn)
    waypoints = waypointsIn
end
