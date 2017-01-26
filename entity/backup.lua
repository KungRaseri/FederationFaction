package.path = package.path .. ";data/scripts/lib/?.lua"
require ("galaxy")
require ("utility")
require ("faction")
ShipGenerator = require("shipgenerator")

local timeUntilBackup = 0
local damageUntilBackup = 0
local damageTaken = 0

-- if this function returns false, the script will not be listed in the interaction window on the client,
-- even though its UI may be registered
--
-- function interactionPossible(playerIndex, option)
-- end

-- this function gets called on creation of the entity the script is attached to, on client and server
function initialize()
    if onServer() then
        local entity = Entity()
        entity:registerCallback("onDamaged" , "onDamaged")

        damageUntilBackup = entity.maxDurability * 0.15
    end
end

function getUpdateInterval()
    return 60.0
end

function update(timeStep)
    timeUntilBackup = math.max(0, timeUntilBackup - timeStep)
end

function onDamaged(selfIndex, amount, inflictor)

    damageTaken = damageTaken + amount

    if damageTaken > damageUntilBackup and timeUntilBackup == 0 then
        local station = Entity(selfIndex)
        local faction = Faction(station.factionIndex)

        if not faction.isPlayer then

            local stationPos = station.translationf

            -- let the backup spawn behind the station
            local dir = normalize(normalize(stationPos) + vec3(0.01, 0.0, 0.0))
            local pos = stationPos + dir * 750
            local up = vec3(0, 1, 0)
            local look = -dir

            local right = normalize(cross(dir, up))

            ShipGenerator.createDefender(faction, MatrixLookUpPosition(look, up, pos))
            ShipGenerator.createDefender(faction, MatrixLookUpPosition(look, up, pos + right * 100))
            ShipGenerator.createDefender(faction, MatrixLookUpPosition(look, up, pos - right * 100))

            timeUntilBackup = 30 * 60 -- only every 30 minutes can a station call for backup
        end
    end

end

-- this function gets called on creation of the entity the script is attached to, on client only
-- AFTER initialize above
-- create all required UI elements for the client side
-- function initUI()
-- end

-- this functions gets called when the indicator of the station is rendered on the client
--function renderUIIndicator(px, py, size)
--
--end

-- this function gets called every time the window is shown on the client, ie. when a player presses F and if interactionPossible() returned 1
-- function onShowWindow()
--
-- end

---- this function gets called every time the window is closed on the client
--function onCloseWindow()
--
--end
--
---- this function gets called once each frame, on client and server
--function update(timeStep)
--
--end
--
---- this function gets called once each frame, on client only
--function updateClient(timeStep)
--
--end
--
---- this function gets called once each frame, on server only
--function updateServer(timeStep)
--
--end
--
---- this function gets called whenever the ui window gets rendered, AFTER the window was rendered (client only)
--function renderUI()
--
--end



