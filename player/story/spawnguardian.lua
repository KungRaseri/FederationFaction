if onServer() then

package.path = package.path .. ";data/scripts/lib/?.lua"
Xsotan = require("story/xsotan")

function initialize()
    Player():registerCallback("onSectorEntered", "onSectorEntered")
end

function onSectorEntered(player, x, y)
    if not (x == 0 and y == 0) then return end

    local respawnTime = Server():getValue("guardian_respawn_time")
    if respawnTime then return end

    -- only spawn him once
    local sector = Sector()
    if Sector():getEntitiesByScript("data/scripts/entity/story/wormholeguardian.lua") then return end

    -- clear everything that's not player owned
    local entities = {sector:getEntities()}
    for _, entity in pairs(entities) do
        if not entity.factionIndex or not Player(entity.factionIndex) then
            sector:deleteEntity(entity)
        end
    end

    Xsotan.createGuardian()
end

end
