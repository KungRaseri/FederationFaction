package.path = package.path .. ";data/scripts/lib/?.lua"
require ("utility")
require ("randomext")
require ("faction")
UpgradeGenerator = require("upgradegenerator")
Shop = require ("shop")

-- if this function returns false, the script will not be listed in the interaction window,
-- even though its UI may be registered
function interactionPossible(playerIndex, option)
    return CheckFactionInteraction(playerIndex, -10000)
end

function sortSystems(a, b)
    if a.rarity.value == b.rarity.value then
        return a.price > b.price
    end

    return a.rarity.value > b.rarity.value
end

function addItems()

    UpgradeGenerator.initialize()

    local counter = 0
    local systems = {}
    while counter < 12 do

        local x, y = Sector():getCoordinates()
        local rarities, weights = UpgradeGenerator.getSectorProbabilities(x, y)

        weights[6] = weights[6] * 0.25 -- strongly reduced probability for normal high rarity equipment
        weights[7] = 0 -- no legendaries in equipment dock

        local system = UpgradeGenerator.generateSystem(nil, weights)

        if system.rarity.value >= 0 or math.random() < 0.25 then
            table.insert(systems, system)
            counter = counter + 1
        end
    end

    table.sort(systems, sortSystems)

    for _, system in pairs(systems) do
        add(system, getInt(1, 2))
    end

end

function initialize()
    Shop.initialize("Equipment Dock"%_t)

    if onClient() and EntityIcon().icon == "" then
        EntityIcon().icon = "data/textures/icons/pixel/sdwhite.png"
    end
end

function initUI()
    Shop.initUI("Buy Upgrades"%_t, "Equipment Dock"%_t)
end
