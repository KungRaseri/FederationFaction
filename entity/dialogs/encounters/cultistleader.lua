package.path = package.path .. ";data/scripts/lib/?.lua"
require("stringutility")

Dialog = require ("dialogutility")

function interactionPossible(player)
    return true
end

function initialize()
    InteractionText(Entity().index).text = "Om..."%_t
end

function initUI()
    ScriptUI():registerInteraction("What's going on here?"%_t, "onInteract")
end

function onInteract()
    ScriptUI():showDialog(normalDialog(), 0)
end

function normalDialog()
    local dialog =
    {
        text = "Hush! We are in the middle of our ceremony."%_t,
        answers = {
            {
                answer = "I see, sorry."%_t
            },
            {
                answer = "It'll have to wait, I'm talking to you."%_t,
                onSelect = "startFight"
            }
        }
    }
    return dialog
end

function startFight()
    local entity = Entity()
    if onClient() then
        displayChatMessage(string.format("%s is attacking!"%_t, entity.title), "", 2)
        invokeServerFunction("startFight")
        return
    end

    Galaxy():changeFactionRelations(Faction(entity.factionIndex), Faction(callingPlayer), -200000)

    for _, cultist in pairs({Sector():getEntitiesByFaction(entity.factionIndex)}) do
        if cultist:hasComponent(ComponentType.ShipAI) then
            ShipAI(cultist.index):setAggressive()
        end
    end

    terminate()
end
