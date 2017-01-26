package.path = package.path .. ";data/scripts/lib/?.lua"

require ("stringutility")

-- if this function returns false, the script will not be listed in the interaction window,
-- even though its UI may be registered
function interactionPossible(playerIndex, option)
    local self = Entity()
    if self.factionIndex ~= playerIndex then
        return false
    end

    -- players can only fly their own craft
    local player = Player(playerIndex)

    local craft = player.craft
    if craft == nil then return false end

    if craft.index == self.index then
        return false
    end

    local dist = craft:getNearestDistance(self)
    if dist > 50.0 then
        return false
    end

    return true
end

-- create all required UI elements for the client side
function initUI()
    local window = ScriptUI():createWindow(Rect(vec2(0, 0), vec2(0, 0)))
    ScriptUI():registerWindow(window, "Enter"%_t);
end

function onShowWindow()
    ScriptUI():stopInteraction()

    local faction = Faction()
    if faction.isPlayer then
        local player = Player(faction.index)

        player.craftIndex = Entity().index
    end
end

