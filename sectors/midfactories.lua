
package.path = package.path .. ";data/scripts/sectors/?.lua"

local template = dofile ("data/scripts/sectors/factoryfield.lua")

template.probability = 250
template.factoryScript = "data/scripts/entity/merchants/midfactory.lua"

return template
