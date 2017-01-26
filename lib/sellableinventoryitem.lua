package.path = package.path .. ";data/scripts/lib/?.lua"
require ("galaxy")
require ("utility")
require ("tooltipmaker")


local SellableInventoryItem = {}
SellableInventoryItem.__index = SellableInventoryItem

function ArmedObjectPrice(object)

    local costFactor = 1.0

    -- collect turret stats
    local dps = object.dps
    local material = object.material

    if object.coolingType == 0 and object.heatPerShot > 0 then
        dps = dps * object.shootingTime / (object.shootingTime + object.coolingTime)
    end

    dps = dps + dps * object.shieldDamageMultiplicator + dps * object.hullDamageMultiplicator

    dps = dps + object.hullRepairRate * 2.0 + object.shieldRepairRate * 3.0
    dps = dps + math.abs(object.selfForce) * 0.2 + math.abs(object.otherForce) * 0.3

    value = dps * 0.5 * object.reach * 0.5

    -- mining laser value scales with the used material and the efficiency
    if object.stoneEfficiency > 0 then
        costFactor = 3.0

        local materialFactor = material.strengthFactor * 5.0
        local efficiencyFactor = object.stoneEfficiency * 8.0

        value = value * materialFactor
        value = value * (1.0 + efficiencyFactor)
    end

    if object.metalEfficiency > 0 then
        costFactor = 3.0

        local efficiencyFactor = object.metalEfficiency * 8.0
        value = value * (1.0 + efficiencyFactor)
    end

    -- rocket launchers gain value if they fire seeker rockets
    if object.seeker then
        value = value * 2.5
    end

    --value = value * 1.5
    local rarityFactor = 1.0 + 1.35 ^ object.rarity.value

    value = value * rarityFactor
    value = value * (1.0 + object.shieldPenetration)
    value = value * costFactor

    return value
end

function SortSellableInventoryItems(a, b)
    if a.item.itemType == b.item.itemType then
        if a.rarity.value == b.rarity.value then
            if a.item.itemType == InventoryItemType.Turret or a.item.itemType == InventoryItemType.TurretTemplate then
                if a.item.weaponPrefix == b.item.weaponPrefix then
                    return a.price > b.price
                else
                    return a.item.weaponPrefix < b.item.weaponPrefix
                end
            elseif a.item.itemType == InventoryItemType.SystemUpgrade then
                if a.item.script == b.item.script then
                    return a.price > b.price
                else
                    return a.item.script < b.item.script
                end
            end
        else
            return a.rarity.value > b.rarity.value
        end
    else
        return a.item.itemType < b.item.itemType
    end
end

local function new(item, index, player)
    local obj = setmetatable({item = item, index = index}, SellableInventoryItem)

    -- initialize the item
    obj.price = obj:getPrice()
    obj.name = obj:getName()
    obj.rarity = obj.item.rarity
    obj.material = obj:getMaterial()
    obj.icon = obj:getIcon()

    if player and index then
        obj.amount = player:getInventory():amount(index)
    elseif index and type(index) == "number" then
        obj.amount = index
    else
        obj.amount = 1
    end

    return obj
end

function SellableInventoryItem:getMaterial()
    if self.item.itemType == InventoryItemType.Turret or self.item.itemType == InventoryItemType.TurretTemplate then
        return self.item.material
    end
end

function SellableInventoryItem:getIcon()
    if self.item.itemType == InventoryItemType.Turret or self.item.itemType == InventoryItemType.TurretTemplate then
        return self.item.weaponIcon
    elseif self.item.itemType == InventoryItemType.SystemUpgrade then
        return self.item.icon
    end
end

function SellableInventoryItem:getTooltip()

    if self.tooltip == nil then
        if self.item.itemType == InventoryItemType.Turret or self.item.itemType == InventoryItemType.TurretTemplate then
            self.tooltip = makeTurretTooltip(self.item)
        elseif self.item.itemType == InventoryItemType.SystemUpgrade then
            self.tooltip = self.item.tooltip
        end
    end

    return self.tooltip
end

function SellableInventoryItem:getPrice()
    local value = 0

    if self.item.itemType == InventoryItemType.Turret or self.item.itemType == InventoryItemType.TurretTemplate then

        local turret = self.item

        local value = round(ArmedObjectPrice(turret))

        return value

    elseif self.item.itemType == InventoryItemType.SystemUpgrade then
        value = self.item.price
    end

    return value
end

function SellableInventoryItem:getName()
    local name = ""

    if self.item.itemType == InventoryItemType.Turret or self.item.itemType == InventoryItemType.TurretTemplate then
        if onClient() then
            local tooltip = self:getTooltip()
            return tooltip:getLine(0).ctext
        else
            return "Turret";
        end

    elseif self.item.itemType == InventoryItemType.SystemUpgrade then
        return self.item.name
    end

    return name
end

function SellableInventoryItem:boughtByPlayer(ship)

    local player = Player(ship.factionIndex)

    player:getInventory():add(self.item)

end

function SellableInventoryItem:soldByPlayer(ship)

    local player = Player(ship.factionIndex)

    local item = player:getInventory():take(self.index)
    if item == nil then
        return "Item to sell not found", {}
    end

end

return setmetatable({new = new}, {__call = function(_, ...) return new(...) end})


