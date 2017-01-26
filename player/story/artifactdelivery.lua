package.path = package.path .. ";data/scripts/lib/?.lua"

require ("mission")
require ("stringutility")
The4 = require ("story/the4")

function initialize(x, y)
    initMissionCallbacks()

    if onServer() then

        if not x or not y then return end

        missionData.location = {x = x, y = y}
        missionData.justStarted = true
        missionData.brief = "Artifact Delivery"%_t
        missionData.title = "Artifact Delivery"%_t
        missionData.description = "Some people who call themselves 'The Brotherhood' have posted bulletins and are looking for Xsotan artifacts. They seem to pay a high reward to people who bring them artifacts."%_t

    else
        sync()
    end

end

function getUpdateInterval()
    return 0.5
end

function updateServer()
    if The4.checkForDrop() then
        showMissionAccomplished()
        terminate()
    end
end

function onTargetLocationEntered(x, y)
    The4.spawnBeacon()
end
