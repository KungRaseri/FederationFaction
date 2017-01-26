if onServer() then

package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"
package.path = package.path .. ";data/scripts/events/?.lua"
package.path = package.path .. ";?"

require ("galaxy")

local eventNames = {}
local events = {}

function addEvent(name, frequency)
    local path = Sector():resolveScriptPath(name)
    if path == nil or path == "" then
        print("resolution of event " .. name .. " failed")
        return
    end

    local event = {}
    event.frequency = frequency or math.random(15 * 60, 20 * 60) -- default is every 15 - 20 minutes
    event.name = name
    event.path = path
    event.path = Sector():resolveScriptPath(event.name)
    event.counter = math.random() * event.frequency * 0.25

    event.isActive = function(self)
            -- check if there is an event with the same name as this event in the sector
--            print ("isActive: " .. path .. " vs ...")

            for i, path in pairs(Sector():getScripts()) do
--                print (path)

                if path == self.path then return true end
            end
            return false
        end

    table.insert(eventNames, name)
    table.insert(events, event)

--    print ("added event " .. event.path .. " every " .. event.frequency .. " seconds")

end

function clear()
    events = {}
    eventNames = {}
end


function initialize(...)

--    print("init events.lua")

    clear()

    for _, event in pairs({...}) do
        addEvent(event)
    end

--    printScripts()
end

function getUpdateInterval()
    return 5
end

function update(timeStep)

    -- count up for all events
    for i, event in pairs(events) do

        -- check if the event is already running
        if not event:isActive() then

            -- increase counter
            event.counter = event.counter + timeStep

            if event.counter > event.frequency then

                -- create a new event
                Sector():addScript(event.path)

                event.counter = 0

--                print("started event: " .. event.path)
--                printScripts()
            end
        else
            -- reset counter to 0, event is running
            event.counter = 0

        end

    end

end

function printScripts()
    print("currently running scripts: ")
    for i, name in pairs(Sector():getScripts()) do
        print(name)
    end
end

function restore(data)
    clear()
    for _, p in pairs(data) do
        addEvent(p.name, p.frequency)
    end
end

function secure()
    local data = {}
    for _, event in pairs(events) do
        table.insert(data, {name = event.name, frequency = event.frequency})
    end
    return data
end

end
