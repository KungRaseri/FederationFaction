package.path = package.path .. ";data/scripts/lib/?.lua"

require ("stringutility")

-- if this function returns false, the script will not be listed in the interaction window,
-- even though its UI may be registered
function interactionPossible(playerIndex, option)
    local entity = Entity()

    if entity.factionIndex == playerIndex then
        return true
    end

    for _, index in pairs({entity:getBuildingPermissions()}) do
        if index == playerIndex then return true end
    end

    return false
end

function initUI()
    ScriptUI():registerInteraction("Build"%_t, "onBuildPressed");
end

function onBuildPressed()

    local ok, error = Player():buildingAllowed(Entity())
    if not ok then
        displayChatMessage(error, "", 1)
        return
    end

    Player():startBuilding(Entity())
end

