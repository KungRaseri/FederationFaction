
function string.starts(String,Start)
    return string.sub(String, 1, string.len(Start)) == Start
end

function string.ends(String,End)
    return End == "" or string.sub(String, -string.len(End)) == End
end

function string:split(sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    self:gsub(pattern, function(c) table.insert(fields, c) end)
    return fields
end

_T = {}
function interp(s, tab)
    if tab == _T then return s end -- pass through when called with %_T
    if not tab then return GetLocalizedString(s) end

    return (s:gsub('($%b{})', function(w)
        local t = tab
        local key = w:sub(3, -2)

        local fragments = key:split(".")

        local num = #fragments
        for i = 1, num - 1, 1 do
            key = fragments[i]
            t = t[key]

            if not t then return w end
        end

        key = fragments[num]

        return t[key] or w
    end))
end
--print( interp("${name} is ${value}", {name = "foo", value = "bar"}) )

getmetatable("").__mod = interp

-- print( "${name} is ${value}" % {name = "foo", value = "bar"} )
-- Outputs "foo is bar"

function enumerate(values, f)

    local result = ""
    local num = #values

    for i = 1, num do
        local value = values[i]

        if i > 1 then
            if i == num then
                result = result .. " and /* this is for the last connection of enumerations, such as A, B and C */"%_t
            else
                result = result .. ", "
            end
        end

        local str

        if f then
            str = f(value)
        else
            str = value
        end

        result = result .. str
    end

    return result
end
