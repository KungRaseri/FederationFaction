package.path = package.path .. ";data/scripts/lib/?.lua"

local Dialog = require ("dialogutility")
require ("mission")
require ("goods")
require ("randomext")
require ("stringutility")

-- this is the public interface for the game, for retrieving data and calling functions
function initialize(goodName, amount, stationIndex, cx, cy, reward)
    if onClient() then

        Player():registerCallback("onStartDialog", "onStartDialog")

        missionData.timeLeft = 0
        missionData.good = ""
        missionData.plural = ""
        missionData.amount = 0
        missionData.stationIndex = 0
        missionData.location = {x = 0, y = 0}
        missionData.stationName = ""
        missionData.reward = 0
        missionData.fulfilled = false

        sync()

    else
        if not goodName then return end

        local g = goods[goodName]
        if not g then return end

        local station = Entity(stationIndex)

        missionData.timeLeft = 30 * 60
        missionData.good = g.name
        missionData.plural = g.plural
        missionData.amount = amount
        missionData.stationIndex = stationIndex
        missionData.location = {x = cx, y = cy}
        missionData.stationName = Sector().name .. " " .. station.translatedTitle
        missionData.reward = reward
        missionData.fulfilled = false
        missionData.brief = "Organize ${amount} ${plural}"%_t
        missionData.title = "Organize ${plural}"%_t
        missionData.justStarted = true

    end
end

local interactedEntityIndex
function onStartDialog(entityIndex)
    if entityIndex == missionData.stationIndex and not missionData.fulfilled then
        interactedEntityIndex = entityIndex
        ScriptUI(entityIndex):addDialogOption("Deliver ${amount} ${plural}"%_t % missionData, "onDeliver")
    end
end

function onDeliver(craftIndex)
    if onClient() then
        ScriptUI(interactedEntityIndex):showDialog(Dialog.empty())

        invokeServerFunction("onDeliver", Player().craftIndex)
        return
    end

    if missionData.fulfilled then return end

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
        missionData.fulfilled = true
    else
        invokeClientFunction(player, "onGoodsDelivered", 1)
    end


end

function onGoodsDelivered(errorCode)

    local dialog = {}

    if errorCode == 0 then
        dialog.text = "Thank you. We transferred the reward to your account."%_t
        missionData.fulfilled = true
        missionData.timeLeft = 3
    elseif errorCode == 1 then
        dialog.text = "There must have been a misunderstanding, you don't have the cargo."%_t
        dialog.followUp = {text = "Please return when you have the goods."%_t}
    elseif errorCode == 2 then
        dialog.text = "You will have to dock to deliver the goods."%_t
    end

--    ScriptUI(interactedEntityIndex):showDialog(nil)
    ScriptUI(interactedEntityIndex):showDialog(dialog)

    return 1
end


function update(timePassed)
    if missionData.timeLeft then missionData.timeLeft = missionData.timeLeft - timePassed end
end

function getUpdateInterval()
    return 1
end

function updateServer(timePassed)
    if missionData.timeLeft < 0 then

        if missionData.fulfilled then
            showMissionAccomplished()
        else
            showMissionFailed()
        end

        terminate()
    end
end

function getMissionDescription()

    missionData.timeLeftStr = string.format("%i Minutes"%_t, math.floor(missionData.timeLeft / 60))

    if missionData.timeLeft < 60 then
        missionData.timeLeftStr = "< 1 min"%_t
    end

    return [[The ${stationName} asked you for an urgent delivery of ${amount} ${plural}.

Upon delivering, you will receive payment for the goods as well as a bonus.

Time Left: ${timeLeftStr}]]%_t % missionData

end

function onSync()
    local g = goods[missionData.good]
    if g then
        g = g:good()
        missionData.plural = g.displayPlural
    end
end
