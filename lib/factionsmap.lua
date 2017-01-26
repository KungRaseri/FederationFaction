package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local assert = assert
local FactionsMap = {}
FactionsMap.__index = FactionsMap

local function new(seed)

    local obj = setmetatable({
                        factionRange = 17,
                        }, FactionsMap)

    obj:initialize(seed, -499, 500, 1750)

    return obj
end

function FactionsMap:initialize(seed, min, max, numFactions)
    -- build up data
    self.seed = seed;

    local random = Random(seed)

    -- create quad tree & index map
    self.tree = QuadTree(vec2(min, min), vec2(max, max), 7)
    self.homeSectors = {}
    self.factions = {}

    -- start counting at 2mio to make sure that factions created during runtime (such as players)
    -- are not mistaken for factions on the map
    local offset = 2000000
    local created = 0
    local coords = vec2()

    while created < numFactions do
        local x = random:getInt(min, max)
        local y = random:getInt(min, max)

        coords.x = x
        coords.y = y
        local rx, ry = self.tree:nearest(x, y)

        local create = 1

        -- make sure coordinates are not yet in the tree
        if rx and ry then
            if rx == x and ry == y then
                create = 0
            end
        end

        local d = length(coords)

        -- don't create sectors that are too near to the center
        if d < 50 then
            create = 0
            created = created + 1
        end

        local probability = math.max(0, d - 50) / 400
        probability = math.max(0.15, probability)
        if random:getFloat(0, 1) > probability then
            create = 0
            created = created + 1
        end


        -- or too far away
        if d > 450 then

            local probability = (650 - d) / 300
            if random:getFloat(0, 1) > probability then
                create = 0
                created = created + 1
            end
        end

        if create == 1 then
            local factionIndex = offset + created

            self.tree:insert(coords)

            self.homeSectors[factionIndex] = vec2(x, y)

            self.factions[x] = self.factions[x] or {}
            assert(self.factions[x][y] == nil)
            self.factions[x][y] = factionIndex

            created = created + 1
        end
    end

end

function FactionsMap:exists(factionIndex)
    return self.homeSectors[factionIndex] ~= nil
end

function FactionsMap:getHomeSector(factionIndex)
    return self.homeSectors[factionIndex]
end

function FactionsMap:getFaction(x, y)
    return self:retrieve(x, y, self.factionRange)
end

function FactionsMap:getNearestFaction(x, y)
    return self:retrieve(x, y)
end

function FactionsMap:retrieve(x, y, radius)
    local x, y = self.tree:nearest(x, y, radius)

    if x and y and self.factions[x] then
        return self.factions[x][y]
    end
end

return setmetatable({new = new}, {__call = function(_, ...) return new(...) end})
