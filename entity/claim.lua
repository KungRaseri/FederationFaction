package.path = package.path .. ";data/scripts/lib/?.lua"

require ("stringutility")

-- if this function returns false, the script will not be listed in the interaction window,
-- even though its UI may be registered
function interactionPossible(playerIndex, option)

    local player = Player(playerIndex)
    local self = Entity()

    local craft = player.craft
    if craft == nil then return false end

    local dist = craft:getNearestDistance(self)

    if dist < 20 then
        return true
    end

    return false, "You are not close enough to claim the object!"%_t
end

-- create all required UI elements for the client side
function initUI()

    local res = getResolution()
    local size = vec2(800, 600)

    local menu = ScriptUI()
    window = menu:createWindow(Rect(vec2(0, 0), vec2(0, 0)))

    menu:registerWindow(window, "Claim"%_t);
end

function onShowWindow()
    invokeServerFunction("claim")
    ScriptUI():stopInteraction()
end

function claim()
    local ok, msg = interactionPossible(callingPlayer)
    if not ok then
        if msg then
            Player():sendChatMessage("", 1, msg)
        end

        return
    end

    Entity().factionIndex = callingPlayer
    Entity():addScript("minefounder.lua")
    Entity():addScript("sellobject.lua")

    terminate()
end
