package.path = package.path .. ";data/scripts/lib/?.lua"
require ("randomext")
require ("galaxy")
require ("utility")
require("stringutility")
Dialog = require("dialogutility")

-- if this function returns false, the script will not be listed in the interaction window on the client,
-- even though its UI may be registered
function interactionPossible(playerIndex, option)

    local player = Player()
    local ship = player.craft
    if ship == nil then return false end

    local self = Entity()
    if self.index == ship.index then return false end

    local relationLevel = player:getRelations(Faction().index)

    local threshold = -45000
    if relationLevel < threshold then
        return false, "We don't want anything to do with you."%_t
    end

    return true
end

-- this function gets called on creation of the entity the script is attached to, on client and server
function initialize()
    local station = Entity()

    if station.title == "" then
        station.title = "Resistance Outpost"%_t
    end

    if onClient() then
        InteractionText(station.index).text = "Always great to see some new faces around here. As long as you're not a Xsotan or a pirate, you're welcome to this sector."%_t
    end
end


function initUI()
    ScriptUI():registerInteraction("Who are you?"%_t, "onWhoAreYou")
    if Player():getValue("known_in_center") then
        ScriptUI():registerInteraction("I heard you have some work for me?"%_t, "onWorkForMe")
    end
end

function onWhoAreYou(entityIndex)
    ScriptUI(entityIndex):showDialog(makeIntroDialog())
end

function onWorkForMe(entityIndex)
    ScriptUI(entityIndex):showDialog(makeDialog())
end

function makeIntroDialog()
    local d0_WeAreWhatsLeftO = {}
    local d1_WaitAreYouActua = {}
    local d2_SoWhat = {}
    local d3_WeHaventSeenAny = {}
    local d4_ImAfraidYouWont = {}
    local d5_IfYouAreSerious = {}
    local d8_FarewellThen = {}
    local d9_DontGetYourself = {}

    d0_WeAreWhatsLeftO.text = "We are what's left of the factions in the center of the galaxy. We have been struggling against the Xsotan for over 200 years now. \n\nHow can you not know this?"%_t
    d0_WeAreWhatsLeftO.answers = {
        {answer = "I'm not from around here."%_t, followUp = d1_WaitAreYouActua},
        {answer = "That's my own business."%_t}
    }

    d1_WaitAreYouActua.text = "Wait, are you actually from the outside? This is incredible!"%_t
    d1_WaitAreYouActua.answers = {
        {answer = "Yes, I am."%_t, followUp = d3_WeHaventSeenAny},
        {answer = "Why is that incredible?"%_t, followUp = d3_WeHaventSeenAny},
        {answer = "I'm from the outside, so what?"%_t, followUp = d2_SoWhat},
        {answer = "I'll be gone now."%_t, followUp = d8_FarewellThen}
    }
    d1_WaitAreYouActua.onStart = "informOthers"

    d2_SoWhat.text = "So what!?"%_t
    d2_SoWhat.followUp = d3_WeHaventSeenAny

    d3_WeHaventSeenAny.text = "We haven't seen anybody from the outside for hundreds of years! \n\nThis changes everything!\n\nSo many questions... How did you manage to get here?\n\nAnd why would you even come here?"%_t
    d3_WeHaventSeenAny.answers = {
        {answer = "I want to put an end to the Xsotan."%_t, followUp = d5_IfYouAreSerious},
        {answer = "Just curious."%_t, followUp = d9_DontGetYourself},
        {answer = "Loot and riches."%_t, followUp = d4_ImAfraidYouWont},
        {answer = "That's none of your business."%_t, followUp = d8_FarewellThen}
    }

    d4_ImAfraidYouWont.text = "I'm afraid you won't find a lot of it here. We only take what we need, we have to be very careful.\n\nMake sure you check out the sectors around here, there's plenty of wreckages that you can search through.\n\nBut there's also the Xsotan."%_t
    d4_ImAfraidYouWont.followUp = d9_DontGetYourself

    d5_IfYouAreSerious.text = "If you are serious about this, then we might have some work for you. I'll inform the others. This might be our chance!"%_t
    d5_IfYouAreSerious.answers = {
        {answer = "Okay."%_t, followUp = makeDialog()},
        {answer = "I'd rather keep to myself."%_t, followUp = d8_FarewellThen}
    }

    d8_FarewellThen.text = "Farewell then."%_t

    d9_DontGetYourself.text = "Don't get yourself killed. I'm sure you can help us out of this miserable situation. I have to inform the others. \n\nThis changes everything."%_t

    return d0_WeAreWhatsLeftO
end

function makeDialog()
    local d0_IfYouManagedToG = {}
    local d1_OurScoutsHaveRe = {}
    local d2_BecauseOurResou = {}
    local d6_AskAway = {}
    local d7_SoFarWeHaventFo = {}
    local d8_WeDontThinkTheX = {}
    local d9_NoIdeaWeStillHa = {}
    local d10_TheThingIsAsLon = {}
    local d11_OurResearchersH = {}
    local d12_IfYouCanFindEno = {}
    local d13_YouLookLikeYour = {}

    d0_IfYouManagedToG.text = "If you managed to get into this area, that means that we can get out of here as well!\n\nBut, it also means that it's possible to send reinforcements, so we can actually fight the Xsotan!"%_t
    d0_IfYouManagedToG.answers = {
        {answer = "How do you want to fight them?"%_t, followUp = d1_OurScoutsHaveRe},
        {answer = "Why didn't you fight them before?"%_t, followUp = d2_BecauseOurResou},
        {answer = "I have some questions about the Xsotan."%_t, followUp = d6_AskAway}
    }

    d1_OurScoutsHaveRe.text = "Our scouts have reported that there is a giant Xsotan mothership in the center of the galaxy, near the black hole.\n\nWe know that this ship somehow channels the black hole's energy, and opens up wormholes to other places. \n\nWe believe that if we take down this ship, we will finally stop their unending reinforcements."%_t
    d1_OurScoutsHaveRe.answers = {
        {answer = "How do we take it down?"%_t, followUp = d11_OurResearchersH}
    }

    d2_BecauseOurResou.text = "Because our resources are limited, and it looks like theirs aren't. \n\nAs soon as you shoot down one of their ships, a new one takes its place. \n\nWe wouldn't stand a chance in an open fight."%_t
    d2_BecauseOurResou.answers = {
        {answer = "How do you want to fight them?"%_t, followUp = d1_OurScoutsHaveRe}
    }

    d6_AskAway.text = "Ask away."%_t
    d6_AskAway.answers = {
        {answer = "What's their weakness?"%_t, followUp = d7_SoFarWeHaventFo},
        {answer = "Where do they come from?"%_t, followUp = d8_WeDontThinkTheX},
        {answer = "What do they want?"%_t, followUp = d9_NoIdeaWeStillHa},
        {answer = "How did you survive this long?"%_t, followUp = d10_TheThingIsAsLon},
        {answer = "I'd like to talk about something else."%_t, followUp = d0_IfYouManagedToG}
    }

    d7_SoFarWeHaventFo.text = "So far we haven't found a real weakness yet. \n\nBut some of our scouts found a large mothership in the center of the galaxy, near the central black hole. \n\nThey saw how it opened wormholes, and lots and lots of Xsotan ships poured through.\n\nWe think that if we manage to destroy this ship, we can stop them from calling in reinforcements, which is the biggest problem when fighting Xsotan. \n\nThere's always more of them."%_t
    d7_SoFarWeHaventFo.answers = {
        {answer = "I'd like to ask something else."%_t, followUp = d6_AskAway},
        {answer = "Thanks, that's it for now."%_t, followUp = d0_IfYouManagedToG}
    }

    d8_WeDontThinkTheX.text = "We don't think the Xsotan came from this galaxy, we would have come across them a lot earlier.\n\nAll we know is, that there's a large mothership in the very center of the galaxy, which opens wormholes regularly. \n\nThey might even be from another galaxy for all we know."%_t
    d8_WeDontThinkTheX.answers = {
        {answer = "I'd like to ask something else."%_t, followUp = d6_AskAway},
        {answer = "Thanks, that's it for now."%_t, followUp = d0_IfYouManagedToG}
    }

    d9_NoIdeaWeStillHa.text = "No idea. We still haven't managed to establish communication with them. \n\nAll we know is, that they come and they eat away matter. \n\nThere are large fields of Xsotan breeders, farms with asteroids that are eaten up from the inside."%_t
    d9_NoIdeaWeStillHa.answers = {
        {answer = "I'd like to ask something else."%_t, followUp = d6_AskAway},
        {answer = "Thanks, that's it for now."%_t, followUp = d0_IfYouManagedToG}
    }

    d10_TheThingIsAsLon.text = "The thing is, as long as you leave them alone, they kind of leave you alone, too. \n\nWe had reports of ships flying through entire Xsotan fleets, and it looked like they barely noticed our ships were there. \n\nWe know that they eat up matter - and they're attracted by energy bursts, such as weapons firing. \n\nMy advice to you: Don't fire weapons when they're there, and don't get too close. You never know."%_t
    d10_TheThingIsAsLon.answers = {
        {answer = "I'd like to ask something else."%_t, followUp = d6_AskAway},
        {answer = "Thanks, that's it for now."%_t, followUp = d0_IfYouManagedToG}
    }

    d11_OurResearchersH.text = "Our researchers have been tampering with some recovered Xsotan wormhole technology, but it's still very experimental.\n\nWe have neither the means nor the technology to research more Xsotan artifacts. But if we could, we might be able to create a system that allows a ship to intercept the wormhole opening process - and to open wormholes itself."%_t
    d11_OurResearchersH.answers = {
        {answer = "I see where this is going."%_t, followUp = d12_IfYouCanFindEno},
        {answer = "I don't understand."%_t, followUp = d13_YouLookLikeYour},
        {answer = "Nope, I'm out."%_t}
    }

    d12_IfYouCanFindEno.text = "If you can find enough Xsotan technology, you might be able to research it to build a wormhole interceptor.\n\nOnce we have the interceptor, we can finally get reinforcements from outside!\n\nWe might be able to cut their supply of reinforcements, and drive them out of our galaxy for good!"%_t
    d12_IfYouCanFindEno.onEnd = "startOrganizeAlliesMission"
    d12_IfYouCanFindEno.answers = {
        {answer = "Sounds like a plan!"%_t, onSelect = "startCollection"},
        {answer = "You'll have to find someone else."%_t}
    }

    d13_YouLookLikeYour.text = "You look like you're capable of fighting the Xsotan, or at least sneak into their territory and collect some of their technology."%_t
    d13_YouLookLikeYour.followUp = d12_IfYouCanFindEno

    return d0_IfYouManagedToG
end

function startOrganizeAlliesMission()
    if onClient() then
        invokeServerFunction("startOrganizeAlliesMission")
        return
    end

    Player(callingPlayer):addScriptOnce("story/organizedallies.lua")
end

function startCollection()
    if onClient() then
        invokeServerFunction("startCollection")
        return
    end

    Player(callingPlayer):addScriptOnce("story/collectxsotantechnology.lua", 12)
end

function informOthers()
    if onClient() then
        invokeServerFunction("informOthers")
        return
    end

    Player(callingPlayer):setValue("known_in_center", true)
end
