package.path = package.path .. ";data/scripts/lib/?.lua"

require ("galaxy")
require ("randomext")

local rand = random()

local TurretGenerator =  {}

function TurretGenerator.initialize(seed)
    if seed then
        rand = Random(seed)
    end
end

function TurretGenerator.generate(x, y, offset_in, rarity_in, type_in, material_in) -- server

    local offset = offset_in or 0
    local seed = rand:createSeed()
    local dps = 0
    local sector = math.floor(length(vec2(x, y))) + offset

    local weaponDPS, weaponTech = Balancing_GetSectorWeaponDPS(sector, 0)
    local miningDPS, miningTech = Balancing_GetSectorMiningDPS(sector, 0)
    local materialProbabilities = Balancing_GetMaterialProbability(sector, 0)
    local material = material_in or Material(getValueFromDistribution(materialProbabilities))
    local weaponType = type_in or getValueFromDistribution(Balancing_GetWeaponProbability(sector, 0))

    local tech = 0
    if weaponType == WeaponType.MiningLaser then
        dps = miningDPS
        tech = miningTech
    elseif weaponType == WeaponType.ForceGun then
        dps = rand:getFloat(800, 1200); -- force
        tech = weaponTech
    else
        dps = weaponDPS
        tech = weaponTech
    end

    local rarities = {}
    rarities[5] = 0.1 -- legendary
    rarities[4] = 1 -- exotic
    rarities[3] = 8 -- exceptional
    rarities[2] = 16 -- rare
    rarities[1] = 32 -- uncommon
    rarities[0] = 128 -- common

    local rarity = rarity_in or Rarity(getValueFromDistribution(rarities))

    return GenerateTurretTemplate(seed, weaponType, dps, tech, rarity, material)
end

function TurretGenerator.generateArmed(x, y, offset_in, rarity_in, material_in) -- server

    local offset = offset_in or 0
    local sector = math.floor(length(vec2(x, y))) + offset
    local types = Balancing_GetWeaponProbability(sector, 0)

    types[WeaponType.RepairBeam] = nil
    types[WeaponType.MiningLaser] = nil
    types[WeaponType.SalvagingLaser] = nil
    types[WeaponType.ForceGun] = nil

    local weaponType = getValueFromDistribution(types)

    return TurretGenerator.generate(x, y, offset_in, rarity_in, weaponType, material_in)
end

return TurretGenerator
