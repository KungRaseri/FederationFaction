package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

require ("galaxy")
require ("goods")
require ("stringutility")

local ShipUtility = {}


function ShipUtility.getMaxVolumes()
    local maxVolumes = {}

    local base = 2000
    local scale = 2.5

    -- base class (explorer)
    maxVolumes[1] = base * math.pow(scale, -3.0)
    maxVolumes[2] = base * math.pow(scale, -2.0)
    maxVolumes[3] = base * math.pow(scale, -1.0)
    maxVolumes[4] = base * math.pow(scale, 0.0)
    maxVolumes[5] = base * math.pow(scale, 1.0)
    maxVolumes[6] = base * math.pow(scale, 2.0)
    maxVolumes[7] = base * math.pow(scale, 2.5)
    maxVolumes[8] = base * math.pow(scale, 3.0)
    maxVolumes[9] = base * math.pow(scale, 3.5)
    maxVolumes[10] = base * math.pow(scale, 4.0)
    maxVolumes[11] = base * math.pow(scale, 4.5)
    maxVolumes[12] = base * math.pow(scale, 5.0)

    return maxVolumes
end

function ShipUtility.getMilitaryNameByVolume(volume)
    local names =
    {
        "Scout /* ship title */"%_T,
        "Sentinel /* ship title */"%_T,
        "Hunter /* ship title */"%_T,
        "Corvette /* ship title */"%_T,
        "Frigate /* ship title */"%_T,
        "Cruiser /* ship title */"%_T,
        "Destroyer /* ship title */"%_T,
        "Dreadnought /* ship title */"%_T,
        "Battleship /* ship title */"%_T
    }

    local volumes = ShipUtility.getMaxVolumes()

    for i = 1, #names do
        if volume < volumes[i] then
            return names[i]
        end
    end

    return names[#names]
end

function ShipUtility.getTraderNameByVolume(volume)
    local names =
    {
        "Trader /* ship title */"%_T,
        "Merchant /* ship title */"%_T,
        "Salesman /* ship title */"%_T,
    }

    local volumes = ShipUtility.getMaxVolumes()

    for i = 1, #names do
        if volume < volumes[i] then
            return names[i]
        end
    end

    return names[#names]
end

function ShipUtility.getFreighterNameByVolume(volume)
    local names =
    {
        "Transporter /* ship title */"%_T,
        "Lifter /* ship title */"%_T,
        "Freighter /* ship title */"%_T,
        "Loader /* ship title */"%_T,
        "Cargo Transport /* ship title */"%_T,
        "Cargo Hauler /* ship title */"%_T,
        "Heavy Cargo Hauler /* ship title */"%_T
    }

    local volumes = ShipUtility.getMaxVolumes()

    for i = 1, #names do
        if volume < volumes[i] then
            return names[i]
        end
    end

    return names[#names]
end

function ShipUtility.getMinerNameByVolume(volume)
    local names =
    {
        "Light Miner /* ship title */"%_T,
        "Light Miner /* ship title */"%_T,
        "Miner /* ship title */"%_T,
        "Miner /* ship title */"%_T,
        "Heavy Miner /* ship title */"%_T,
        "Heavy Miner /* ship title */"%_T,
        "Mining Moloch /* ship title */"%_T,
        "Mining Moloch /* ship title */"%_T,
    }

    local volumes = ShipUtility.getMaxVolumes()

    for i = 1, #names do
        if volume < volumes[i] then
            return names[i]
        end
    end

    return names[#names]
end


function ShipUtility.addTurretsToCraft(entity, turret, numTurrets)

    local values = {entity:getTurretPositions(turret, numTurrets)}

    local c = 1;
    numTurrets = tablelength(values) / 2

    for i = 1, numTurrets do
        local position = values[c]; c = c + 1;
        local part = values[c]; c = c + 1;

        if part ~= nil then
            entity:addTurret(turret, position, part)
        else
            -- print("no turrets added, no place for turret found")
        end
    end

end


function ShipUtility.addArmedTurretsToCraft(entity, amount)

    local faction = Faction(entity.factionIndex)

    local turrets = {}

    local items = faction:getInventory():getItemsByType(InventoryItemType.TurretTemplate)

    for i, slotItem in pairs(items) do
        local turret = slotItem.item

        if turret.armed then
            table.insert(turrets, turret)
        end
    end

    -- find out what kind of turret to add to the craft
    if #turrets == 0 then return end

    local turret
    if entity.isStation then
        -- stations get turrets with highest reach

        local currentReach = 0.0

        for i, t in pairs(turrets) do
            for j = 0, t.numWeapons - 1 do

                local reach = t.reach
                if reach > currentReach then
                    currentReach = reach
                    turret = t
                end
            end
        end

    else
        -- ships get random turrets
        turret = turrets[math.random(1, #turrets)]
    end

    -- find out how many are possible with the current crew limitations
    local requiredCrew = turret:getCrew()

    if requiredCrew.size > 0 then
        local numTurrets = 0;

        if entity.isStation then
            numTurrets = math.random(40, 60)
        else
            numTurrets = amount
        end

        -- add turrets
        ShipUtility.addTurretsToCraft(entity, turret, numTurrets)

    end

end

function ShipUtility.addUnarmedTurretsToCraft(entity, amount)

    local faction = Faction(entity.factionIndex)

    local turrets = {}

    local items = faction:getInventory():getItemsByType(InventoryItemType.TurretTemplate)
    for i, slotItem in pairs(items) do
        local turret = slotItem.item

        if turret.civil then
            table.insert(turrets, turret)
        end
    end

    if #turrets == 0 then return end

    local turret = turrets[math.random(1, #turrets)]

    -- find out how many are possible with the current crew limitations
    local requiredCrew = turret:getCrew()

    if requiredCrew.size > 0 then
        local numTurrets = 0;

        if entity.isStation then
            numTurrets = math.random(40, 60)
        else
            numTurrets = amount
        end

        -- add turrets
        ShipUtility.addTurretsToCraft(entity, turret, numTurrets)
    end

end

function ShipUtility.addCargoToCraft(entity)
    local g = goodsArray[getInt(1, #goodsArray)]

    entity:addCargo(g:good(), 500)

end


return ShipUtility

