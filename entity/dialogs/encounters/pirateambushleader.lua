package.path = package.path .. ";data/scripts/lib/?.lua"

-- make the NPC talk to players
require("npcapi/singleinteraction")
require("stringutility")

function getSingleInteractionDialog()
    return {text = "Haha, our fake distress call worked! You're as good as dead maggot!"%_t}
end
