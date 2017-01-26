
local minedAsteroid = nil
local minedLoot = nil
local collectCounter = 0

-- this function will be executed every frame on the server only
function updateServer(timeStep)
    -- find an asteroid that can be harvested

    local ship = Entity()
    local faction = Faction(ship.factionIndex)

    if faction.isPlayer then
        local player = Player(faction.index)

        if player.craftIndex == ship.index then
            return
        end
    end

    updateMining(timeStep)

end

-- check the immediate region around the ship for loot that can be collected
-- and if there is some, assign minedLoot
function findMinedLoot()

    local loots = {Sector():getEntitiesByType(EntityType.Loot)}

    local ship = Entity()

    minedLoot = nil
    for _, loot in pairs(loots) do
        if loot:isCollectable(ship) and distance2(loot.translationf, ship.translationf) < 150 * 150 then
            minedLoot = loot
            break
        end
    end

end

-- check the sector for an asteroid that can be mined
-- if there is one, assign minedAsteroid
function findMinedAsteroid()
    local radius = 20
    local ship = Entity()
    local sector = Sector()

    minedAsteroid = nil

    local asteroids = {sector:getEntitiesByType(EntityType.Asteroid)}
    local nearest = math.huge

    for _, a in pairs(asteroids) do
        local resources = a:getMineableResources()
        if resources ~= nil and resources > 0 then

            local dist = distance2(a.translationf, ship.translationf)
            if dist < nearest then
                nearest = dist
                minedAsteroid = a
            end

        end
    end

    if minedAsteroid then
        broadcastInvokeClientFunction("setMinedAsteroid", minedAsteroid.index)
    end

end

function updateMining(timeStep)

    -- highest priority is collecting the resources
    if not valid(minedAsteroid) and not valid(minedLoot) then

        -- first, check if there is loot to collect
        findMinedLoot()

        -- then, if there's no loot, check if there is an asteroid to mine
        if not valid(minedLoot) then
            findMinedAsteroid()
        end

    end

    local ship = Entity()
    local ai = ShipAI()

    if valid(minedLoot) then

        -- there is loot to collect, fly there
        collectCounter = collectCounter + timeStep
        if collectCounter > 3 then
            collectCounter = collectCounter - 3
            ai:setFly(minedLoot.translationf, 0)
        end

    elseif valid(minedAsteroid) then

        -- if there is an asteroid to collect, attack it
        if ship.selectedObject == nil
            or ship.selectedObject.index ~= minedAsteroid.index
            or ai.state ~= AIState.Attack then

            ai:setAttack(minedAsteroid)
        end
    end

end

function setMinedAsteroid(index)
    minedAsteroid = Entity(index)
end

---- this function will be executed every frame on the client only
--function updateClient(timeStep)
--
--    if valid(minedAsteroid) then
--        drawDebugSphere(minedAsteroid:getBoundingSphere(), ColorRGB(1, 0, 0))
--    end
--end
