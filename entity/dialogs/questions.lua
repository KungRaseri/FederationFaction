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
    local d0_Shoot = {}
    local d1_WhatWhatDoYouMe = {}

    d0_Shoot.text = "Shoot."%_t
    d0_Shoot.answers = {
        {answer = "How come there are so many asteroids with resources, even in populated sectors?"%_t, followUp = d1_WhatWhatDoYouMe}
    }

    d1_WhatWhatDoYouMe.text = "What? What do you mean, \"many\"? There's nearly nothing left!\n\nDo you see those big asteroids that all those mines are built on? Well, back at the time, for every big sector you'll find, there were three or four of those, packed with resources!\n\nWhen the big space age began, we mined them all, and built our stations out of those resources.\n\nWhat you're seeing is nothing but a shadow of what has once been. \n\nNobody cares for those little rocks, except for the most greedy races. In general you're free to mine them."%_t

    return d0_Shoot
end
