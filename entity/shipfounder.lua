package.path = package.path .. ";data/scripts/lib/?.lua"
require ("defaultscripts")
require ("stringutility")

local nameTextBox = nil

-- if this function returns false, the script will not be listed in the interaction window,
-- even though its UI may be registered
function interactionPossible(playerIndex, option)
    local self = Entity()
    local player = Player(playerIndex)

    if self.factionIndex ~= player.index then return false end

    local craft = player.craft
    if craft == nil then return false end

    if self.index == craft.index then
        return true
    end

    return false, "Fly the craft to found a ship."%_t
end

function getIcon()
    return "data/textures/icons/flying-flag.png"
end

-- create all required UI elements for the client side
function initUI()

    local res = getResolution()
    local size = vec2(350, 125)

    local menu = ScriptUI()
    window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
    window.caption = "Found Ship (500 Iron)"%_t
    window.showCloseButton = 1
    window.moveable = 1
    menu:registerWindow(window, "Found Ship"%_t);


    local vsplit = UIVerticalSplitter(window.rect, 10, 10, 0.5)

    local label = window:createLabel(vec2(10, 10), "Enter the name of your new ship:"%_t, 14);
    label.size = vec2(size.x - 20, 40)
    label.centered = true

    nameTextBox = window:createTextBox(Rect(vec2(10, 40), vec2(size.x - 10, 40 + 30)), "")
    nameTextBox.maxCharacters = 35

    -- button at the bottom
    local button = window:createButton(Rect(), "OK"%_t, "onFoundButtonPress");
    local organizer = UIOrganizer(Rect(window.size))
    organizer.padding = 10
    organizer.margin = 10
    organizer:placeElementBottom(button)
end

function onFoundButtonPress()

    name = nameTextBox.text

    if Player():ownsShip(name) then
        displayChatMessage("You already have a ship called '${name}'."%_t % {name = name}, "Server"%_t, 1)
        return
    end

    invokeServerFunction("found", name)
end

function found(name)

    if Faction().index ~= callingPlayer then return end
    local player = Player(callingPlayer)

    local ok, msg, args = player:canPay(0, 500)
    if not ok then
        player:sendChatMessage("Server"%_t, 1, msg, unpack(args))
        return
    end

    player:pay(0, 500)

    local self = Entity()

    local plan = BlockPlan()
    local material = Material()
    plan:addBlock(vec3(0, 0, 0), vec3(2, 2, 2), -1, -1, material.blockColor, material, Matrix(), BlockType.Hull)

    local ship = Sector():createShip(player, name, plan, self.position);

    -- add base scripts
    AddDefaultShipScripts(ship)
    ship:addScript("insurance.lua")

    player.craft = ship

end

























