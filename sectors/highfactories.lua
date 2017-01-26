
package.path = package.path .. ";data/scripts/sectors/?.lua"

local template = dofile ("data/scripts/sectors/factoryfield.lua")

template.probability = 100
template.factoryScript = "data/scripts/entity/merchants/highfactory.lua"

return template
