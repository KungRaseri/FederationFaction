
function initialize()
    Sector():registerCallback("onPlayerLeft", "updateDeletion")
end

function onSectorChanged()
    Sector():registerCallback("onPlayerLeft", "updateDeletion")
end

function updateDeletion()
    if Sector().numPlayers == 0 then
        Sector():deleteEntity(Entity())
    end
end
