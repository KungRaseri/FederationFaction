package.path = package.path .. ";data/scripts/lib/?.lua"

require("utility")
Scientist = require("story/scientist")

function initialize()
    if onServer() then
        Entity():registerCallback("onDestroyed", "onDestroyed")
    end

end

function onDestroyed(...)
    -- all players in the sector get a scientist spawn counter
    local spawn

    for _, player in pairs({Sector():getPlayers()}) do
        local value = player:getValue("scientist_spawn") or 0
        value = value + 1

        if value == 4 then
            spawn = true
            value = 0
        end

        player:setValue("scientist_spawn", value)
    end

    if spawn then
        Scientist.spawn()
    end

end


