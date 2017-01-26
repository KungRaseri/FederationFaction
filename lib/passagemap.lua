
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local assert = assert
local PassageMap = {}
PassageMap.__index = PassageMap

local Balancing = require("galaxy")

local function distanceLinePoint(a, b, p)
    local dx = (b.x - a.x)
    local dy = (b.y - a.y)

    return math.abs(dx * (a.y - p.y) - dy * (a.x - p.x)) / math.sqrt(dx * dx + dy * dy)
end

local function new(seed)

    local obj = setmetatable({}, PassageMap)

    obj:initialize(seed, -499, 500)

    return obj
end

function PassageMap:initialize(seed, min, max, numRifts)

    self.seed = seed;
    self.rifts = {}
    self.indices = {}
    self.tree = QuadTree(vec2(min, min), vec2(max, max), 7)

    numRifts = numRifts or 200

    local random = Random(seed)
    local center = vec2()
    local offset = vec2()

    for i = 1, numRifts do

        local x = random:getInt(min + 50, max - 50)
        local y = random:getInt(min + 50, max - 50)

        center.x = x
        center.y = y

        local rx, ry = self.tree:nearest(x, y)

        local create = 1

        -- make sure coordinates are not yet in the tree
        if rx and ry then
            if rx == x and ry == y then
                create = 0
            end
        end

        if create == 1 then
            local angle = random:getFloat(0, math.pi)

            local length = random:getFloat(30, 50)

            local rift = {}

            offset.x = math.cos(angle) * length * 0.5
            offset.y = math.sin(angle) * length * 0.5

            rift.a = center + offset
            rift.b = center - offset
            rift.width = random:getFloat(3, 6);

            table.insert(self.rifts, rift)
            local index = #self.rifts

            self.tree:insert(center)

            self.indices[x] = self.indices[x] or {}
            if self.indices[x][y] then
                print("indices not nil: " .. x .. ", " .. y)
                print("returned indices: " .. rx .. ", " .. ry)
            end
            assert(self.indices[x][y] == nil)
            self.indices[x][y] = index

        end
    end

end

function PassageMap:passable(x, y)

    -- no blockings around the home sectors
    local min = 440.0 * 440.0
    local max = 460.0 * 460.0

    local d2 = x * x + y * y

    if d2 > min and d2 < max then
        return true
    end

    -- always block around this specific ring, which is the entrance to the endgame
    local min = Balancing.BlockRingMin
    local max = Balancing.BlockRingMax

    if d2 > min * min and d2 < max * max then
        return false
    end

    -- never block in the immediate range behind the blockring
    if d2 < min * min and d2 > (min - 5) * (min - 5) then
        return true
    end

    -- never block in the center
    if d2 < 20 * 20 then
        return true
    end

    local p = vec2(x, y)

    -- get all near rift centers
    local near = {self.tree:get(p, 40)}

    -- check if the point is near a rift
    for _, coords in pairs(near) do

        local rift

        local indicesX = self.indices[coords.x]
        if indicesX then
            local index = indicesX[coords.y]

            if index then
                rift = self.rifts[index]
            end
        end

        if rift then

            local center = (rift.a + rift.b) * 0.5

            local test = (1.0 - distance(center, p) / 40.0) * rift.width

            if distanceLinePoint(rift.a, rift.b, p) < test then
                return false
            end
        end
    end

    return true
end

function PassageMap:insideRing(x, y)
    -- always block around this specific ring, which is the entrance to the endgame
    local min = Balancing.BlockRingMin
    local max = Balancing.BlockRingMax

    local d2 = x * x + y * y
    if d2 < min * min then
        return true
    end

    return false
end

return setmetatable({new = new}, {__call = function(_, ...) return new(...) end})
