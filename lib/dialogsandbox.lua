package.path = package.path .. ";data/scripts/lib/?.lua" .. ";data/scripts/entity/dialogs/?.lua"
require("stringutility")

require("storyhints")

function onAnythingInteresting()
    ScriptUI():showDialog(thefour3())
end
