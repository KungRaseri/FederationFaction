package.path = package.path .. ";data/scripts/lib/?.lua"

require("defaultscripts")
require("stringutility")

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

    return false, "You'e not close enough to claim the object."%_t
end

-- create all required UI elements for the client side
function initUI()
    InteractionText().text = "This wreckage looks like it's still functional."%_t
    ScriptUI():registerInteraction("Repair"%_t, "onRepair")
end

function onRepair()
    invokeServerFunction("repair")
end

function repair()
    -- transform into a normal ship
    if not interactionPossible(callingPlayer) then
        print ("no interaction possible")
        return
    end

    local wreckage = Entity()
    local plan = wreckage:getPlan()

    -- set an empty plan, this will both delete the entity and avoid collisions with the ship
    -- that we're creating at this exact position
    wreckage:setPlan(BlockPlan())

    local ship = Sector():createShip(Player(callingPlayer), wreckage.name, plan, wreckage.position)

    AddDefaultShipScripts(ship)
    terminate()
end
