package.path = package.path .. ";data/scripts/lib/?.lua"
require ("stringutility")

local seed = nil
local rarity = nil

function initialize(seed32_in, rarity_in)
    if seed32_in and rarity_in then
        seed = Seed(seed32_in)
        rarity = rarity_in
        if seed and rarity then
            onInstalled(seed, rarity)
        end
    end

    if onClient() then
        invokeServerFunction("remoteInstall")
    end
end

function remoteInstall()
    broadcastInvokeClientFunction("remoteInstallCallback", seed, rarity)
end

function remoteInstallCallback(seed_in, rarity_in)
    seed = seed_in
    rarity = rarity_in
    onInstalled(seed, rarity)
end

-- example: factor 0.3 -> new = old * 1.3
function addBaseMultiplier(bonus, factor)
    if factor == 1 then return end
    if onClient() then return end

    local key = Entity():addBaseMultiplier(bonus, factor)
    return key
end

-- example: factor 0.3 -> new = old * 0.3
function addMultiplier(bonus, factor)
    if factor == 1 then return end
    if onClient() then return end

    local key = Entity():addMultiplier(bonus, factor)
    return key
end

function addMultiplyableBias(bonus, factor)
    if factor == 0 then return end
    if onClient() then return end

    local key = Entity():addMultiplyableBias(bonus, factor)
    return key
end

function addAbsoluteBias(bonus, factor)
    if factor == 0 then return end
    if onClient() then return end

    local key = Entity():addAbsoluteBias(bonus, factor)
    return key
end

function removeBonus(key)
    if onClient() then return end

    Entity():removeBonus(key)
end

function onDelete()
    onUninstalled(seed, rarity)
end

function secure()
    -- this acts as a failsafe when something crashes
    seed = seed or Seed(111111)
    rarity = rarity or Rarity(0)

    return {seed = seed.value, rarity = rarity.value}
end

function restore(data)
    if not data then
        seed = Seed(111111)
        rarity = Rarity(0)
    else
        seed = Seed(data.seed or 111111)
        rarity = Rarity(data.rarity or 0)
    end

    onInstalled(seed, rarity)
end

function makeTooltip(seed, rarity)
    local tooltip = Tooltip()
    tooltip.icon = getIcon(seed, rarity)

    local iconColor = ColorRGB(0.5, 0.5, 0.5)

    -- head line
    local line = TooltipLine(25, 15)
    line.ctext = getName(seed, rarity)
    line.ccolor = rarity.color
    tooltip:addLine(line)

    -- rarity name
    local line = TooltipLine(5, 12)
    line.ctext = tostring(rarity)
    line.ccolor = rarity.color
    tooltip:addLine(line)

    local fontSize = 14;
    local lineHeight = 20;

    -- empty line to separate headline from descriptions
    tooltip:addLine(TooltipLine(18, 18))

    if getTooltipLines then
        local lines = getTooltipLines(seed, rarity)
        for _, l in pairs(lines) do
            -- size
            local line = TooltipLine(lineHeight, fontSize)
            line.ltext = l.ltext or ""
            line.ctext = l.ctext or ""
            line.rtext = l.rtext or ""
            line.icon = l.icon or ""
            line.lcolor = l.lcolor or ColorRGB(1, 1, 1)
            line.ccolor = l.ccolor or ColorRGB(1, 1, 1)
            line.rcolor = l.rcolor or ColorRGB(1, 1, 1)
            line.lbold = l.lbold or false
            line.cbold = l.cbold or false
            line.rbold = l.rbold or false
            line.litalic = l.litalic or false
            line.citalic = l.citalic or false
            line.ritalic = l.ritalic or false
            line.iconColor = l.color or iconColor
            tooltip:addLine(line)
        end
    end

    -- empty lines to separate stats and descriptions
    -- energy consumption (if any)
    if getEnergy then
        tooltip:addLine(TooltipLine(15, 15))

        local energy, unitPrefix = getReadableValue(getEnergy(seed, rarity))

        if energy ~= 0 then
            local line = TooltipLine(lineHeight, fontSize)
            line.ltext = "Energy Consumption"%_t
            line.rtext = string.format("%g %sW", energy, unitPrefix)
            line.icon = "data/textures/icons/electric.png"
            line.iconColor = iconColor
            tooltip:addLine(line)
        end
    end

    tooltip:addLine(TooltipLine(15, 15))

    if getDescriptionLines then
        local lines = getDescriptionLines(seed, rarity)

        for _, l in pairs(lines) do
            -- size
            local line = TooltipLine(lineHeight, fontSize)
            line.ltext = l.ltext or ""
            line.ctext = l.ctext or ""
            line.rtext = l.rtext or ""
            line.icon = l.icon or ""
            line.lcolor = l.lcolor or ColorRGB(1, 1, 1)
            line.ccolor = l.ccolor or ColorRGB(1, 1, 1)
            line.rcolor = l.rcolor or ColorRGB(1, 1, 1)
            line.lbold = l.lbold or false
            line.cbold = l.cbold or false
            line.rbold = l.rbold or false
            line.litalic = l.litalic or false
            line.citalic = l.citalic or false
            line.ritalic = l.ritalic or false
            line.iconColor = l.color or iconColor
            tooltip:addLine(line)
        end

        -- empty lines so the icon wont overlap with the descriptions
        for i = 1, 3 - #lines do
            tooltip:addLine(TooltipLine(15, 15))
        end

    else
        -- empty lines so the icon wont overlap with the descriptions
        for i = 1, 3 do
            tooltip:addLine(TooltipLine(15, 15))
        end
    end

    return tooltip
end

function getRarity()
    return rarity
end

function getSeed()
    return seed
end



