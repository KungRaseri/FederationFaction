package.path = package.path .. ";data/scripts/lib/?.lua"
require("stringutility")

local Dialog = {}

function Dialog.generateStationInteractionText(entity, random)

    local text = ""

    local title = entity.translatedTitle
    local name = entity.name

    local nameStr = " of this station/* as in: you're talking to the system' of this station'*/"%_t

    if title and name then
        nameStr = " of the ${title} ${name}/* as in: you're talking to the system' of the Shipyard Luna41'*/"%_t % {title = title%_t, name = name}
    elseif name then
        nameStr = " of ${name}/* as in: you're talking to the system' of Luna41'*/"%_t
    end

    local greetings = {
        "Hello. "%_t,
        "Welcome. "%_t,
        "Greetings. "%_t,
        "Good day. "%_t,
        "",
        "",
    }

    local intro1 = {
        "This is "%_t,
        "You are talking to "%_t,
        "You are now talking to "%_t,
        "You are speaking to "%_t,
        "You are now speaking to "%_t,
    }

    local intro2 = {
        "the automated interaction system${name_string}. "%_t % {name_string = nameStr},
        "the automatic interaction response system${name_string}. "%_t % {name_string = nameStr},
    }

    local service = {
        "What can we do for you?"%_t,
        "How can we help you?"%_t,
        "What do you need?"%_t,
        "How can we be of service?"%_t,
        "Please state the nature of your inquiry."%_t,
    }

    local str =
        greetings[random:getInt(1, #greetings)] ..
        intro1[random:getInt(1, #intro1)] ..
        intro2[random:getInt(1, #intro2)] ..
        service[random:getInt(1, #service)]

    return str
end

function Dialog.generateShipInteractionText(entity, random)

    local text = ""

    local title = entity.translatedTitle
    local name = entity.name

    local nameStr = "the captain /* as in: This is 'the captain'. */"%_t

    if title and title ~= "" and name and name ~= "" then
        nameStr = "the ${title} ${name} /* as in: This is 'the Freighter Eclipse'. */"%_t % {title = title, name = name}
    elseif name and name ~= "" then
        nameStr = "the ship ${name} /* as in: This is 'the ship Eclipse'. */"%_t % {name = name}
    end

    local greetings = {
        "Hello. "%_t,
        "Greetings. "%_t,
        "",
        "",
    }

    local intro1 = {
        "This is ${speaker}. "%_t % {speaker = nameStr},
        "Here is ${speaker}. "%_t % {speaker = nameStr},
    }

    local service = {
        "What can we do for you?"%_t,
        "How can we help you?"%_t,
        "What's up?"%_t,
        "What do you need?"%_t,
        "What do you want?"%_t,
        "What is it?"%_t,
        "Make it quick."%_t,
    }

    local str =
        greetings[random:getInt(1, #greetings)] ..
        intro1[random:getInt(1, #intro1)] ..
        service[random:getInt(1, #service)]

    return str
end

function Dialog.restart()
    ScriptUI():restartInteraction()
end

function Dialog.empty()
    return {text = "                                                                                                                                                        "}
end

restart = Dialog.restart


return Dialog
