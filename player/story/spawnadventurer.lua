if onServer() then

package.path = package.path .. ";data/scripts/lib/?.lua"

AdventurerGuide = require("story/adventurerguide")


function initialize()
    if Player():getValue("met_adventurer") then
        terminate()
        return
    end

    Player():registerCallback("onSectorEntered", "onSectorEntered")
end

function onSectorEntered(player, x, y)
    if Player():getValue("met_adventurer") then return end
    --if

    -- check if there are friendly stations
    local friendlyStations = false
    local unfriendlyStations = false

    for _, station in pairs({Sector():getEntitiesByType(EntityType.Station)}) do

        if station.factionIndex then
            local relations = Player():getRelations(station.factionIndex)

            if relations > 30000 then
                friendlyStations = true
            end

            if relations < -10000 then
                unfriendlyStations = true
            end
        end
    end

    if friendlyStations and (not unfriendlyStations) then
        Player():setValue("met_adventurer", true)

        AdventurerGuide.spawn1(Player())
    end

end

end
