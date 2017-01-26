package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/entity/?.lua"

require ("ai/trade")
require ("randomext")

local bought

local initializeAI = initialize
local updateServerAI = updateServer
local restoreAI = restore
local secureAI = secure

function initialize(stationIndex_in, script_in, goodname, amount)
    initializeAI(stationIndex_in, script_in)

    if goodname and amount then
        bought = {name = goodname, amount = amount}
    end
end

function sell(ship, station, script)
    -- sell all goods
    local cargos = ship:getCargos()
    for good, amount in pairs(cargos) do
        -- when the ship sells, the station buys from the ship
        station:invokeFunction(script, "buyFromShip", ship.index, good.name, amount, true)
    end

end

function buy(ship, station, script)
    station:invokeFunction(script, "sellToShip", ship.index, bought.name, bought.amount, true)
end

function doTransaction(ship, station, script)
    if bought then
        buy(ship, station, script)
    else
        sell(ship, station, script)
    end
end

function onTradingFinished(ship)
    startFlyAway(ship)
end


function startFlyAway(ship)
    -- player crafts should NEVER fly away since this will DELETE the ship
    if Faction().isPlayer then
        print ("Warning: A player craft wanted to enter trader fly away stage")
        terminate()
        return
    end

    ship:addScript("ai/passsector.lua", random():getDirection() * 1500)
    terminate()
end

function updateServer(timeStep)
    updateServerAI(timeStep)
end

function restore(data)
    restoreAI(data.ai)
    bought = data.bought
end

function secure()
    local data = {
        ai = secureAI(),
        bought = bought
    }

    return data
end
