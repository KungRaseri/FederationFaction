package.path = package.path .. ";data/scripts/lib/*.lua"

require ("randomext")
require ("stringutility")
local ShipGenerator = require("shipgenerator")
local Placer = require("placer")

local AdventurerGuide = {}

function AdventurerGuide.spawn1(player)

    -- don't double-spawn
    if Sector():getEntitiesByScript("data/scripts/entity/story/adventurer1.lua") then return end

    local faction = Galaxy():getNearestFaction(player:getHomeSectorCoordinates())
    local volume = Balancing_GetSectorShipVolume(faction:getHomeSectorCoordinates())

    local pos = random():getVector(-1000, 1000)
    local matrix = MatrixLookUpPosition(-pos, vec3(0, 1, 0), pos)

    local ship = ShipGenerator.createMilitaryShip(faction, matrix, volume)

    local language = faction:getLanguage()
    language.seed = Server().seed

    local name = language:getName()

    ship:setTitle("${name} The Adventurer"%_t, {name = name})
    ship:addScript("story/adventurer1.lua")

    Placer.resolveIntersections({ship})

    return ship
end

return AdventurerGuide
