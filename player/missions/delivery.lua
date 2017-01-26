package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local Dialog = require ("dialogutility")
require ("stringutility")
require ("goods")
require ("randomext")
require ("mission")
local SectorSpecifics = require("sectorspecifics")

local clientStationName = ""


-- this is the public interface for the game, for retrieving data and calling functions
function initialize(goodName, amount, giverIndex, reward)
    initMissionCallbacks()

    if onClient() then

        Player():registerCallback("onStartDialog", "onStartDialog")

        missionData.timeLeft = 0
        missionData.good = ""
        missionData.plural = ""
        missionData.amount = 0
        missionData.location = {x = 0, y = 0}
        missionData.stationIndex = 0
        missionData.giverIndex = 0
        missionData.giverName = ""
        missionData.reward = 0
        missionData.fulfilled = 0

        sync()

    else
        Player():registerCallback("onSectorEntered", "onSectorEntered")

        -- if it's not being initialized from outside, skip initialization
        -- the script will be restored via restore()
        if not goodName then return end

        -- find a location to fly to
        -- this location must have stations
        local specs = SectorSpecifics()
        local x, y = Sector():getCoordinates()
        local coords = specs.getShuffledCoordinates(random(), x, y, 1, 25)
        local serverSeed = Server().seed
        local target = nil
        local destinations = specs.getRegularStationSectors()

        for _, coord in pairs(coords) do
            local regular, offgrid, blocked, home = specs:determineContent(coord.x, coord.y, serverSeed)

            if regular or home then
                specs:initialize(coord.x, coord.y, serverSeed)

                if destinations[specs.generationTemplate.path] then
                    target = {x=coord.x, y=coord.y}
                    break
                end
            end
        end

        if not target then
            print ("no target location found!")
            terminate()
        end


        local g = goods[goodName]

        local giver = Entity(giverIndex)
        local gx, gy = Sector():getCoordinates()

        missionData.timeLeft = 20 * 60
        missionData.good = g.name
        missionData.plural = g.plural
        missionData.amount = math.floor(amount)
        missionData.giverIndex = giverIndex
        missionData.giverName = Sector().name .. " " .. giver.translatedTitle
        missionData.stationIndex = 0
        missionData.factionIndex = giver.factionIndex
        missionData.giverCoordinates = {x = gx, y = gy}
        missionData.location = {x = target.x, y = target.y}
        missionData.reward = reward
        missionData.fulfilled = 0
        missionData.brief = "Deliver ${amount} ${plural}"%_t
        missionData.title = "Delivery: ${plural}"%_t
        missionData.justStarted = true

        Player():sendChatMessage("Client"%_T, 0, [[Please deliver the goods to \s(%s:%s).]]%_t, target.x, target.y)
    end
end

local interactedEntityIndex
function onStartDialog(entityIndex)

    if entityIndex == missionData.stationIndex and missionData.fulfilled == 0 then
        interactedEntityIndex = entityIndex
        ScriptUI(entityIndex):addDialogOption(string.format("Deliver %i %s"%_t, missionData.amount, missionData.plural), "onDeliver")
    end
end
function onDeliver(craftIndex)

    if onClient() then
        ScriptUI(interactedEntityIndex):showDialog(Dialog.empty())

        invokeServerFunction("onDeliver", Player().craftIndex)
        return
    end

    if missionData.fulfilled == 1 then return end

    local station = Entity(missionData.stationIndex)
    local ship = Entity(craftIndex)
    local cargo = ship:getCargoAmount(missionData.good) or 0
    local player = Player(callingPlayer)

    if cargo >= missionData.amount then

        if not station:isDocked(ship) then
            invokeClientFunction(player, "onGoodsDelivered", 2)
            return
        end

        -- remove cargo, pay reward
        player:receive(missionData.reward)
        ship:removeCargo(goods[missionData.good]:good(), missionData.amount)

        invokeClientFunction(player, "onGoodsDelivered", 0)

        -- don't terminate immediately, since this will close the dialog
        -- just set the timer to a few seconds so it will auto-terminate
        missionData.timeLeft = 5
        missionData.fulfilled = 1
    else
        invokeClientFunction(player, "onGoodsDelivered", 1)
    end


end

function onGoodsDelivered(errorCode)

    local dialog = {}

    if errorCode == 0 then
        dialog.text = "Thank you. We returned your deposit and transferred the reward to your account."%_t
        missionData.fulfilled = 1
        missionData.timeLeft = 5
    elseif errorCode == 1 then
        dialog.text = "There must have been a misunderstanding, you don't have all the cargo. We need ${amount} ${good}."%_t % missionData
        dialog.followUp = {text = "Please return when you have the goods."%_t}
    elseif errorCode == 2 then
        dialog.text = "You will have to dock to deliver the goods."%_t
    end

    ScriptUI(interactedEntityIndex):showDialog(dialog)

    return 1
end


function update(timePassed)
    if missionData.timeLeft then
        local before = missionData.timeLeft
        missionData.timeLeft = missionData.timeLeft - timePassed

        if onServer() then
            if missionData.timeLeft < 10 * 60 and before > 10 * 60 then
                local msg = "What are you doing? The client is waiting for his goods! Get them delivered!"%_t
                Player():sendChatMessage("Client"%_T, 0, msg)
            end
        end
    end
end

function getUpdateInterval()
    return 1
end

function updateServer(timePassed)
    if missionData.timeLeft < 0 then
        if missionData.fulfilled == 0 then
            local messages =
            {
                "Are you flying away with my goods? Thief! This will have consequences! You're fired!"%_t,
                "Where are you? You're late on your delivery! Someone else has delivered to the goods to the client. You're fired!"%_t,
                "Great. My courier is somewhere in the galaxy and not to be found. The client was waiting for his delivery! You're fired!"%_t,
            }

            Player():sendChatMessage("Client"%_T, 0, messages[getInt(1, #messages)])
            Galaxy():changeFactionRelations(Player(), Faction(missionData.factionIndex), -5000 - missionData.reward / 40.0)

            showMissionFailed()
        end

        showMissionAccomplished()
        terminate()
    end
end

function updateClient()

    local x, y = Sector():getCoordinates()
    if x == missionData.location.x and y == missionData.location.y then
        if not missionData.stationName and missionData.stationIndex ~= 0 then
            local entity = Entity(missionData.stationIndex)
            if entity then
                missionData.stationName = entity.translatedTitle

                displayChatMessage("Please deliver the cargo to the ${recipient}."%_t % {recipient = missionData.stationName}, "Client"%_t, 0)
            end
        end
    end
end

function onTargetLocationEntered(x, y)
    if missionData.stationIndex == 0 then
        -- find a station
        local stations = {Sector():getEntitiesByType(EntityType.Station)}

        if #stations == 0 then
            -- no stations for some reason? -> return cargo
            missionData.stationIndex = missionData.giverIndex
            missionData.location = missionData.giverCoordinates

            sync()
            Player():sendChatMessage("Client"%_T, 0, "It looks like the recipient has disappeared. Please return the cargo, we've updated your mission status."%_t)

            return
        else
            local station = stations[getInt(1, #stations)]

            missionData.stationIndex = station.index
        end

        sync()
    end
end

function getMissionDescription()

    local timeLeft = string.format("%i Minutes"%_t, math.floor(missionData.timeLeft / 60))

    if missionData.timeLeft < 60 then
        timeLeft = "< 1 min"%_t
    end

    local client = ""
    if missionData.stationName then
        client = string.format("The receiver's address is the %s."%_t, missionData.stationName)
    end

    local msg = "A client asked you to take care of an urgent delivery of ${amount} ${goods}.\n\n"%_t ..
        "The client expecting the goods is located at (${x}:${y}). "%_t..
        "${client}\n\n"%_t..
        "Time Left: ${time}"%_t

    local data = {client = client, amount = missionData.amount, goods = missionData.plural, x = missionData.location.x, y = missionData.location.y, time = timeLeft}

    return msg % data
end


function onSync()
    local g = goods[missionData.good]
    if g then
        g = g:good()
        missionData.plural = g.displayPlural
    end
end
