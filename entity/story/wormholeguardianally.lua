
package.path = package.path .. ";data/scripts/lib/?.lua"

require ("stringutility")

function interactionPossible(playerIndex, option)
   return true
end

function initUI()
    ScriptUI():registerInteraction("Attack the Guardian!"%_t, "onAttackGuardian")
    ScriptUI():registerInteraction("Attack the small ships!"%_t, "onAttackShips")
end


function getAlliedShips()
    local allies = {Sector():getEntitiesByScript("entity/story/wormholeguardianally.lua")}
    local guardian = Sector():getEntitiesByScript("entity/story/wormholeguardian.lua")

    return allies, guardian
end

function onAttackGuardian()

    if onClient() then
        invokeServerFunction("onAttackGuardian")
        return
    end

    local allies, guardian = getAlliedShips()
    if not guardian then return end

    for _, ally in pairs(allies) do

        for index, name in pairs(ally:getScripts()) do
            if string.match(name, "data/scripts/entity/ai/") then
                ally:removeScript(index)
            end
        end

        ShipAI(ally.index):setAttack(guardian)
        ShipAI(ally.index):registerEnemyEntity(guardian)
    end

end

function onAttackShips()

    if onClient() then
        invokeServerFunction("onAttackShips")
        return
    end

    local allies, guardian = getAlliedShips()
    if not guardian then return end

    for _, ally in pairs(allies) do
        ally:addScript("data/scripts/entity/ai/patrol.lua")
        ShipAI(ally.index):registerFriendEntity(guardian)
    end

end


