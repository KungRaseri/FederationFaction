package.path = package.path .. ";data/scripts/lib/?.lua"

The4 = require("story/the4")
require ("stringutility")

local interactable = true

function initialize()
    Entity().title = "Scanner Beacon"%_t
end

function interactionPossible(playerIndex, option)
    return interactable
end

function initUI()
    ScriptUI():registerInteraction("Activate"%_t, "onActivate")
end

function spawnTheFour()
    if onClient() then
        invokeServerFunction("spawnTheFour")
        return
    end

    The4.spawn(Sector():getCoordinates())

    terminate()
end

function onActivate()
    local dialog = {text = "OnActivate"}
    dialog.text = "Scanning..."%_t

    local positive = {}
    positive.text = "Success. Calling the collector."%_t
    positive.followUp = {text = "Please be patient. Extraction will begin soon."%_t, onEnd = "spawnTheFour"}

    local negative = {}
    negative.text = "Negative."%_t

    local ship = Player().craft

    -- check if the ship has a key equipped
    if ship:hasScript("systems/teleporterkey") then
        dialog.followUp = positive
    else
        dialog.followUp = negative
    end


    ScriptUI():showDialog(dialog)
end
