package.path = package.path .. ";data/scripts/lib/?.lua"

-- make the NPC talk to players
require("npcapi/singleinteraction")
require("stringutility")

-- the data variable is created by the singleinteraction.lua api
-- we can just add more variables and it will be saved in the database by the singleinteraction api.
data.given = {}


function getSingleInteractionDialog()
    return makeDialog()
end

function makeDialog()
    local d0_HelloThereAreYo = {}
    local d1_ThatsGreat = {}
    local d2_TwoHundredYears = {}
    local d3_PeopleDontKnowF = {}
    local d4_IveHeardRumorsT = {}
    local d5_OhThatsAlright = {}
    local d6_ImOnTheHuntOf = {}
    local d7_ImSureWeCanHelp = {}
    local d8_ThankYouYouKnow = {}
    local d9_HaveThisItsAnUp = {}
    local d10_IllBeHereForA = {}
    local d11_NobodyKnowsWhoT = {}
    local d12_ImNotSureYetBut = {}
    local d13_OfCourseTheClos = {}

    d0_HelloThereAreYo.text = "Hello there! Are you off on an adventure, too?"%_t
    d0_HelloThereAreYo.answers = {
        {answer = "Absolutely!"%_t, followUp = d1_ThatsGreat},
        {answer = "I'd like to keep to myself."%_t, followUp = d5_OhThatsAlright}
    }
    d0_HelloThereAreYo.onStart = "onMeetAdventurer"

    d1_ThatsGreat.text = "That's great!"%_t
    d1_ThatsGreat.followUp = d7_ImSureWeCanHelp

    d2_TwoHundredYears.text = "Two hundred years ago, there was a cataclysmic catastrophe, which nearly ripped our entire galaxy apart!\n\nEverybody just calls it \"The Event\". "%_t
    d2_TwoHundredYears.answers = {
        {answer = "What happened?"%_t, followUp = d3_PeopleDontKnowF},
        {answer = "Let's talk about something else."%_t, followUp = d7_ImSureWeCanHelp},
        {answer = "I'd like to leave now."%_t, followUp = d5_OhThatsAlright}
    }

    d3_PeopleDontKnowF.text = "People don't know for sure. But legend has it that an unsurmountable ring of torn hyperspace fabric appeared around the center of the galaxy!\n\nAnd now our hyperspace engines can’t pass it to get to the center, meaning it's cut off from the rest of the galaxy.\n\nSince the event nobody has managed to get near the center of the galaxy.\n\nThe worst part is that the event also spawned hyperspace rifts throughout the galaxy, which makes navigation difficult.\n\nAnd then there's the Xsotan."%_t
    d3_PeopleDontKnowF.answers = {
        {answer = "Go on."%_t, followUp = d11_NobodyKnowsWhoT},
        {answer = "Let's talk about something else."%_t, followUp = d7_ImSureWeCanHelp},
        {answer = "I'd like to leave now."%_t, followUp = d5_OhThatsAlright}
    }

    d4_IveHeardRumorsT.text = "I've heard rumors that there's lots and lots of it in the center!\n\nApparently it's the perfect element for building space ships. It's robust and light, and its energy properties are crazy!\n\nBut so far nobody has ever found much of it, but I'm going to change that!\n\nI'm going to fly to the center of the galaxy, I'm going to overcome the barrier and then I'll mine all the Avorion I can find so I'll get rich!"%_t
    d4_IveHeardRumorsT.answers = {
        {answer = "I wish you best of luck on your journey."%_t, followUp = d8_ThankYouYouKnow},
        {answer = "How do you want to overcome the barrier?"%_t, followUp = d12_ImNotSureYetBut},
        {answer = "Let's talk about something else."%_t, followUp = d7_ImSureWeCanHelp},
        {answer = "I'd like to leave now."%_t, followUp = d5_OhThatsAlright}
    }
    d4_IveHeardRumorsT.onEnd = "onPlayerIntroDone"

    d5_OhThatsAlright.text = "Oh, that's alright! "%_t
    d5_OhThatsAlright.followUp = d10_IllBeHereForA

    d6_ImOnTheHuntOf.text = "I'm on the hunt of a new element, called 'Avorion'. \n\nAfter the event 200 years ago, it just appeared!"%_t
    d6_ImOnTheHuntOf.followUp = d4_IveHeardRumorsT

    d7_ImSureWeCanHelp.text = "I'm sure we can help each other out. If there's anything you'd like to know, just ask away!"%_t
    d7_ImSureWeCanHelp.answers = {
        {answer = "Can you give me some tips?"%_t, followUp = d13_OfCourseTheClos},
        {answer = "What's happening around here?"%_t, followUp = d2_TwoHundredYears},
        {answer = "What are you doing?"%_t, followUp = d6_ImOnTheHuntOf},
        {answer = "Goodbye."%_t, followUp = d10_IllBeHereForA}
    }

    d8_ThankYouYouKnow.text = "Thank you! You know what? Here ..."%_t
    d8_ThankYouYouKnow.followUp = d9_HaveThisItsAnUp
    d8_ThankYouYouKnow.onEnd = "givePlayerGoodie"

    d9_HaveThisItsAnUp.text = "Have this! It's an upgrade for your ship. It allows you to scan for hidden sectors. \n\nYou'll have to install it in your ship menu for it to work! But you can only install upgrades into a real ship, it doesn't work with drones or fighters.\n\nThe green blips on your galaxy map are sectors where you can find interesting stuff, but there's also a lot of things that your radar can't pick up. \n\nWith this upgrade, you'll be able to scan for those hidden secrets! They'll show up as a yellow blip on your map."%_t
    d9_HaveThisItsAnUp.answers = {
        {answer = "Thank you."%_t, followUp = d7_ImSureWeCanHelp},
        {answer = "Goodbye."%_t, followUp = d10_IllBeHereForA}
    }

    d10_IllBeHereForA.text = "I'll be here for a while in case you want to talk. \n\nAnd even if not, I'm sure we're going to meet again some other time."%_t

    d11_NobodyKnowsWhoT.text = "Nobody knows who they are, and they don't answer any intercom calls. When you get too close to them, they start attacking.\n\nThey have been around since the event, and some people say they were created by it. \n\nBut there is also a bright side!\n\nTogether with the event a new metallic element called \"Avorion\" has appeared!\n"%_t
    d11_NobodyKnowsWhoT.followUp = d4_IveHeardRumorsT

    d12_ImNotSureYetBut.text = "I'm not sure yet. But there has to be a way! I know it!\n\nBesides, it wouldn't be a very good adventure if everything was clear from the start, would it?"%_t
    d12_ImNotSureYetBut.answers = {
        {answer = "I wish you best of luck on your journey."%_t, followUp = d8_ThankYouYouKnow},
        {answer = "I'll be on my way then."%_t, followUp = d5_OhThatsAlright}
    }

    d13_OfCourseTheClos.text = "Of course!\n\nThe closer you get to the center of the galaxy, the better materials you'll find to build your ship. You'll be able to build energy generators or parts that protect your ship, like integrity blocks or even shield generators. \n\nThe first thing you should do is find yourself some Titanium. Iron is great to get yourself started, but Titanium is lighter and you can build better parts with it.\n\nAnd be wary of the no man's space around here. I hear there's a pirate leader who terrorizes everyone who strays too far away from the civilised sectors."%_t
    d13_OfCourseTheClos.answers = {
        {answer = "Let's talk about something else."%_t, followUp = d7_ImSureWeCanHelp},
        {answer = "I'd like to leave now."%_t, followUp = d5_OhThatsAlright}
    }

    return d0_HelloThereAreYo
end

function initUI()
    ScriptUI():registerInteraction("Greet", "onGreet")
end

function onGreet()
    ScriptUI():showDialog(makeDialog())
end

function onMeetAdventurer()
    if onClient() then
        invokeServerFunction("onMeetAdventurer")
        return
    end

    Player(callingPlayer):setValue("met_adventurer", true)

end

function givePlayerGoodie()
    if onClient() then
        invokeServerFunction("givePlayerGoodie")
        return
    end

    if data.given[callingPlayer] then return end
    data.given[callingPlayer] = true

    local player = Player(callingPlayer)
    player:getInventory():add(SystemUpgradeTemplate("data/scripts/systems/radarbooster.lua", Rarity(1), Seed(124)))

end

function onPlayerIntroDone()
    if onClient() then
        invokeServerFunction("onPlayerIntroDone")
        return
    end

    Player(callingPlayer):setValue("story_intro_done", true)

end

