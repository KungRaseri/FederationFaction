package.path = package.path .. ";data/scripts/lib/?.lua"

require ("randomext")

local NamePool = {}

local wreckageNames =
{
    "Draperium",
    "Dastardly Darieu's Devious Device",
    "The Arc",
    "UFS Jade Sabre",
    "The Medicament Impulse",
    "Dubious Remnants",
    "The Gigantic II",
    "The Gentry X",
}

local shipNames =
{
    "Emissary's Flagship",
    "Weltraumputze",
    "Skaree",
    "Nexi's Catharsis",
}

local stationNames =
{
    "Mr. Fish's Emporium",
    "Kraven's Landing",
    "Kane's Bunker",
    "Kotzubase",
    "Jensen 82",
}


function NamePool.setWreckageName(wreckage, rand, chance)
    rand = rand or random()
    chance = chance or 1 / 10

    if rand:getFloat() <= chance then
        wreckage.name = NamePool.getWreckageName(rand)
    end
end

function NamePool.setShipName(ship, rand, chance)
    rand = rand or random()
    chance = chance or 1 / 10

    if rand:getFloat() <= chance then
        ship.name = NamePool.getShipName(rand)
    end
end

function NamePool.setStationName(station, rand, chance)
    rand = rand or random()
    chance = chance or 1 / 10

    if rand:getFloat() <= chance then
        station.name = NamePool.getStationName(rand)
    end
end

function NamePool.getName(collection, rand)
    rand = rand or random()
    return randomEntry(rand, collection)
end

function NamePool.getWreckageName(rand)
    return NamePool.getName(wreckageNames, rand)
end

function NamePool.getShipName(rand)
    return NamePool.getName(shipNames, rand)
end

function NamePool.getStationName(rand)
    return NamePool.getName(stationNames, rand)
end

return NamePool
