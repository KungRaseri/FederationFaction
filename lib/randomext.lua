-- This library serves as an extension to the existing random functions.
-- The math.random() function uses the c rand() and srand() functions, which are global for all lua states.
-- This means that whenever a lua state sets a new seed or requests a new value, the seed is changed for all other lua states as well.
-- In order to avoid this and to introduce 64bit seeds, these extensions were created.
-- They behave exactly the same way as the lua math.random() math.randomseed() functions, but accept Avorion's Seed class as well, which is basically a 64bit integer.
-- In addition to the 64 bit seeds, each lua state has a separate random number generator.
local rand = Random(Seed(systemTimeMs()))

function isint(n)
    return n == math.floor(n)
end

function random()
    return rand
end

math.random = function(min, max)
    if min and max then
        return rand:getInt(min, max)
    elseif min then
        return rand:getInt(1, min)
    end

    return rand:getFloat()
end

math.randomseed = function(seed)
    if type(seed) == "number" then
        rand = Random(Seed(seed))
    else
        rand = Random(seed)
    end
end

function getFloat(minValue, maxValue)
    if minValue > maxValue then
        minValue, maxValue = maxValue, minValue
    end

    return rand:getFloat(minValue, maxValue)
end

function getInt(minValue, maxValue)
    if minValue > maxValue then
        minValue, maxValue = maxValue, minValue
    end

    return rand:getInt(minValue, maxValue)
end

function selectByWeight(random, values)

    local thresholds = {}

    local sum = 0.0

    for key, value in pairs(values) do

        local t = {}

        t.lower = sum
        sum = sum + value
        t.upper = sum

        thresholds[key] = t
    end

    local rnd = random:getFloat(sum)
    local lastkey
    for key, value in pairs(thresholds) do

        if rnd >= value.lower and rnd < value.upper then
            return key
        end

        lastkey = key
    end

    return lastkey
end

function shuffle(random, array)
    local entries = #array
    for i = 1, entries do
        local o = random:getInt(1, #array)
        array[i], array[o] = array[o], array[i]
    end
end

function randomEntry(random, array)
    return array[random:getInt(1, #array)]
end
