
package.path = package.path .. ";data/scripts/sectors/?.lua"

local template = dofile ("data/scripts/sectors/factoryfield.lua")

template.probability = 400
template.factoryScript = "data/scripts/entity/merchants/basefactory.lua"

return template
