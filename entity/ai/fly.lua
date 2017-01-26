package.path = package.path .. ";data/scripts/lib/?.lua"

local waypoints
local current = 1

function getUpdateInterval()
    return 1
end

function initialize(...)
    if onServer() then
        setWaypoints({...})
        Entity():registerCallback("onSectorEntered", "stop")
    end
end

-- this function will be executed every frame on the server only
function updateServer(timeStep)
    if waypoints == nil or #waypoints == 0 then
        stop()
        return
    end

    -- check if there are enemies
    local sector = Sector()
    local faction = Faction()

    local ship = Entity()
    local ai = ShipAI()

    local d = (ship:getBoundingSphere().radius * 2)
    local d2 = d * d

    if distance2(ship.translationf, waypoints[current]) < d2 then
        current = current + 1
        if current > #waypoints then
            stop()
            return
        end
    end

    if current < #waypoints then
        ai:setFly(waypoints[current], ship:getBoundingSphere().radius)
    else
        -- fly straight to the last waypoint
        ai:setFlyLinear(waypoints[current], ship:getBoundingSphere().radius)
    end
end

function setWaypoints(waypointsIn)
    waypoints = waypointsIn
end

function stop()
    ShipAI():setPassive()
    terminate()
end
