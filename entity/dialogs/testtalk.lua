package.path = package.path .. ";data/scripts/lib/?.lua"
require("stringutility")

function interactionPossible(player, option)
    return true
end

function initUI()
    ScriptUI():registerInteraction("Interact"%_t, "onInteract")
end

function onInteract()
    ScriptUI():showDialog(makeDialog())
end

function makeDialog()
    local d0_HelloMyNameIsTi = {}
    local d1_INeedAFastShip = {}
    local d2_AlrightHereAreT = {}
    local d3_IHaveFoundAVery = {}
    local d4_WhateverIWillFi = {}
    local d5_AhhAMercenaryKi = {}
    local d6_FineIWillPayYou = {}

    d0_HelloMyNameIsTi.text = "Hello, my name is Tin. I am a trader in need of help. I see you have a functioning spaceship. Would it be open for buisness?"%_t
    d0_HelloMyNameIsTi.answers = {
        {answer = "What do you need?"%_t, followUp = d1_INeedAFastShip},
        {answer = "For gold I shall sell my soul..."%_t, followUp = d5_AhhAMercenaryKi},
        {answer = "No, I am busy at the moment."%_t, followUp = d4_WhateverIWillFi},
        {answer = "You bothered the wrong man. Prepare to die!"%_t, onSelect = "setAIAgressive"}
    }

    d1_INeedAFastShip.text = "I need a fast ship to transport some wood from a far spacestation to another not far from the first one."%_t
    d1_INeedAFastShip.answers = {
        {answer = "Roger! Send me the coordinates."%_t, followUp = d2_AlrightHereAreT},
        {answer = "Wood? Seems not very lucrative, but whatever.."%_t, followUp = d3_IHaveFoundAVery},
        {answer = "What will it pay me?"%_t, followUp = d5_AhhAMercenaryKi},
        {answer = "No, I am busy at the moment."%_t, followUp = d4_WhateverIWillFi}
    }

    d2_AlrightHereAreT.text = "Alright, here are the coordinates. I will wait for you in the destination sector."%_t
    d2_AlrightHereAreT.answers = {
        {answer = "See you there"%_t}
    }
    d2_AlrightHereAreT.onStart = "givePlayerTargetCoordinates"

    d3_IHaveFoundAVery.text = "I have found a very specific niche for wood. You wouldn't believe the amount of money you can make, with seemingly worthless stuff."%_t
    d3_IHaveFoundAVery.answers = {
        {answer = "If, thats so, what will it pay me?"%_t, followUp = d5_AhhAMercenaryKi},
        {answer = "Sure... 'wood'.. whatever, I will do it. Where should I go?"%_t, followUp = d2_AlrightHereAreT},
        {answer = "That seems suspicious, I have to decline."%_t, followUp = d4_WhateverIWillFi}
    }

    d4_WhateverIWillFi.text = "Whatever, I will find someone else."%_t

    d5_AhhAMercenaryKi.text = "Ahh.. a mercenary kind? We will thrive together my friend.. I will pay you half the cut I make. How does this sound?"%_t
    d5_AhhAMercenaryKi.answers = {
        {answer = "Deal! Where should I go?"%_t, followUp = d2_AlrightHereAreT},
        {answer = "You haven't mentioned how much you made.."%_t, followUp = d6_FineIWillPayYou},
        {answer = "Not good enough. You seem suspicious."%_t, followUp = d4_WhateverIWillFi}
    }

    d6_FineIWillPayYou.text = "Fine! I will pay you one third the worth of the wood. Final offer!"%_t
    d6_FineIWillPayYou.answers = {
        {answer = "Alright fair enough. Where is the designated pickup point?"%_t, followUp = d2_AlrightHereAreT},
        {answer = "No! Final answer!"%_t},
        {answer = "I deserve more, than the price of wood!"%_t, followUp = d4_WhateverIWillFi}
    }

    return d0_HelloMyNameIsTi
end

function givePlayerTargetCoordinates()

end

function setAIAgressive()

end
