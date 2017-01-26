
function AddDefaultShipScripts(ship)
    ship:addScriptOnce("data/scripts/entity/startbuilding.lua")
    ship:addScriptOnce("data/scripts/entity/entercraft.lua")
    ship:addScriptOnce("data/scripts/entity/exitcraft.lua")

    ship:addScriptOnce("data/scripts/entity/craftorders.lua")
    ship:addScriptOnce("data/scripts/entity/transfercrewgoods.lua")
    ship:addScriptOnce("data/scripts/entity/collaboration.lua")
end

function AddDefaultStationScripts(station)
    station:addScriptOnce("data/scripts/entity/startbuilding.lua")
    station:addScriptOnce("data/scripts/entity/entercraft.lua")
    station:addScriptOnce("data/scripts/entity/exitcraft.lua")

    station:addScriptOnce("data/scripts/entity/crewboard.lua")
    station:addScriptOnce("data/scripts/entity/backup.lua")
    station:addScriptOnce("data/scripts/entity/bulletinboard.lua")
    station:addScriptOnce("data/scripts/entity/story/bulletins.lua")

    station:addScriptOnce("data/scripts/entity/craftorders.lua")
    station:addScriptOnce("data/scripts/entity/transfercrewgoods.lua")
    station:addScriptOnce("data/scripts/entity/collaboration.lua")
end


