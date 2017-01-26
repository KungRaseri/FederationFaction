
package.path = package.path .. ";data/scripts/lib/?.lua"

Dialog = require ("dialogutility")
require ("stringutility")

local interacted
local flyAway
local paymentSuccessful

function getUpdateInterval()
    return 0.5
end

function initialize()

end

function startFightStupidQuestions()
    Achievements():unlockProvokedSwoks()
    startFight()
end

function startFight()
    if onClient() then
        displayChatMessage(string.format("%s is attacking!"%_t, Entity().translatedTitle), "", 2)
        invokeServerFunction("startFight")
        registerBoss(Entity().index)
        return
    end

    for _, pirate in pairs(getPirates()) do
        ShipAI(pirate.index):registerEnemyFaction(callingPlayer)
    end
end

function payUp()
    if onClient() then
        invokeServerFunction("payUp")
        return
    end

    local player = Player(callingPlayer)
    local sum = math.max(math.ceil(player.money / 3000) * 1000, 10000)

    local canPay, msg, args = player:canPayMoney(sum)

    if canPay then
        player:pay(sum)
        invokeClientFunction(player, "paySuccessful")
    else
        invokeClientFunction(player, "payFailed")
    end

end

function paySuccessful()
    paymentSuccessful = 1
    interacted = nil
end

function payFailed()
    paymentSuccessful = 0
    interacted = nil
end

function paySuccessfulDialog()
    local dialog = {
        text = "Pleasure doing business with you!"%_t,
        followUp = {
            text = "Hahahahahaha!"%_t,
            onEnd = "despawn",
        }
    }

    return dialog
end

function payFailedDialog()
    local dialog = {
        text = "Looks like you don't have the coin. And I can't afford any witnesses."%_t,
        followUp = {
            text = "Enjoy your last moments in this universe!"%_t,
            onEnd = "startFight",
        }
    }

    return dialog
end

function normalDialog()
    local entity = Entity()
    local sum = math.max(math.ceil(Player().money / 3000) * 1000, 10000)

    local choose = {
        text = "Now, what will it be?"%_t,
    }

    choose.answers = {
        {answer = "I'll kill you!"%_t, onSelect = "startFight",},
        {answer = "I'll pay."%_t, onSelect = "payUp", text = "..."},
        {answer = "Is there a third alternative?"%_t, followUp = {
            text = "No."%_t,
            answers = {
                {answer = "Okay, then I'll kill you!"%_t, onSelect = "startFight",},
                {answer = "I'll pay then."%_t, onSelect = "payUp", text = "..."},
                {answer = "Is there really no third alternative?"%_t, followUp = {
                    text = "No!"%_t,
                    answers = {
                        {answer = "Okay, then I'll kill you!"%_t, onSelect = "startFight",},
                        {answer = "I'll pay then."%_t, onSelect = "payUp", text = "..."},
                        {answer = "Why no third alternative?"%_t, text = "Because I said so!"%_t, followUp = {
                            text = "Enough stupid questions, die!"%_t, onEnd = "startFightStupidQuestions"
                        },},
                    }
                },},
            }
        },},
    }

    local choices =
    {
        text = "You have 2 choices. You can choose to pay ${amount} credits for your pathetic life and ship, or you can choose to die."%_t % {amount = createMonetaryString(sum)},
        followUp = choose
    }

    local heardOfMe =
    {
        text = "You have not heard of me yet? I am ${boss}, scourge of the outer sectors. You will get to know me soon enough."%_t % {boss = entity.translatedTitle},
    }

    heardOfMe.answers = {
        {
            answer = "You don't scare me."%_t,
            text = "Oh, looks like we have a brave hero here! I might actually like you. I'll kill you quickly."%_t,
            followUp = choices,
        },
        {
            answer = "What do you want from me?"%_t,
            followUp = choices,
        },
        {
            answer = "It's time someone put an end to you!"%_t,
            text = "Look at this maggot! Do you really think you have a chance?"%_t,
            followUp = {
                text = "Prepare to die!"%_t,
            }
        },
        {
            answer = "${boss}? Who were your predecessors?"%_t % {boss = entity.translatedTitle},
            text = "I am just one of many brothers! After they were killed, it was my time to rise to power!"%_t,
            followUp = choices
        },
        {
            answer = "I'll be leaving now."%_t,
            text = "Not so fast."%_t,
            followUp = choices,
        }
    }

    local dialog =
    {
        text = "Well hello there. Now who might you be?"%_t,

        answers = {
            {
                answer = "I could ask you the same."%_t,
                followUp = heardOfMe,
            },
            {answer = "Nobody, goodbye."%_t, text = "Not so fast."%_t, followUp = choices,},
        }
    }

    return dialog
end

function onDialogClosed()
    if paymentSuccessful == nil then
        displayChatMessage("Don't you dare cut me off! You will pay for this!"%_t, Entity().translatedTitle, 0)
        startFight()
    end
end

function despawn()
    if onClient() then
        invokeServerFunction("despawn")
        return
    end

    flyAway = true
end

function updateClient()
    if not interacted then

        if not paymentSuccessful then
            ScriptUI():interactShowDialog(normalDialog(), 0)
        elseif paymentSuccessful == 1 then
            ScriptUI():interactShowDialog(paySuccessfulDialog(), 0)
        else
            ScriptUI():interactShowDialog(payFailedDialog(), 0)
        end

        interacted = true
    end

end

function getPirates()
    local self = Entity()
    local pirates = {}

    for _, other in pairs({Sector():getEntitiesByComponent(ComponentType.ShipAI)}) do
        if other.factionIndex == self.factionIndex then
            table.insert(pirates, other)
        end
    end

    return pirates
end

function updateServer()

    if flyAway then
        local self = Entity()
        local pirates = getPirates()

        if #pirates > 1 then
            -- despawn all other pirates before the boss
            if pirates[1].index == self.index then
                Sector():deleteEntityJumped(pirates[2])
            else
                Sector():deleteEntityJumped(pirates[1])
            end
        else
            Sector():deleteEntityJumped(pirates[1])
        end
    end



end





