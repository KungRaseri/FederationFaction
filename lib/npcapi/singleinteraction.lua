-- this API provides code for npcs that will speak to the player by themselves, once.
-- a function getSingleInteractionDialog() must be defined in the script, which should return the dialog that is to be displayed.

data = data or {}
data.interacted = {}

local receivedData

function interactionPossible(player, option)
    return true
end

function initialize()
    if onClient() then sync() end
end

function getUpdateInterval()
    return 1.0
end

function updateClient(timeStep)
    if not receivedData then return end
    if data.interacted[Player().index] then return end

    rememberInteractionWithPlayer()

    ScriptUI():interactShowDialog(getSingleInteractionDialog())
end


function rememberInteractionWithPlayer()
    if onClient() then
        data.interacted[Player().index] = true
        invokeServerFunction("rememberInteractionWithPlayer")
        return
    end

    data.interacted[callingPlayer] = true

    sync()
end

function sync(data_in)
    if onServer() then
        invokeClientFunction(Player(callingPlayer), "sync", data)
    else
        if data_in then
            data = data_in
            receivedData = true
        else
            invokeServerFunction("sync")
        end
    end
end

function secure()
    return data
end

function restore(data_in)
    data = data_in
end

