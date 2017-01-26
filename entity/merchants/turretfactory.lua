
package.path = package.path .. ";data/scripts/lib/?.lua"
require ("utility")
require ("faction")
require ("defaultscripts")
require ("randomext")
require ("stationextensions")
require ("galaxy")
require ("randomext")
require ("goods")
require ("tooltipmaker")
require ("faction")
require ("player")
require("stringutility")
SellableInventoryItem = require ("sellableinventoryitem")
Dialog = require("dialogutility")
TurretGenerator = require("turretgenerator")


local weaponTypes = {}

table.insert(weaponTypes, WeaponType.ChainGun)
table.insert(weaponTypes, WeaponType.Bolter)
table.insert(weaponTypes, WeaponType.Laser)
table.insert(weaponTypes, WeaponType.PlasmaGun)
table.insert(weaponTypes, WeaponType.Cannon)
table.insert(weaponTypes, WeaponType.RocketLauncher)
table.insert(weaponTypes, WeaponType.RailGun)
table.insert(weaponTypes, WeaponType.RepairBeam)
table.insert(weaponTypes, WeaponType.MiningLaser)
table.insert(weaponTypes, WeaponType.SalvagingLaser)
table.insert(weaponTypes, WeaponType.ForceGun)
table.insert(weaponTypes, WeaponType.LightningGun)

local weaponNamesByType = {}
weaponNamesByType[WeaponType.ChainGun] = "Chaingun /* Weapon Type */"%_t
weaponNamesByType[WeaponType.Bolter] = "Bolter /* Weapon Type */"%_t
weaponNamesByType[WeaponType.Laser] = "Laser /* Weapon Type */"%_t
weaponNamesByType[WeaponType.PlasmaGun] = "Plasma /* Weapon Type */"%_t
weaponNamesByType[WeaponType.Cannon] = "Cannon /* Weapon Type */"%_t
weaponNamesByType[WeaponType.RocketLauncher] = "Launcher /* Weapon Type */"%_t
weaponNamesByType[WeaponType.RailGun] = "Railgun /* Weapon Type */"%_t
weaponNamesByType[WeaponType.RepairBeam] = "Repair /* Weapon Type */"%_t
weaponNamesByType[WeaponType.MiningLaser] = "Mining Laser /* Weapon Type */"%_t
weaponNamesByType[WeaponType.SalvagingLaser] = "Salvaging Laser /* Weapon Type */"%_t
weaponNamesByType[WeaponType.ForceGun] = "Force Gun /* Weapon Type */"%_t
weaponNamesByType[WeaponType.LightningGun] = "Lightning Gun /* Weapon Type */"%_t

local weaponsByComboEntry = {}


local StatChanges =
{
    ToNextLevel = 0,
    Percentage = 1,
    Flat = 2,
}

function getBaseIngredients(weaponType)

    if weaponType == WeaponType.ChainGun then
        return {
            {name = "Servo",            amount = 15,    investable = 10,    minimum = 3, rarityFactor = 0.75, weaponStat = "fireRate", investFactor = 0.3, },
            {name = "Steel Tube",       amount = 6,     investable = 7,     weaponStat = "reach"},
            {name = "Ammunition S",     amount = 5,     investable = 10,    minimum = 1, weaponStat = "damage"},
            {name = "Steel",            amount = 5,     investable = 10,    minimum = 3},
            {name = "Aluminium",        amount = 7,     investable = 5,     minimum = 3},
            {name = "Lead",             amount = 10,    investable = 10,    minimum = 1},
        }
    elseif weaponType == WeaponType.Bolter then
        return {
            {name = "Servo",                amount = 15,    investable = 8,     minimum = 5,    rarityFactor = 0.75, weaponStat = "fireRate", investFactor = 0.3, },
            {name = "High Pressure Tube",   amount = 1,     investable = 3,                     weaponStat = "reach", investFactor = 1.5},
            {name = "Ammunition M",         amount = 5,     investable = 10,    minimum = 1,    weaponStat = "damage", investFactor = 0.25},
            {name = "Explosive Charge",     amount = 2,     investable = 4,     minimum = 1,    weaponStat = "damage", investFactor = 1.5},
            {name = "Steel",                amount = 5,     investable = 10,    minimum = 3,},
            {name = "Aluminium",            amount = 7,     investable = 5,     minimum = 3,},
        }
    elseif weaponType == WeaponType.Laser then
        return {
            {name = "Laser Head",           amount = 2,    investable = 4, minimum = 1, weaponStat = "damage", investFactor = 2.0, },
            {name = "Laser Compressor",     amount = 2,    investable = 3, weaponStat = "damage", investFactor = 2.0, },
            {name = "High Capacity Lens",   amount = 2,    investable = 4, weaponStat = "reach", investFactor = 2.0, },
            {name = "Laser Modulator",      amount = 2,    investable = 4, turretStat = "energyIncreasePerSecond", investFactor = -0.2, changeType = StatChanges.Percentage },
            {name = "Steel",                amount = 5,    investable = 10, minimum = 3,},
            {name = "Crystal",              amount = 2,    investable = 10, minimum = 1,},
        }
    elseif weaponType == WeaponType.PlasmaGun then
        return {
            {name = "Plasma Cell",          amount = 8,    investable = 4,  minimum = 1,   weaponStat = "damage",   },
            {name = "Energy Tube",          amount = 2,    investable = 6, minimum = 1,    weaponStat = "reach", },
            {name = "Conductor",            amount = 5,    investable = 6, minimum = 1,    turretStat = "energyIncreasePerSecond", investFactor = -0.3, changeType = StatChanges.Percentage },
            {name = "Energy Container",     amount = 5,    investable = 6, minimum = 1,    turretStat = "baseEnergyPerSecond", investFactor = -0.3, changeType = StatChanges.Percentage },
            {name = "Steel",                amount = 4,    investable = 10, minimum = 3,},
            {name = "Crystal",              amount = 2,    investable = 10, minimum = 1,},
        }
    elseif weaponType == WeaponType.Cannon then
        return {
            {name = "Servo",                amount = 15,   investable = 10,  minimum = 5,  weaponStat = "fireRate", investFactor = 1.0, changeType = StatChanges.Percentage},
            {name = "Warhead",              amount = 5,    investable = 6, minimum = 1,    weaponStat = "damage",  },
            {name = "High Pressure Tube",   amount = 2,    investable = 6, minimum = 1,    weaponStat = "reach", },
            {name = "Explosive Charge",     amount = 2,    investable = 6, minimum = 1,    weaponStat = "reach", investFactor = 0.5,},
            {name = "Steel",                amount = 8,    investable = 10, minimum = 3,},
            {name = "Wire",                 amount = 5,    investable = 10, minimum = 3,},
        }
    elseif weaponType == WeaponType.RocketLauncher then
        return {
            {name = "Servo",                amount = 15,   investable = 10,  minimum = 5,  weaponStat = "fireRate", investFactor = 1.0, changeType = StatChanges.Percentage},
            {name = "Rocket",               amount = 5,    investable = 6,  minimum = 1,    weaponStat = "damage",  },
            {name = "High Pressure Tube",   amount = 2,    investable = 6,  minimum = 1,    weaponStat = "reach", },
            {name = "Fuel",                 amount = 2,    investable = 6,  minimum = 1,    weaponStat = "reach", investFactor = 0.5,},
            {name = "Targeting Card",       amount = 5,    investable = 5, minimum = 0,     weaponStat = "seeker", investFactor = 1, changeType = StatChanges.Flat},
            {name = "Steel",                amount = 8,    investable = 10, minimum = 3,},
            {name = "Wire",                 amount = 5,    investable = 10, minimum = 3,},
        }
    elseif weaponType == WeaponType.RailGun then
        return {
            {name = "Servo",                amount = 15,   investable = 10,  minimum = 5,   weaponStat = "fireRate", investFactor = 1.0, changeType = StatChanges.Percentage},
            {name = "Electromagnetic Charge",amount = 5,    investable = 6,  minimum = 1,   weaponStat = "damage", investFactor = 0.75,},
            {name = "Electro Magnet",       amount = 8,    investable = 10, minimum = 3,    weaponStat = "reach", investFactor = 0.75,},
            {name = "Gauss Rail",           amount = 5,    investable = 6,  minimum = 1,    weaponStat = "damage", investFactor = 0.75,},
            {name = "High Pressure Tube",   amount = 2,    investable = 6,  minimum = 1,    weaponStat = "reach",  investFactor = 0.75,},
            {name = "Steel",                amount = 5,    investable = 10, minimum = 3,},
            {name = "Copper",               amount = 2,    investable = 10, minimum = 1,},
        }
    elseif weaponType == WeaponType.RepairBeam then
        return {
            {name = "Nanobot",              amount = 5,    investable = 6,  minimum = 1,      weaponStat = "hullRepair", },
            {name = "Transformator",        amount = 2,    investable = 6,  minimum = 1,    weaponStat = "shieldRepair",  investFactor = 0.75,},
            {name = "Laser Modulator",      amount = 2,    investable = 5,  minimum = 0,    weaponStat = "reach",  investFactor = 0.75, changeType = StatChanges.Percentage},
            {name = "Conductor",            amount = 2,    investable = 6,  minimum = 0,    turretStat = "energyIncreasePerSecond",  investFactor = -0.5, changeType = StatChanges.Percentage},
            {name = "Gold",                 amount = 3,    investable = 10, minimum = 1,},
            {name = "Steel",                amount = 8,    investable = 10, minimum = 3,},
        }
    elseif weaponType == WeaponType.MiningLaser then
        return {
            {name = "Laser Compressor",     amount = 5,    investable = 6,  minimum = 1,    weaponStat = "damage", },
            {name = "Laser Modulator",      amount = 2,    investable = 4,  minimum = 0,    weaponStat = "stoneEfficiency", investFactor = 0.075, changeType = StatChanges.Flat },
            {name = "High Capacity Lens",   amount = 2,    investable = 6,  minimum = 0,    weaponStat = "reach",  investFactor = 2.0,},
            {name = "Conductor",            amount = 5,    investable = 6,  minimum = 2,},
            {name = "Steel",                amount = 5,    investable = 10, minimum = 3,},
        }
    elseif weaponType == WeaponType.SalvagingLaser then
        return {
            {name = "Laser Compressor",     amount = 5,    investable = 6,  minimum = 1,    weaponStat = "damage", },
            {name = "Laser Modulator",      amount = 2,    investable = 4,  minimum = 0,    weaponStat = "metalEfficiency", investFactor = 0.075, changeType = StatChanges.Flat },
            {name = "High Capacity Lens",   amount = 2,    investable = 6,  minimum = 0,    weaponStat = "reach",  investFactor = 2.0,},
            {name = "Conductor",            amount = 5,    investable = 6,  minimum = 2,},
            {name = "Steel",                amount = 5,    investable = 10, minimum = 3,},
        }
    elseif weaponType == WeaponType.ForceGun then
        return {
            {name = "Force Generator",      amount = 5,    investable = 3,  minimum = 1,    weaponStat = "otherForce", investFactor = 1.0, changeType = StatChanges.Percentage},
            {name = "Energy Inverter",      amount = 2,    investable = 4,  minimum = 1,    weaponStat = "selfForce", investFactor = 1.0, changeType = StatChanges.Percentage },
            {name = "Energy Tube",          amount = 2,    investable = 6,  minimum = 1,    weaponStat = "reach",  investFactor = 2.0,},
            {name = "Conductor",            amount = 10,   investable = 6,  minimum = 2,},
            {name = "Steel",                amount = 7,    investable = 10, minimum = 3,},
            {name = "Cink",                 amount = 3,    investable = 10, minimum = 3,},
        }
    elseif weaponType == WeaponType.TeslaGun then
        return {
            {name = "Industrial Tesla Coil",amount = 5,    investable = 6,  minimum = 1,    weaponStat = "damage", investFactor = 3.0},
            {name = "Electromagnetic Charge",amount = 2,    investable = 4,  minimum = 1,   weaponStat = "reach", investFactor = 0.2, changeType = StatChanges.Percentage },
            {name = "Energy Inverter",      amount = 2,    investable = 4,  minimum = 1,    turretStat = "baseEnergyPerSecond",  investFactor = -0.5, changeType = StatChanges.Percentage},
            {name = "Conductor",            amount = 5,    investable = 6,  minimum = 2,    turretStat = "energyIncreasePerSecond",  investFactor = -0.5, changeType = StatChanges.Percentage},
            {name = "Copper",               amount = 5,    investable = 10, minimum = 3,},
            {name = "Energy Cell",          amount = 5,    investable = 10, minimum = 3,},
        }
    elseif weaponType == WeaponType.LightningGun then
        return {
            {name = "Military Tesla Coil",  amount = 5,    investable = 6,  minimum = 1,    weaponStat = "damage", investFactor = 3.0},
            {name = "High Capacity Lens",   amount = 2,    investable = 4,  minimum = 1,    weaponStat = "reach", investFactor = 0.2, changeType = StatChanges.Percentage },
            {name = "Electromagnetic Charge",amount = 2,    investable = 4,  minimum = 1,   turretStat = "baseEnergyPerSecond",  investFactor = -0.5, changeType = StatChanges.Percentage},
            {name = "Conductor",            amount = 5,    investable = 6,  minimum = 2,    turretStat = "energyIncreasePerSecond",  investFactor = -0.5, changeType = StatChanges.Percentage},
            {name = "Copper",               amount = 5,    investable = 10, minimum = 3,},
            {name = "Energy Cell",          amount = 5,    investable = 10, minimum = 3,},
        }
    else




        return { {name = "Servo",                amount = 20,    investable = 10, minimum = 3, rarityFactor = 0.75, weaponStat = "damage", investFactor = 0.15, }, }
    end


end





local requirements
local price = 0

-- Menu items
local window
local lines = {}

function initialize()
    local station = Entity()

    if station.title == "" then
        station.title = "Turret Factory"%_t

        if onServer() then
            local x, y = Sector():getCoordinates()
            local seed = Server().seed

            math.randomseed(makeHash(station.index, x, y, seed.value))
            addProductionCenters(station)
            math.randomseed(os.time())
        end
    end

    if onClient() and EntityIcon().icon == "" then
        EntityIcon().icon = "data/textures/icons/pixel/turret.png"
        InteractionText(station.index).text = Dialog.generateStationInteractionText(station, random())
    end

    -- remove weapons that aren't dropped in these regions
    local newWeaponTypes = {}
    local probabilities = Balancing_GetWeaponProbability(Sector():getCoordinates())
    for type, probability in pairs(probabilities) do

        for i, t in pairs(weaponTypes) do
            if t == type then
                newWeaponTypes[i] = t
            end
        end
    end

    weaponTypes = newWeaponTypes

end


function interactionPossible(playerIndex, option)
    return CheckFactionInteraction(playerIndex, 10000)
end

function initUI()
    local res = getResolution()
    local size = vec2(700, 500)

    local menu = ScriptUI()
    window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))

    window.caption = "Turret Factory"%_t
    window.showCloseButton = 1
    window.moveable = 1
    menu:registerWindow(window, "Build Turrets /*window title*/"%_t);

    local container = window:createContainer(Rect(vec2(0, 0), size));

    local vsplit = UIVerticalSplitter(Rect(vec2(0, 0), size), 10, 10, 0.5)
    vsplit:setRightQuadratic()

    local left = vsplit.left
    local right = vsplit.right

    container:createFrame(left);
    container:createFrame(right);

    --- LEFT SIDE
    local lister = UIVerticalLister(left, 10, 10)
    lister.padding = 10 -- add a higher padding as the slider texts might overlap otherwise

    container:createLabel(lister:placeCenter(vec2(lister.inner.width, 15)).lower, "Weapon Type"%_t, 14)
    turretTypeCombo = container:createComboBox(Rect(), "onTurretTypeSelect")
    lister:placeElementCenter(turretTypeCombo)

    container:createLabel(lister:placeCenter(vec2(lister.inner.width, 15)).lower, "Rarity"%_t, 14)
    rarityCombo = container:createComboBox(Rect(), "onRaritySelect")
    lister:placeElementCenter(rarityCombo)

    --- RIGHT SIDE
    local lister = UIVerticalLister(right, 10, 10)

    local vsplit = UIArbitraryVerticalSplitter(lister:placeCenter(vec2(lister.inner.width, 30)), 10, 5, 320, 390)

    container:createLabel(vsplit:partition(0).lower, "Parts"%_t, 14)
    container:createLabel(vsplit:partition(1).lower, "Req"%_t, 14)
    container:createLabel(vsplit:partition(2).lower, "You"%_t, 14)

    for i = 1, 15 do
        local rect = lister:placeCenter(vec2(lister.inner.width, 30))
        local vsplit = UIArbitraryVerticalSplitter(rect, 10, 7, 20, 250, 280, 310, 320, 390)

        local frame = container:createFrame(rect)

        local i = 0

        local icon = container:createPicture(vsplit:partition(i), ""); i = i + 1
        local materialLabel = container:createLabel(vsplit:partition(i).lower, "", 14); i = i + 1
        local plus = container:createButton(vsplit:partition(i), "+", "onPlus"); i = i + 1
        local minus = container:createButton(vsplit:partition(i), "-", "onMinus"); i = i + 2
        local requiredLabel = container:createLabel(vsplit:partition(i).lower, "", 14); i = i + 1
        local youLabel = container:createLabel(vsplit:partition(i).lower, "", 14); i = i + 1

        icon.isIcon = 1
        minus.textSize = 12
        plus.textSize = 12

        local hide = function(self)
            self.icon:hide()
            self.frame:hide()
            self.material:hide()
            self.plus:hide()
            self.minus:hide()
            self.required:hide()
            self.you:hide()
        end

        local show = function(self)
            self.icon:show()
            self.frame:show()
            self.material:show()
            self.plus:show()
            self.minus:show()
            self.required:show()
            self.you:show()
        end

        local line =  {frame = frame, icon = icon, plus = plus, minus = minus, material = materialLabel, required = requiredLabel, you = youLabel, hide = hide, show = show}
        line:hide()

        table.insert(lines, line)
    end

    buildButton = container:createButton(Rect(), "Build"%_t, "onBuildButtonPressed")
    local organizer = UIOrganizer(right)
    organizer.margin = 10
    organizer:placeElementBottomRight(buildButton)

    priceLabel = container:createLabel(vec2(right.lower.x, right.upper.y) + vec2(12, -75), "Manufacturing Price: Too Much"%_t, 16)

    -- needs a separate counter here, weaponTypes are not strictly numbered from 1 to X
    local c = 0
    for _, type in pairs(weaponTypes) do
        local name = weaponNamesByType[type]

        turretTypeCombo:addEntry(name)
        weaponsByComboEntry[c] = type
        c = c + 1
    end

    rarityCombo:addEntry("Common"%_t)
    rarityCombo:addEntry("Uncommon"%_t)
    rarityCombo:addEntry("Rare"%_t)
    rarityCombo:addEntry("Exceptional"%_t)

    turretTypeCombo.selectedIndex = 0

    onTurretTypeSelect()

end

function renderUI()

    local weaponType = getUIWeapon()
    local rarity = getUIRarity()
    local material = getMaterial()
    local ingredients = getUIIngredients()

    local turret = makeTurret(weaponType, rarity, material, ingredients)
    local tooltip = makeTurretTooltip(turret)

    tooltip:draw(vec2(window.upper.x, window.lower.y) + vec2(20, 10))
end

function getUIWeapon()
    return weaponsByComboEntry[turretTypeCombo.selectedIndex]
end

function getUIRarity()
    return Rarity(rarityCombo.selectedIndex)
end

function getUIIngredients()
    return requirements, price
end

function getMaterial()
    local material

    materialProbabilities = Balancing_GetMaterialProbability(Sector():getCoordinates())

    local highest = 0.0
    for i, probability in pairs(materialProbabilities) do
        if probability > highest then
            highest = probability
            material = Material(i)
        end
    end

    return material;
end

function getTurretIngredients(weaponType, rarity, material)
    -- make the turrets generally cheaper, to compensate for randomness and having to bring your own goods
    local turret = makeTurretBase(weaponType, rarity, material)
    local better = makeTurretBase(weaponType,  Rarity(rarity.value + 1), material)

    local item = SellableInventoryItem(turret)
    item.price = item.price * 0.65

    local ingredients = getBaseIngredients(weaponType)

    -- scale required goods with rarity
    for _, ingredient in pairs(ingredients) do
        ingredient.amount = ingredient.amount * (1.0 + rarity.value * (ingredient.rarityFactor or 1.0))
    end

    -- calculate the worth of the required goods
    local goodsPrice = 0
    for _, ingredient in pairs(ingredients) do
        goodsPrice = goodsPrice + goods[ingredient.name].price * ingredient.amount
    end

    if item.price < goodsPrice then
        -- turret is cheaper than the goods required to build it
        -- scale down goods
        local factor = item.price / goodsPrice

        for _, ingredient in pairs(ingredients) do
            ingredient.amount = math.max(ingredient.minimum or 0, math.floor(ingredient.amount * factor))
        end

        -- recalculate the worth
        local oldPrice = goodsPrice
        goodsPrice = 0
        for _, ingredient in pairs(ingredients) do
            goodsPrice = goodsPrice + goods[ingredient.name].price * ingredient.amount
        end

        -- scale ingredients back up. now, ingredients with minimum 0 won't be taken into account
        -- those are usually very expensive ingredients that might cause all ingredients to be scaled down to 0 or 1
        for _, ingredient in pairs(ingredients) do
            ingredient.amount = math.max(ingredient.minimum or 0, math.floor(ingredient.amount * oldPrice / goodsPrice))
        end

        goodsPrice = 0
        for _, ingredient in pairs(ingredients) do
            goodsPrice = goodsPrice + goods[ingredient.name].price * ingredient.amount
        end

        -- and, finally, scale back down if necessary
        if item.price < goodsPrice then
            for _, ingredient in pairs(ingredients) do
                ingredient.amount = math.max(ingredient.minimum or 0, math.floor(ingredient.amount * factor))
            end

            -- recalculate the worth
            goodsPrice = 0
            for _, ingredient in pairs(ingredients) do
                goodsPrice = goodsPrice + goods[ingredient.name].price * ingredient.amount
            end
        end
    end

    -- adjust the maximum additional investable goods
    -- get the difference of stats to the next better turret
    for i, ingredient in pairs(ingredients) do

        local object
        local betterObject
        local stat

        if ingredient.weaponStat then
            object = turret:getWeapons()
            betterObject = better:getWeapons()
            stat = ingredient.weaponStat
        end

        if ingredient.turretStat then
            object = turret
            betterObject = better
            stat = ingredient.turretStat
        end

        if object and stat then

            local changeType = ingredient.changeType or StatChanges.ToNextLevel

            local difference
            if changeType == StatChanges.ToNextLevel then
                difference = (betterObject[stat] - object[stat]) * 0.8

                if difference == 0.0 then
                    difference = object[stat] * 0.3
                end
            elseif changeType == StatChanges.Percentage then
                difference = object[stat]
            elseif changeType == StatChanges.Flat then
                difference = ingredient.investFactor
                ingredient.investFactor = 1.0
            end

            -- print ("changeType: " .. changeType)
            -- print ("stat: " .. stat)
            -- print ("difference: " .. difference)

            local sign = 0
            if difference > 0 then sign = 1
            elseif difference < 0 then sign = -1 end

            local statDelta = math.max(math.abs(difference) / ingredient.investable, 0.01)

            local investable = math.floor(math.abs(difference) / statDelta)
            investable = math.min(investable, ingredient.investable)

            local s = 0
            if type(object[stat]) == "boolean" then
                if object[stat] then
                    s = 1
                else
                    s = 0
                end
            else
                s = math.abs(object[stat])
            end

            local removable = math.floor(s / statDelta)
            removable = math.min(removable, math.floor(ingredient.amount * 0.75))

            ingredient.default = ingredient.amount
            ingredient.minimum = ingredient.amount - removable
            ingredient.maximum = ingredient.amount + investable
            ingredient.statDelta = statDelta * (ingredient.investFactor or 1.0) * sign


            -- print ("delta: " .. ingredient.statDelta)
            -- print ("removable: " .. removable)
            -- print ("investable: " .. investable)
            -- print ("minimum: " .. ingredient.minimum)
            -- print ("maximum: " .. ingredient.maximum)
        else
            ingredient.default = ingredient.amount
            ingredient.minimum = ingredient.amount
            ingredient.maximum = ingredient.amount
            ingredient.statDelta = 0
        end

        if ingredient.amount == 0 and ingredient.investable == 0 then
            ingredients[i] = nil
        end
    end

    --
    local finalIngredients = {}
    for i, ingredient in pairs(ingredients) do
        table.insert(finalIngredients, ingredient)
    end

    -- remaining price is the difference between the goods price sum and the actual turret sum
    local remaining = math.floor(math.max(item.price * 0.15, item.price - goodsPrice)) / 0.65

    return finalIngredients, remaining
end

function makeTurretBase(weaponType, rarity, material)
    local station = Entity()
    local x, y = Sector():getCoordinates()

    local seed = station.index + 123 + x + y * 300 * station.factionIndex

    TurretGenerator.initialize(Seed(seed))
    return TurretGenerator.generate(x, y, 0, rarity, weaponType, material)
end

function makeTurret(weaponType, rarity, material, ingredients)

    local turret = makeTurretBase(weaponType, rarity, material)
    local weapons = {turret:getWeapons()}

    turret:clearWeapons()

    for _, weapon in pairs(weapons) do
        -- modify weapons
        for _, ingredient in pairs(ingredients) do
            if ingredient.weaponStat then
                -- add one stat for each additional ingredient
                local additions = math.max(ingredient.minimum - ingredient.default, math.min(ingredient.maximum - ingredient.default, ingredient.amount - ingredient.default))

                local value = weapon[ingredient.weaponStat]
                if type(value) == "boolean" then
                    if value then
                        value = 1
                    else
                        value = 0
                    end
                end

                value = value + ingredient.statDelta * additions
                weapon[ingredient.weaponStat] = value
            end
        end

        turret:addWeapon(weapon)
    end

    for _, ingredient in pairs(ingredients) do
        if ingredient.turretStat then
            -- add one stat for each additional ingredient
            local additions = math.max(ingredient.minimum - ingredient.default, math.min(ingredient.maximum - ingredient.default, ingredient.amount - ingredient.default))

            local value = turret[ingredient.turretStat]
            value = value + ingredient.statDelta * additions
            turret[ingredient.turretStat] = value
        end
    end


    return turret;
end

function refreshUI()
    local ingredients = getUIIngredients()
    local rarity = getUIRarity()

    for i, line in pairs(lines) do
        line:hide()
    end

    local ship = Entity(Player().craftIndex)

    for i, ingredient in pairs(ingredients) do
        local line = lines[i]
        line:show()

        local good = goods[ingredient.name]:good()

        local needed = ingredient.amount
        local have = ship:getCargoAmount(ingredient.name) or 0

        line.icon.picture = good.icon
        line.material.caption = good.displayName
        line.required.caption = needed
        line.you.caption = have

        line.plus.visible = (ingredient.amount < ingredient.maximum)
        line.minus.visible = (ingredient.amount > ingredient.minimum)

        if have < needed then
            line.you.color = ColorRGB(1, 0, 0)
        else
            line.you.color = ColorRGB(1, 1, 1)
        end
    end

    priceLabel.caption = "Manufacturing Cost: $${money}"%_t % {money = createMonetaryString(price)}

end

function onPlus(button)
    local ingredients = getUIIngredients()

    local ingredient
    for i, line in pairs(lines) do
        if button.index == line.plus.index then
            ingredient = ingredients[i]
        end
    end

    ingredient.amount = math.min(ingredient.maximum, ingredient.amount + 1)

    refreshUI()
end

function onMinus(button)
    local ingredients = getUIIngredients()

    local ingredient
    for i, line in pairs(lines) do
        if button.index == line.minus.index then
            ingredient = ingredients[i]
        end
    end

    ingredient.amount = math.max(ingredient.minimum, ingredient.amount - 1)

    refreshUI()

end

function onRaritySelect()
    requirements, price = getTurretIngredients(getUIWeapon(), getUIRarity(), getMaterial())
    refreshUI()
end

function onTurretTypeSelect()
    requirements, price = getTurretIngredients(getUIWeapon(), getUIRarity(), getMaterial())
    refreshUI()
end

function onBuildButtonPressed(button)
    invokeServerFunction("buildTurret", getUIWeapon(), getUIRarity(), getMaterial(), getUIIngredients())
end

function onShowWindow()
    refreshUI()
end

function buildTurret(weaponType, rarity, material, clientIngredients)

    local player = Player(callingPlayer)
    local ship = Entity(player.craftIndex)
    local station = Entity()


    -- can the weapon be built in this sector?
    local weaponProbabilities = Balancing_GetWeaponProbability(Sector():getCoordinates())
    if not weaponProbabilities[weaponType] then
        sendError(player, "This turret cannot be built here."%_t)
        return
    end

    -- don't take ingredients from clients blindly, they might want to cheat
    local ingredients, price = getTurretIngredients(weaponType, rarity, material)

    for i, ingredient in pairs(ingredients) do
        local other = clientIngredients[i]
        if other then
            ingredient.amount = other.amount
        end
    end

    -- make sure all required goods are there
    local missing
    for i, ingredient in pairs(ingredients) do
        local amount = ship:getCargoAmount(ingredient.name)

        if not amount or amount < ingredient.amount then
            missing = goods[ingredient.name].plural
            break;
        end
    end

    if missing then
        sendError(player, "You need more %s."%_t, missing)
        return
    end

    local canPay, msg, args = player:canPay(price)
    if not canPay then
        sendError(player, msg, unpack(args))
        return
    end

    local errors = {}
    errors[EntityType.Station] = "You must be docked to the station to build turrets."%_T
    errors[EntityType.Ship] = "You must be closer to the ship to build turrets."%_T
    if not CheckPlayerDocked(player, station, errors) then
        return
    end

    -- pay
    player:pay(price)

    for i, ingredient in pairs(ingredients) do
        local g = goods[ingredient.name]:good()
        ship:removeCargo(g, ingredient.amount)
    end

    local turret = makeTurret(weaponType, rarity, material, ingredients)

    player:getInventory():add(InventoryTurret(turret))

    invokeClientFunction(player, "onShowWindow")
end


function sendError(player, msg, ...)
    local station = Entity()
    player:sendChatMessage(station.title, 1, msg, ...)
end







function updateServer()

end
