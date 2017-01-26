
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

SectorSpecifics = require ("sectorspecifics")

local assert = assert
local GatesMap = {}
GatesMap.__index = GatesMap

local function new(serverSeed)

    local obj = setmetatable({
                        range = 15,
                        serverSeed = serverSeed
                        }, GatesMap)

    obj:initialize()

    return obj
end

local function distance2(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y

    return dx * dx + dy * dy
end

function GatesMap:initialize()
    self.specs = SectorSpecifics(0, 0, self.serverSeed)
    self.range2 = self.range * self.range

    local up = vec2(0, 1)
    local down = vec2(0, -1)
    local left = vec2(-1, 0)
    local right = vec2(1, 0)

    self.directions =
    {
        { up, down, left, right },
        { up, down, right, left },
        { up, right, down, left },
        { up, right, left, down },
        { up, left, right, down },
        { up, left, down, right },

        { down, up, left, right },
        { down, up, right, left },
        { down, left, up, right },
        { down, left, right, up },
        { down, right, up, left },
        { down, right, left, up },

        { left, right, down, up },
        { left, right, up, down },
        { left, up, down, right },
        { left, up, right, down },
        { left, down, up, right },
        { left, down, right, up },

        { right, left, down, up },
        { right, left, up, down },
        { right, up, down, left },
        { right, up, left, down },
        { right, down, up, left },
        { right, down, left, up }
    }

    self.numDirections = #self.directions

end

function GatesMap:potentialConnections(a, sectors)

    local connections = {}

    -- choose directions
    local hash = makeFastHash(a.x, a.y, self.serverSeed.int32)
    local directions = self.directions[(hash % self.numDirections) + 1]

    local passageMap = self.specs.passageMap

    local dirvec = vec2()

    local threshold = math.cos(math.pi / 3.9)

    -- check each direction
    for _, dir in pairs(directions) do

        -- find nearest indicator in that direction
        local minimum = self.range2
        local coord = nil

        for _, other in pairs(sectors) do
            -- don't connect to self
            if other.x == a.x and other.y == a.y then goto continue end

            -- check if the other sector lies in the direction
            dirvec.x = other.x - a.x
            dirvec.y = other.y - a.y
            normalize_ip(dirvec)

            if dot(dirvec, dir) < threshold then goto continue end

            -- check if it's not crossing the ring
            if passageMap:insideRing(a.x, a.y) ~= passageMap:insideRing(other.x, other.y) then goto continue end

            -- find minimum
            local dist = distance2(a, other)
            if dist < minimum then
                minimum = dist
                coord = other
            end

            -- if b is among the connections, return true
            ::continue::
        end

        if coord then
            -- the threshold is > 45 degrees, which can lead to sectors being inserted multiple
            -- times if they lie exactly in a 45 degree angle
            local existing = false
            for _, c in pairs(connections) do
                if c.x == coord.x and c.y == coord.y then
                    existing = true
                    break
                end
            end

            if not existing then
                table.insert(connections, coord)
            end
        end
    end

    return connections
end

function GatesMap:hasGates(specs)
    local player = Galaxy():findFaction(1)

    if player then
        local hx, hy = player:getHomeSectorCoordinates()
        if specs.coordinates.x == hx and specs.coordinates.y == hy then
            return true
        end
    end

    return specs.gates
end

function GatesMap:getConnectedSectors(from)

    -- find all sectors that can be considered to have a gate connection
    local sectors = {}

    local range = self.range

    for dx = -range, range do
        for dy = -range, range do

            -- check if sector is in range
            local d2 = dx * dx + dy * dy
            if d2 > range * range then goto continue end

            -- check if sector has content
            local x = from.x + dx
            local y = from.y + dy

            self.specs:initialize(x, y, self.serverSeed)

            if not self:hasGates(self.specs) then goto continue end

            table.insert(sectors, {x=x, y=y})

            ::continue::
        end
    end

    -- now check if there is a two-way connection between these sectors and self
    local connected = {}

    local outgoing = self:potentialConnections(from, sectors)
    for _, target in pairs(outgoing) do

        local incoming = self:potentialConnections(target, sectors)

        for _, otherTarget in pairs(incoming) do
            if from.x == otherTarget.x and from.y == otherTarget.y then
                table.insert(connected, target)
            end
        end

    end

    return connected
end





return setmetatable({new = new}, {__call = function(_, ...) return new(...) end})
