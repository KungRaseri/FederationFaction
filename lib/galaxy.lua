
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

require ("utility")

local blockRingMin = 147;
local blockRingMax = 150;

local shipVolumeInCenter = 2750
local turretsInCenter = 25

-- All values related to distribution of things in the galaxy

-- returns the richness factor of sectors, a factor to determine how many more resources
-- sectors near the center of the galaxy have
function Balancing_GetSectorRichnessFactor(x, y)
    -- sectors near the center shall be richer concerning the amount of resources found in them

    local coords = vec2(x, y)

    local maxDist = Balancing_GetDimensions() / 2
    local dist = length(coords)

    if dist > maxDist then dist = maxDist end

    local linFactor = 1.0 - (dist / maxDist) -- range 0 to 1, 0 at the very edge
    local distFactor = linFactor + 1.0 -- range 1 to 2
    distFactor = distFactor * distFactor * distFactor -- cubic rise from 1 to 8


    local richness = distFactor * 2.0 - 2 -- cubic rise from 1 to 14
    richness = richness + linFactor * 6 -- mix of cubic + linear rise from 1 to 20

    return richness
end


-- returns the volume of an average ship in a sector, dependent on the position of the sector
function Balancing_GetSectorShipVolume(x, y)
    -- sectors near the center shall be have bigger ships in them

    local coords = vec2(x, y)

    local maxDist = Balancing_GetDimensions() / 2
    local dist = length(coords)

    if dist > maxDist then dist = maxDist end
    local linFactor = 1.0 - (dist / maxDist) -- range 0 to 1, 0 at the edge (not corner)
    local linFactorOverall = linFactor -- range 0 to 1, 0 at the edge (not corner)
    local linFactorOuter = math.min(1.0, math.max(0.0, 1.0 - (dist / 400))) -- range 0 to 1, 0 at 400
    local linFactorMid = math.min(1.0, math.max(0.0, 1.0 - (dist / 350))) -- etc

    local b = 150
    local q = 1000
    local loverall = 1000
    local louter = 2500
    local lmid = 2500

    local distFactor = linFactor * 3 + 1.0 -- range 1 to 4
    distFactor = math.pow(distFactor, 4) - 1 -- rise from 0 to 255

    local shipVolume = distFactor * (q / 255) -- flat in the beginning, more steep at the center
    shipVolume = shipVolume + linFactorOverall * loverall -- add a linear factor for the outer regions, so some progress is visible.
    shipVolume = shipVolume + linFactorOuter * louter -- add a linear factor for the inner regions, so the difficulty rises after the early game
    shipVolume = shipVolume + linFactorMid * lmid -- add a linear factor for the inner regions, so the difficulty rises after the early game

    shipVolume = shipVolume * (shipVolumeInCenter / (q + loverall + louter + lmid))

    shipVolume = shipVolume + b -- add a small basic factor so there are no ships with volume 0 in the outer regions

    return shipVolume
end

function Balancing_GetSectorStationVolume(x, y)
    return Balancing_GetSectorShipVolume(x, y) * 100
end

function Balancing_GetShipVolumeDeviation()
    return 1.0 + 30.0 * math.random() ^ 4.0
end

function Balancing_GetStationVolumeDeviation()
    return 1.0 + 10.0 * math.random() ^ 3.0
end

function Balancing_GetSectorMaterialStrength(x, y)
    local probabilities = Balancing_GetMaterialProbability(x, y)

    local strength = 0
    local strengthSum = 0
    for key, value in pairs(probabilities) do
        strength = strength + value * Material(key).strengthFactor
        strengthSum = strengthSum + value
    end

    return strength / strengthSum
end

function Balancing_GetTechLevel(x, y)
    -- this is just a number indicating how strong the tech of the object is
    -- ranges from 0 to ... lots
    local coords = vec2(x, y)
    local dist = math.floor(length(coords))

    local tech = lerp(dist, 0, 500, 52, 1)

    return math.floor(tech + 0.5)
end

function Balancing_GetSectorByTechLevel(tech)
    local dist = lerp(tech, 1, 52, 500, 0)
    return math.floor(dist + 0.5), 0
end

function Balancing_TechWeaponDPS(tech)
    local x, y = Balancing_GetSectorByTechLevel(tech);
    return Balancing_GetSectorWeaponDPS(x, y)
end

function Balancing_GetSectorTurretsUnrounded(x, y)
    local dist = length(vec2(x, y))
    return lerp(dist, 460, 0, 2, turretsInCenter)
end

function Balancing_GetSectorTurrets(x, y)
    return math.floor(Balancing_GetSectorTurretsUnrounded(x, y))
end

function Balancing_GetEnemySectorTurretsUnrounded(x, y)
    return Balancing_GetSectorTurretsUnrounded(x, y) * 1.5
end

function Balancing_GetEnemySectorTurrets(x, y)
    return math.floor(Balancing_GetEnemySectorTurretsUnrounded(x, y))
end


function Balancing_GetSectorShipHP(x, y)
    -- an average craft in this sector has approx. this health
    -- blocks have an average durability of volume * 4
    local materialStrength = Balancing_GetSectorMaterialStrength(x, y)
    local shipVolume = Balancing_GetSectorShipVolume(x, y)

    return shipVolume * materialStrength * 4.0
end

function Balancing_GetSectorWeaponDPS(x, y)

    -- this function creates a dps ratio to the hp so an average player ship with average numbers of turrets
    -- takes 15 seconds to destroy another average ship
    local coords = vec2(x, y)

    local dist = length(coords)

    local la = math.min(1.0, math.max(0.0, 1.0 - (dist / 800))) -- range 0 to 1, 0 at 800
    local lb = math.min(1.0, math.max(0.0, 1.0 - (dist / 560))) -- etc
    local lc = math.min(1.0, math.max(0.0, 1.0 - (dist / 470)))
    local ld = math.min(1.0, math.max(0.0, 1.0 - (dist / 430)))
    local le = math.min(1.0, math.max(0.0, 1.0 - (dist / 360)))
    local lf = math.min(1.0, math.max(0.0, 1.0 - (dist / 310)))
    local lg = math.min(1.0, math.max(0.0, 1.0 - (dist / 220)))
    local lmin = math.min(1.0, math.max(0.0, 1.0 - (dist / 220)))

    local b = 250
    local q = 1000
    local loverall = 1000
    local louter = 500
    local lmid = 30

    local dps = 0
    dps = math.max(dps, 95 * la)
    dps = math.max(dps, 190 * lb)
    dps = math.max(dps, 310 * lc)
    dps = math.max(dps, 370 * ld)
    dps = math.max(dps, 470 * le)
    dps = math.max(dps, 550 * lf)
    dps = math.max(dps, 650 * lg)

    -- add a cap so dps won't explode towards the middle
    dps = math.min(dps, 100 * lmin + 500)

    -- finally apply the size factor here, too, since this one should scale with the ship sizes from Balancing_GetSectorShipVolume
    local maximumHP = Balancing_GetSectorShipHP(0, 0)
    local maximumTurrets = Balancing_GetSectorTurretsUnrounded(0, 0)
    local maximumDps = maximumHP / maximumTurrets / 15.0 -- assuming it should this many seconds to destroy an average ship with a fully armed ship in the center

    -- print (maximumDps)

    dps = dps * (maximumDps / 600)

    dps = math.max(dps, 18)

    return dps, Balancing_GetTechLevel(x, y)
end

function Balancing_GetCraftWeaponDPS(hp)
    -- strength is dps, where it would take 20 seconds to destroy a craft
    local dps = hp / 20.0

    return dps
end

function Balancing_GetSectorMiningDPS(x, y)
    -- this is a good value for mining lasers in the beginning
    local dps = 3.0

    local materialFactor = 1.0 + (Balancing_GetSectorMaterialStrength(x, y) - 1.0) * 0.1

    dps = dps * materialFactor

    return dps, Balancing_GetTechLevel(x, y)
end

function Balancing_GetMaterialProbability(x, y)
    -- this table will be returned
    local result = {}

    local coords = vec2(x, y)

    local distFromCenter = length(coords) / Balancing_GetMaxCoordinates()
    local beltSize = Balancing_GetMaterialBeltSize()

    for i = 0, NumMaterials() - 1, 1 do
        local beltRadius = Balancing_GetMaterialBeltRadius(i)

        local distFromBelt = math.abs(distFromCenter - beltRadius)

        local value = lerp(distFromBelt, beltSize, beltSize + beltSize * Balancing_GetMaterialExistanceThreshold(), 1, 0)

        if distFromCenter < beltRadius then value = value + 0.085 end

        if i == 0 then
            -- lowest material is everywhere in the outer regions
            if distFromCenter > beltRadius then value = 1 end
        elseif i == NumMaterials() - 1 then
            -- highest material is everywhere in the center
            if distFromCenter < beltRadius then value = 1 end
        end

        result[i] = value
    end

    -- always add a small amount of titanium so building isn't too frustrating at the start
    if distFromCenter < 460 then
        result[1] = math.max(result[1], 0.065)
    end

    -- never create avorion outside the barrier
    if distFromCenter > Balancing_GetBlockRingMin() then
        result[6] = 0
    end

    local sum = 0
    for _, amount in pairs(result) do
        sum = sum + amount
    end

    -- normalize
    for i = 0, NumMaterials() - 1, 1 do
        result[i] = result[i] / sum
    end

    return result
end

function Balancing_GetSingleMaterialProbability(x, y, material)
    local probabilities = Balancing_GetMaterialProbability(x, y)
    return probabilities[material]
end

function Balancing_GetWeaponProbability(x, y)
    local distFromCenter = length(vec2(x, y)) / Balancing_GetMaxCoordinates()

    local data = {}

    data[WeaponType.ChainGun] =         {p = 3.0}
    data[WeaponType.MiningLaser] =      {p = 3.0}
    data[WeaponType.SalvagingLaser] =   {p = 2.0}
    data[WeaponType.Bolter] =           {d = 0.9, p = 1.0}
    data[WeaponType.ForceGun] =         {d = 0.85, p = 1.0}
    data[WeaponType.PlasmaGun] =        {d = 0.8, p = 2.0}
    data[WeaponType.Laser] =            {d = 0.75, p = 2.0}
    data[WeaponType.Cannon] =           {d = 0.7, p = 2.0}
    data[WeaponType.RepairBeam] =       {d = 0.65, p = 2.0}
    data[WeaponType.RocketLauncher] =   {d = 0.6, p = 1.0}
    data[WeaponType.LightningGun] =     {d = 0.55, p = 2.0}
    data[WeaponType.TeslaGun] =         {d = 0.55, p = 2.0}
    data[WeaponType.RailGun] =          {d = 0.5, p = 1.0}

    local probabilities = {}

    for t, specs in pairs(data) do
        if not specs.d or distFromCenter < specs.d then
            probabilities[t] = specs.p
        end
    end

    return probabilities
end

function Balancing_GetMaterialBeltRadius(material)

    -- the lower the material, the further away from the galaxy core it is found
    local level = NumMaterials() - material

    local distanceFactor = level / (NumMaterials()) - 0.1

    return distanceFactor
end

function Balancing_GetMaterialBeltSize()
    local outer = Balancing_GetMaterialBeltRadius(0)
    local inner = Balancing_GetMaterialBeltRadius(1)

    return (outer - inner) / 2
end

function Balancing_GetMaterialExistanceThreshold()
    -- Materials can be still found at X * belt size away from their regular position
    return 0.5
end

function Balancing_GetMaxCoordinates()
    return Balancing_GetDimensions() / 2
end

function Balancing_GetMinCoordinates()
    return -(Balancing_GetDimensions() / 2 - 1)
end

function Balancing_GetDimensions()
    return 1000
end

function Balancing_GetPirateLevel(x, y)
    local p = vec2(x, y)

    local dist = length(p)

    local max = Balancing_GetMaxCoordinates();
    max = math.sqrt(max * max + max * max)

    local level = (1 - (dist / max)) * 32;

    return level;
end

function Balancing_GetBlockRingMin()
    return blockRingMin;
end

function Balancing_GetBlockRingMax()
    return blockRingMax;
end


return
{

BlockRingMin = blockRingMin,
BlockRingMax = blockRingMax,
BlockRingMin2 = blockRingMin * blockRingMin,
BlockRingMax2 = blockRingMax * blockRingMax,

GetSectorRichnessFactor = Balancing_GetSectorRichnessFactor,
GetSectorShipVolume = Balancing_GetSectorShipVolume,
GetSectorStationVolume = Balancing_GetSectorStationVolume,
GetShipVolumeDeviation = Balancing_GetShipVolumeDeviation,
GetStationVolumeDeviation = Balancing_GetStationVolumeDeviation,
GetSectorMaterialStrength = Balancing_GetSectorMaterialStrength,
GetTechLevel = Balancing_GetTechLevel,
GetSectorWeaponDPS = Balancing_GetSectorWeaponDPS,
GetCraftWeaponDPS = Balancing_GetCraftWeaponDPS,
GetSectorMiningDPS = Balancing_GetSectorMiningDPS,
GetMaterialProbability = Balancing_GetMaterialProbability,
GetSingleMaterialProbability = Balancing_GetSingleMaterialProbability,
GetMaterialBeltRadius = Balancing_GetMaterialBeltRadius,
GetMaterialBeltSize = Balancing_GetMaterialBeltSize,
GetMaterialExistanceThreshold = Balancing_GetMaterialExistanceThreshold,
GetMaxCoordinates = Balancing_GetMaxCoordinates,
GetMinCoordinates = Balancing_GetMinCoordinates,
GetDimensions = Balancing_GetDimensions,
GetPirateLevel = Balancing_GetPirateLevel,
GetSectorTurrets = Balancing_GetSectorTurrets,


}



