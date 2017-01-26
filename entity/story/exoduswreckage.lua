package.path = package.path .. ";data/scripts/lib/?.lua"

require ("stringutility")

function initialize()

end

function interactionPossible(playerIndex, option) return true end

function initUI()
    ScriptUI():registerInteraction("Investigate"%_t, "onInvestigate");
end


function onInvestigate()

    local wreckage = Entity():getValue("exoduswreckage") or 1
    local dialog = {}

    if wreckage == 1 then
        local repeated = {}

        repeated.text = "We won't make it to the next rendez-vous point in time. Our hyperdrive has severe damage."%_t
        repeated.followUp = {
            text = "We fought them off for now, but I'm sure there's going to be more soon. I've instructed my men to work as fast as they can."%_t,
            followUp = {
                text = "I'm sure this might not even have been necessary. They all know the gravity of the situation we're in."%_t,
                followUp = {
                    text = "[Static Noise]"%_t,
                    answers = {
                        {answer = "Listen"%_t, followUp = repeated },
                        {answer = "Leave it alone"%_t}
                    }
                }
            }
        }

        dialog = {
            text = "The wreckage is sending some kind of broadcast that looks like an entry from the captain's logs."%_t,
            answers = {
                {answer = "Listen"%_t, followUp = repeated },
                {answer = "Leave it alone"%_t}
            }
        }
    end

    ScriptUI():showDialog(dialog)

end






