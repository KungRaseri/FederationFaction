package.path = package.path .. ";data/scripts/lib/?.lua"

require ("randomext")
require ("utility")
require ("stringutility")
Dialog = require ("dialogutility")

local willFlee = false

function interactionPossible(playerIndex, option)

    if option == 1 then
        local ship = Entity()

        local cargos = ship:getCargos()

        if tablelength(cargos) == 0 then
            return false
        end
    end

    return true
end

function initialize()
    local entity = Entity()

    if onClient() then
        InteractionText(entity.index).text = Dialog.generateShipInteractionText(entity, random())
    end

    -- 50% chance that a civil ship will just run
    willFlee = math.random() > 0.5

    -- player ships should never run, since run == delete
    local faction = Faction()
    if faction and faction.isPlayer then
        willFlee = false
    end

end

function initUI()
    ScriptUI():registerInteraction("Where is your home sector?"%_t, "onWhereHomeSector");
    ScriptUI():registerInteraction("Give me all your cargo!"%_t, "onRaid");
end





function onRaid()
    -- evaluate strength of own ship vs strength of player
    local me = Entity()
    local player = getPlayerCraft()


    local myDps = me.firePower
    local playerDps = player.firePower

    local meDestroyed = me.durability / playerDps
    local playerDestroyed = player.durability / myDps

    local dumpCargo = {}
    dumpCargo.onStart = "worsenRelations"
    dumpCargo.onEnd = "dumpCargo"
    dumpCargo.text = "Dumping the cargo. I hope you're happy you damn pirate."%_t

    local ridiculous = {}
    ridiculous.text = "Hahahahaha!"%_t
    ridiculous.answers = {
        {answer = "I'm serious!"%_t, followUp = {
            text = "And how are you planning on doing that?"%_t,
            answers = {
                {answer = "I'm going to destroy you!"%_t, text = "This is ridiculous. Go away."%_t},
                {answer = "Leave"%_t }
            }
        }},
        {answer = "Okay, sorry, wrong ship."%_t},
    }

    local giveup = {}
    giveup.text = "..."%_t
    giveup.followUp = {
        text = "Leave us alone!"%_t,
        answers = {
            {answer = "Dump your cargo or you'll be destroyed!"%_t, followUp = {
                onStart = "worsenRelations",
                text = "Please don't shoot! We will dump the cargo, but then you leave us alone!"%_t,
                answers = {
                    {answer = "Dump your cargo and you will be spared."%_t, followUp = dumpCargo},
                    {answer = "If you cooperate, I might spare your lives."%_t, followUp = dumpCargo},
                    {answer = "I'm going to destroy you!"%_t, followUp = dumpCargo},
                    {answer = "At second thought I don't need anything of you."%_t, text = "What kind of sick joke is this!?"%_t }
                }
            }},
            {answer = "Okay, sorry, wrong ship."%_t},
        }
    }

    local fleeDialog = {
        text = "We'll be out of here before you even get to us!"%_t,
        onEnd = "flee",
    }

    local attack = {}
    attack.text = "..."%_t
    attack.followUp = {
        text = "You should leave."%_t,
        answers = {
            {answer = "Dump your cargo or you'll be destroyed!"%_t, followUp = {
                onStart = "worsenRelations",
                text = "I will not give up my cargo freely to some petty pirate!"%_t,
                answers = {
                    {answer = "So be it then!"%_t, onSelect = "attackPlayer"},
                    {answer = "I'm going to destroy you!"%_t, onSelect = "attackPlayer"},
                    {answer = "Oops, sorry, wrong ship, carry on!"%_t},
                }
            }},
            {answer = "Okay, sorry, wrong ship."%_t},
        }
    }

    local dialog

    if myDps == 0 and meDestroyed / 60 > 2 then
        -- player can't do anything
        dialog = ridiculous
        -- dialog.onEnd = "restart"

    elseif meDestroyed * 2.0 < playerDestroyed then
        -- "okay I'm dead"
        if willFlee == true then
            dialog = fleeDialog
        else
            dialog = giveup
        end

    elseif meDestroyed < playerDestroyed then
        -- "I might be in trouble"

        if willFlee == true then
            dialog = fleeDialog
        else
            if math.random() > 0.5 then
                dialog = giveup
            else
                dialog = attack
            end
        end

    elseif meDestroyed * 0.5 > playerDestroyed then
        -- "I will take you on!"
        dialog = attack

    elseif meDestroyed > playerDestroyed then
        -- "I might get out of this"
        dialog = attack

    end

    worsenRelations()

    ScriptUI():showDialog(dialog)
end

function dumpCargo()
    if onClient() then
        invokeServerFunction("dumpCargo")
        return
    end

    local ship = Entity()
    local cargos = ship:getCargos()

    for good, amount in pairs(cargos) do
        for i = 1, amount, 2 do
            Sector():dropCargo(ship.translationf, Faction(callingPlayer), Faction(ship.factionIndex), good, ship.factionIndex, 2)
        end

        ship:removeCargo(good, amount)
    end
end

function worsenRelations(delta)
    delta = delta or -15000
    if not callingPlayer then return end

    if onClient() then
        invokeServerFunction("worsenRelations", delta)
        return
    end

    local crafts = {Sector():getEntitiesByComponent(ComponentType.Crew)}

    local factions = {}
    for _, entity in pairs(crafts) do
        factions[entity.factionIndex] = 1
    end

    for factionIndex, _ in pairs(factions) do
        local faction = Faction(factionIndex)
        if faction then
            Galaxy():changeFactionRelations(faction, Player(callingPlayer), delta)
        end
    end
end

function flee()
    if onClient() then
        invokeServerFunction("flee")
        return
    end

    willFlee = false

    -- don't delete player ships
    local faction = Faction()
    if faction and faction.isPlayer then
        return
    end

    Sector():deleteEntityJumped(Entity())
end

function attackPlayer()
    print ("calling attackPlayer")

    if onClient() then
        invokeServerFunction("attackPlayer")
        return
    end

    local ai = ShipAI()

    local player = Player(callingPlayer)

    ai:setPassiveShooting(1)
    ai:registerEnemyEntity(player.craftIndex)

    print("attack")
end



function onWhereHomeSector()
    ScriptUI():showDialog(makeHomeSectorDialog())
end

function makeHomeSectorDialog()
    local entity = Entity()

    local faction = Faction(entity.factionIndex)
    local x, y = faction:getHomeSectorCoordinates()

    local name = faction.name
    if name:starts("The ") then name = name:sub(5) end

    local dialog = {}
    dialog.text = string.format("%s Prime is at (%i:%i)."%_t, name, x, y)
    dialog.onStart = "postHomeSector"
    dialog.onEnd = "restart"

    return dialog;
end

function postHomeSector()
    local faction = Faction()
    local x, y = faction:getHomeSectorCoordinates()

    local name = faction.name
    if name:starts("The ") then name = name:sub(5) end

    displayChatMessage(string.format("%s Prime: \\s(%i:%i)"%_t, name, x, y), faction.name, 0)
end
