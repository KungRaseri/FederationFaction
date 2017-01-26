package.path = package.path .. ";data/scripts/lib/?.lua"
require("stringutility")

require ("randomext")
require ("stringutility")
Dialog = require ("dialogutility")

function initialize()

end

function interactionPossible(playerIndex, option)
--    if option == 0 and Entity().factionIndex == playerIndex then
--        return false
--    end

    return true
end

local tips =
{
    "You can upgrade your hyperspace drive with system upgrades."%_t,
    "There are lots of sectors that don't show up as a green point on your map. Equip a radar upgrade with deep scan bonuses and they will show up as yellow points."%_t,
}


function onWhatsUp()

    local xsotanDialog1 = {}
    xsotanDialog1.text = "All I want is that those damn Xsotan leave me alone."%_t
    xsotanDialog1.answers = {
        {answer = "Who are the Xsotan?"%_t,
            text = "I don't know. Nobody knows. A few centuries ago, they just appeared in the center of the galaxy."%_t,
            followUp = {
                text = "Some say they found a way of harvesting the energy of the black hole in the center. But that's just rumours, I guess."%_t,
                answers = {{answer = "Thank you."%_t}},
            }
        },
        {answer = "I'll be on my way then."%_t},
    }

    local xsotanDialog2 = {}
    xsotanDialog2.text = "Horrible things happening in the center of the galaxy!"%_t
    xsotanDialog2.answers = {
        {answer = "Like what exactly?"%_t,
            text = "The Xsotan are eating up our galaxy from the inside!"%_t,
            answers = {
                {
                    answer = "You can't be serious."%_t,
                    text = "The only thing that gives me some peace of mind is that this process takes centuries, so I'll be long dead when they reach me!"%_t,
                    answers = {{answer = "Thanks, I guess?"%_t}},
                },
                {answer = "I don't have time for this."%_t},
            }
        },
        {answer = "I don't have time for this."%_t},
    }

    local dialog = xsotanDialog2
    ScriptUI():showDialog(dialog)

end

function initUI()
    ScriptUI():registerInteraction("What's up?"%_t, "onWhatsUp");
end





