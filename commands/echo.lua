package.path = package.path .. ";data/scripts/lib/?.lua"

function execute(sender, commandName, ...)
    local args = {...}

    local str = ""
    for i, v in pairs(args) do
        str = str .. v .. " "
    end

    print(str)

    return 0, "", ""
end

function getDescription()
    return "Echoes all given parameters to console"
end

function getHelp()
    return "Echoes all given parameters to console. Usage: /echo This is a test"
end
