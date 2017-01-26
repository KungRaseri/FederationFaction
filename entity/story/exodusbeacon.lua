
function initialize()
    if onClient() then
        Player():registerCallback("onStartDialog", "onStartDialog")
    end
end

function onStartDialog()
    invokeServerFunction("startExodus")
end

function startExodus()
    Player(callingPlayer):addScriptOnce("story/exodus.lua", true)

    local x, y = Sector():getCoordinates()
    Player(callingPlayer):invokeFunction("story/exodus.lua", "beaconFound", x, y)
end
