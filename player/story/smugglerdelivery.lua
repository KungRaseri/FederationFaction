package.path = package.path .. ";data/scripts/lib/?.lua"

require("mission")
require("stringutility")
ShipGenerator = require("shipgenerator")
Placer = require("placer")
Smuggler = require("story/smuggler")

missionData.brief = "Easy Delivery"%_t
missionData.title = "Easy Delivery"%_t
missionData.description = "A stranger gave you some suspicious goods to deliver, in exchange for a lot of money. According to him the delivery will be easy.\n"%_t
missionData.description = missionData.description .. "You have 60 minutes to deliver the goods."%_t

function initialize(x, y)

    if onClient() then
        sync()
    end

    if onServer() then
        initMissionCallbacks()
        Player():registerCallback("onSectorEntered", "onSectorEntered")

        if not x or not y then return end

        missionData.justStarted = true
        missionData.location = {x = x, y = y}
        missionData.timeLimit = 60 * 60 -- 1 hour
        missionData.stage = 0

    end
end

function getUpdateInterval()
    return 5
end

function updateServer(timeStep)
    updateMission(timeStep)
end

function onSectorEntered(player, x, y)
    if x == missionData.location.x and y == missionData.location.y then return end

    local d = distance(vec2(x, y), vec2(missionData.location.x, missionData.location.y))
    if d < 30 and missionData.stage == 0 then
        spawnControllers(x, y)
        missionData.stage = 1
    end
end

function onTargetLocationEntered(x, y)
    Smuggler.spawn(x, y)
end

function spawnControllers(x, y)
    local faction = Galaxy():getNearestFaction(x, y)

    local player = Player()
    local ship = player.craft

    for i = 1, 4 do
        local pos = random():getDirection() * 150
        local look = random():getDirection()
        local up = random():getDirection()

        ShipGenerator.createDefender(faction, MatrixLookUpPosition(look, up, pos))
    end

    Placer.resolveIntersections()

end

function showMissionAccomplished(text)
    if onServer() then
        invokeClientFunction(Player(), "showMissionAccomplished", text)
        return
    end

    displayMissionAccomplishedText("MISSION \"ACCOMPLISHED\""%_t, (text or missionData.title or "")%_t % missionData)
end
