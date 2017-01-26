package.path = package.path .. ";data/scripts/lib/?.lua"
require("stringutility")

function nothing1()
    local d0_NotThatIKnowOf = {}

    d0_NotThatIKnowOf.text = "I don't know about anything, but it's always possible someone else knows something. You should keep asking around.\n\nOh, and people at different places in the galaxy will know different things."%_t
    d0_NotThatIKnowOf.answers = {
        {answer = "Thanks, I'll keep asking around."%_t}
    }

    return d0_NotThatIKnowOf
end
function nothing2()
    local d0_NotThatIKnowOf = {}

    d0_NotThatIKnowOf.text = "Not that I know of, but that doesn't mean anything.\n\nIf you're looking for work, you should check the bulletin boards of the stations around here."%_t
    d0_NotThatIKnowOf.answers = {
        {answer = "Thank you, I'll have a look."%_t}
    }


    return d0_NotThatIKnowOf
end


function swoks1()
    local d0_IveHeardThatAPi = {}

    d0_IveHeardThatAPi.text = "I've heard that a pirate called 'Swoks' has started raiding freighters nearby. Bad for business, you know?\n\nHe's keeping it low profile, ships just disappear. But everybody knows it's him.\n\nYou should not go explore on your own in these sectors around here."%_t
    d0_IveHeardThatAPi.answers = {
        {answer = "Thanks, I'll keep it in mind."%_t}
    }

    return d0_IveHeardThatAPi
end
function swoks2()
    local d0_TheresANewPirat = {}

    d0_TheresANewPirat.text = "There's a new pirate captain who has been raiding freighters around here lately.\n\nI haven't seen him in one of the civilized sectors yet, but you should be careful when exploring in no man's space."%_t
    d0_TheresANewPirat.answers = {
        {answer = "I'll keep it in mind."%_t}
    }

    return d0_TheresANewPirat
end


function ai1()
    local d0_NotReallyExcept = {}
    local d1_YesIDidntPayAtt = {}
    local d2_WhatDoIKnowIm = {}
    local d3_ItWasOneOfThese = {}

    d0_NotReallyExcept.text = "Not really. Except that I nearly got killed a few weeks ago by one of those war machines.\n\n"%_t
    d0_NotReallyExcept.answers = {
        {answer = "War machines?"%_t, followUp = d1_YesIDidntPayAtt},
        {answer = "Very interesting. Goodbye."%_t}
    }

    d1_YesIDidntPayAtt.text = "Yes! I didn't pay attention during a hyperspace jump recalculation and all of a sudden this thing attacked me!"%_t
    d1_YesIDidntPayAtt.answers = {
        {answer = "Why did it attack you?"%_t, followUp = d2_WhatDoIKnowIm},
        {answer = "What thing?"%_t, followUp = d3_ItWasOneOfThese},
        {answer = "Very interesting. Goodbye."%_t}
    }

    d2_WhatDoIKnowIm.text = "What do I know? I'm lucky I got away. Someone should take care of these things."%_t

    d3_ItWasOneOfThese.text = "It was one of these huge ships. They're usually dormant, but for some reason this one wasn't."%_t

    return d0_NotReallyExcept
end
function ai2()
    local d0_AFewCenturiesAg = {}
    local d1_TheyHaveBeenLon = {}
    local d2_WhatDoYouThinkT = {}

    d0_AFewCenturiesAg.text = "A few centuries ago, a highly advanced species lived in these sectors."%_t
    d0_AFewCenturiesAg.answers = {
        {answer = "Where are they now?"%_t, followUp = d1_TheyHaveBeenLon},
        {answer = "Very interesting. Goodbye."%_t}
    }

    d1_TheyHaveBeenLon.text = "They have been long gone, but some say that they fought the Xsotan."%_t
    d1_TheyHaveBeenLon.answers = {
        {answer = "What happened?"%_t, followUp = d2_WhatDoYouThinkT},
        {answer = "Very interesting. Goodbye."%_t}
    }

    d2_WhatDoYouThinkT.text = "What do you think? They lost. All that remains of them now is their technology."%_t

    return d0_AFewCenturiesAg
end


function trader1()
    local d0_OneOfTheTravell = {}

    d0_OneOfTheTravell.text = "One of the travelling equipment traders I met a while ago had a strange alien artifact with him. I've never seen something like that before.\n\nI thought maybe it's Xsotan? But that's impossible. He even told me I could integrate it into my ship. \n\nBut when I asked about the price it was way too expensive."%_t
    d0_OneOfTheTravell.answers = {
        {answer = "Thanks."%_t}
    }

    return d0_OneOfTheTravell
end
function trader2()
    local d0_ThereAreTravell = {}

    d0_ThereAreTravell.text = "There are travelling merchants who sell all sorts of things. You should keep an eye on them, they will jump to the next sector after a while if they don't find anybody to trade with. \n\nSome of them have really exotic wares, I even met some who had old Xsotan artifacts for sale."%_t
    d0_ThereAreTravell.answers = {
        {answer = "Thanks."%_t}
    }

    return d0_ThereAreTravell
end


function exodus1()
    local d0_IfYoureTheTreas = {}

    d0_IfYoureTheTreas.text = "If you're the treasure hunting type, the you should check asteroid fields in the no man's space for beacons. \n\nI've seen lots of beacons on my travels, and they seem to have some message for all members of 'Operation Exodus'. Whatever this may be."%_t
    d0_IfYoureTheTreas.answers = {
        {answer = "Thanks, I'll check it out."%_t}
    }

    return d0_IfYoureTheTreas
end
function exodus2()
    local d0_AFriendOfMineIs = {}

    d0_AFriendOfMineIs.text = "A friend of mine is obsessed with these beacons you can find in asteroid fields around here. \n\nHe says they have some kind of message encoded into them, with coordinates leading to a great treasure. \n\nBut that's all nonsense if you ask me."%_t
    d0_AFriendOfMineIs.answers = {
        {answer = "Thanks, I'll keep it in mind."%_t}
    }

    return d0_AFriendOfMineIs
end

function research1()
    local d0_TheResearchLabs = {}

    d0_TheResearchLabs.text = "The research labs are getting better and better. Now they're using genetic algorithms to improve the quality of the researched objects. \n\nIt destroys the objects you put in, but you have a good chance to get an object of an even better quality.\n\nI wonder what happens when you put in three objects with the best quality there is. Maybe the universe will implode?"%_t
    d0_TheResearchLabs.answers = {
        {answer = "Huh. I guess I'll try!"%_t}
    }

    return d0_TheResearchLabs
end
function research2()
    local d0_AFriendOfMineGo = {}
    local d1_OhWowYoureGulli = {}

    d0_AFriendOfMineGo.text = "A friend of mine got some great new equipment because he researched it at the research lab! \n\nIt's a little like playing the lottery, but if you put in 5 objects, apparently you're guaranteed to get something better. \n\nI'll do this too, and in the end I'll put in 3 objects of the highest possible rarity. I wonder what happens then..."%_t
    d0_AFriendOfMineGo.answers = {
        {answer = "I've heard the universe might implode."%_t, followUp = d1_OhWowYoureGulli},
        {answer = "I guess I'll have to try."%_t}
    }

    d1_OhWowYoureGulli.text = "Oh wow, you're gullible!\n\nThe universe can't implode, and we're only subjects that have been made up by someone. Once that someone wants us gone, we'll go."%_t
    d1_OhWowYoureGulli.answers = {
        {answer = "This is getting a little too dark for me."%_t},
        {answer = "Goodbye."%_t}
    }

    return d0_AFriendOfMineGo
end


function smuggler1()
    local d0_IHearTheresASmu = {}
    local d1_IKnowButAsFar = {}

    d0_IHearTheresASmu.text = "I hear there's a smuggler around here who got his hands on some Xsotan technology. "%_t
    d0_IHearTheresASmu.answers = {
        {answer = "That sounds interesting."%_t, followUp = d1_IKnowButAsFar},
        {answer = "I'll leave now."%_t}
    }

    d1_IKnowButAsFar.text = "I know, but as far as I know, nobody has ever caught him. \n\nApparently his hyperspace engine is extremely advanced and he can jump anywhere in the entire galaxy!"%_t

    return d0_IHearTheresASmu
end
function smuggler2()
    local d0_YouShouldBeware = {}

    d0_YouShouldBeware.text = "You should beware of Bottan. He's a smuggler who doesn't have the courage to fly his own deals, even though he has the most advanced hyperspace engine I've ever seen.\n\nHe lets others do his dirty work for him, so he won't get in trouble."%_t
    d0_YouShouldBeware.answers = {
        {answer = "I'll be careful."%_t}
    }

    return d0_YouShouldBeware
end
function smuggler3()
    local d0_AfterThisScumba = {}
    local d2_ApparentlyThisN = {}
    local d3_BecauseEveryone = {}

    d0_AfterThisScumba.text = "After this scumbag Bottan got his hands on this Xsotan technology, he's become a real pain. \n\nHe built up a big smuggling ring, and since then has been betraying people over and over."%_t
    d0_AfterThisScumba.answers = {
        {answer = "Why doesn't anybody stop him?"%_t, followUp = d2_ApparentlyThisN},
        {answer = "Why do people follow him?"%_t, followUp = d3_BecauseEveryone},
        {answer = "Goodbye."%_t}
    }

    d2_ApparentlyThisN.text = "Apparently this new Xsotan technology made his hyperspace engine crazy strong. "%_t
    d2_ApparentlyThisN.answers = {
        {answer = "Why do people follow him?"%_t, followUp = d3_BecauseEveryone},
        {answer = "Goodbye."%_t}
    }

    d3_BecauseEveryone.text = "Because everyone wants some of the money he's making! He's betraying wanna-be smugglers who can't help themselves. \n\nPoor bastards. But it's their own fault. They should just stick to normal trade."%_t
    d3_BecauseEveryone.answers = {
        {answer = "Why doesn't anybody stop him?"%_t, followUp = d2_ApparentlyThisN},
        {answer = "Goodbye."%_t}
    }

    return d0_AfterThisScumba
end


function energylab1()
    local d0_ItsFunnyThatYou = {}

    d0_ItsFunnyThatYou.text = "It's funny that you ask, because I found some research satellites in the sectors around here.\n\nApparently someone is doing state of the art energy research with those things. They were looking really expensive. I wonder what kind of equipment must be used in there."%_t
    d0_ItsFunnyThatYou.answers = {
        {answer = "Thanks, I'll keep an eye out."%_t}
    }

    return d0_ItsFunnyThatYou
end
function energylab2()
    local d0_TheMADScienceAs = {}

    d0_TheMADScienceAs.text = "The M.A.D. Science Association has started looking into new ways of energy generation. I found some of their satellites just floating around in space. \n\nI don't think that's such a good idea with all the bandits and Xsotan around here. I'm pretty sure they have state of the art equipment."%_t
    d0_TheMADScienceAs.answers = {
        {answer = "Thanks, I'll keep an eye out."%_t}
    }

    return d0_TheMADScienceAs
end
function energylab3()
    local d0_HaveYouSeenTheN = {}

    d0_HaveYouSeenTheN.text = "Have you seen the new energy satellites by the M.A.D. Science Association? They're full of state of the art energy equipment. \n\nAnd nobody is guarding them! It's like they're asking people to steal or salvage them!\n\nDon't tell anybody, but once I'm done with work, I'll see if I can grab one of them. "%_t
    d0_HaveYouSeenTheN.answers = {
        {answer = "Uhh... Thanks?"%_t}
    }

    return d0_HaveYouSeenTheN
end
function energylab4()
    local d0_HaveYouSeenTheN = {}

    d0_HaveYouSeenTheN.text = "The M.A.D. Science Association is researching new electricity weapons. A complete waste of time if you ask me.\n\nEverybody knows that electricity can't do anything against stone.\n\nOn the other hand, who would plate his ship with stones?"%_t
    d0_HaveYouSeenTheN.answers = {
        {answer = "Huh. Good to know."%_t}
    }

    return d0_HaveYouSeenTheN
end
function energylab5()
    local d0_HaveYouSeenTheN = {}

    d0_HaveYouSeenTheN.text = "A friend of mine got some new electriciy weapons from the M.A.D. Science Association.\n\nBut when he tried them out, he realized that they don't do anything to asteroids!\n\nWhat good is a weapon that you can't even use on stone?"%_t
    d0_HaveYouSeenTheN.answers = {
        {answer = "Huh. Good to know."%_t}
    }

    return d0_HaveYouSeenTheN
end


function thefour1()
    local d0_IWasRecentlyCon = {}

    d0_IWasRecentlyCon.text = "I was recently contacted by a group of people who are apparently looking for Xsotan artifacts.\n\nAs if I had anything to do with this nonsense! I told them they should maybe post a bulletin with a reward."%_t
    d0_IWasRecentlyCon.answers = {
        {answer = "Thanks, I'll check it out."%_t}
    }

    return d0_IWasRecentlyCon
end
function thefour2()
    local d0_YoureNotTheOnly = {}

    d0_YoureNotTheOnly.text = "You're not the only one asking around here lately. Recently there have been people who were looking for Xsotan artifacts. \n\nThey said they wanted to journey to the center of the galaxy. That's crazy if you ask me."%_t
    d0_YoureNotTheOnly.answers = {
        {answer = "Thanks, I'll keep an eye out."%_t}
    }

    return d0_YoureNotTheOnly
end
function thefour3()
    local d0_HaveYouSeenThes = {}

    d0_HaveYouSeenThes.text = "Have you seen these bulletins that have been around on stations lately? Someone must be really desperate to get their hands on these Xsotan artifacts. \n\nI really wonder why anybody would want to have anything to do with these monsters."%_t
    d0_HaveYouSeenThes.answers = {
        {answer = "Thanks, I'll keep an eye out."%_t}
    }

    return d0_HaveYouSeenThes
end



function rift1()
    local d0_IfYouHaventNoti = {}
    local d1_ImNotSureButIt = {}

    d0_IfYouHaventNoti.text = "If you haven't noticed yet, there's a subspace rift that's preventing people from going to the center of the galaxy.\n\nSome say it's the Xsotan. Some say it's just a natural phenomenon and that it will pass."%_t
    d0_IfYouHaventNoti.answers = {
        {answer = "What do you think?"%_t, followUp = d1_ImNotSureButIt},
        {answer = "Thanks. Goodbye."%_t}
    }

    d1_ImNotSureButIt.text = "I'm not sure. But it sure as hell isn't going away.\n\nMy grandfather already knew this barrier. But when he was a boy, it was a lot nearer to the center of the galaxy."%_t

    return d0_IfYouHaventNoti
end
function rift2()
    local d0_HaveYouNotSeenT = {}

    d0_HaveYouNotSeenT.text = "Have you not seen the rift?\n\nAh, of course not, you can't see it. But no hyperspace drive can get past it!\n\nI wonder what's inside?"%_t

    return d0_HaveYouNotSeenT
end
function rift3()
    local d0_YouShouldBeCare = {}
    local d1_JustOverTheRift = {}

    d0_YouShouldBeCare.text = "You should be careful. The Xsotan are nearby."%_t
    d0_YouShouldBeCare.answers = {
        {answer = "Where?"%_t, followUp = d1_JustOverTheRift},
        {answer = "I'll be careful."%_t}
    }

    d1_JustOverTheRift.text = "Just over the rift a few sectors further in.\n\nI don't know how they do it, but they must have found a way to cross the rift."%_t

    return d0_YouShouldBeCare
end
function rift4()
    local d0_LastWeekICameAc = {}

    d0_LastWeekICameAc.text = "Last week I came across some strange asteroid formations near the rift.\n\nThere were eight asteroids aligned in a circle, and they had some kind of metal structures built onto them, that all pointed into the middle. \n\nI wonder what this is all about."%_t
    d0_LastWeekICameAc.answers = {
        {answer = "Thanks."%_t}
    }

    return d0_LastWeekICameAc
end

local dialogs =
{
    {
        from = 0, to = math.huge,
        dialogs = {nothing1(), nothing2()}
    },
    {
        from = 370, to = 425,
        dialogs = {swoks1(), swoks2()}
    },
    {
        from = 280, to = 325,
        dialogs = {ai1(), ai2()}
    },
    {
        from = 250, to = math.huge,
        dialogs = {smuggler1(), smuggler2(), smuggler3()}
    },
    {
        from = 150, to = math.huge,
        dialogs = {exodus1(), exodus2(), trader1(), trader2(), research1(), research2()}
    },
    {
        from = 150, to = 250,
        dialogs = {energylab1(), energylab2(), energylab3(), energylab4(), energylab5()}
    },
    {
        from = 150, to = 180,
        dialogs = {rift1(), rift2(), rift3(), rift4(), thefour1(), thefour2(), thefour3()}
    },

}


package.path = package.path .. ";data/scripts/lib/?.lua"
require("faction")
require("randomext")

function interactionPossible(playerIndex, option)
    if Player(playerIndex).craftIndex == Entity().index then return false end

    local ok, msg = CheckFactionInteraction(playerIndex, -15000)

    if not ok then
        local responses =
        {
            "Don't talk to me."%_t,
            "I have nothing to say to you."%_t,
            "I don't know why I should talk to you."%_t,
            "Why do you think I'd talk to you?"%_t,
            "Go away."%_t,
            "Leave me alone."%_t,
            "I might know something, but I won't tell you."%_t,
            "There is nothing that I want to tell you."%_t,
        }

        msg = randomEntry(random(), responses)
    end

    return ok, msg
end

function initUI()
    ScriptUI():registerInteraction("Anything interesting around here?"%_t, "onAnythingInteresting")
end

function onAnythingInteresting()

    -- check what dialogs are possible at this position in the galaxy
    local distanceFromCenter = length(vec2(Sector():getCoordinates()))
    local possibilities = {}

    for _, d in pairs(dialogs) do
        if distanceFromCenter >= d.from and distanceFromCenter <= d.to then
            for _, dialog in pairs(d.dialogs) do
                table.insert(possibilities, dialog)
            end
        end
    end

    local x, y = Sector():getCoordinates()
    local index = Entity().index
    local seed = makeFastHash(x, y, index)

    local random = Random(Seed(seed))

    -- choose a dialog with a random number based on the sector and the index of the entity
    local dialog = randomEntry(random, possibilities)

    ScriptUI():showDialog(dialog)
end






