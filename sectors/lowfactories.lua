
package.path = package.path .. ";data/scripts/sectors/?.lua"

local template = dofile ("data/scripts/sectors/factoryfield.lua")

template.probability = 350
template.factoryScript = "data/scripts/entity/merchants/lowfactory.lua"

return template
