package.path = package.path .. ";data/scripts/lib/?.lua"

require("stringutility")
The4 = require("story/the4")

function interactionPossible(player)
--    if not interacted then return 1 end
    return true
end

function getUpdateInterval()
    return 0.5
end

function initialize()

end

function initUI()
    ScriptUI():registerInteraction("Hello.", "onInteract")
end

function startAttacking()
    local ships = {Sector():getEntitiesByFaction(Entity().factionIndex)}

    if onClient() then
        for _, ship in pairs(ships) do
            if ship:hasComponent(ComponentType.Plan) then
                registerBoss(ship.index)
                if ship.title:match("Tankem") then setBossHealthColor(ship.index, ColorRGB(1.0, 0.5, 0.3)) end
                if ship.title:match("Reconstructo") then setBossHealthColor(ship.index, ColorRGB(0.2, 0.7, 0.2)) end
            end
        end
        invokeServerFunction("startAttacking")
        return
    end

    local players = {Sector():getPlayers()}

    for _, player in pairs(players) do
        for _, ship in pairs(ships) do
            if ship:hasComponent(ComponentType.ShipAI) then
                ShipAI(ship.index):registerEnemyFaction(player.index)
                ShipAI(ship.index):setAggressive()
            end
        end
    end

end

function onInteract()
    local dialog = {}
    local giveItToUs = {}
    local extraction = {}
    local notImportant = {}
    local noChoice = {}

    notImportant.text = "You are looking at the first people in centuries who will fly into Xsotan territory."%_t
    notImportant.followUp = {text = "Once we've collected all the artifacts, we'll be able to open the gateway and recover the Xsotan's treasures and technology!"%_t,
    followUp = {text = "But you won't have to worry about that. All that's important is that you brought us one of the artifacts."%_t,
    followUp = giveItToUs
    }}


    noChoice.text = "You don't understand."%_t
    noChoice.followUp = { text = "We are not giving you a choice."%_t, followUp = extraction}

    extraction.text = "And we don't want any witnesses or competition."%_t
    extraction.followUp = {text = "Boys and girls, let's blow this maggot to space dust and get the artifact!"%_t, onEnd = "startAttacking"}

    giveItToUs.text = "You will now give it to us."%_t
    giveItToUs.answers = {
        {
            answer = "Here, have it."%_t, followUp = extraction,
        },
        {
            answer = "Who are you?"%_t,
            followUp = notImportant
        },
        {
            answer = "What about my reward?"%_t,
            text = "Oh man, look at this one!"%_t,
            followUp = {text = "Did you really think you'd get a reward?"%_t,
            followUp = {text = "We lied!"%_t, followUp = extraction
            }}
        },
        {
            answer = "On second thought, I'd rather not."%_t,
            followUp = noChoice
        },
    }


    dialog.text = "I can't believe it, our bulletin actually worked!"%_t
    dialog.answers = {
        {
            answer = "I have your artifact."%_t,
            text = "Yes, we know."%_t,
            followUp = giveItToUs,
        },
        {answer = "Who are you? /*plural*/"%_t, followUp = notImportant},
        {answer = "Yeah, I'm leaving now."%_t, followUp = noChoice},
    }

    ScriptUI():showDialog(dialog, 0)
end

function updateClient()
    if not interacted and Entity().title == "Tankem" then
        Player():startInteracting(Entity(), "story/the4.lua", 0)
        interacted = true
    end
end

function updateServer()
    if Sector().numPlayers == 0 then
        Sector():deleteEntity(Entity())
    end
end





