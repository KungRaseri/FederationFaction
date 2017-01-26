package.path = package.path .. ";data/scripts/lib/?.lua"

require ("stringutility")

-- if this function returns false, the script will not be listed in the interaction window,
-- even though its UI may be registered
function interactionPossible(playerIndex, option)
    local self = Entity()
    local player = Player(playerIndex)

    local craft = player.craft
    if craft == nil then return false end

    -- players can only exit their own craft
    if craft.index == self.index then
        return true
    end

    return false
end

function initUI()
    local window = ScriptUI():createWindow(Rect(vec2(0, 0), vec2(0, 0)))
    ScriptUI():registerWindow(window, "Exit Into Drone"%_t);
end

function getIcon()
    return "data/textures/icons/drone.png"
end

function onShowWindow()
    ScriptUI():stopInteraction()

    local faction = Faction()
    if faction.isPlayer then
        local player = Player(faction.index)

        player.craftIndex = -1
    end

end

