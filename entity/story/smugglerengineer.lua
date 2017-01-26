package.path = package.path .. ";data/scripts/lib/?.lua"

require ("stringutility")

function initialize()
    if onServer() then
        Entity():registerCallback("onDestroyed", "onDestroyed")
    end
end

function onDestroyed()
    for _, player in pairs({Sector():getPlayers()}) do
        player:invokeFunction("story/smugglerretaliation.lua", "fail")
    end
end

function initUI()
    ScriptUI():registerInteraction("Hello"%_t, "onInteract")
end

function interactionPossible(playerIndex, option)
    return true
end

function onInteract()
    local dialog = createMainDialog()

    ScriptUI():showDialog(dialog)
end

function startNextStage()
    if onClient() then
        invokeServerFunction("startNextStage")
        return
    end

    local player = Player(callingPlayer)
    local goods = {
        {name = "Neutron Accelerator", amount = 1},
        {name = "Electron Accelerator", amount = 1},
        {name = "Fusion Generator", amount = 2},
        {name = "Energy Inverter", amount = 5},
        {name = "Transformator", amount = 6},
        {name = "Semi Conductor", amount = 8},
        {name = "Processor", amount = 2},
    }

    player:invokeFunction("story/smugglerretaliation.lua", "startCollecting", goods, Entity().index)

end

function createMainDialog()

    local dialog = {}
    local coward = {}
    local smuggler = {}
    local revenge = {}
    local chiefEngineer = {}
    local betrayal = {}
    local instructions = {}

    local howDowWeStop = {answer = "How do we stop Bottan?"%_t, followUp = coward}
    local whoIsBottan = {answer = "Who is Bottan?"%_t, followUp = smuggler}
    local whatsInItForMe = {answer = "What's in it for me?"%_t, followUp = revenge}
    local whoAreYou = {answer = "Who are you?"%_t, followUp = chiefEngineer}
    local whyBetrayHim = {answer = "Why would you betray Bottan?"%_t, followUp = betrayal}
    local illHelpYou = {answer = "Alright, I'll help you."%_t, followUp = instructions}
    local noneOfMyBusiness = {answer = "That's none of my business."%_t}

    local initialAnswers = {
        howDowWeStop,
        whoIsBottan,
        whatsInItForMe,
        noneOfMyBusiness,
    }

    local mainAnswers = {
        illHelpYou,
        howDowWeStop,
        whoIsBottan,
        whatsInItForMe,
        whoAreYou,
        whyBetrayHim,
        noneOfMyBusiness,
    }

    dialog.text = "I've heard some impressive stories about you. Maybe we can work together to stop Bottan."%_t
    dialog.answers = initialAnswers

    coward.text = "Bottan is a coward. He won't do anything himself, and if there is only the slightest hint of combat, he'll jump away to safety."%_t
    coward.followUp = {text = "In order to catch him, we have to disable his hyperspace drive."%_t, answers = mainAnswers}

    smuggler.text = "He's a smuggler who operates in these sectors here."%_t
    smuggler.followUp = {text = "Or, more accurately, who lets others work for him."%_t, followUp = {
    text = "He won't do anything himself, and if there is only the slightest hint of combat, he'll jump away to safety."%_t, followUp = {
    text = "A few months back, he got his hands on some Xsotan hyperspace tech."%_t, followUp = {
    text = "It was me who integrated it into his ship."%_t, followUp = {
    text = "Now he can jump three times as far as other ships, and five times as quick, and nobody can catch him."%_t, followUp = {
    text = "But he made a big mistake when he threw me out."%_t, followUp = {
    text = "He doesn't know that I know of a way to disable his precious hyperspace drive."%_t, answers = mainAnswers
    }}}}}}}

    revenge.text = "You'll get revenge on a man who betrayed you."%_t
    revenge.followUp = {text = "And, maybe, we can extract the Xsotan tech from his ship. I'll modify it so you can integrate it into your ship."%_t, answers = mainAnswers}

    chiefEngineer.text = "I was Bottan's chief engineer. As such, I know everyhting about his hyperspace engine. It was me who integrated the Xsotan Technology into the ship."%_t
    chiefEngineer.followUp = {text = "That same drive that allows him to jump extreme distances very quickly."%_t, followUp = {
    text = "Since I know how it works, I can build a ray that disables his engine."%_t, answers = mainAnswers
    }}

    betrayal.text = "That's none of your business, but I'll tell you this much: He betrayed me, one of his most loyal men!"%_t
    betrayal.followUp = {text = "Now I'm a fugitive, hunted by my former friends and nearly all factions in the quadrant."%_t, followUp = {
    text = "I can't just let that go without retaliation."%_t, answers = mainAnswers
    }}


    instructions.text = "Since I have to remain here, I need you to organize all the parts I need to build the disruption ray."%_t
    instructions.followUp = {text = "I've sent the list of the parts to your ship."%_t, followUp = {
    text = "Come back once you have them."%_t, followUp = {
    text = "I don't care how you get them, do what you must."%_t, followUp = {
    text = "Just get me those parts."%_t, onEnd = "startNextStage"
    }}}}

    return dialog
end
