package.path = package.path .. ";data/scripts/lib/?.lua"

require ("randomext")

local Placer = {}

function Placer.resolveIntersections(entities)

    local sector = Sector()
    entities = entities or {sector:getEntitiesByComponent(ComponentType.BoundingSphere)}

    local loops = 0
    local resolve = 1
    while resolve == 1 do
        resolve = 0

        loops = loops + 1

        local resolutions = 0
        for _, entity in pairs(entities) do
            local a = entity:getBoundingSphere()

            a.radius = a.radius * 2

            -- get all entities that might intersect
            local others = {sector:getEntitiesByLocation(a)}

            a.radius = a.radius / 2

            for _, other in pairs(others) do

                if other.index ~= entity.index then

                    -- check for intersection
                    local b = other:getBoundingSphere()

                    local r = (a.radius + b.radius)
                    local d = distance(a.center, b.center)

                    if d < r then

                        if d == 0 then
                            entity:moveBy(random():getDirection())
                        end

                        -- they intersect, move away from each other
                        local center = (a.center + b.center) * 0.5

                        local factorA = other.mass / (entity.mass + other.mass)
                        local factorB = -entity.mass / (entity.mass + other.mass)

                        local delta = normalize(a.center - center) * (r - d + 0.1) * 1.1

                        entity:moveBy(delta * factorA)
                        other:moveBy(delta * factorB)

                        resolve = 1

                        resolutions = resolutions + 1

--                        if loops % 10 == 0 then
--                            print ("moved A by: " .. tostring(delta) .. ", factor: " .. factorA)
--                            print ("moved B by: " .. tostring(delta) .. ", factor: " .. factorB)
--                        end
                    end
                end
            end
        end


--        if loops % 10 == 0 then
--            print("loops: " .. loops)
--            print("resolutions: " .. resolutions)
--        end

        if loops > 100 then
            return
        end

    end

end


function Placer.placeNextToEachOther(position, look, up, ...)
    local ships = {...}
    local diameters = {}

    local width = 0
    local numShips = #ships

    for i = 1, numShips do
        local ship = ships[i]

        local diameter = ship:getBoundingSphere().radius * 2
        table.insert(diameters, diameter)

        width = width + diameter
    end

    local avgDiameter = width / numShips
    local padding = avgDiameter * 0.2 + 10

    local width = width + padding * (#ships - 1)

    normalize_ip(look)
    normalize_ip(up)

    local right = normalize(cross(up, look))
    local pos = position - right * width * 0.5

    for i = 1, numShips do
        local diameter = diameters[i]
        local offset = right * (diameter + padding) * 0.5
        pos = pos + offset

        local ship = ships[i]
        ship.position = MatrixLookUpPosition(look, up, pos)

        pos = pos + offset
    end

end



return Placer
