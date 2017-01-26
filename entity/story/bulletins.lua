package.path = package.path .. ";data/scripts/lib/?.lua"

The4 = require("story/the4")

function initialize()
    if onServer() then
        -- if appropriate, post a bulletin for the 4
        local self = Entity()
        The4.tryPostBulletin(self)
    end

end





