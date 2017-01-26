
function getFactionWarSideVariableName(faction)
    faction = faction or Faction()

    local a = faction.index
    local b = faction:getValue("enemy_faction")
    local enemy = b

    if a > b then a, b = b, a end

    return string.format("factionwar_%i_%i_side", a, b), enemy
end
