package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

require ("utility")
require ("stringutility")

local iconColor = ColorRGB(0.5, 0.5, 0.5)

local headLineSize = 25
local headLineFont = 15

local function fillWeaponTooltipData(obj, tooltip)

    -- rarity name
    local line = TooltipLine(5, 12)
    line.ctext = tostring(obj.rarity)
    line.ccolor = obj.rarity.color
    tooltip:addLine(line)

    -- primary stats, one by one
    local fontSize = 14
    local lineHeight = 20

    local line = TooltipLine(lineHeight, fontSize)
    line.ltext = "Tech"%_t
    line.rtext = round(obj.averageTech, 1)
    line.icon = "data/textures/icons/circuitry.png";
    line.iconColor = iconColor
    tooltip:addLine(line)

    -- empty line
    tooltip:addLine(TooltipLine(15, 15))

    if obj.damage > 0 then
        if obj.continuousBeam then

            local line = TooltipLine(lineHeight, fontSize)
            line.ltext = "Damage /s"%_t
            line.rtext = round(obj.dps, 1)
            line.icon = "data/textures/icons/screen-impact.png";
            line.iconColor = iconColor
            tooltip:addLine(line)

        else
            -- damage
            local line = TooltipLine(lineHeight, fontSize)
            line.ltext = "Damage"%_t
            line.rtext = round(obj.damage, 1)
            if obj.shotsPerFiring > 1 then
                line.rtext = line.rtext .. " x" .. obj.shotsPerFiring
            end
            line.icon = "data/textures/icons/screen-impact.png";
            line.iconColor = iconColor
            tooltip:addLine(line)

            -- fire rate
            local line = TooltipLine(lineHeight, fontSize)
            line.ltext = "Fire Rate"%_t
            line.rtext = round(obj.fireRate, 1)
            line.icon = "data/textures/icons/bullets.png";
            line.iconColor = iconColor
            tooltip:addLine(line)
        end
    end

    if obj.otherForce > 0 then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Push"%_t
        line.rtext = toReadableValue(obj.otherForce, "N /* unit: Newton*/"%_t)
        line.icon = "data/textures/icons/back-forth.png";
        line.iconColor = iconColor
        tooltip:addLine(line)
    elseif obj.otherForce < 0 then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Pull"%_t
        line.rtext = toReadableValue(-obj.otherForce, "N /* unit: Newton*/"%_t)
        line.icon = "data/textures/icons/back-forth.png";
        line.iconColor = iconColor
        tooltip:addLine(line)
    end

    if obj.selfForce > 0 then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Self Push"%_t
        line.rtext = toReadableValue(obj.selfForce, "N /* unit: Newton*/"%_t)
        line.icon = "data/textures/icons/back-forth.png";
        line.iconColor = iconColor
        tooltip:addLine(line)
    elseif obj.selfForce < 0 then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Self Pull"%_t
        line.rtext = toReadableValue(-obj.selfForce, "N /* unit: Newton*/"%_t)
        line.icon = "data/textures/icons/back-forth.png";
        line.iconColor = iconColor
        tooltip:addLine(line)
    end

    if obj.stoneEfficiency > 0 and obj.metalEfficiency > 0 then

        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Eff. Stone"%_t
        line.rtext = round(obj.stoneEfficiency * 100, 1)
        line.icon = "data/textures/icons/recycle.png";
        line.iconColor = iconColor
        tooltip:addLine(line)

        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Eff. Metal"%_t
        line.rtext = round(obj.metalEfficiency * 100, 1)
        line.icon = "data/textures/icons/recycle.png";
        line.iconColor = iconColor
        tooltip:addLine(line)

    elseif obj.stoneEfficiency > 0 then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Efficiency"%_t
        line.rtext = round(obj.stoneEfficiency * 100, 1)
        line.icon = "data/textures/icons/recycle.png";
        line.iconColor = iconColor
        tooltip:addLine(line)
    elseif obj.metalEfficiency > 0 then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Efficiency"%_t
        line.rtext = round(obj.metalEfficiency * 100, 1)
        line.icon = "data/textures/icons/recycle.png";
        line.iconColor = iconColor
        tooltip:addLine(line)
    end

    if obj.hullRepairRate > 0 then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Hull Dmg /s"%_t
        line.rtext = round(obj.hullRepairRate, 1)
        line.icon = "data/textures/icons/health-normal.png";
        line.iconColor = iconColor
        tooltip:addLine(line)
    end

    if obj.shieldRepairRate > 0 then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Shield Dmg /s"%_t
        line.rtext = round(obj.shieldRepairRate, 1)
        line.icon = "data/textures/icons/health-normal.png";
        line.iconColor = iconColor
        tooltip:addLine(line)
    end

    local line = TooltipLine(lineHeight, fontSize)
    line.ltext = "Accuracy"%_t
    line.rtext = round(obj.accuracy * 100, 1)
    line.icon = "data/textures/icons/reticule.png";
    line.iconColor = iconColor
    tooltip:addLine(line)

    local line = TooltipLine(lineHeight, fontSize)
    line.ltext = "Range"%_t
    line.rtext = round(obj.reach * 10 / 1000, 2)
    line.icon = "data/textures/icons/target-shot.png";
    line.iconColor = iconColor
    tooltip:addLine(line)

    -- empty line
    tooltip:addLine(TooltipLine(15, 15))

    if obj.coolingType == 1 or obj.coolingType == 2 then

        local line = TooltipLine(lineHeight, fontSize)

        if obj.coolingType == 2 then
            line.ltext = "Energy /s"%_t
        else
            line.ltext = "Energy /shot"%_t
        end
        line.rtext = round(obj.baseEnergyPerSecond)
        line.icon = "data/textures/icons/electric.png";
        line.iconColor = iconColor
        tooltip:addLine(line)

        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Energy Increase /s"%_t
        line.rtext = round(obj.energyIncreasePerSecond, 1)
        line.icon = "data/textures/icons/electric.png";
        line.iconColor = iconColor
        tooltip:addLine(line)

        -- empty line
        tooltip:addLine(TooltipLine(15, 15))
    end

    local line = TooltipLine(lineHeight, fontSize)
    line.ltext = "Material"%_t
    line.rtext = obj.material.name
    line.rcolor = obj.material.color
    line.icon = "data/textures/icons/metal-bar.png";
    line.iconColor = iconColor
    tooltip:addLine(line)

end

local function fillDescriptions(obj, tooltip, additional)

    -- now count the lines, as there will have to be lines inserted
    -- to make sure that the icon of the weapon won't overlap with the stats
    local extraLines = 0
    local fontSize = 14
    local lineHeight = 18
    additional = additional or {}

    -- one line for flavor text
    local line = TooltipLine(lineHeight, fontSize)
    line.ltext = obj.flavorText
    line.lcolor = ColorRGB(1.0, 0.7, 0.7)
    tooltip:addLine(line)

    extraLines = extraLines + 1

    local descriptions = obj:getDescriptions()

    for desc, value in pairs(descriptions) do
        local line = TooltipLine(lineHeight, fontSize)

        if value == "" then
            line.ltext = desc % _t
        else
            line.ltext = string.format(desc % _t, value)
        end

        local existsAlready
        for _, desc in pairs(additional) do
            if desc == line.ltext then
                existsAlready = true
            end
        end

        if not existsAlready then
            tooltip:addLine(line)
            extraLines = extraLines + 1
        end
    end

    if obj.seeker then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Seeker Missiles"%_t
        tooltip:addLine(line)
        extraLines = extraLines + 1
    end

    for _, text in pairs(additional) do
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = text
        tooltip:addLine(line)
        extraLines = extraLines + 1
    end

    for i = 1, 3 - extraLines do
        -- empty line
        tooltip:addLine(TooltipLine(15, 15))
    end

end

function makeTurretTooltip(turret)
    local tooltip = Tooltip()

        -- create tool tip
    tooltip.icon = turret.weaponIcon

    -- build title
    local title = ""

    local weapon = turret.weaponPrefix .. " /* Weapon Prefix*/"
    weapon = weapon % _t

    local tbl = {material = turret.material.name, weaponPrefix = weapon}

    if turret.stoneEfficiency > 0 or turret.metalEfficiency > 0 then
        if turret.numVisibleWeapons == 1 then
            title = "${material} ${weaponPrefix} Turret"%_t % tbl
        elseif turret.numVisibleWeapons == 2 then
            title = "Double ${material} ${weaponPrefix} Turret"%_t % tbl
        elseif turret.numVisibleWeapons == 3 then
            title = "Triple ${material} ${weaponPrefix} Turret"%_t % tbl
        elseif turret.numVisibleWeapons == 4 then
            title = "Quad ${material} ${weaponPrefix} Turret"%_t % tbl
        else
            title = "Multi ${material} ${weaponPrefix} Turret"%_t % tbl
        end
    else
        if turret.numVisibleWeapons == 1 then
            title = "${weaponPrefix} Turret"%_t % tbl
        elseif turret.numVisibleWeapons == 2 then
            title = "Double ${weaponPrefix} Turret"%_t % tbl
        elseif turret.numVisibleWeapons == 3 then
            title = "Triple ${weaponPrefix} Turret"%_t % tbl
        elseif turret.numVisibleWeapons == 4 then
            title = "Quad ${weaponPrefix} Turret"%_t % tbl
        else
            title = "Multi ${weaponPrefix} Turret"%_t % tbl
        end
    end

    -- head line
    local line = TooltipLine(headLineSize, headLineFont)
    line.ctext = title
    line.ccolor = turret.rarity.color
    tooltip:addLine(line)

    local fontSize = 14;
    local lineHeight = 20;

    fillWeaponTooltipData(turret, tooltip)

    -- size
    local line = TooltipLine(lineHeight, fontSize)
    line.ltext = "Size"%_t
    line.rtext = round(turret.size, 1)
    line.icon = "data/textures/icons/shotgun.png";
    line.iconColor = iconColor
    tooltip:addLine(line)

    -- automatic/independent firing
    if turret.automatic then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Independent Targeting"%_t
        line.icon = "data/textures/icons/cog.png";
        line.iconColor = iconColor
        tooltip:addLine(line)
    end

    -- empty line
    tooltip:addLine(TooltipLine(15, 15))

    -- crew requirements
    local crew = turret:getCrew()

    for crewman, amount in pairs(crew:getMembers()) do

        if amount > 0 then
            local profession = crewman.profession

            local line = TooltipLine(lineHeight, fontSize)
            line.ltext = profession.name
            line.rtext = round(amount)
            line.icon = profession.icon;
            line.iconColor = iconColor
            tooltip:addLine(line)

        end
    end

    -- empty line
    tooltip:addLine(TooltipLine(15, 15))

    local description = {}
    if turret.automatic then
        table.insert(description, "Independent targeting, but deals less damage"%_t)
    end

    fillDescriptions(turret, tooltip, description)

    return tooltip
end



function makeFighterTooltip(fighter)

    -- create tool tip
    local tooltip = Tooltip()
    tooltip.icon = fighter.weaponIcon

    -- title
    local title = "${weaponPrefix} Fighter"%_t % fighter

    local line = TooltipLine(headLineSize, headLineFont)
    line.ctext = title
    line.ccolor = fighter.rarity.color
    tooltip:addLine(line)

    -- primary stats, one by one
    local fontSize = 14
    local lineHeight = 20

    fillWeaponTooltipData(fighter, tooltip)

    -- size
    local line = TooltipLine(lineHeight, fontSize)
    line.ltext = "Size"%_t
    line.rtext = round(fighter.volume)
    line.icon = "data/textures/icons/fighter.png";
    line.iconColor = iconColor
    tooltip:addLine(line)

    -- empty line
    tooltip:addLine(TooltipLine(15, 15))

    -- durability
    local line = TooltipLine(lineHeight, fontSize)
    line.ltext = "Durability"%_t
    line.rtext = round(fighter.durability)
    line.icon = "data/textures/icons/health-normal.png";
    line.iconColor = iconColor
    tooltip:addLine(line)

    if fighter.shield > 0 then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Shield"%_t
        line.rtext = round(fighter.durability)
        line.icon = "data/textures/icons/health-normal.png";
        line.iconColor = iconColor
        tooltip:addLine(line)
    end

    -- empty line
    tooltip:addLine(TooltipLine(15, 15))

    -- maneuverability
    local line = TooltipLine(lineHeight, fontSize)
    line.ltext = "Maneuverability"%_t
    line.rtext = round(fighter.turningSpeed, 2)
    line.icon = "data/textures/icons/dodge.png";
    line.iconColor = iconColor
    tooltip:addLine(line)

    -- velocity
    local line = TooltipLine(lineHeight, fontSize)
    line.ltext = "Speed"%_t
    line.rtext = round(fighter.maxVelocity * 10.0)
    line.icon = "data/textures/icons/afterburn.png";
    line.iconColor = iconColor
    tooltip:addLine(line)

    -- empty line
    tooltip:addLine(TooltipLine(15, 15))

    -- crew requirements
    local pilot = CrewProfession(CrewProfessionType.Pilot)

    local line = TooltipLine(lineHeight, fontSize)
    line.ltext = pilot.name
    line.rtext = round(fighter.crew)
    line.icon = pilot.icon
    line.iconColor = iconColor
    tooltip:addLine(line)


    -- empty line
    tooltip:addLine(TooltipLine(15, 15))

    fillDescriptions(fighter, tooltip)

    return tooltip
end
