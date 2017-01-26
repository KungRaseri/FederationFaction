package.path = package.path .. ";data/scripts/lib/?.lua"
require ("galaxy")
require ("utility")
require ("stringutility")
require ("faction")
ShipGenerator = require("shipgenerator")

local active = false

-- if this function returns false, the script will not be listed in the interaction window on the client,
-- even though its UI may be registered
function interactionPossible(playerIndex, option)
    if Entity().factionIndex == playerIndex then
        return true
    end

    return false
end

-- this function gets called on creation of the entity the script is attached to, on client and server
function initialize(active_in)
    active = active_in or 0
end

function initUI()

    local menu = ScriptUI()
    local window = menu:createWindow(Rect(0, 0, 0, 0))
    menu:registerWindow(window, "Activate"%_t)

end

function getUpdateInterval()
    return 1.0
end

function updateServer(timeStep)

    if active then
        -- block all hyperspace engines in the sector
        local entities = {Sector():getEntitiesByComponent(ComponentType.HyperspaceEngine)}

        for _, entity in pairs(entities) do
            entity:blockHyperspace(5.0)
        end
    end

end

-- this function gets called every time the window is shown on the client, ie. when a player presses F and if interactionPossible() returned 1
function onShowWindow()
    invokeServerFunction("toggleActive")
    ScriptUI():stopInteraction()
end

function toggleActive()
    if not active then
        active = true
    else
        active = false
    end

    print("active: " .. tostring(active))
end

function activate()
    active = true
end

function deactivate()
    active = false
end

---- this function gets called every time the window is closed on the client
--function onCloseWindow()
--
--end
--
-- this function gets called on creation of the entity the script is attached to, on client only
-- AFTER initialize above
-- create all required UI elements for the client side
-- function initUI()
-- end
--
-- this functions gets called when the indicator of the station is rendered on the client
--function renderUIIndicator(px, py, size)
--
--end
--
-- this function gets called every time the window is shown on the client, ie. when a player presses F and if interactionPossible() returned 1
-- function onShowWindow()
--
-- end
--
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



