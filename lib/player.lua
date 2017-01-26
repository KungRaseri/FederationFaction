package.path = package.path .. ";/data/scripts/lib/?.lua"
require ("stringutility")

function CheckPlayerDocked(player, object, errors, generic)
    local object = object or Entity()

    return CheckShipDocked(player, player.craft, object, errors, generic)
end

function CheckShipDocked(faction, ship, object, errors, generic)
    if not faction then return false end

    local object = object or Entity()
    if not object then return false end

    if not ship then
        local error = "You're not in a ship."%_T
        if faction.isPlayer then
            Player(faction.index):sendChatMessage(object.title, 1, error)
        end
        return false, error
    end

    local error
    if object:hasComponent(ComponentType.DockingPositions) then
        if not object:isDocked(ship) then
            error = errors[object.type] or generic or "You must be docked to the object for this."%_T
        end
    else
        if object:getNearestDistance(ship) > 0.2 then
            error = errors[object.type] or generic or "You must be closer to the object for this."%_T
        end
    end

    if error then
        if faction.isPlayer then
            if type(error) == "string" then
                Player(faction.index):sendChatMessage(object.title, 1, error)
            elseif type(error) == "table" then
                Player(faction.index):sendChatMessage(object.title, 1, error.text, unpack(error.args or {}))
            end
        end
        return false, error
    end

    return true
end
