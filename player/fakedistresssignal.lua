package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

require ("stringutility")

if onServer() then

require ("galaxy")
local PirateGenerator = require ("pirategenerator")
local SectorSpecifics = require ("sectorspecifics")

local target = nil

function initialize(firstInitialization)

    local specs = SectorSpecifics()
    local x, y = Sector():getCoordinates()
    local coords = specs.getShuffledCoordinates(random(), x, y, 7, 12)

    target = nil

    for _, coord in pairs(coords) do

        local regular, offgrid, blocked, home = specs:determineContent(coord.x, coord.y, Server().seed)

        if not regular and not offgrid and not blocked and not home then
            target = {x=coord.x, y=coord.y}
            break
        end
    end

    -- if no empty sector could be found, exit silently
    if not target then
        terminate()
        return
    end

    local player = Player()
    player:registerCallback("onSectorEntered", "onSectorEntered")

    if firstInitialization then
        local messages =
        {
            "Mayday! Mayday! We are under attack by pirates! Our position is \\s(%i:%i), someone help, please!"%_t,
            "Mayday! CHRRK ... under attack CHRRK ... pirates ... CHRRK ... position \\s(%i:%i) ... help!"%_t,
            "Can anybody hear us? We have been ambushed by pirates! Our position is \\s(%i:%i) Help!"%_t,
            "This is a distress call! Our position is \\s(%i:%i) We are under attack by pirates, please help!"%_t,
            "Help! uh... I'm a rich trader and I'm being attacked by pirates at \\s(%i:%i) Help! Help! Reward! Reward!"%_t,
        }

        player:sendChatMessage("Unkown"%_t, 0, messages[random():getInt(1, #messages)], target.x, target.y)
        player:sendChatMessage("", 3, "You have received a distress signal by an unknown source."%_t)
    end

end

function piratePosition()
    local pos = random():getVector(-1000, 1000)
    return MatrixLookUpPosition(-pos, vec3(0, 1, 0), pos)
end

function onSectorEntered(player, x, y)

    if x ~= target.x or y ~= target.y then return end

    -- spawn 10 pirates
    local leader = PirateGenerator.createMarauder(piratePosition())
    leader:addScript("dialogs/encounters/pirateambushleader.lua")

    PirateGenerator.createPirate(piratePosition())
    PirateGenerator.createPirate(piratePosition())
    PirateGenerator.createPirate(piratePosition())
    PirateGenerator.createBandit(piratePosition())
    PirateGenerator.createBandit(piratePosition())
    PirateGenerator.createBandit(piratePosition())
    PirateGenerator.createBandit(piratePosition())
    PirateGenerator.createBandit(piratePosition())

    terminate()
end

function sendCoordinates()
    invokeClientFunction(Player(callingPlayer), "receiveCoordinates", target)
end

end

function abandon()
    if onClient() then
        invokeServerFunction("abandon")
        return
    end
    terminate()
end

if onClient() then

function initialize()
    invokeServerFunction("sendCoordinates")
    target = {x=0,y=0}
end

function receiveCoordinates(target_in)
    target = target_in
end

function getMissionBrief()
    return "Distress Signal"%_t
end

function getMissionDescription()
    return string.format("You received a distress call from an unknown source. Their last reported position was (%i:%i)."%_t, target.x, target.y)
end

function getMissionLocation()
    return target.x, target.y
end

function secure()
    return {dummy = 1}
end

function restore(data)
    terminate()
end

end


