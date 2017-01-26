if onServer() then

package.path = package.path .. ";data/scripts/lib/?.lua"

Scientist = require ("story/scientist")

function initialize()
    -- check if there is already a satellite
    if Sector():getEntitiesByScript("data/scripts/entity/story/researchsatellite.lua") then return end

    -- if not, create a new one
    Scientist.createSatellite(Matrix())
end


end
