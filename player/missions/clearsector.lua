package.path = package.path .. ";data/scripts/lib/?.lua"

local PirateGenerator = require("pirategenerator")
require("stringutility")
require("mission")

missionData.brief = "Wipe out Pirates"%_t
missionData.title = "Wipe out pirates in (${location.x}:${location.y})"%_t
missionData.description = "The ${giver} asked you to take care of a group of pirates that settled in sector (${location.x}:${location.y})."%_t

function initialize(giverIndex, x, y, reward)

    if onClient() then
        sync()
    else
        Player():registerCallback("onSectorEntered", "onSectorEntered")

        -- don't initialize data if there is none
        if not giverIndex then return end

        local station = Entity(giverIndex)

        missionData.giver = Sector().name .. " " .. station.translatedTitle
        missionData.location = {x = x, y = y}
        missionData.reward = reward
        missionData.justStarted = true
    end

end

function updateServer()

    local x, y = Sector():getCoordinates()

    if missionData.location.x == x and missionData.location.y == y then
        local numPirates = getNumPirates()

        if numPirates == 0 then
            local player = Player()
            player:receive(missionData.reward)
            player:sendChatMessage(missionData.giver, 0, "Thank you for taking care of this scum. We transferred the reward to your account."%_t)
            finish()
        end
    end

end

function onTargetLocationEntered(x, y)
    if getNumPirates() == 0 then
        Player():sendChatMessage(missionData.giver, 0, "Looks like someone already took care of them. Thank you nevertheless."%_t)
        finish()
    end
end

function getNumPirates()
    local faction = PirateGenerator.getPirateFaction()

    local num = 0
    for _, entity in pairs({Sector():getEntitiesByComponent(ComponentType.Owner)}) do
        if entity.factionIndex == faction.index then
            num = num + 1
        end
    end

    return num
end
