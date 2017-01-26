if onServer() then

package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

require ("galaxy")
require ("stringutility")
local ShipGenerator = require ("shipgenerator")

local threshold = 60 * 15

function initialize()
end

function getUpdateInterval()
    return threshold
end

function update(timeStep)

    local x, y = Sector():getCoordinates()
    local hx, hy = Faction():getHomeSectorCoordinates()

    local dist = length(vec2(x, y))
    if dist > 550 then return end

    -- no attacks in the home sector
    if x == hx and y == hy then
        threshold = 60 * 3 -- try again after some minutes
        return
    end

    -- find a hopefully evil faction that the player knows already
    local faction = findNearbyEnemyFaction()

    if faction == nil then
        threshold = 60 * 3 -- try again after some minutes
        return
    end

    -- create the head hunters
    createEnemies(faction)

    threshold = 60 * 25
end

function findNearbyEnemyFaction()

    -- find a hopefully evil faction that the player knows already
    local player = Player();

    local x, y = Sector():getCoordinates()


    local locations =
    {
        {x = x, y = y},
        {x = x + math.random(-7, 7), y = y + math.random(-7, 7)},
        {x = x + math.random(-7, 7), y = y + math.random(-7, 7)}
    }

    local faction = nil
    for i, coords in pairs(locations) do

        local f = Galaxy():getNearestFaction(x, y)

        if player:knowsFaction(f.index) then
            local relation = player:getRelations(f.index)

            if relation < -40000 then
                faction = f
                break
            end
        end
    end

    return faction
end

function createEnemies(faction)

    -- create the head hunters
    local dir = normalize(vec3(getFloat(-1, 1), getFloat(-1, 1), getFloat(-1, 1)))
    local up = vec3(0, 1, 0)
    local right = normalize(cross(dir, up))
    local pos = dir * 1500

    local volume = Balancing_GetSectorShipVolume(faction:getHomeSectorCoordinates());

    local enemy = ShipGenerator.createMilitaryShip(faction, MatrixLookUpPosition(-dir, up, pos), volume * 4)
    enemy.title = "Head Hunter"%_t
    ShipAI(enemy.index):setAggressive()

    local distance = enemy:getBoundingSphere().radius * 2 + 20

    local enemy = ShipGenerator.createMilitaryShip(faction, MatrixLookUpPosition(-dir, up, pos + right * distance), volume * 2)
    enemy.title = "Head Hunter"%_t
    ShipAI(enemy.index):setAggressive()

    local enemy = ShipGenerator.createMilitaryShip(faction, MatrixLookUpPosition(-dir, up, pos + right * -distance), volume * 2)
    enemy.title = "Hyperspace Blocker"%_t
    enemy:addScript("blocker.lua", 1)
    ShipAI(enemy.index):setAggressive()

end

end
