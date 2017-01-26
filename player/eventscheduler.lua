if onServer() then

package.path = package.path .. ";data/scripts/lib/?.lua"

require ("randomext")
require ("utility")

local events =
{
    {schedule = random():getInt(25, 35) * 60, script = "convoidistresssignal", arguments = {true}, to = 560},
    {schedule = random():getInt(45, 60) * 60, script = "fakedistresssignal", arguments = {true}, to = 560},
    {schedule = random():getInt(45, 60) * 60, script = "piratehunter", to = 560},
    {schedule = random():getInt(25, 50) * 60, script = "alienattack", arguments = {0}, minimum = 5 * 60, from = 0, to = 500},
    {schedule = random():getInt(35, 70) * 60, script = "alienattack", arguments = {1}, minimum = 25 * 60, to = 500},
    {schedule = random():getInt(60, 80) * 60, script = "alienattack", arguments = {2}, minimum = 60 * 60, to = 350},
    {schedule = random():getInt(80, 120) * 60, script = "alienattack", arguments = {3}, minimum = 120 * 60, to = 300},
    {schedule = random():getInt(50, 70) * 60, script = "spawntravellingmerchant", to = 520},
}

local pause = 5 * 60
local pauseTime = pause

function initialize()
    for _, event in pairs(events) do
        event.time = (event.minimum or 5 * 60) + math.random() * event.schedule
    end

    local frequency = 0
    for _, event in pairs(events) do
        frequency = frequency + 1 / event.schedule
    end

    print ("player events roughly every " .. round((1 / frequency + pause) / 60, 2) .. " minutes")

end

function getUpdateInterval()
    return 5
end

function updateServer(timeStep)
    local player = Player()

    -- timeStep = timeStep * 60

    -- only run script for the lowest player index in the sector -> no stacking events
    local players = {Sector():getPlayers()}
    for _, p in pairs(players) do
        -- when there is a player with a lower index, we return
        if p.index < player.index then return end
    end

    -- but, if we're not alone, we speed up events by 50%
    if #players > 1 then timeStep = timeStep * 1.5 end

    if pauseTime > 0 then
        pauseTime = pauseTime - timeStep
        return
    end

    -- update times of events
    for _, event in pairs(events) do
        event.time = event.time - timeStep

        if event.time < 0 then
            -- check if the location is OK
            local from = event.from or 0
            local to = event.to or math.huge

            local position = length(vec2(Sector():getCoordinates()))
            if position >= from and position <= to then
                -- start event
                local arguments = event.arguments or {}
                Player():addScriptOnce(event.script, unpack(arguments))
                event.time = event.schedule

                print ("starting event " .. event.script)

                pauseTime = pause

                break;
            end
        end
    end

end


function secure()
    local times = {}

    for _, event in pairs(events) do
        table.insert(times, event.time)
    end

    return times
end

function restore(times)
    for i = 1, math.min(#times, #events) do
        events[i].time = times[i]
    end
end


end
