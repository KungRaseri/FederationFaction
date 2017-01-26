package.path = package.path .. ";data/scripts/lib/?.lua"

require("utility")
require("stringutility")

local playerCombo = nil
local playerList = nil
local buildingPlayerIndicesByName = {}

function getIcon()
    return "data/textures/icons/shaking-hands.png"
end

-- if this function returns false, the script will not be listed in the interaction window,
-- even though its UI may be registered
function interactionPossible(playerIndex, option)

    if Entity().factionIndex == playerIndex then
        return true, ""
    end

    return false
end

-- create all required UI elements for the client side
function initUI()

    local res = getResolution()
    local size = vec2(300, 400)

    local menu = ScriptUI()
    local window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
    menu:registerWindow(window, "Permissions"%_t)

    window.caption = "Permissions"%_t
    window.showCloseButton = 1
    window.moveable = 1

    -- create a tabbed window inside the main window
    local tabbedWindow = window:createTabbedWindow(Rect(vec2(10, 10), size - 10))

    local buildTab = tabbedWindow:createTab("Build"%_t, "data/textures/icons/brick-pile.png", "Manage Building Permissions"%_t)

    local hsplit = UIHorizontalSplitter(Rect(vec2(0, 0), tabbedWindow.size - vec2(0, 55)), 10, 0, 0.5)
    hsplit.bottomSize = 70

    playerList = buildTab:createListBox(hsplit.top)

    local hsplit = UIHorizontalSplitter(hsplit.bottom, 10, 0, 0.5)
    hsplit.bottomSize = 35

    playerCombo = buildTab:createComboBox(hsplit.top, "")

    local vsplit = UIVerticalSplitter(hsplit.bottom, 10, 0, 0.5)

    addScriptButton = buildTab:createButton(vsplit.left, "Add"%_t, "onAddBuildingPermissionPressed")
    removeScriptButton = buildTab:createButton(vsplit.right, "Remove"%_t, "onRemoveBuildingPermissionPressed")

end

function onShowWindow()

    buildingPlayerIndicesByName = {}
    playerCombo:clear()
    playerList:clear()

    local player = Player()

    -- fill combo box
    for index, name in pairs(Galaxy():getPlayerNames()) do
        if player.name:lower() ~= name:lower() then
            playerCombo:addEntry(name);
            buildingPlayerIndicesByName[name] = index
        end
    end

    -- fill list
    local entity = Entity()
    for _, index in pairs({entity:getBuildingPermissions()}) do

        local other = Faction(index)
        if other then
            playerList:addEntry(other.name)
        else
            print("Building collaboration: Removed player " .. index .. " as it was not a valid faction or player")
            invokeServerFunction("removePermission", index)
        end
    end

end

function onAddBuildingPermissionPressed()

    local name = playerCombo.selectedEntry
    local index = buildingPlayerIndicesByName[name]

    if index then
        invokeServerFunction("addPermission", index)
    end

end

function onRemoveBuildingPermissionPressed()

    local name = playerList:getSelectedEntry()
    local index = buildingPlayerIndicesByName[name]

    if index then
        invokeServerFunction("removePermission", index)
    end

end

function addPermission(playerIndex)
    local entity = Entity()
    if entity.factionIndex and entity.factionIndex ~= callingPlayer then return end

    entity:addBuildingPermission(playerIndex)

    invokeClientFunction(Player(callingPlayer), "onShowWindow")
end

function removePermission(playerIndex)
    local entity = Entity()
    if entity.factionIndex and entity.factionIndex ~= callingPlayer then return end

    entity:removeBuildingPermission(playerIndex)

    invokeClientFunction(Player(callingPlayer), "onShowWindow")
end

