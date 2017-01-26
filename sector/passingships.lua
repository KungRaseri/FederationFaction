if onServer() then

package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"
package.path = package.path .. ";?"

require ("galaxy")
ShipGenerator = require ("shipgenerator")

-- ships passing through
local passThroughCreationCounter = 0

function getUpdateInterval()
    return 180
end

function update(timeStep)

    -- not too many passing ships at one time
    local sector = Sector()
    local stations = {sector:getEntitiesByType(EntityType.Station)}

    local maxPassThroughs = #stations * 0.5 + 1

    local passingShips = {Sector():getEntitiesByScript("ai/passsector.lua")}
    if tablelength(passingShips) >= maxPassThroughs then return end


    local galaxy = Galaxy()
    local x, y = sector:getCoordinates()

    local faction = galaxy:getNearestFaction(x + math.random(-15, 15), y + math.random(-15, 15))

    -- this is the position where the trader spawns
    local dir = random():getDirection()
    local pos = dir * 1500

    -- this is the position where the trader will jump into hyperspace
    local destination = -pos + vec3(math.random(), math.random(), math.random()) * 1000
    destination = normalize(destination) * 1500

    -- create a single trader or a convoy
    local numTraders = 1
    if math.random() < 0.1 then
        numTraders = 6
    end

    for i = 1, numTraders do
        pos = pos + dir * 200
        local matrix = MatrixLookUpPosition(-dir, vec3(0, 1, 0), pos)

        local ship
        if math.random() < 0.5 then
            ship = ShipGenerator.createTradingShip(faction, matrix)
        else
            ship = ShipGenerator.createFreighterShip(faction, matrix)
        end

        if math.random() < 0.8 then
            ShipUtility.addCargoToCraft(ship)
        end

        ship:addScript("ai/passsector.lua", destination)
    end

end

end
