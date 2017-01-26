package.path = package.path .. ";data/scripts/lib/?.lua"

require ("randomext")
require ("utility")
require ("stringutility")

function initialize()
    if onClient() then
        InteractionText().text = ""
        Entity().title = "Communication Beacon"%_t

        Player():registerCallback("onPreRenderHud", "onRenderHud")
    end
end

function interactionPossible(playerIndex, option)
    return true
end

function initUI()
    ScriptUI():registerInteraction("Establish Connection"%_t, "onEstablishConnection")
end

--[[

]]

function playerHasKey1()
    local player = Player()

    -- check inventory
    local upgrades = player:getInventory():getItemsByType(InventoryItemType.SystemUpgrade)

    for _, item in pairs(upgrades) do
        if item.item.script:find("teleporterkey1") then
            return true
        end
    end

    -- check all ships that are present
    for _, entity in pairs({Sector():getEntitiesByComponents(ComponentType.Owner, ComponentType.Scripts)}) do
        if entity.factionIndex == player.index then
            if entity:hasScript("systems/teleporterkey1.lua") then
                return true
            end
        end
    end

    return false
end

function dropKey()

    if onClient() then
        invokeServerFunction("dropKey")
        return
    end

    local player = Player(callingPlayer)

    -- find a position
    local position = vec3()

    -- find a wreckage
    local wreckages = {Sector():getEntitiesByType(EntityType.Wreckage)}
    if #wreckages > 0 then
        local ship = player.craft

        function eval(wreckage) return distance2(ship.translationf, wreckage.translationf) end

        position = findMinimum(wreckages, eval).translationf
    end


    local system = SystemUpgradeTemplate("data/scripts/systems/teleporterkey1.lua", Rarity(RarityType.Legendary), random():createSeed())
    Sector():dropUpgrade(position, player, nil, system)

end

function onEstablishConnection()

    local hasKey = playerHasKey1()

    -- dialogs
    local intro = {}
    local dialog = {}
    local theStory = {}
    local operationExodus = {}
    local weAreTheHaatii = {}
    local liveHere = {}
    local weHide = {}
    local thisPlace = {}
    local fightThem = {}
    local giveKey = {}
    local main = {}

    -- answers
    local whatIsOpExodus = {answer = "What is Operation Exodus?"%_t, followUp = operationExodus}
    local whoAreYou = {answer = "Who are you?"%_t, followUp = weAreTheHaatii}
    local whatHappened = {answer = "What happened?"%_t, followUp = theStory}
    local whereAreYou = {answer = "Where are you?"%_t, followUp = weHide}
    local whyLiveHere = {answer = "Why do you live here?"%_t, followUp = liveHere}
    local howToFight = {answer = "Do you know how to beat the Xsotan?"%_t, followUp = fightThem}
    local whatIsThis = {answer = "What is this place?"%_t, followUp = thisPlace}
    local leave = {answer = "I have to go."%_t}

    main.text = "And now we live here."%_t
    main.answers = {whoAreYou, whatHappened, whatIsOpExodus, whyLiveHere, whereAreYou, whatIsThis, howToFight, leave}

    if hasKey then
        giveKey.text = "Ah. It looks like you already have everything we could give you."%_t
        giveKey.followUp = main
    else
        giveKey.text = "You can have some of it if you want. It's worthless to us anyways."%_t
        giveKey.onEnd = "dropKey"
        giveKey.followUp = {text = "We dumped one of the artifacts from a wreckage near you, have a look around."%_t, followUp = main}
    end


    fightThem.text = "The Xsotan ships are no more special than ours or yours. They're strong, but you can defeat them in combat."%_t
    fightThem.followUp = {text = "The main problem is that there's just so many of them."%_t,
    followUp = {text = "You have to stop them from calling in reinforcements."%_t,
    followUp = {text = "We don't know how to do that or where they're coming from, but during our times fighting them our ancestors managed to get their hands on some of their technology."%_t,
    followUp = giveKey,
    }}}


    weHide.text = "We're scattered over all these wreckages."%_t
    weHide.followUp = {text = "I would never have thought that anybody would come out here."%_t,
    followUp = {text = "We set up this beacon, but we never thought anybody would use it."%_t,
    followUp = {text = "There are many more of us, in other sectors, but sadly we can't reach them."%_t,
    followUp = main,
    }}}

    thisPlace.text = "This is the place where our last great defeat happened."%_t
    thisPlace.followUp = {text = "We were overwhelmed by outlaws and bandits. When they realized that our technology was completely incompatible with theirs and thus worthless to them, they left our ancestors to die here."%_t,
    followUp = {text = "Since our hyperdrives are all gone, we're stuck here."%_t,
    followUp = {text = "But luckily we're living in the wreckages of a convoy that was meant for the migration of millions."%_t,
    followUp = {text = "We have enough food and energy to sustain us for hundreds of years to come."%_t,
    followUp = main,
    }}}}


    liveHere.text = "We were disorganized, demoralized and weak. Our best guess is that a lot of people in the outer sectors here knew that."%_t
    liveHere.followUp = {text = "And a large convoy like ours was not exactly easy to hide."%_t,
    followUp = {text = "We were constantly attacked. They wanted our technology. Our ships. Our weapons."%_t,
    followUp = {text = "For a long time we managed to fight them back, but at some point we couldn't fight any longer, and were overwhelmed."%_t,
    followUp = {text = "Our hyperspace drives were destroyed, and now we're stuck here."%_t,
    followUp = main,
    }}}}

    weAreTheHaatii.text = "We are the descendants of the Haatii. Our ancestors used to live near the center of the galaxy."%_t
    weAreTheHaatii.answers = {whatHappened, whatIsOpExodus, whereAreYou}

    operationExodus.text = "Operation Exodus was the largest migration the galaxy had seen."%_t
    operationExodus.followUp = {text = "After we realized we couldn't beat the Xsotan at the time, we decided to flee."%_t,
    followUp = {text = "They were getting closer and closer to our home sectors, so we and our allies decided that it was time to fall back and work out a new strategy."%_t,
    followUp = {text = "We realized that the Xsotan were expanding their territory from the center of the galaxy, so we thought the best move would be to journey to the edge of the galaxy."%_t,
    followUp = {text = "We hoped that this might give us enough time to find a strategy to beat them."%_t,
    followUp = {text = "Half the galaxy had agreed to join us, and we went on with the preparations."%_t,
    followUp = {text = "Then they hit us. We didn't know if they knew what we were planning or if it was just a coincidence, but subspace rifts started to appear."%_t,
    followUp = {text = "They tore the galaxy to shreds. Billions of lives were lost. Entire sectors just disappeared. It was a slaughter. And the worst part? We never even saw a single Xsotan ship."%_t,
    followUp = {text = "The alliance was weakened, and there were thousands of factions arising out of the chaos."%_t,
    followUp = {text = "But we had come too far, invested too many resources, we had to go through with Operation Exodus. But it was too disorganized."%_t,
    followUp = {text = "Nothing went according to plan. Most members of the alliance weren't even agreeing on where we would leave to."%_t,
    followUp = {text = "Finally we decided that we could not wait any longer. We took off and left behind beacons that would lead the members of the Operation Exodus to this place."%_t,
    followUp = main
    }}}}}}}}}}}

    theStory.text = "A few hundred years back, an alien species appeared in the center of the galaxy. The Xsotan."%_t
    theStory.followUp = {text = "We knew aliens. Since the great rise of technology 600 years back, everybody knew how to build and use spaceships. This is how we all colonised space in the first place."%_t,
    followUp = {text = "But the Xsotan were different. Cold. Careless."%_t,
    followUp = {text = "They didn't care for anybody, they didn't even answer our attempts to communicate. They just appeared and it seemed like they didn't care about anything at all."%_t,
    followUp = {text = "Then they started... harvesting. "%_t,
    followUp = {text = "They ate away everything. Asteroids. Ships. Some say they even consume entire planets. "%_t,
    followUp = {text = "After a great battle we realized that we didn't stand a chance. Not that they were unbeatable, we did manage to win several battles. "%_t,
    followUp = {text = "But they just kept pouring out of the center, more and more of them. In the end it didn't matter, they would just overrun us as they had way more resources."%_t,
    followUp = {text = "The only thing that was left for us to do, was to flee. So we started Operation Exodus. "%_t,
    followUp = main, }}}}}}}}


    dialog.text = "What? Hello? Who is this?"%_t
    dialog.answers = {
        {
            answer = "Are you from Operation Exodus?"%_t,
            followUp = {text = "Operation Exodus..?"%_t,
                followUp = {text = "Yes... yes..."%_t,
                    followUp = {
                        text = "Well... and no."%_t,
                        answers = {
                            {
                                answer = "I don't understand."%_t,
                                text = "We never took part in Operation Exodus ourselves. It was our ancestors who did it."%_t,
                                answers = {
                                    {
                                        answer = "Your ancestors?"%_t,
                                        text = "Yes. The Exodus took place more than a hundred years ago."%_t,
                                        answers = {
                                            whoAreYou,
                                            whatHappened,
                                            whatIsOpExodus,
                                        }
                                    },
                                    {
                                        answer = "We? Who are you?"%_t,
                                        followUp = weAreTheHaatii
                                    },
                                    whatIsOpExodus,
                                }
                            },
                            {answer = "I don't have time for this."%_t, text = "Maybe you should leave then."%_t}
                        }
                    }
                }
            }
        },
        {answer = "Leave"%_t},
    }


    intro.text = "[Static Noise]"%_t
    intro.followUp = {
        text = "...",
        followUp = {
            text = "...",
            followUp = {
                text = "... is this thing working?"%_t,
                followUp = dialog
            }
        }
    }

    ScriptUI():showDialog(intro)

end

function onRenderHud()
    -- display nearest x
    if os.time() % 2 == 0 then
        local renderer = UIRenderer()
        renderer:renderEntityTargeter(Entity(), ColorRGB(1, 1, 1));
        renderer:display()
    end
end
