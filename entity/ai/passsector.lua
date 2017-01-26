if onServer() then

-- ships passing through
local destination = vec3()

function getUpdateInterval()
    return 5
end

function initialize(destination_in)
    destination = destination_in or vec3()

    if destination_in then
        ShipAI():setFly(destination, 0)
    end
end

function update(timeStep)

    -- check if arrived at the target position
    local self = Entity()
    local sphere = self:getBoundingSphere()

    ShipAI():setFly(destination, 0)

    if distance(sphere.center, destination) < sphere.radius + 50 then
        if self.factionIndex and Player(self.factionIndex) then
            print ("Error: Tried to jump-delete a ship of a player! Ship: %i, Player: %s", self.index, Player(self.factionIndex).name)
            terminate()
        else
            Sector():deleteEntityJumped(self)
        end
    end
end

function secure()
    return {destination = {x = destination.x, y = destination.y, z = destination.z}}
end

function restore(values)
    destination = vec3(values.destination.x, values.destination.y, values.destination.z)
end

end
