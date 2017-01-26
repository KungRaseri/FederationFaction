package.path = package.path .. ";data/scripts/lib/?.lua"
require("stringutility")

function lerp (factor, lowerBound, upperBound, lowerValue, upperValue)
    if lowerBound > upperBound then
        lowerBound, upperBound = upperBound, lowerBound
        lowerValue, upperValue = upperValue, lowerValue
    end

    if lowerBound == upperBound then
        return lowerValue
    end

    local value = math.min(1.0, math.max(0.0, (factor - lowerBound) / (upperBound - lowerBound)))

    return lowerValue + (upperValue - lowerValue) * value
end

function round(num, idp)
    local mult = 10^(idp or 0)
    if num >= 0 then return math.floor(num * mult + 0.5) / mult
    else return math.ceil(num * mult - 0.5) / mult end
end

function getRandomEntry(tbl)
    return tbl[getInt(1, tablelength(tbl))]
end

function getDistribution(numElements, variation)
    assert(variation >= 0 and variation < 1, "Variation must be between [0 , 1)")
    assert(numElements > 0, "numElements must be > 0")

    local result = {}

    variation = variation * 0.5

    local sum = 0
    for i = 0, numElements - 1, 1 do
        local value = getFloat(0.5 - variation, 0.5 + variation)

        sum = sum + value

        result[i] = value
    end

    for i = 0, numElements - 1, 1 do
        result[i] = result[i] / sum
    end

    return result

end

function getValueFromDistribution(distribution)

    local thresholds = {}

    local sum = 0.0

    for key, value in pairs(distribution) do

        local t = {}

        t.lower = sum
        sum = sum + value
        t.upper = sum

        thresholds[key] = t
    end

    local rnd = math.random() * sum
    local lastkey
    for key, value in pairs(thresholds) do

        if rnd >= value.lower and rnd < value.upper then
            return key
        end

        lastkey = key
    end

    return lastkey
end

function createReadableTimeString(seconds)

    seconds = math.floor(seconds)

    local hours = math.floor(seconds / 3600)
    seconds = seconds - hours * 3600

    local minutes = math.floor(seconds / 60)
    seconds = seconds - minutes * 60

    local result = ""

    local tbl = {hours = hours, minutes = minutes, seconds = seconds}

    if hours > 0 then
        return "${hours} hours, ${minutes} minutes"%_t % tbl
    end

    if minutes > 0 then
        return "${minutes} minutes, ${seconds} seconds"%_t % tbl
    end

    return "${seconds} seconds"%_t % tbl

end

function toReadableValue(value, unit)
    local value, prefix = getReadableValue(value)

    return tostring(value) .. " " .. prefix .. (unit or "")
end

function getReadableValue(value)
    local unitPrefix = ""

    if value > 10.0 ^ 23 then
        value = value / 10.0 ^ 24
        unitPrefix = "Y /*10^24, prefix*/"%_t
    elseif value > 10.0 ^ 20 then
        value = value / 10.0 ^ 21
        unitPrefix = "Z /*10^21, prefix*/"%_t
    elseif value > 10.0 ^ 17 then
        value = value / 10.0 ^ 18
        unitPrefix = "E /*10^18, prefix*/"%_t
    elseif value > 10.0 ^ 14 then
        value = value / 10.0 ^ 15
        unitPrefix = "P /*10^15, prefix*/"%_t
    elseif value > 10.0 ^ 11 then
        value = value / 10.0 ^ 12
        unitPrefix = "T /*10^12, prefix*/"%_t
    elseif value > 10.0 ^ 8 then
        value = value / 10.0 ^ 9
        unitPrefix = "G /*10^9, prefix*/"%_t
    elseif value > 10.0 ^ 5 then
        value = value / 10.0 ^ 6
        unitPrefix = "M /*10^6, prefix*/"%_t
    elseif value > 10.0 ^ 2 then
        value = value / 10.0 ^ 3
        unitPrefix = "k /*10^3, prefix*/"%_t
    end

    return round(value, 2), unitPrefix
end

function getReadableNumber(value)
    local abbreviation = ""

    if value > 10.0 ^ 11 then
        value = value / 10.0 ^ 12
        abbreviation = "trill /*10^12, abbreviation*/"%_t
    elseif value > 10.0 ^ 8 then
        value = value / 10.0 ^ 9
        abbreviation = "bill /*10^9, abbreviation*/"%_t
    elseif value > 10.0 ^ 5 then
        value = value / 10.0 ^ 6
        abbreviation = "mill /*10^6, abbreviation*/"%_t
    elseif value > 10.0 ^ 2 then
        value = value / 10.0 ^ 3
        abbreviation = "k /*10^3, abbreviation*/"%_t
    end

    return round(value, 2), abbreviation
end

function toRomanLiterals(number)

    local result = ""
    if number < 0 then
        number = -number
        result = "-"
    end

    while number >= 1000 do
        number = number - 1000
        result = result .. "M"
    end

    if number >= 900 then result = result .. "CM"; number = number - 900
    elseif number >= 800 then result = result .. "DCCC"; number = number - 800
    elseif number >= 700 then result = result .. "DCC"; number = number - 700
    elseif number >= 600 then result = result .. "DC"; number = number - 600
    elseif number >= 500 then result = result .. "D"; number = number - 500
    elseif number >= 400 then result = result .. "CD"; number = number - 400
    elseif number >= 300 then result = result .. "CCC"; number = number - 300
    elseif number >= 200 then result = result .. "CC"; number = number - 200
    elseif number >= 100 then result = result .. "C"; number = number - 100
    end

    if number >= 90 then result = result .. "XC"; number = number - 90
    elseif number >= 80 then result = result .. "LXXX"; number = number - 80
    elseif number >= 70 then result = result .. "LXX"; number = number - 70
    elseif number >= 60 then result = result .. "LX"; number = number - 60
    elseif number >= 50 then result = result .. "L"; number = number - 50
    elseif number >= 40 then result = result .. "XL"; number = number - 40
    elseif number >= 30 then result = result .. "XXX"; number = number - 30
    elseif number >= 20 then result = result .. "XX"; number = number - 20
    elseif number >= 10 then result = result .. "X"; number = number - 10
    end

    if number >= 9 then result = result .. "IX"
    elseif number >= 8 then result = result .. "VIII"
    elseif number >= 7 then result = result .. "VII"
    elseif number >= 6 then result = result .. "VI"
    elseif number >= 5 then result = result .. "V"
    elseif number >= 4 then result = result .. "IV"
    elseif number >= 3 then result = result .. "III"
    elseif number >= 2 then result = result .. "II"
    elseif number >= 1 then result = result .. "I"
    end

    return result;

end

function renderPrices(pos, caption, money, resources)

    local earlyExit = true
    money = money or 0
    resources = resources or {}

    if money > 0 then earlyExit = false end

    for i, v in ipairs(resources) do
        if v > 0 then
            earlyExit = false
            break
        end
    end

    if earlyExit then return 0 end

    local fontSize = 13

    drawText(caption, pos.x, pos.y, ColorRGB(1, 1, 1), fontSize, 0, 0, 2)
    local py = pos.y + fontSize * 1.5

    -- render contruction costs
    if money > 0 then
        drawText("$", pos.x, py, ColorRGB(1, 1, 1), fontSize, 0, 0, 2)
        drawText(createMonetaryString(round(money, 0)), pos.x + 100, py, ColorRGB(1, 1, 1), fontSize, 0, 0, 2)
        py = py + fontSize
    end

    -- render resources costs
    for i, v in ipairs(resources) do
        local planResources = resources[i]

        if planResources > 0 then
            drawText(Material(i - 1).name, pos.x, py, Material(i - 1).color, fontSize, 0, 0, 2)
            drawText(createMonetaryString(round(planResources, 0)), pos.x + 100, py, Material(i - 1).color, fontSize, 0, 0, 2)
            py = py + fontSize
        end
    end

    return py - pos.y + 10
end

function GetRelationChangeFromMoney(money)
    return money / 210
end

function tablelength(T)
    if T == nil then return 0 end

    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

function table.first(tbl)
    for _, value in pairs(tbl) do
        return value
    end
end

function pairsByKeys (t, f)
    local a = {}
    for n in pairs(t) do table.insert(a, n) end
    table.sort(a, f)
    local i = 0      -- iterator variable
    local iter = function ()   -- iterator function
        i = i + 1
        if a[i] == nil then return nil
        else return a[i], t[a[i]]
        end
    end
    return iter
end

-- shamelessly copied from the lua doc
function string:split(sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    self:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end

function printEntityDebugInfo(entity)
    entity = entity or Entity()
    if not entity then return end

    local scripts = ""
    for _, name in pairs(entity:getScripts()) do
        scripts = scripts .. "'" .. name .. "' "
    end

    local faction = Faction(entity.factionIndex)
    local factionName = ""

    if faction then factionName = faction.translatedName end

    print ("## Entity Information ##")
    print ("Index: " .. entity.index)
    print ("Title: " .. (entity.title or ""))
    print ("Scripts: " .. scripts)
    print ("Owner: " .. factionName)
    print ("## Entity Information End ##")

end

function findMinimum(array, eval)
    local d = math.huge
    local min
    for _, e in pairs(array) do
        local de = eval(e)
        if de < d then
            d = de
            min = e
        end
    end
    return min
end

function findMaximum(array, eval)
    local d = -math.huge
    local max
    for _, e in pairs(array) do
        local de = eval(e)
        if de > d then
            d = de
            max = e
        end
    end
    return max
end

function printTable(tbl, prefix)
    prefix = prefix or ""
    for k, v in pairs(tbl) do
        print (prefix .. "k: " .. tostring(k) .. " -> v: " .. tostring(v))
        if type(v) == "table" then
            printTable(v, prefix .. "  ")
        end
    end
end

function directionalDistance(d, coords)
    coords = coords or vec2(Sector():getCoordinates())

    local dir = vec2(coords.x, coords.y) -- this way we can use tables, too
    normalize_ip(dir)

    dir = dir * d

    return {x = math.floor(dir.x + 0.5), y = math.floor(dir.y + 0.5)}
end
