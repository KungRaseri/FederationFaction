if onServer() then

package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

require ("stringutility")
require ("galaxy")
local ShipGenerator = require ("shipgenerator")
local Xsotan = require("story/xsotan")

local minute = 0
local attackType = 1

function initialize(attackType_in)
    attackType = attackType_in or 1
    deferredCallback(1.0, "update", 1.0)
end

function getUpdateInterval()
    return 60
end

function update(timeStep)

    minute = minute + 1

    if attackType == 0 then

        if minute == 1 then
            Player():sendChatMessage("Server"%_t, 3, "Your sensors picked up a short burst of subspace signals."%_t)
        elseif minute == 4 then
            Player():sendChatMessage("Server"%_t, 3, "More strange subspace signals, they're getting stronger."%_t)
        elseif minute == 5 then
            createEnemies({
                  {size=1, title="Small Unknown Ship"%_t},
                  {size=1, title="Small Unknown Ship"%_t},
                  {size=1, title="Small Unknown Ship"%_t},
                  })

            Player():sendChatMessage("Server"%_t, 2, "A small group of alien ships appeared!"%_t)
            terminate()
        end

    elseif attackType == 1 then

        if minute == 1 then
            Player():sendChatMessage("Server"%_t, 3, "Your sensors picked up short bursts of subspace signals."%_t)
        elseif minute == 4 then
            Player():sendChatMessage("Server"%_t, 3, "The signals are growing stronger."%_t)
        elseif minute == 5 then
            createEnemies({
                  {size=1, title="Small Unknown Ship"%_t},
                  {size=3, title="Unknown Ship"%_t},
                  {size=3, title="Unknown Ship"%_t},
                  {size=1, title="Small Unknown Ship"%_t},
                  })

            Player():sendChatMessage("Server"%_t, 2, "A group of alien ships warped in!"%_t)
            terminate()
        end

    elseif attackType == 2 then

        if minute == 1 then
            Player():sendChatMessage("Server"%_t, 3, "Your sensors picked up short bursts of subspace signals."%_t)
        elseif minute == 4 then
            Player():sendChatMessage("Server"%_t, 3, "There are lots and lots of subspace signals! Careful!"%_t)
        elseif minute == 5 then

            createEnemies({
                  {size=1, title="Small Unknown Ship"%_t},
                  {size=2, title="Small Unknown Ship"%_t},
                  {size=3, title="Unknown Ship"%_t},
                  {size=5, title="Big Unknown Ship"%_t},
                  {size=3, title="Unknown Ship"%_t},
                  {size=2, title="Small Unknown Ship"%_t},
                  {size=1, title="Small Unknown Ship"%_t},
                  })

            Player():sendChatMessage("Server"%_t, 2, "A large group of alien ships appeared!"%_t)
            terminate()
        end

    elseif attackType == 3 then

        if minute == 1 then
            Player():sendChatMessage("Server"%_t, 3, "Your sensors picked up short bursts of subspace signals."%_t)
        elseif minute == 4 then
            Player():sendChatMessage("Server"%_t, 3, "The subspace signals are getting too strong for your scanners. Brace yourself!"%_t)
        elseif minute == 5 then

            createEnemies({
                  {size=1, title="Small Unknown Ship"%_t},
                  {size=1, title="Small Unknown Ship"%_t},
                  {size=2, title="Small Unknown Ship"%_t},
                  {size=3, title="Unknown Ship"%_t},
                  {size=3, title="Unknown Ship"%_t},
                  {size=5, title="Big Unknown Ship"%_t},
                  {size=3, title="Unknown Ship"%_t},
                  {size=3, title="Unknown Ship"%_t},
                  {size=2, title="Small Unknown Ship"%_t},
                  {size=1, title="Small Unknown Ship"%_t},
                  {size=1, title="Small Unknown Ship"%_t},
                  })

            Player():sendChatMessage("Server"%_t, 2, "Danger! A large fleet of alien ships appeared!"%_t)
            terminate()
        end

    end

end


function createEnemies(volumes)

    local galaxy = Galaxy()

    local faction = Xsotan.getFaction()

    local player = Player()
    local others = Galaxy():getNearestFaction(Sector():getCoordinates())
    Galaxy():changeFactionRelations(faction, player, -200000)
    Galaxy():changeFactionRelations(faction, others, -200000)

    -- create the enemies
    local dir = normalize(vec3(getFloat(-1, 1), getFloat(-1, 1), getFloat(-1, 1)))
    local up = vec3(0, 1, 0)
    local right = normalize(cross(dir, up))
    local pos = dir * 1500

    local volume = Balancing_GetSectorShipVolume(faction:getHomeSectorCoordinates());

    for _, p in pairs(volumes) do

        local enemy = Xsotan.createShip(MatrixLookUpPosition(-dir, up, pos), p.size)
        enemy.title = p.title

        local distance = enemy:getBoundingSphere().radius + 20

        pos = pos + right * distance

        enemy.translation = dvec3(pos.x, pos.y, pos.z)

        pos = pos + right * distance + 20

        ShipAI(enemy.index):setAggressive()
    end
end



end
